using System;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using Mono.Cecil;
using Mono.Cecil.Cil;

internal static class HavenMoonVRAssemblyPatcher
{
    private const string SupportedOriginalSha256 = "863be6215489f7cce586539cc5feb146587cf433dabf31bac326e1a366d164f5";

    public static int Main(string[] args)
    {
        if (args.Length < 2 || args.Length > 3)
        {
            Console.Error.WriteLine("Usage: HavenMoonVR.AssemblyPatcher.exe <clean Assembly-CSharp.dll> <output Assembly-CSharp.dll> [game Managed directory]");
            return 2;
        }

        try
        {
            string input = Path.GetFullPath(args[0]);
            string output = Path.GetFullPath(args[1]);
            string hash = FileSha256(input);
            if (!String.Equals(hash, SupportedOriginalSha256, StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException("Unsupported clean Assembly-CSharp.dll. SHA-256: " + hash);

            DefaultAssemblyResolver resolver = new DefaultAssemblyResolver();
            resolver.AddSearchDirectory(Path.GetDirectoryName(input));
            resolver.AddSearchDirectory(AppDomain.CurrentDomain.BaseDirectory);
            if (args.Length == 3) resolver.AddSearchDirectory(Path.GetFullPath(args[2]));
            AssemblyDefinition assembly = AssemblyDefinition.ReadAssembly(input, new ReaderParameters
            {
                ReadingMode = ReadingMode.Immediate,
                AssemblyResolver = resolver
            });
            ModuleDefinition module = assembly.MainModule;
            TypeDefinition controller = module.Types
                .SelectMany(AllTypes)
                .First(t => t.FullName == "UnityStandardAssets.Characters.FirstPerson.FirstPersonControllerHM");
            MethodDefinition update = controller.Methods.First(m => m.Name == "Update" && !m.HasParameters);

            Instruction firstCentralRay = update.Body.Instructions.First(i =>
            {
                MethodReference method = i.Operand as MethodReference;
                return method != null && method.Name == "get_main" && method.DeclaringType.FullName == "UnityEngine.Camera";
            });

            Instruction ladderStart = null;
            for (int index = update.Body.Instructions.IndexOf(firstCentralRay); index < update.Body.Instructions.Count; index++)
            {
                FieldReference field = update.Body.Instructions[index].Operand as FieldReference;
                if (field != null && field.Name == "isOnLadder")
                {
                    ladderStart = update.Body.Instructions[index - 1];
                    break;
                }
            }
            if (ladderStart == null) throw new InvalidOperationException("Could not locate the post-interaction ladder block.");

            AssemblyNameReference helperAssembly = module.AssemblyReferences.FirstOrDefault(a => a.Name == "HavenMoonVR.Experimental");
            if (helperAssembly == null)
            {
                helperAssembly = new AssemblyNameReference("HavenMoonVR.Experimental", new Version(1, 1, 0, 0));
                module.AssemblyReferences.Add(helperAssembly);
            }

            AssemblyNameReference unityAssembly = module.AssemblyReferences.First(a => a.Name == "UnityEngine");
            TypeReference componentType = new TypeReference("UnityEngine", "Component", module, unityAssembly, false);
            TypeReference helperType = new TypeReference("HavenMoonVR", "ExperimentalPointers", module, helperAssembly, false);
            MethodReference tick = new MethodReference("Tick", module.TypeSystem.Void, helperType)
            {
                HasThis = false,
                ExplicitThis = false,
                CallingConvention = MethodCallingConvention.Default
            };
            tick.Parameters.Add(new ParameterDefinition(componentType));

            ILProcessor il = update.Body.GetILProcessor();
            Instruction loadController = il.Create(OpCodes.Ldarg_0);
            Instruction callTick = il.Create(OpCodes.Call, tick);
            Instruction skipCentralInteraction = il.Create(OpCodes.Br, ladderStart);
            il.InsertBefore(firstCentralRay, loadController);
            il.InsertAfter(loadController, callTick);
            il.InsertAfter(callTick, skipCentralInteraction);

            update.Body.MaxStackSize = Math.Max(update.Body.MaxStackSize, 2);
            assembly.Write(output, new WriterParameters { WriteSymbols = false });
            assembly.Dispose();

            AssemblyDefinition check = AssemblyDefinition.ReadAssembly(output, new ReaderParameters
            {
                ReadingMode = ReadingMode.Immediate,
                AssemblyResolver = resolver
            });
            MethodDefinition checkedUpdate = check.MainModule.Types
                .SelectMany(AllTypes)
                .First(t => t.FullName == controller.FullName)
                .Methods.First(m => m.Name == "Update" && !m.HasParameters);
            bool callPresent = checkedUpdate.Body.Instructions.Any(i =>
            {
                MethodReference method = i.Operand as MethodReference;
                return method != null && method.FullName == "System.Void HavenMoonVR.ExperimentalPointers::Tick(UnityEngine.Component)";
            });
            check.Dispose();
            if (!callPresent) throw new InvalidOperationException("Post-write verification did not find the experimental pointer hook.");

            Console.WriteLine(FileSha256(output));
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("ERROR: " + ex.Message);
            return 1;
        }
    }

    private static System.Collections.Generic.IEnumerable<TypeDefinition> AllTypes(TypeDefinition type)
    {
        yield return type;
        foreach (TypeDefinition nested in type.NestedTypes)
            foreach (TypeDefinition descendant in AllTypes(nested))
                yield return descendant;
    }

    private static string FileSha256(string path)
    {
        using (SHA256 sha = SHA256.Create())
        using (FileStream stream = File.OpenRead(path))
            return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", String.Empty).ToLowerInvariant();
    }
}
