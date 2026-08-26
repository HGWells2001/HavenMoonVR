using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;

internal static class HavenMoonVRSteamShortcutTool
{
    private sealed class VdfNode
    {
        public byte Type;
        public string Name;
        public object Value;
        public List<VdfNode> Children;
    }

    public static int Main(string[] args)
    {
        if (args.Length < 3 || (args[0] != "add" && args[0] != "remove"))
        {
            Console.Error.WriteLine("Usage: HavenMoonVR.SteamShortcutTool.exe add <shortcuts.vdf> <exe> <name> [icon]");
            Console.Error.WriteLine("       HavenMoonVR.SteamShortcutTool.exe remove <shortcuts.vdf> <name>");
            return 2;
        }

        try
        {
            string command = args[0];
            if (command == "add" && args.Length != 4 && args.Length != 5) throw new ArgumentException("The add command requires an executable path, app name and optional icon path.");
            if (command == "remove" && args.Length != 3) throw new ArgumentException("The remove command requires an app name.");
            string path = Path.GetFullPath(args[1]);
            string appName = command == "add" ? args[3] : args[2];
            string iconPath = command == "add" && args.Length == 5
                ? Path.GetFullPath(args[4])
                : null;

            VdfNode root = File.Exists(path) && new FileInfo(path).Length > 0
                ? Parse(File.ReadAllBytes(path))
                : NewObject("shortcuts");

            if (root.Type != 0 || !String.Equals(root.Name, "shortcuts", StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("This is not a Steam shortcuts.vdf file.");

            int preservedBefore = root.Children.Count(n =>
                !String.Equals(GetString(n, "AppName"), appName, StringComparison.OrdinalIgnoreCase));
            uint appId = 0;
            bool changed = command == "add"
                ? AddOrUpdate(root, Path.GetFullPath(args[2]), appName, iconPath, out appId)
                : Remove(root, appName);

            if (!changed)
            {
                if (command == "add") Console.WriteLine("APPID=" + appId.ToString(CultureInfo.InvariantCulture));
                Console.WriteLine("UNCHANGED");
                return 0;
            }

            for (int index = 0; index < root.Children.Count; index++)
                root.Children[index].Name = index.ToString(CultureInfo.InvariantCulture);

            byte[] encoded = Serialize(root);
            VdfNode verification = Parse(encoded);
            int preservedAfter = verification.Children.Count(n =>
                !String.Equals(GetString(n, "AppName"), appName, StringComparison.OrdinalIgnoreCase));
            int targetAfter = verification.Children.Count(n =>
                String.Equals(GetString(n, "AppName"), appName, StringComparison.OrdinalIgnoreCase));
            if (preservedAfter != preservedBefore || (command == "add" ? targetAfter != 1 : targetAfter != 0))
                throw new InvalidDataException("Internal VDF verification failed; existing shortcuts would be lost.");

            string directory = Path.GetDirectoryName(path);
            if (!Directory.Exists(directory)) Directory.CreateDirectory(directory);
            if (File.Exists(path))
            {
                string backup = path + ".havenmoonvr-backup-" +
                    DateTime.Now.ToString("yyyyMMdd-HHmmss-fff", CultureInfo.InvariantCulture) + "-" +
                    Guid.NewGuid().ToString("N").Substring(0, 8) + ".bak";
                File.Copy(path, backup, false);
                Console.WriteLine("BACKUP=" + backup);
            }

            string temporary = path + ".havenmoonvr-tmp-" + Guid.NewGuid().ToString("N");
            File.WriteAllBytes(temporary, encoded);
            if (File.Exists(path)) File.Replace(temporary, path, null);
            else File.Move(temporary, path);
            Console.WriteLine(command == "add" ? "ADDED_OR_UPDATED" : "REMOVED");
            if (command == "add") Console.WriteLine("APPID=" + appId.ToString(CultureInfo.InvariantCulture));
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("ERROR: " + ex.Message);
            return 1;
        }
    }

    private static bool AddOrUpdate(VdfNode root, string executable, string appName, string iconPath, out uint appId)
    {
        List<VdfNode> matches = root.Children.Where(n => String.Equals(GetString(n, "AppName"), appName, StringComparison.OrdinalIgnoreCase)).ToList();
        VdfNode entry;
        if (matches.Count == 0)
        {
            entry = NewObject(root.Children.Count.ToString(CultureInfo.InvariantCulture));
            root.Children.Add(entry);
        }
        else
        {
            entry = matches[0];
            foreach (VdfNode duplicate in matches.Skip(1).ToList()) root.Children.Remove(duplicate);
        }

        string quotedExe = "\"" + executable + "\"";
        string quotedStart = "\"" + Path.GetDirectoryName(executable) + "\"";
        appId = Crc32(Encoding.UTF8.GetBytes(quotedExe + appName)) | 0x80000000u;

        SetInt(entry, "appid", unchecked((int)appId));
        SetString(entry, "AppName", appName);
        SetString(entry, "Exe", quotedExe);
        SetString(entry, "StartDir", quotedStart);
        SetString(entry, "icon", String.IsNullOrEmpty(iconPath) ? executable : iconPath);
        SetString(entry, "ShortcutPath", String.Empty);
        SetString(entry, "LaunchOptions", String.Empty);
        SetInt(entry, "IsHidden", 0);
        SetInt(entry, "AllowDesktopConfig", 1);
        SetInt(entry, "AllowOverlay", 1);
        SetInt(entry, "OpenVR", 1);
        SetInt(entry, "Devkit", 0);
        SetString(entry, "DevkitGameID", String.Empty);
        SetInt(entry, "LastPlayTime", 0);
        SetString(entry, "FlatpakAppID", String.Empty);
        if (Find(entry, "tags") == null) entry.Children.Add(NewObject("tags"));
        return true;
    }

    private static bool Remove(VdfNode root, string appName)
    {
        int removed = root.Children.RemoveAll(n => String.Equals(GetString(n, "AppName"), appName, StringComparison.OrdinalIgnoreCase));
        return removed > 0;
    }

    private static VdfNode Find(VdfNode parent, string name)
    {
        return parent.Children.FirstOrDefault(n => String.Equals(n.Name, name, StringComparison.OrdinalIgnoreCase));
    }

    private static string GetString(VdfNode parent, string name)
    {
        VdfNode node = Find(parent, name);
        return node != null && node.Type == 1 ? (string)node.Value : null;
    }

    private static void SetString(VdfNode parent, string name, string value)
    {
        Set(parent, name, 1, value);
    }

    private static void SetInt(VdfNode parent, string name, int value)
    {
        Set(parent, name, 2, value);
    }

    private static void Set(VdfNode parent, string name, byte type, object value)
    {
        VdfNode node = Find(parent, name);
        if (node == null)
        {
            node = new VdfNode { Name = name };
            parent.Children.Add(node);
        }
        node.Type = type;
        node.Value = value;
        node.Children = null;
    }

    private static VdfNode NewObject(string name)
    {
        return new VdfNode { Type = 0, Name = name, Children = new List<VdfNode>() };
    }

    private static VdfNode Parse(byte[] bytes)
    {
        using (MemoryStream stream = new MemoryStream(bytes, false))
        using (BinaryReader reader = new BinaryReader(stream, Encoding.UTF8))
        {
            VdfNode root = ReadNode(reader);
            if (stream.Position != stream.Length)
            {
                while (stream.Position < stream.Length)
                {
                    byte trailing = reader.ReadByte();
                    if (trailing != 0 && trailing != 8)
                        throw new InvalidDataException("Unexpected data after the VDF root object.");
                }
            }
            return root;
        }
    }

    private static VdfNode ReadNode(BinaryReader reader)
    {
        byte type = reader.ReadByte();
        if (type == 8) throw new InvalidDataException("Unexpected VDF end marker.");
        string name = ReadCString(reader);
        VdfNode node = new VdfNode { Type = type, Name = name };
        switch (type)
        {
            case 0:
                node.Children = new List<VdfNode>();
                while (PeekByte(reader) != 8) node.Children.Add(ReadNode(reader));
                reader.ReadByte();
                break;
            case 1: node.Value = ReadCString(reader); break;
            case 2: node.Value = reader.ReadInt32(); break;
            case 3: node.Value = reader.ReadBytes(4); break;
            case 4: node.Value = reader.ReadInt32(); break;
            case 5: node.Value = ReadWideCString(reader); break;
            case 6: node.Value = reader.ReadBytes(4); break;
            case 7: node.Value = reader.ReadUInt64(); break;
            case 9: node.Value = reader.ReadInt64(); break;
            default: throw new InvalidDataException("Unsupported VDF field type: " + type);
        }
        return node;
    }

    private static byte PeekByte(BinaryReader reader)
    {
        long position = reader.BaseStream.Position;
        if (position >= reader.BaseStream.Length) throw new EndOfStreamException("Unexpected end of VDF data.");
        byte value = reader.ReadByte();
        reader.BaseStream.Position = position;
        return value;
    }

    private static string ReadCString(BinaryReader reader)
    {
        List<byte> bytes = new List<byte>();
        byte value;
        while ((value = reader.ReadByte()) != 0) bytes.Add(value);
        return Encoding.UTF8.GetString(bytes.ToArray());
    }

    private static string ReadWideCString(BinaryReader reader)
    {
        List<byte> bytes = new List<byte>();
        while (true)
        {
            byte first = reader.ReadByte();
            byte second = reader.ReadByte();
            if (first == 0 && second == 0) break;
            bytes.Add(first);
            bytes.Add(second);
        }
        return Encoding.Unicode.GetString(bytes.ToArray());
    }

    private static byte[] Serialize(VdfNode root)
    {
        using (MemoryStream stream = new MemoryStream())
        using (BinaryWriter writer = new BinaryWriter(stream, Encoding.UTF8))
        {
            WriteNode(writer, root);
            writer.Write((byte)8);
            writer.Flush();
            return stream.ToArray();
        }
    }

    private static void WriteNode(BinaryWriter writer, VdfNode node)
    {
        writer.Write(node.Type);
        WriteCString(writer, node.Name);
        switch (node.Type)
        {
            case 0:
                foreach (VdfNode child in node.Children) WriteNode(writer, child);
                writer.Write((byte)8);
                break;
            case 1: WriteCString(writer, (string)node.Value); break;
            case 2: writer.Write((int)node.Value); break;
            case 3: writer.Write((byte[])node.Value); break;
            case 4: writer.Write((int)node.Value); break;
            case 5:
                writer.Write(Encoding.Unicode.GetBytes((string)node.Value));
                writer.Write((ushort)0);
                break;
            case 6: writer.Write((byte[])node.Value); break;
            case 7: writer.Write((ulong)node.Value); break;
            case 9: writer.Write((long)node.Value); break;
            default: throw new InvalidDataException("Unsupported VDF field type: " + node.Type);
        }
    }

    private static void WriteCString(BinaryWriter writer, string value)
    {
        writer.Write(Encoding.UTF8.GetBytes(value ?? String.Empty));
        writer.Write((byte)0);
    }

    private static uint Crc32(byte[] bytes)
    {
        uint crc = 0xffffffffu;
        foreach (byte value in bytes)
        {
            crc ^= value;
            for (int bit = 0; bit < 8; bit++)
                crc = (crc >> 1) ^ ((crc & 1) != 0 ? 0xedb88320u : 0u);
        }
        return ~crc;
    }
}
