using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyVersion("1.2.6.0")]

internal static class Program
{
    [STAThread]
    private static int Main()
    {
        try
        {
            string executable = Assembly.GetExecutingAssembly().Location;
            string directory = Path.GetDirectoryName(executable);
            string script = Path.Combine(directory, "Start_HavenMoonVR.cmd");
            if (!File.Exists(script))
            {
                MessageBox.Show(
                    "Start_HavenMoonVR.cmd was not found next to the HavenMoonVR launcher.",
                    "Haven Moon VR",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                return 2;
            }

            ProcessStartInfo start = new ProcessStartInfo();
            start.FileName = Environment.GetEnvironmentVariable("COMSPEC") ?? "cmd.exe";
            start.Arguments = "/d /s /c \"\"" + script + "\"\"";
            start.WorkingDirectory = directory;
            start.UseShellExecute = false;
            start.CreateNoWindow = false;
            using (Process process = Process.Start(start))
            {
                if (process == null) return 3;
                process.WaitForExit();
                return process.ExitCode;
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                ex.ToString(),
                "Haven Moon VR launcher error",
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
            return 1;
        }
    }
}
