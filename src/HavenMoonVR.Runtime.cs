using System;
using System.Reflection;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.VR;

[assembly: AssemblyVersion("1.2.0.0")]

namespace HavenMoonVR
{
    public static class CommunityPatch
    {
        private const float InteractionRayLength = 4.0f;
        private const float InteractionDistance = 1.8f;
        // Haven Moon's camera already has a serialized +0.683 m local offset.
        // The VR Origin must compensate both that base offset and the tracked
        // HMD height; otherwise the original camera height is counted twice.
        private const float OriginalCameraHeight = 0.683f;
        private const float DefaultEyeHeight = OriginalCameraHeight;
        private const float HeightStep = 0.05f;
        private const float RecentTargetGraceSeconds = 0.18f;
        private const int ReleaseGraceFrames = 3;
        private const string EyeHeightPreference = "HavenMoonVR_EyeHeight";

        private static readonly SharedPoseReader Shared = new SharedPoseReader();
        private static readonly PointerVisual LeftVisual = new PointerVisual("HavenMoonVR Left Pointer", new Color(0.15f, 0.75f, 1.0f, 1.0f));
        private static readonly PointerVisual RightVisual = new PointerVisual("HavenMoonVR Right Pointer", new Color(1.0f, 0.50f, 0.12f, 1.0f));

        private static GameObject crossHair;
        private static Component canvasUi;
        private static string lastKeyTag = String.Empty;
        private static string lastScene = String.Empty;
        private static int recenterFramesRemaining;
        private static bool previousLeftAction;
        private static bool previousRightAction;
        private static GameObject recentLeftTarget;
        private static GameObject recentRightTarget;
        private static float recentLeftTargetTime;
        private static float recentRightTargetTime;
        private static int leftReleaseGraceFrames;
        private static int rightReleaseGraceFrames;
        private static float desiredEyeHeight = -1.0f;
        private static string waterFallbackScene = String.Empty;
        private static UnityEngine.Object waterFallbackMarker;

        // Haven Moon's original FixedUpdate calls CharacterController.Move twice
        // with the same vector. The patcher redirects the first call here and the
        // second to MoveOnceCenteredOnHead. Returning without moving removes the
        // duplicate while the second helper preserves the original total speed.
        public static CollisionFlags SuppressDuplicateMove(CharacterController controller, Vector3 motion)
        {
            return (CollisionFlags)0;
        }

        // Preserve the distance of the original two Move calls in one continuous
        // sweep. Unity's native VR tracking offsets the child camera horizontally
        // but does not move the parent CharacterController capsule. Keeping the
        // capsule below the tracked head makes visible railing clearance symmetric.
        public static CollisionFlags MoveOnceCenteredOnHead(CharacterController controller, Vector3 motion)
        {
            if (controller == null) return (CollisionFlags)0;

            Camera camera = Camera.main;
            if (camera != null)
            {
                Transform playerTransform = controller.transform;
                Transform cameraTransform = camera.transform;
                if (cameraTransform == playerTransform || cameraTransform.IsChildOf(playerTransform))
                {
                    Vector3 headLocal = playerTransform.InverseTransformPoint(cameraTransform.position);
                    Vector3 center = controller.center;
                    if (Mathf.Abs(center.x - headLocal.x) > 0.0001f ||
                        Mathf.Abs(center.z - headLocal.z) > 0.0001f)
                    {
                        center.x = headLocal.x;
                        center.z = headLocal.z;
                        controller.center = center;
                    }
                }
            }

            return controller.Move(motion * 2.0f);
        }

