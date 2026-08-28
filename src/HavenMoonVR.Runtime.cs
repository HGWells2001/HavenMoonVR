using System;
using System.Reflection;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.VR;

[assembly: AssemblyVersion("1.2.6.0")]

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
        private static string planarReflectionScene = String.Empty;
        private static UnityEngine.Object planarReflectionMarker;
        private static string enhancedWaterScene = String.Empty;
        private static UnityEngine.Object enhancedWaterMarker;

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
            DisableOceanPlanarReflection();
            EnhanceOceanWater();
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

        private static void DisableOceanPlanarReflection()
        {
            string scene = SceneManager.GetActiveScene().name;
            if (scene == planarReflectionScene && planarReflectionMarker != null) return;

            try
            {
                int disconnectedTiles = 0;
                int disabledReflections = 0;
                UnityEngine.Object marker = null;

                Type tileType = FindLoadedType("UnityStandardAssets.Water.WaterTile");
                if (tileType != null)
                {
                    FieldInfo reflectionField = tileType.GetField(
                        "reflection",
                        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                    UnityEngine.Object[] tiles = UnityEngine.Object.FindObjectsOfType(tileType);
                    if (tiles.Length > 0) marker = tiles[0];
                    if (reflectionField != null)
                    {
                        for (int i = 0; i < tiles.Length; i++)
                        {
                            if (reflectionField.GetValue(tiles[i]) != null)
                            {
                                reflectionField.SetValue(tiles[i], null);
                                disconnectedTiles++;
                            }
                        }
                    }
                }

                Type reflectionType = FindLoadedType("UnityStandardAssets.Water.PlanarReflection");
                if (reflectionType != null)
                {
                    UnityEngine.Object[] reflections = UnityEngine.Object.FindObjectsOfType(reflectionType);
                    if (marker == null && reflections.Length > 0) marker = reflections[0];
                    for (int i = 0; i < reflections.Length; i++)
                    {
                        Behaviour behaviour = reflections[i] as Behaviour;
                        if (behaviour != null && behaviour.enabled)
                        {
                            behaviour.enabled = false;
                            disabledReflections++;
                        }
                    }
                }

                if (marker == null) return;
                planarReflectionScene = scene;
                planarReflectionMarker = marker;
                if (disconnectedTiles > 0 || disabledReflections > 0)
                    Debug.Log("[HavenMoonVR] Ocean planar reflection disabled: " +
                        disconnectedTiles + " WaterTile reference(s) disconnected, " +
                        disabledReflections + " reflection component(s) disabled. Other original rendering remains active.");
            }
            catch (Exception ex)
            {
                Debug.LogWarning("[HavenMoonVR] Could not disable the ocean planar reflection: " + ex.Message);
            }
        }

        private static void EnhanceOceanWater()
        {
            string scene = SceneManager.GetActiveScene().name;
            if (scene == enhancedWaterScene && enhancedWaterMarker != null) return;

            try
            {
                int materialCount = 0;
                int textureCount = 0;
                UnityEngine.Object marker = null;
                UnityEngine.Object[] materials = Resources.FindObjectsOfTypeAll(typeof(Material));
                for (int i = 0; i < materials.Length; i++)
                {
                    Material material = materials[i] as Material;
                    if (material == null || material.shader == null || material.shader.name != "FX/Water4")
                        continue;

                    if (marker == null) marker = material;
                    if (material.HasProperty("_FresnelScale"))
                        material.SetFloat("_FresnelScale", 0.25f);
                    if (material.HasProperty("_ReflectionColor"))
                        material.SetColor("_ReflectionColor", new Color(0.24f, 0.39f, 0.50f, 0.50f));
                    if (material.HasProperty("_Shininess"))
                        material.SetFloat("_Shininess", 45.0f);
                    if (material.HasProperty("_Foam"))
                    {
                        Vector4 foam = material.GetVector("_Foam");
                        foam.x = Mathf.Max(foam.x, 0.24f);
                        material.SetVector("_Foam", foam);
                    }

                    textureCount += EnhanceWaterTexture(material, "_BumpMap");
                    textureCount += EnhanceWaterTexture(material, "_ShoreTex");
                    materialCount++;
                }

                if (marker == null) return;
                enhancedWaterScene = scene;
                enhancedWaterMarker = marker;
                Debug.Log("[HavenMoonVR] Water Enhanced VR applied to " + materialCount +
                    " Water4 material(s): stronger Fresnel, sharper sun highlight, subtle foam boost and " +
                    textureCount + " filtered water texture(s). Planar reflection remains disabled.");
            }
            catch (Exception ex)
            {
                Debug.LogWarning("[HavenMoonVR] Could not apply Water Enhanced VR: " + ex.Message);
            }
        }

        private static int EnhanceWaterTexture(Material material, string propertyName)
        {
            if (!material.HasProperty(propertyName)) return 0;
            Texture texture = material.GetTexture(propertyName);
            if (texture == null) return 0;
            texture.anisoLevel = 8;
            texture.filterMode = FilterMode.Trilinear;
            return 1;
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