        public static void Tick(Component controller)
        {
            HideFixedCrossHair();
            ApplyVrSafeOceanFallback();
            UpdateHeightRecenter();

            Camera camera = Camera.main;
            if (camera == null)
            {
                LeftVisual.Hide();
                RightVisual.Hide();
                ResetInteractionMemory();
                PreserveControllerInteractionState(controller, false);
                return;
            }

            PreserveSteamAchievementRay(camera);

            SharedPoseState state;
            if (!Shared.TryRead(out state))
            {
                LeftVisual.Hide();
                RightVisual.Hide();
                ResetInteractionMemory();
                PreserveControllerInteractionState(controller, false);
                SetKeyUi("none");
                return;
            }

            bool isMoving = ReadControllerBool(controller, "isMoving");
            bool isOnMovingPlatform = ReadControllerBool(controller, "isOnMovingPlatform");

            GameObject leftTarget = ResolvePointer(
                LeftVisual,
                camera,
                state.LeftValid,
                state.LeftPosition,
                state.LeftForward,
                isMoving,
                isOnMovingPlatform);

            GameObject rightTarget = ResolvePointer(
                RightVisual,
                camera,
                state.RightValid,
                state.RightPosition,
                state.RightForward,
                isMoving,
                isOnMovingPlatform);

            PreserveControllerInteractionState(controller, leftTarget != null || rightTarget != null);
            UpdateKeyUi(leftTarget, rightTarget, state.LeftAction, state.RightAction);

            UpdateActivation(
                leftTarget,
                state.LeftAction,
                ref previousLeftAction,
                ref recentLeftTarget,
                ref recentLeftTargetTime,
                ref leftReleaseGraceFrames);
            UpdateActivation(
                rightTarget,
                state.RightAction,
                ref previousRightAction,
                ref recentRightTarget,
                ref recentRightTargetTime,
                ref rightReleaseGraceFrames);
        }

        private static void UpdateActivation(
            GameObject target,
            bool action,
            ref bool previousAction,
            ref GameObject recentTarget,
            ref float recentTargetTime,
            ref int releaseGraceFrames)
        {
            float now = Time.realtimeSinceStartup;
            if (target != null)
            {
                recentTarget = target;
                recentTargetTime = now;
            }

            if (previousAction && !action)
                releaseGraceFrames = ReleaseGraceFrames;
            else if (action)
                releaseGraceFrames = 0;

            bool releaseGrace = releaseGraceFrames > 0;
            if (releaseGraceFrames > 0) releaseGraceFrames--;

            GameObject activationTarget = target;
            if (activationTarget == null &&
                recentTarget != null &&
                now - recentTargetTime <= RecentTargetGraceSeconds)
                activationTarget = recentTarget;

            if (activationTarget != null && (action || releaseGrace))
                activationTarget.SendMessage("Activate");

            previousAction = action;
            if (!action &&
                releaseGraceFrames == 0 &&
                recentTarget != null &&
                now - recentTargetTime > RecentTargetGraceSeconds)
                recentTarget = null;
        }

        private static void ResetInteractionMemory()
        {
            previousLeftAction = false;
            previousRightAction = false;
            recentLeftTarget = null;
            recentRightTarget = null;
            recentLeftTargetTime = 0.0f;
            recentRightTargetTime = 0.0f;
            leftReleaseGraceFrames = 0;
            rightReleaseGraceFrames = 0;
        }

        private static GameObject ResolvePointer(
            PointerVisual visual,
            Camera camera,
            bool poseValid,
            Vector3 cameraRelativePosition,
            Vector3 cameraRelativeForward,
            bool isMoving,
            bool isOnMovingPlatform)
        {
            if (!poseValid || cameraRelativeForward.sqrMagnitude < 0.25f)
            {
                visual.Hide();
                return null;
            }

            Vector3 origin = camera.transform.TransformPoint(cameraRelativePosition);
            Vector3 direction = camera.transform.TransformDirection(cameraRelativeForward).normalized;
            RaycastHit hit;
            bool hasHit = Physics.Raycast(new Ray(origin, direction), out hit, InteractionRayLength);
            Vector3 idleEnd = origin + (direction * InteractionRayLength);
            if (hasHit) idleEnd = hit.point;
            visual.ShowIdle(origin, idleEnd);
            if (!hasHit) return null;

            string tag = hit.collider.tag;
            bool activable = tag != null && tag.StartsWith("Activable", StringComparison.Ordinal);
            if (tag == "ActivableIfOnPlatform" && !isOnMovingPlatform)
                activable = false;

            if (!activable || isMoving || hit.distance >= InteractionDistance)
                return null;

            visual.ShowTarget(origin, hit.point);
            return hit.collider.gameObject;
        }

        private static void PreserveSteamAchievementRay(Camera camera)
        {
            RaycastHit hit;
            Ray ray = camera.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0.0f));
            if (Physics.Raycast(ray, out hit, 2.0f) && hit.collider.tag == "SteamAchievement")
                hit.collider.gameObject.SendMessage("ActivateSteamAchievement");
        }

        private static void HideFixedCrossHair()
        {
            if (crossHair == null)
                crossHair = GameObject.Find("UI_CrossHair");
            if (crossHair != null && crossHair.activeSelf)
                crossHair.SetActive(false);
        }

        private static void ApplyVrSafeOceanFallback()
        {
            string scene = SceneManager.GetActiveScene().name;
            if (scene == waterFallbackScene && waterFallbackMarker != null) return;

            try
            {
                int fogCount = 0;
                int tileCount = 0;
                int waterCount = 0;
                UnityEngine.Object sceneMarker = null;

                // Haven Moon attaches both GlobalFog and GlobalFogWATER to the
                // player camera. Their legacy full-screen blits reconstruct one
                // symmetric desktop frustum from Camera.fieldOfView/aspect. In
                // stereo VR each eye has an asymmetric projection, so rolling
                // the HMD exposes an unrendered black wedge at the horizon.
                // Keep Unity's native scene fog, but remove these two incompatible
                // post-processing passes from the community VR runtime.
                string[] legacyFogTypes = new string[]
                {
                    "UnityStandardAssets.ImageEffects.GlobalFog",
                    "UnityStandardAssets.ImageEffects.GlobalFogWATER"
                };
                for (int fogTypeIndex = 0; fogTypeIndex < legacyFogTypes.Length; fogTypeIndex++)
                {
                    Type fogType = FindLoadedType(legacyFogTypes[fogTypeIndex]);
                    if (fogType == null) continue;

                    UnityEngine.Object[] fogEffects = UnityEngine.Object.FindObjectsOfType(fogType);
                    if (sceneMarker == null && fogEffects.Length > 0) sceneMarker = fogEffects[0];
                    for (int i = 0; i < fogEffects.Length; i++)
                    {
                        Behaviour behaviour = fogEffects[i] as Behaviour;
                        if (behaviour != null && behaviour.enabled)
                        {
                            behaviour.enabled = false;
                            fogCount++;
                        }
                    }
                }

                Type tileType = FindLoadedType("UnityStandardAssets.Water.WaterTile");
                if (tileType != null)
                {
                    FieldInfo reflectionField = tileType.GetField(
                        "reflection",
                        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                    UnityEngine.Object[] tiles = UnityEngine.Object.FindObjectsOfType(tileType);
                    if (tiles.Length > 0) sceneMarker = tiles[0];
                    if (reflectionField != null)
                    {
                        for (int i = 0; i < tiles.Length; i++)
                        {
                            // WaterTile calls PlanarReflection directly even when that
                            // component is disabled, so clear its cached reference.
                            reflectionField.SetValue(tiles[i], null);
                            tileCount++;
                        }
                    }
                }

                Type reflectionType = FindLoadedType("UnityStandardAssets.Water.PlanarReflection");
                if (reflectionType != null)
                {
                    UnityEngine.Object[] reflections = UnityEngine.Object.FindObjectsOfType(reflectionType);
                    for (int i = 0; i < reflections.Length; i++)
                    {
                        Behaviour behaviour = reflections[i] as Behaviour;
                        if (behaviour != null) behaviour.enabled = false;
                    }
                }

                Type waterBaseType = FindLoadedType("UnityStandardAssets.Water.WaterBase");
                if (waterBaseType != null)
                {
                    FieldInfo qualityField = waterBaseType.GetField(
                        "waterQuality",
                        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                    FieldInfo edgeBlendField = waterBaseType.GetField(
                        "edgeBlend",
                        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                    MethodInfo updateShader = waterBaseType.GetMethod(
                        "UpdateShader",
                        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                    UnityEngine.Object[] waterBases = UnityEngine.Object.FindObjectsOfType(waterBaseType);
                    if (sceneMarker == null && waterBases.Length > 0) sceneMarker = waterBases[0];
                    for (int i = 0; i < waterBases.Length; i++)
                    {
                        if (qualityField != null)
                            // Water4 Medium unlocks its improved 300-LOD pass without
                            // the 500-LOD screen GrabPass, which is unsafe in legacy VR.
                            qualityField.SetValue(waterBases[i], Enum.ToObject(qualityField.FieldType, 1));
                        if (edgeBlendField != null)
                            edgeBlendField.SetValue(waterBases[i], false);
                        if (updateShader != null)
                            updateShader.Invoke(waterBases[i], null);
                        waterCount++;
                    }
                }

                int cinematicProfiles = ApplyCinematicRenderingProfile();
                waterFallbackScene = scene;
                waterFallbackMarker = sceneMarker != null ? sceneMarker : Camera.main;
                if (fogCount > 0 || tileCount > 0 || waterCount > 0)
                    Debug.Log(
                        "HavenMoonVR VR-safe horizon fallback: " + fogCount +
                        " legacy fog pass(es) disabled; planar reflection disabled; stereo-safe Water4 300-LOD shader enabled; " +
                        cinematicProfiles + " cinematic post-processing profile(s) configured.");
            }
            catch (Exception exception)
            {
                waterFallbackScene = scene;
                waterFallbackMarker = Camera.main;
                Debug.LogWarning("HavenMoonVR could not apply the VR-safe ocean fallback: " + exception.Message);
            }
        }

        private static int ApplyCinematicRenderingProfile()
        {
            // This intentionally prioritises image quality over GPU cost. All
            // changes operate on normal scene rendering or per-eye-safe colour
            // effects; the legacy fog and planar-reflection passes remain off.
            Shader.globalMaximumLOD = 1000;
            QualitySettings.masterTextureLimit = 0;
            QualitySettings.anisotropicFiltering = AnisotropicFiltering.ForceEnable;
            QualitySettings.lodBias = 4.0f;
            QualitySettings.maximumLODLevel = 0;
            QualitySettings.pixelLightCount = 32;
            QualitySettings.shadowResolution = ShadowResolution.VeryHigh;
            QualitySettings.shadowProjection = ShadowProjection.StableFit;
            QualitySettings.shadowCascades = 4;
            QualitySettings.shadowDistance = 250.0f;
            QualitySettings.realtimeReflectionProbes = true;
            QualitySettings.antiAliasing = 8;

            UnityEngine.Object[] shaders = Resources.FindObjectsOfTypeAll(typeof(Shader));
            for (int i = 0; i < shaders.Length; i++)
            {
                Shader shader = shaders[i] as Shader;
                if (shader != null)
                    shader.maximumLOD = shader.name == "FX/Water4" ? 301 : 1000;
            }

            UnityEngine.Object[] textures = Resources.FindObjectsOfTypeAll(typeof(Texture2D));
            for (int i = 0; i < textures.Length; i++)
            {
                Texture2D texture = textures[i] as Texture2D;
                if (texture == null) continue;
                texture.anisoLevel = 16;
                texture.filterMode = FilterMode.Trilinear;
                texture.mipMapBias = -0.35f;
            }

            UnityEngine.Object[] cameras = UnityEngine.Object.FindObjectsOfType(typeof(Camera));
            for (int i = 0; i < cameras.Length; i++)
            {
                Camera camera = cameras[i] as Camera;
                if (camera == null) continue;
                camera.hdr = true;
                camera.depthTextureMode |= DepthTextureMode.DepthNormals;
            }

            UnityEngine.Object[] terrains = UnityEngine.Object.FindObjectsOfType(typeof(Terrain));
            for (int i = 0; i < terrains.Length; i++)
            {
                Terrain terrain = terrains[i] as Terrain;
                if (terrain == null) continue;
                terrain.heightmapPixelError = 1.0f;
                terrain.basemapDistance = 10000.0f;
                terrain.detailObjectDensity = 1.0f;
                terrain.detailObjectDistance = 300.0f;
                terrain.treeDistance = 5000.0f;
                terrain.treeBillboardDistance = 1000.0f;
                terrain.treeCrossFadeLength = 200.0f;
                terrain.treeMaximumFullLODCount = 500;
            }

            UnityEngine.Object[] lights = UnityEngine.Object.FindObjectsOfType(typeof(Light));
            for (int i = 0; i < lights.Length; i++)
            {
                Light light = lights[i] as Light;
                if (light != null && light.shadows != LightShadows.None)
                    light.shadowResolution = LightShadowResolution.VeryHigh;
            }

            return ConfigureCinematicPostProcessing();
        }

        private static int ConfigureCinematicPostProcessing()
        {
            Type behaviourType = FindLoadedType("UnityEngine.PostProcessing.PostProcessingBehaviour");
            Type profileType = FindLoadedType("UnityEngine.PostProcessing.PostProcessingProfile");
            if (behaviourType == null || profileType == null) return 0;

            UnityEngine.Object[] profiles = Resources.FindObjectsOfTypeAll(profileType);
            UnityEngine.Object normalProfile = null;
            for (int i = 0; i < profiles.Length; i++)
            {
                if (profiles[i] != null && profiles[i].name == "HM_PostProcessings_Normal")
                {
                    normalProfile = profiles[i];
                    break;
                }
            }
            if (normalProfile == null) return 0;

            ConfigureAmbientOcclusion(normalProfile);
            ConfigureBloom(normalProfile);
            ConfigureColorGrading(normalProfile);
            SetPostProcessingModelEnabled(normalProfile, "screenSpaceReflection", false);
            SetPostProcessingModelEnabled(normalProfile, "depthOfField", false);
            SetPostProcessingModelEnabled(normalProfile, "motionBlur", false);
            SetPostProcessingModelEnabled(normalProfile, "eyeAdaptation", false);
            SetPostProcessingModelEnabled(normalProfile, "chromaticAberration", false);
            SetPostProcessingModelEnabled(normalProfile, "grain", false);
            SetPostProcessingModelEnabled(normalProfile, "vignette", false);

            FieldInfo profileField = FindInstanceField(behaviourType, "profile");
            if (profileField == null) return 0;

            int configured = 0;
            UnityEngine.Object[] behaviours = UnityEngine.Object.FindObjectsOfType(behaviourType);
            for (int i = 0; i < behaviours.Length; i++)
            {
                if (behaviours[i] == null) continue;
                profileField.SetValue(behaviours[i], normalProfile);
                Behaviour behaviour = behaviours[i] as Behaviour;
                if (behaviour != null) behaviour.enabled = true;
                configured++;
            }
            return configured;
        }

        private static void ConfigureAmbientOcclusion(object profile)
        {
            object model = GetPostProcessingModel(profile, "ambientOcclusion");
            if (model == null) return;
            SetModelEnabled(model, true);

            FieldInfo settingsField = FindInstanceField(model.GetType(), "m_Settings");
            if (settingsField == null) return;
            object settings = settingsField.GetValue(model);
            SetValue(settings, "intensity", 2.0f);
            SetValue(settings, "radius", 0.45f);
            SetValue(settings, "sampleCount", 3);
            SetValue(settings, "downsampling", false);
            SetValue(settings, "ambientOnly", false);
            SetValue(settings, "highPrecision", true);
            settingsField.SetValue(model, settings);
        }

        private static void ConfigureBloom(object profile)
        {
            object model = GetPostProcessingModel(profile, "bloom");
            if (model == null) return;
            SetModelEnabled(model, true);

            FieldInfo settingsField = FindInstanceField(model.GetType(), "m_Settings");
            if (settingsField == null) return;
            object settings = settingsField.GetValue(model);
            FieldInfo bloomField = FindInstanceField(settings.GetType(), "bloom");
            if (bloomField == null) return;
            object bloom = bloomField.GetValue(settings);
            SetValue(bloom, "intensity", 0.8f);
            SetValue(bloom, "threshold", 1.05f);
            SetValue(bloom, "softKnee", 0.75f);
            SetValue(bloom, "radius", 7.0f);
            SetValue(bloom, "antiFlicker", true);
            bloomField.SetValue(settings, bloom);
            settingsField.SetValue(model, settings);
        }

        private static void ConfigureColorGrading(object profile)
        {
            object model = GetPostProcessingModel(profile, "colorGrading");
            if (model == null) return;
            SetModelEnabled(model, true);

            FieldInfo settingsField = FindInstanceField(model.GetType(), "m_Settings");
            if (settingsField == null) return;
            object settings = settingsField.GetValue(model);

            FieldInfo tonemappingField = FindInstanceField(settings.GetType(), "tonemapping");
            if (tonemappingField != null)
            {
                object tonemapping = tonemappingField.GetValue(settings);
                SetValue(tonemapping, "tonemapper", 1); // ACES
                tonemappingField.SetValue(settings, tonemapping);
            }

            FieldInfo basicField = FindInstanceField(settings.GetType(), "basic");
            if (basicField != null)
            {
                object basic = basicField.GetValue(settings);
                SetValue(basic, "postExposure", 0.10f);
                SetValue(basic, "saturation", 1.08f);
                SetValue(basic, "contrast", 1.12f);
                basicField.SetValue(settings, basic);
            }

            settingsField.SetValue(model, settings);
            PropertyInfo dirtyProperty = model.GetType().GetProperty(
                "isDirty", BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (dirtyProperty != null && dirtyProperty.CanWrite)
                dirtyProperty.SetValue(model, true, null);
        }

        private static object GetPostProcessingModel(object profile, string fieldName)
        {
            if (profile == null) return null;
            FieldInfo field = FindInstanceField(profile.GetType(), fieldName);
            return field != null ? field.GetValue(profile) : null;
        }

        private static void SetPostProcessingModelEnabled(object profile, string fieldName, bool enabled)
        {
            object model = GetPostProcessingModel(profile, fieldName);
            if (model != null) SetModelEnabled(model, enabled);
        }

        private static void SetModelEnabled(object model, bool enabled)
        {
            FieldInfo enabledField = FindInstanceField(model.GetType(), "m_Enabled");
            if (enabledField != null) enabledField.SetValue(model, enabled);
        }

        private static void SetValue(object target, string fieldName, object value)
        {
            if (target == null) return;
            FieldInfo field = FindInstanceField(target.GetType(), fieldName);
            if (field == null) return;
            if (field.FieldType.IsEnum)
                field.SetValue(target, Enum.ToObject(field.FieldType, Convert.ToInt32(value)));
            else
                field.SetValue(target, value);
        }

        private static FieldInfo FindInstanceField(Type type, string name)
        {
            while (type != null)
            {
                FieldInfo field = type.GetField(
                    name, BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                if (field != null) return field;
                type = type.BaseType;
            }
            return null;
        }

        private static Type FindLoadedType(string fullName)
        {
            Assembly[] assemblies = AppDomain.CurrentDomain.GetAssemblies();
            for (int i = 0; i < assemblies.Length; i++)
            {
                Type type = assemblies[i].GetType(fullName, false);
                if (type != null) return type;
            }
            return null;
        }

        private static bool ReadControllerBool(Component controller, string fieldName)
        {
            if (controller == null) return false;
            FieldInfo field = controller.GetType().GetField(
                fieldName,
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            return field != null && field.FieldType == typeof(bool) && (bool)field.GetValue(controller);
        }

        private static int ReadControllerInt(Component controller, string fieldName)
        {
            if (controller == null) return 0;
            FieldInfo field = controller.GetType().GetField(
                fieldName,
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            return field != null && field.FieldType == typeof(int) ? (int)field.GetValue(controller) : 0;
        }

        private static void WriteControllerBool(Component controller, string fieldName, bool value)
        {
            if (controller == null) return;
            FieldInfo field = controller.GetType().GetField(
                fieldName,
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (field != null && field.FieldType == typeof(bool)) field.SetValue(controller, value);
        }

        private static void PreserveControllerInteractionState(Component controller, bool hasTarget)
        {
            int controlStyle = ReadControllerInt(controller, "controlStyle");
            if (controlStyle == 1)
            {
                WriteControllerBool(controller, "canMove", !hasTarget);
                WriteControllerBool(controller, "isGreen", false);
            }
            else
            {
                WriteControllerBool(controller, "isGreen", hasTarget);
                if (!hasTarget) WriteControllerBool(controller, "canMove", true);
            }
        }

        private static void UpdateKeyUi(GameObject leftTarget, GameObject rightTarget, bool leftAction, bool rightAction)
        {
            string leftTag = KeyTag(leftTarget);
            string rightTag = KeyTag(rightTarget);
            string selected = "none";
            if (rightAction && rightTag != null) selected = rightTag;
            else if (leftAction && leftTag != null) selected = leftTag;
            else if (rightTag != null) selected = rightTag;
            else if (leftTag != null) selected = leftTag;
            SetKeyUi(selected);
        }

        private static string KeyTag(GameObject target)
        {
            if (target == null) return null;
            string tag = target.tag;
            return tag != null && tag.StartsWith("ActivableKEY_", StringComparison.Ordinal) ? tag : null;
        }

        private static void SetKeyUi(string tag)
        {
            if (lastKeyTag == tag) return;
            lastKeyTag = tag;

            if (canvasUi == null)
            {
                GameObject canvas = GameObject.Find("CanvasController");
                if (canvas != null) canvasUi = canvas.GetComponent("InGameUI");
            }
            if (canvasUi == null) return;

            MethodInfo method = canvasUi.GetType().GetMethod(
                "LightUpUIKey",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
            if (method != null) method.Invoke(canvasUi, new object[] { tag });
        }

        private static void UpdateHeightRecenter()
        {
            string scene = SceneManager.GetActiveScene().name;
            if (scene != lastScene)
            {
                lastScene = scene;
                recenterFramesRemaining = 900;
                crossHair = null;
                canvasUi = null;
                lastKeyTag = String.Empty;
            }

            if (Input.GetKeyDown(KeyCode.F7) || Input.GetKeyDown(KeyCode.F9))
            {
                float delta = Input.GetKeyDown(KeyCode.F7) ? -HeightStep : HeightStep;
                desiredEyeHeight = Mathf.Clamp(GetDesiredEyeHeight() + delta, 0.25f, 0.85f);
                PlayerPrefs.SetFloat(EyeHeightPreference, desiredEyeHeight);
                PlayerPrefs.Save();
                TryRecenterHeight(true);
                recenterFramesRemaining = 0;
                Debug.Log("HavenMoonVR eye height: " + desiredEyeHeight.ToString("0.00") + " m");
            }
            else if (Input.GetKeyDown(KeyCode.F8))
            {
                TryRecenterHeight(true);
                recenterFramesRemaining = 0;
            }
            else if (recenterFramesRemaining > 0)
            {
                if (TryRecenterHeight(false)) recenterFramesRemaining = 0;
                else recenterFramesRemaining--;
            }
        }

        private static bool TryRecenterHeight(bool manual)
        {
            GameObject origin = GameObject.Find("VR Origin");
            if (origin == null) return false;

            Vector3 tracked = InputTracking.GetLocalPosition(VRNode.CenterEye);
            if (tracked.y <= 0.75f && !manual) return false;
            if (tracked.y <= 0.05f) return false;

            Vector3 position = origin.transform.localPosition;
            position.y = GetDesiredEyeHeight() - OriginalCameraHeight - tracked.y;
            origin.transform.localPosition = position;
            return true;
        }

        private static float GetDesiredEyeHeight()
        {
            if (desiredEyeHeight < 0.0f)
                desiredEyeHeight = Mathf.Clamp(PlayerPrefs.GetFloat(EyeHeightPreference, DefaultEyeHeight), 0.25f, 0.85f);
            return desiredEyeHeight;
        }
    }

    internal sealed class PointerVisual
    {
        private readonly string name;
        private readonly Color color;
        private readonly Color idleColor;
        private Material material;
        private LineRenderer line;
        private GameObject dot;

        public PointerVisual(string name, Color color)
        {
            this.name = name;
            this.color = color;
            this.idleColor = new Color(color.r * 0.60f, color.g * 0.60f, color.b * 0.60f, 1.0f);
        }

        public void ShowIdle(Vector3 origin, Vector3 endPoint)
        {
            EnsureCreated();
            line.enabled = true;
            line.SetWidth(0.003f, 0.003f);
            line.SetColors(idleColor, idleColor);
            if (material != null) material.color = idleColor;
            line.SetPosition(0, origin);
            line.SetPosition(1, endPoint);
            dot.SetActive(false);
        }

        public void ShowTarget(Vector3 origin, Vector3 hitPoint)
        {
            EnsureCreated();
            line.enabled = true;
            line.SetWidth(0.004f, 0.004f);
            line.SetColors(color, color);
            if (material != null) material.color = color;
            line.SetPosition(0, origin);
            line.SetPosition(1, hitPoint);
            dot.SetActive(true);
            dot.transform.position = hitPoint - ((hitPoint - origin).normalized * 0.006f);
        }

        public void Hide()
        {
            if (line != null) line.enabled = false;
            if (dot != null) dot.SetActive(false);
        }

        private void EnsureCreated()
        {
            if (line != null && dot != null) return;

            Shader shader = Shader.Find("Unlit/Color");
            if (shader == null) shader = Shader.Find("Sprites/Default");
            if (shader == null) shader = Shader.Find("Diffuse");
            material = shader != null ? new Material(shader) : null;
            if (material != null) material.color = color;

            GameObject lineObject = new GameObject(name + " Ray");
            line = lineObject.AddComponent<LineRenderer>();
            line.useWorldSpace = true;
            line.SetVertexCount(2);
            line.SetWidth(0.003f, 0.003f);
            line.SetColors(color, color);
            if (material != null) line.material = material;

            dot = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            dot.name = name + " Hit";
            dot.transform.localScale = new Vector3(0.018f, 0.018f, 0.018f);
            Collider collider = dot.GetComponent<Collider>();
            if (collider != null) UnityEngine.Object.Destroy(collider);
            Renderer renderer = dot.GetComponent<Renderer>();
            if (renderer != null && material != null) renderer.material = material;
        }
    }

    internal struct SharedPoseState
    {
        public bool LeftValid;
        public bool RightValid;
        public bool LeftAction;
        public bool RightAction;
        public Vector3 LeftPosition;
        public Vector3 LeftForward;
        public Vector3 RightPosition;
        public Vector3 RightForward;
    }

    internal sealed class SharedPoseReader
    {
        private const string MappingName = "Local\\HavenMoonVR_1_2_ControllerState";
        private const int FileMapRead = 0x0004;
        private const int Magic = 0x31564D48;
        private IntPtr mapping;
        private IntPtr view;
        private long nextOpenAttempt;

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr OpenFileMapping(int desiredAccess, bool inheritHandle, string name);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr MapViewOfFile(IntPtr mapping, int desiredAccess, int offsetHigh, int offsetLow, UIntPtr bytesToMap);

        public bool TryRead(out SharedPoseState state)
        {
            state = new SharedPoseState();
            if (!EnsureOpen()) return false;

            int sequenceBefore = Marshal.ReadInt32(view, 8);
            if ((sequenceBefore & 1) != 0) return false;
            if (Marshal.ReadInt32(view, 0) != Magic || Marshal.ReadInt32(view, 4) != 1) return false;

            int flags = Marshal.ReadInt32(view, 12);
            long ticks = Marshal.ReadInt64(view, 16);
            float[] values = new float[12];
            Marshal.Copy(Plus(view, 24), values, 0, values.Length);

            int sequenceAfter = Marshal.ReadInt32(view, 8);
            if (sequenceBefore != sequenceAfter || (sequenceAfter & 1) != 0) return false;
            if (DateTime.UtcNow.Ticks - ticks > TimeSpan.TicksPerSecond) return false;

            state.LeftValid = (flags & 1) != 0;
            state.RightValid = (flags & 2) != 0;
            state.LeftAction = (flags & 4) != 0;
            state.RightAction = (flags & 8) != 0;
            state.LeftPosition = new Vector3(values[0], values[1], values[2]);
            state.LeftForward = new Vector3(values[3], values[4], values[5]);
            state.RightPosition = new Vector3(values[6], values[7], values[8]);
            state.RightForward = new Vector3(values[9], values[10], values[11]);
            return true;
        }

        private bool EnsureOpen()
        {
            if (view != IntPtr.Zero) return true;
            long now = DateTime.UtcNow.Ticks;
            if (now < nextOpenAttempt) return false;
            nextOpenAttempt = now + TimeSpan.TicksPerSecond;

            mapping = OpenFileMapping(FileMapRead, false, MappingName);
            if (mapping == IntPtr.Zero) return false;
            view = MapViewOfFile(mapping, FileMapRead, 0, 0, new UIntPtr(80));
            return view != IntPtr.Zero;
        }

        private static IntPtr Plus(IntPtr pointer, int offset)
        {
            return new IntPtr(pointer.ToInt64() + offset);
        }
    }
}
