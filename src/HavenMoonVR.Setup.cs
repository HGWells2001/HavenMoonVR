using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Globalization;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("HavenMoonVR Setup")]
[assembly: AssemblyDescription("Graphical self-extracting installer for HavenMoonVR")]
[assembly: AssemblyCompany("Massimo Giannelli")]
[assembly: AssemblyProduct("HavenMoonVR Community Patch")]
[assembly: AssemblyCopyright("Created by Massimo Giannelli using ChatGPT in Florence, Italy")]
[assembly: AssemblyVersion("1.2.6.0")]
[assembly: AssemblyFileVersion("1.2.6.0")]

internal static class SetupProgram
{
    [STAThread]
    private static int Main(string[] args)
    {
        if (args.Length == 2 && string.Equals(args[0], "--self-test", StringComparison.OrdinalIgnoreCase))
            return RunSelfTest(args[1]);

        if (args.Length == 2 && string.Equals(args[0], "--render-preview", StringComparison.OrdinalIgnoreCase))
            return RenderPreview(args[1]);

        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        using (SetupForm form = new SetupForm())
        {
            Application.Run(form);
            return form.ExitCode;
        }
    }

    private static int RunSelfTest(string reportPath)
    {
        try
        {
            using (ExtractedPackage package = PayloadPackage.Extract())
            {
                PayloadPackage.VerifyRequiredFiles(package.RootPath);
                string detectionProbe = Path.Combine(package.RootPath, "UninstallDetectionProbe");
                Directory.CreateDirectory(Path.Combine(detectionProbe, "HavenMoon_Data", "Managed"));
                File.WriteAllBytes(Path.Combine(detectionProbe, "HavenMoon.exe"), new byte[] { 0 });
                if (SetupForm.IsPatchInstalled(detectionProbe))
                    throw new InvalidOperationException("Uninstall detection reported a clean game as patched.");
                File.WriteAllBytes(Path.Combine(detectionProbe, "HavenMoon_Data", "Managed", "HavenMoonVR.Runtime.dll"), new byte[] { 0 });
                if (!SetupForm.IsPatchInstalled(detectionProbe))
                    throw new InvalidOperationException("Uninstall detection did not recognize an installed patch.");
                File.WriteAllText(
                    reportPath,
                    "SELF-TEST OK\r\nPayload SHA-256: " + package.PayloadHash +
                    "\r\nExtracted files: " + package.FileCount.ToString(CultureInfo.InvariantCulture) +
                    "\r\nUninstall button detection: OK\r\n",
                    new UTF8Encoding(false));
            }
            return 0;
        }
        catch (Exception ex)
        {
            try { File.WriteAllText(reportPath, "SELF-TEST FAILED\r\n" + ex, new UTF8Encoding(false)); }
            catch { }
            return 1;
        }
    }

    private static int RenderPreview(string outputPath)
    {
        try
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            using (SetupForm form = new SetupForm())
            {
                form.ShowInTaskbar = false;
                form.StartPosition = FormStartPosition.Manual;
                form.Location = new Point(-32000, -32000);
                form.Show();
                Application.DoEvents();
                using (Bitmap bitmap = new Bitmap(form.Width, form.Height))
                {
                    form.DrawToBitmap(bitmap, new Rectangle(0, 0, bitmap.Width, bitmap.Height));
                    bitmap.Save(outputPath, System.Drawing.Imaging.ImageFormat.Png);
                }
                form.Close();
            }
            return 0;
        }
        catch
        {
            return 1;
        }
    }
}

internal sealed class ExtractedPackage : IDisposable
{
    internal string RootPath;
    internal string PayloadHash;
    internal int FileCount;

    public void Dispose()
    {
        if (string.IsNullOrEmpty(RootPath) || !Directory.Exists(RootPath)) return;
        string resolved = Path.GetFullPath(RootPath);
        string tempPrefix = Path.GetFullPath(Path.GetTempPath()).TrimEnd(Path.DirectorySeparatorChar) +
                            Path.DirectorySeparatorChar + "HavenMoonVR-Setup-";
        if (!resolved.StartsWith(tempPrefix, StringComparison.OrdinalIgnoreCase)) return;
        try { Directory.Delete(resolved, true); }
        catch { }
    }
}

internal static class PayloadPackage
{
    private const string PayloadResource = "HavenMoonVR.Payload.zip";
    private const string HashResource = "HavenMoonVR.Payload.sha256";

    internal static ExtractedPackage Extract()
    {
        Assembly assembly = Assembly.GetExecutingAssembly();
        byte[] payload = ReadResourceBytes(assembly, PayloadResource);
        string expectedHash = Encoding.ASCII.GetString(ReadResourceBytes(assembly, HashResource)).Trim().ToLowerInvariant();
        string actualHash = ComputeSha256(payload);
        if (!Regex.IsMatch(expectedHash, "^[0-9a-f]{64}$") || actualHash != expectedHash)
            throw new InvalidDataException("The embedded HavenMoonVR package failed its SHA-256 verification.");

        string root = Path.Combine(Path.GetTempPath(), "HavenMoonVR-Setup-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(root);
        string zipPath = Path.Combine(root, "HavenMoonVR.payload.zip");
        File.WriteAllBytes(zipPath, payload);

        ExtractedPackage result = new ExtractedPackage();
        result.RootPath = root;
        result.PayloadHash = actualHash;

        try
        {
            string rootPrefix = Path.GetFullPath(root).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            using (FileStream stream = new FileStream(zipPath, FileMode.Open, FileAccess.Read, FileShare.Read))
            using (ZipArchive archive = new ZipArchive(stream, ZipArchiveMode.Read, false))
            {
                foreach (ZipArchiveEntry entry in archive.Entries)
                {
                    string relative = entry.FullName.Replace('/', Path.DirectorySeparatorChar);
                    if (string.IsNullOrEmpty(relative)) continue;
                    if (Path.IsPathRooted(relative) || relative.IndexOf(':') >= 0)
                        throw new InvalidDataException("Unsafe path in embedded package: " + entry.FullName);

                    string destination = Path.GetFullPath(Path.Combine(root, relative));
                    if (!destination.StartsWith(rootPrefix, StringComparison.OrdinalIgnoreCase))
                        throw new InvalidDataException("Unsafe path in embedded package: " + entry.FullName);

                    if (string.IsNullOrEmpty(entry.Name))
                    {
                        Directory.CreateDirectory(destination);
                        continue;
                    }

                    string parent = Path.GetDirectoryName(destination);
                    if (!Directory.Exists(parent)) Directory.CreateDirectory(parent);
                    using (Stream source = entry.Open())
                    using (FileStream target = new FileStream(destination, FileMode.Create, FileAccess.Write, FileShare.None))
                        source.CopyTo(target);
                    result.FileCount++;
                }
            }
            File.Delete(zipPath);
            VerifyRequiredFiles(root);
            return result;
        }
        catch
        {
            result.Dispose();
            throw;
        }
    }

    internal static void VerifyRequiredFiles(string root)
    {
        string[] required = new string[]
        {
            "HavenMoonVR_Patcher.ps1",
            "Haven Moon VR.exe",
            "Start_HavenMoonVR.cmd",
            "HavenMoonVR_InputBridge.ps1",
            "HavenMoonVR_Display.ini",
            "Runtime\\HavenMoonVR.Runtime.dll",
            "Runtime\\HavenMoonVR.AssemblyPatcher.exe",
            "Runtime\\HavenMoonVR.SteamShortcutTool.exe",
            "Runtime\\Mono.Cecil.dll",
            "Runtime\\HavenMoonVR.Launcher.cs",
            "Artwork\\HavenMoonVR_LibraryHero_3840x1240.png",
            "Artwork\\HavenMoonVR_LibraryLogo_720x720.png",
            "Artwork\\HavenMoonVR_LauncherIcon.ico"
        };
        foreach (string relative in required)
        {
            if (!File.Exists(Path.Combine(root, relative)))
                throw new InvalidDataException("Required embedded package file is missing: " + relative);
        }
    }

    internal static Image LoadImageResource(string resourceName)
    {
        byte[] bytes = ReadResourceBytes(Assembly.GetExecutingAssembly(), resourceName);
        using (MemoryStream stream = new MemoryStream(bytes))
        using (Image source = Image.FromStream(stream))
            return new Bitmap(source);
    }

    private static byte[] ReadResourceBytes(Assembly assembly, string resourceName)
    {
        using (Stream stream = assembly.GetManifestResourceStream(resourceName))
        {
            if (stream == null) throw new InvalidDataException("Embedded resource not found: " + resourceName);
            using (MemoryStream buffer = new MemoryStream())
            {
                stream.CopyTo(buffer);
                return buffer.ToArray();
            }
        }
    }

    private static string ComputeSha256(byte[] bytes)
    {
        using (SHA256 sha = SHA256.Create())
        {
            byte[] hash = sha.ComputeHash(bytes);
            StringBuilder text = new StringBuilder(hash.Length * 2);
            foreach (byte value in hash) text.Append(value.ToString("x2", CultureInfo.InvariantCulture));
            return text.ToString();
        }
    }
}

internal sealed class HeroPanel : Panel
{
    private readonly Image hero;
    private readonly Image logo;

    internal HeroPanel()
    {
        hero = PayloadPackage.LoadImageResource("HavenMoonVR.Hero.png");
        logo = PayloadPackage.LoadImageResource("HavenMoonVR.Logo.png");
        DoubleBuffered = true;
        Height = 230;
        Dock = DockStyle.Top;
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            hero.Dispose();
            logo.Dispose();
        }
        base.Dispose(disposing);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        e.Graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
        e.Graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
        DrawCover(e.Graphics, hero, ClientRectangle);

        using (LinearGradientBrush shade = new LinearGradientBrush(
            ClientRectangle,
            Color.FromArgb(0, 3, 11, 22),
            Color.FromArgb(205, 3, 11, 22),
            LinearGradientMode.Vertical))
            e.Graphics.FillRectangle(shade, ClientRectangle);

        int logoSize = 176;
        Rectangle logoRect = new Rectangle((Width - logoSize) / 2, 12, logoSize, logoSize);
        e.Graphics.DrawImage(logo, logoRect);

        using (Font titleFont = new Font("Segoe UI Semibold", 16f, FontStyle.Bold, GraphicsUnit.Point))
        using (Font subFont = new Font("Segoe UI", 9.5f, FontStyle.Regular, GraphicsUnit.Point))
        using (Brush subBrush = new SolidBrush(Color.FromArgb(220, 226, 238)))
        using (StringFormat center = new StringFormat())
        {
            center.Alignment = StringAlignment.Center;
            center.LineAlignment = StringAlignment.Center;
            e.Graphics.DrawString("HavenMoonVR 1.2.6", titleFont, Brushes.White,
                new RectangleF(0, 181, Width, 27), center);
            e.Graphics.DrawString("COMMUNITY PATCH  •  GRAPHICAL SETUP", subFont,
                subBrush, new RectangleF(0, 207, Width, 20), center);
        }
    }

    private static void DrawCover(Graphics graphics, Image image, Rectangle bounds)
    {
        float scale = Math.Max((float)bounds.Width / image.Width, (float)bounds.Height / image.Height);
        int width = (int)Math.Ceiling(image.Width * scale);
        int height = (int)Math.Ceiling(image.Height * scale);
        int x = bounds.X + (bounds.Width - width) / 2;
        int y = bounds.Y + (bounds.Height - height) / 2;
        graphics.DrawImage(image, new Rectangle(x, y, width, height));
    }
}

internal sealed class InstallRequest
{
    internal string GamePath;
    internal string SteamMode;
    internal string Mode;
}

internal sealed class InstallResult
{
    internal int ExitCode;
    internal string Error;
    internal string Mode;
}

internal sealed class SetupForm : Form
{
    private readonly Color pageColor = Color.FromArgb(21, 32, 46);
    private readonly Color panelColor = Color.FromArgb(31, 47, 65);
    private readonly Color accentColor = Color.FromArgb(39, 154, 241);

    private readonly TextBox gamePathBox;
    private readonly Button browseButton;
    private readonly RadioButton automaticRadio;
    private readonly RadioButton manualRadio;
    private readonly Label automaticDescription;
    private readonly Label manualDescription;
    private readonly Label pathLabel;
    private readonly Label noticeLabel;
    private readonly Label statusLabel;
    private readonly Label badgeLabel;
    private readonly GroupBox steamGroup;
    private readonly TextBox logBox;
    private readonly ProgressBar progress;
    private readonly Button installButton;
    private readonly Button uninstallButton;
    private readonly Button closeButton;
    private readonly Button languageButton;
    private readonly BackgroundWorker worker;
    private bool italian;
    private bool running;
    private string runningMode = "Install";

    internal int ExitCode { get; private set; }

    internal SetupForm()
    {
        italian = string.Equals(CultureInfo.CurrentUICulture.TwoLetterISOLanguageName, "it", StringComparison.OrdinalIgnoreCase);
        Text = "HavenMoonVR 1.2.6 Setup";
        ClientSize = new Size(900, 680);
        MinimumSize = MaximumSize = Size;
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = pageColor;
        ForeColor = Color.White;
        Font = new Font("Segoe UI", 9f, FontStyle.Regular, GraphicsUnit.Point);
        ExitCode = 0;
        try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); }
        catch { }

        HeroPanel heroPanel = new HeroPanel();
        heroPanel.Dock = DockStyle.None;
        heroPanel.Location = new Point(0, 0);
        heroPanel.Size = new Size(900, 230);

        Panel page = new Panel();
        page.Dock = DockStyle.None;
        page.Location = new Point(0, 230);
        page.Size = new Size(900, 450);
        page.BackColor = pageColor;
        Controls.Add(page);
        Controls.Add(heroPanel);

        PictureBox logoBox = new PictureBox();
        logoBox.Image = PayloadPackage.LoadImageResource("HavenMoonVR.Logo.png");
        logoBox.SizeMode = PictureBoxSizeMode.Zoom;
        logoBox.Location = new Point(24, 23);
        logoBox.Size = new Size(116, 116);
        page.Controls.Add(logoBox);

        badgeLabel = NewLabel(page, new Point(24, 146), new Size(116, 42), "", 8.5f, FontStyle.Bold);
        badgeLabel.TextAlign = ContentAlignment.MiddleCenter;
        badgeLabel.ForeColor = Color.FromArgb(184, 206, 225);

        languageButton = NewButton(page, new Point(780, 14), new Size(82, 29), "English");
        languageButton.BackColor = Color.FromArgb(50, 69, 88);
        languageButton.Click += delegate { italian = !italian; ApplyLanguage(); };

        pathLabel = NewLabel(page, new Point(160, 18), new Size(590, 24), "", 10f, FontStyle.Bold);
        gamePathBox = new TextBox();
        gamePathBox.Location = new Point(160, 46);
        gamePathBox.Size = new Size(592, 25);
        gamePathBox.BackColor = Color.FromArgb(235, 240, 245);
        gamePathBox.ForeColor = Color.FromArgb(15, 24, 34);
        gamePathBox.BorderStyle = BorderStyle.FixedSingle;
        gamePathBox.TextChanged += delegate { RefreshUninstallAvailability(); };
        page.Controls.Add(gamePathBox);

        browseButton = NewButton(page, new Point(762, 44), new Size(100, 29), "Browse");
        browseButton.Click += BrowseButtonClick;

        steamGroup = new GroupBox();
        steamGroup.Location = new Point(160, 84);
        steamGroup.Size = new Size(702, 127);
        steamGroup.BackColor = panelColor;
        steamGroup.ForeColor = Color.White;
        page.Controls.Add(steamGroup);

        automaticRadio = new RadioButton();
        automaticRadio.Location = new Point(16, 22);
        automaticRadio.Size = new Size(655, 23);
        automaticRadio.Checked = true;
        automaticRadio.ForeColor = Color.White;
        steamGroup.Controls.Add(automaticRadio);

        automaticDescription = NewLabel(steamGroup, new Point(35, 45), new Size(645, 22), "", 8.5f, FontStyle.Regular);
        automaticDescription.ForeColor = Color.FromArgb(186, 205, 222);

        manualRadio = new RadioButton();
        manualRadio.Location = new Point(16, 70);
        manualRadio.Size = new Size(655, 23);
        manualRadio.ForeColor = Color.White;
        steamGroup.Controls.Add(manualRadio);

        manualDescription = NewLabel(steamGroup, new Point(35, 93), new Size(645, 22), "", 8.5f, FontStyle.Regular);
        manualDescription.ForeColor = Color.FromArgb(186, 205, 222);

        noticeLabel = NewLabel(page, new Point(160, 219), new Size(702, 54), "", 8.7f, FontStyle.Regular);
        noticeLabel.ForeColor = Color.FromArgb(222, 202, 145);

        logBox = new TextBox();
        logBox.Location = new Point(24, 283);
        logBox.Size = new Size(838, 87);
        logBox.Multiline = true;
        logBox.ReadOnly = true;
        logBox.ScrollBars = ScrollBars.Vertical;
        logBox.BackColor = Color.FromArgb(10, 19, 29);
        logBox.ForeColor = Color.FromArgb(207, 220, 231);
        logBox.BorderStyle = BorderStyle.FixedSingle;
        logBox.Font = new Font("Consolas", 8.4f, FontStyle.Regular, GraphicsUnit.Point);
        page.Controls.Add(logBox);

        progress = new ProgressBar();
        progress.Location = new Point(24, 380);
        progress.Size = new Size(838, 9);
        progress.Style = ProgressBarStyle.Blocks;
        page.Controls.Add(progress);

        statusLabel = NewLabel(page, new Point(24, 401), new Size(355, 35), "", 9.2f, FontStyle.Bold);
        statusLabel.TextAlign = ContentAlignment.MiddleLeft;

        uninstallButton = NewButton(page, new Point(394, 400), new Size(152, 38), "Uninstall");
        uninstallButton.Click += UninstallButtonClick;
        uninstallButton.Enabled = false;

        installButton = NewButton(page, new Point(556, 400), new Size(190, 38), "Install / Update");
        installButton.BackColor = accentColor;
        installButton.ForeColor = Color.White;
        installButton.Font = new Font("Segoe UI Semibold", 10f, FontStyle.Bold, GraphicsUnit.Point);
        installButton.Click += InstallButtonClick;

        closeButton = NewButton(page, new Point(756, 400), new Size(106, 38), "Close");
        closeButton.Click += delegate { Close(); };

        worker = new BackgroundWorker();
        worker.DoWork += WorkerDoWork;
        worker.RunWorkerCompleted += WorkerCompleted;

        FormClosing += SetupFormClosing;
        ApplyLanguage();
        Shown += delegate
        {
            string detected = SteamLocator.FindHavenMoon();
            if (!string.IsNullOrEmpty(detected)) gamePathBox.Text = detected;
            ApplyLanguage();
            RefreshUninstallAvailability();
        };
    }

    private static Label NewLabel(Control parent, Point location, Size size, string text, float fontSize, FontStyle style)
    {
        Label label = new Label();
        label.Location = location;
        label.Size = size;
        label.Text = text;
        label.BackColor = Color.Transparent;
        label.Font = new Font("Segoe UI", fontSize, style, GraphicsUnit.Point);
        parent.Controls.Add(label);
        return label;
    }

    private static Button NewButton(Control parent, Point location, Size size, string text)
    {
        Button button = new Button();
        button.Location = location;
        button.Size = size;
        button.Text = text;
        button.FlatStyle = FlatStyle.Flat;
        button.FlatAppearance.BorderColor = Color.FromArgb(92, 114, 135);
        button.FlatAppearance.MouseOverBackColor = Color.FromArgb(58, 91, 120);
        button.BackColor = Color.FromArgb(45, 65, 84);
        button.ForeColor = Color.White;
        button.Cursor = Cursors.Hand;
        parent.Controls.Add(button);
        return button;
    }

    private void ApplyLanguage()
    {
        Text = italian ? "Installazione HavenMoonVR 1.2.6" : "HavenMoonVR 1.2.6 Setup";
        badgeLabel.Text = italian ? "PATCH VR\nNON UFFICIALE" : "UNOFFICIAL\nVR PATCH";
        languageButton.Text = italian ? "English" : "Italiano";
        pathLabel.Text = italian ? "Cartella di installazione di Haven Moon" : "Haven Moon installation folder";
        browseButton.Text = italian ? "Sfoglia…" : "Browse…";
        steamGroup.Text = italian ? "Registrazione nella Libreria Steam / SteamVR" : "Steam / SteamVR Library registration";
        automaticRadio.Text = italian ? "Automatica (consigliata)" : "Automatic (recommended)";
        automaticDescription.Text = italian
            ? "Chiude Haven Moon, SteamVR e Steam; registra tutto, quindi riapre Steam."
            : "Closes Haven Moon, SteamVR and Steam; registers everything, then reopens Steam.";
        manualRadio.Text = italian ? "Manuale" : "Manual";
        manualDescription.Text = italian
            ? "Steam può restare aperto; Haven Moon e SteamVR devono essere già chiusi."
            : "Steam may remain open; Haven Moon and SteamVR must already be closed.";
        noticeLabel.Text = italian
            ? "La modalità automatica chiude gioco, SteamVR e Steam. Water Enhanced VR migliora l'acqua mantenendo disattivata la riflessione planare dell'oceano. Patch artigianale non ufficiale."
            : "Automatic mode closes the game, SteamVR and Steam. Water Enhanced VR improves the water while keeping the ocean planar reflection disabled. Unofficial homemade patch.";
        installButton.Text = running
            ? (runningMode == "Install" ? (italian ? "Installazione…" : "Installing…") : (italian ? "Attendi…" : "Please wait…"))
            : (italian ? "Installa / Aggiorna" : "Install / Update");
        uninstallButton.Text = running && runningMode == "Uninstall"
            ? (italian ? "Disinstallazione…" : "Uninstalling…")
            : (italian ? "Disinstalla" : "Uninstall");
        closeButton.Text = italian ? "Chiudi" : "Close";
        if (!running && string.IsNullOrEmpty(logBox.Text))
            logBox.Text = italian ? "Pronto. Seleziona le opzioni e premi Installa / Aggiorna." : "Ready. Choose the options and click Install / Update.";
        if (!running && (string.IsNullOrEmpty(statusLabel.Text) || statusLabel.Tag == null))
            SetStatus(italian ? "Pronto per l’installazione" : "Ready to install", Color.FromArgb(165, 201, 226), "ready");
        RefreshUninstallAvailability();
    }

    private void BrowseButtonClick(object sender, EventArgs e)
    {
        using (FolderBrowserDialog dialog = new FolderBrowserDialog())
        {
            dialog.Description = italian
                ? "Seleziona la cartella che contiene HavenMoon.exe"
                : "Select the folder containing HavenMoon.exe";
            dialog.ShowNewFolderButton = false;
            if (Directory.Exists(gamePathBox.Text)) dialog.SelectedPath = gamePathBox.Text;
            if (dialog.ShowDialog(this) == DialogResult.OK) gamePathBox.Text = dialog.SelectedPath;
        }
    }

    private void InstallButtonClick(object sender, EventArgs e)
    {
        string gamePath = gamePathBox.Text.Trim().Trim('"');
        if (string.IsNullOrEmpty(gamePath)) gamePath = SteamLocator.FindHavenMoon();
        if (string.IsNullOrEmpty(gamePath) || !File.Exists(Path.Combine(gamePath, "HavenMoon.exe")))
        {
            MessageBox.Show(
                this,
                italian ? "HavenMoon.exe non è stato trovato. Seleziona la cartella corretta del gioco." : "HavenMoon.exe was not found. Select the correct game folder.",
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
            return;
        }

        gamePathBox.Text = Path.GetFullPath(gamePath);
        if (!automaticRadio.Checked)
        {
            List<string> runningProcesses = new List<string>();
            foreach (string name in new string[] { "HavenMoon", "vrmonitor", "vrserver", "vrcompositor", "vrdashboard", "vrwebhelper", "vrstartup", "vrpathreg" })
                if (Process.GetProcessesByName(name).Length > 0) runningProcesses.Add(name);
            if (runningProcesses.Count > 0)
            {
                MessageBox.Show(
                    this,
                    (italian ? "Con la modalità manuale devi chiudere Haven Moon e SteamVR. Ancora aperti: " : "Manual mode requires Haven Moon and SteamVR to be closed. Still running: ") +
                    string.Join(", ", runningProcesses.ToArray()),
                    Text,
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
                return;
            }
        }

        InstallRequest request = new InstallRequest();
        request.GamePath = gamePathBox.Text;
        request.SteamMode = automaticRadio.Checked ? "Auto" : "Manual";
        request.Mode = "Install";

        logBox.Clear();
        runningMode = "Install";
        SetRunning(true);
        AppendLog(automaticRadio.Checked
            ? (italian
                ? "Preparazione del pacchetto; Haven Moon, SteamVR e Steam verranno chiusi automaticamente…"
                : "Preparing the package; Haven Moon, SteamVR and Steam will be closed automatically…")
            : (italian
                ? "Preparazione del pacchetto in modalità manuale…"
                : "Preparing the package in manual mode…"));
        worker.RunWorkerAsync(request);
    }

    private void UninstallButtonClick(object sender, EventArgs e)
    {
        string gamePath = gamePathBox.Text.Trim().Trim('"');
        if (string.IsNullOrEmpty(gamePath) || !File.Exists(Path.Combine(gamePath, "HavenMoon.exe")))
        {
            MessageBox.Show(
                this,
                italian ? "HavenMoon.exe non è stato trovato. Seleziona la cartella corretta del gioco." : "HavenMoon.exe was not found. Select the correct game folder.",
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Warning);
            RefreshUninstallAvailability();
            return;
        }

        gamePathBox.Text = Path.GetFullPath(gamePath);
        if (!IsPatchInstalled(gamePathBox.Text))
        {
            MessageBox.Show(
                this,
                italian ? "Non risulta installata una patch HavenMoonVR in questa cartella." : "No HavenMoonVR patch appears to be installed in this folder.",
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
            RefreshUninstallAvailability();
            return;
        }

        DialogResult answer = MessageBox.Show(
            this,
            italian
                ? "Disinstallare HavenMoonVR e ripristinare i file originali del gioco? Il backup pulito verrà conservato."
                : "Uninstall HavenMoonVR and restore the original game files? The clean backup will be retained.",
            Text,
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Warning,
            MessageBoxDefaultButton.Button2);
        if (answer != DialogResult.Yes) return;

        InstallRequest request = new InstallRequest();
        request.GamePath = gamePathBox.Text;
        request.SteamMode = automaticRadio.Checked ? "Auto" : "Manual";
        request.Mode = "Uninstall";

        logBox.Clear();
        runningMode = "Uninstall";
        SetRunning(true);
        AppendLog(italian
            ? "Preparazione della disinstallazione; verrà usata la modalità Steam memorizzata durante l’installazione…"
            : "Preparing uninstallation; the Steam mode saved during installation will be used…");
        worker.RunWorkerAsync(request);
    }

    private void WorkerDoWork(object sender, DoWorkEventArgs e)
    {
        InstallRequest request = (InstallRequest)e.Argument;
        InstallResult result = new InstallResult();
        result.Mode = request.Mode;
        try
        {
            using (ExtractedPackage package = PayloadPackage.Extract())
            {
                AppendLog("Payload SHA-256: " + package.PayloadHash);
                string script = Path.Combine(package.RootPath, "HavenMoonVR_Patcher.ps1");
                string arguments = "-NoProfile -ExecutionPolicy Bypass -NonInteractive -File " + Quote(script) +
                    " -Mode " + request.Mode + " -GamePath " + Quote(request.GamePath);
                if (request.Mode == "Install")
                    arguments += " -HeightOffset -1.00 -SteamRegistration " + request.SteamMode;

                ProcessStartInfo start = new ProcessStartInfo();
                start.FileName = Path.Combine(Environment.SystemDirectory, "WindowsPowerShell", "v1.0", "powershell.exe");
                if (!File.Exists(start.FileName)) start.FileName = "powershell.exe";
                start.Arguments = arguments;
                start.WorkingDirectory = package.RootPath;
                start.UseShellExecute = false;
                start.CreateNoWindow = true;
                start.RedirectStandardOutput = true;
                start.RedirectStandardError = true;

                using (Process process = new Process())
                {
                    process.StartInfo = start;
                    process.OutputDataReceived += delegate(object s, DataReceivedEventArgs a) { if (a.Data != null) AppendLog(a.Data); };
                    process.ErrorDataReceived += delegate(object s, DataReceivedEventArgs a) { if (a.Data != null) AppendLog("ERROR: " + a.Data); };
                    if (!process.Start()) throw new InvalidOperationException("PowerShell could not be started.");
                    process.BeginOutputReadLine();
                    process.BeginErrorReadLine();
                    process.WaitForExit();
                    result.ExitCode = process.ExitCode;
                }
            }
        }
        catch (Exception ex)
        {
            result.ExitCode = 1;
            result.Error = ex.ToString();
            AppendLog("ERROR: " + ex.Message);
        }
        e.Result = result;
    }

    private void WorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
    {
        SetRunning(false);
        InstallResult result = e.Error != null
            ? new InstallResult { ExitCode = 1, Error = e.Error.ToString(), Mode = runningMode }
            : (InstallResult)e.Result;

        if (result.ExitCode == 0)
        {
            ExitCode = 0;
            bool uninstall = result.Mode == "Uninstall";
            SetStatus(
                uninstall
                    ? (italian ? "Disinstallazione completata" : "Uninstallation complete")
                    : (italian ? "Installazione completata" : "Installation complete"),
                Color.FromArgb(95, 211, 129),
                "done");
            MessageBox.Show(
                this,
                uninstall
                    ? (italian ? "HavenMoonVR è stato disinstallato e i file originali sono stati ripristinati." : "HavenMoonVR was uninstalled and the original game files were restored.")
                    : (italian ? "HavenMoonVR 1.2.6 è stato installato correttamente." : "HavenMoonVR 1.2.6 was installed successfully."),
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Information);
        }
        else
        {
            ExitCode = result.ExitCode == 0 ? 1 : result.ExitCode;
            bool uninstall = result.Mode == "Uninstall";
            SetStatus(
                uninstall
                    ? (italian ? "Disinstallazione non completata" : "Uninstallation did not complete")
                    : (italian ? "Installazione non completata" : "Installation did not complete"),
                Color.FromArgb(240, 112, 103),
                "error");
            MessageBox.Show(
                this,
                uninstall
                    ? (italian ? "La disinstallazione non è stata completata. Controlla il messaggio nel riquadro." : "Uninstallation did not complete. Check the message in the log box.")
                    : (italian ? "L’installazione non è stata completata. Controlla il messaggio nel riquadro." : "Installation did not complete. Check the message in the log box."),
                Text,
                MessageBoxButtons.OK,
                MessageBoxIcon.Error);
        }
    }

    private void SetRunning(bool value)
    {
        running = value;
        gamePathBox.Enabled = !value;
        browseButton.Enabled = !value;
        automaticRadio.Enabled = !value;
        manualRadio.Enabled = !value;
        languageButton.Enabled = !value;
        installButton.Enabled = !value;
        uninstallButton.Enabled = !value && IsPatchInstalled(gamePathBox.Text);
        closeButton.Enabled = !value;
        progress.Style = value ? ProgressBarStyle.Marquee : ProgressBarStyle.Blocks;
        progress.MarqueeAnimationSpeed = value ? 25 : 0;
        installButton.Text = value
            ? (runningMode == "Install" ? (italian ? "Installazione…" : "Installing…") : (italian ? "Attendi…" : "Please wait…"))
            : (italian ? "Installa / Aggiorna" : "Install / Update");
        uninstallButton.Text = value && runningMode == "Uninstall"
            ? (italian ? "Disinstallazione…" : "Uninstalling…")
            : (italian ? "Disinstalla" : "Uninstall");
        if (value)
            SetStatus(
                runningMode == "Uninstall"
                    ? (italian ? "Disinstallazione in corso — non chiudere" : "Uninstalling — do not close")
                    : (italian ? "Installazione in corso — non chiudere" : "Installing — do not close"),
                Color.FromArgb(242, 203, 108),
                "running");
        else
            RefreshUninstallAvailability();
    }

    private void RefreshUninstallAvailability()
    {
        if (uninstallButton == null) return;
        uninstallButton.Enabled = !running && IsPatchInstalled(gamePathBox.Text);
    }

    internal static bool IsPatchInstalled(string gamePath)
    {
        try
        {
            if (string.IsNullOrEmpty(gamePath)) return false;
            string root = Path.GetFullPath(gamePath.Trim().Trim('"'));
            if (!File.Exists(Path.Combine(root, "HavenMoon.exe"))) return false;
            return File.Exists(Path.Combine(root, "HavenMoon_Data", "Managed", "HavenMoonVR.Runtime.dll")) ||
                   File.Exists(Path.Combine(root, "Start_HavenMoonVR.cmd")) ||
                   File.Exists(Path.Combine(root, "Haven Moon VR.exe"));
        }
        catch
        {
            return false;
        }
    }

    private void AppendLog(string line)
    {
        if (IsDisposed) return;
        if (InvokeRequired)
        {
            try { BeginInvoke(new Action<string>(AppendLog), line); }
            catch { }
            return;
        }
        logBox.AppendText(line + Environment.NewLine);
        logBox.SelectionStart = logBox.TextLength;
        logBox.ScrollToCaret();
    }

    private void SetStatus(string text, Color color, string tag)
    {
        statusLabel.Text = text;
        statusLabel.ForeColor = color;
        statusLabel.Tag = tag;
    }

    private void SetupFormClosing(object sender, FormClosingEventArgs e)
    {
        if (!running) return;
        e.Cancel = true;
        MessageBox.Show(
            this,
            italian ? "Attendi il termine dell’operazione prima di chiudere." : "Wait for the operation to finish before closing.",
            Text,
            MessageBoxButtons.OK,
            MessageBoxIcon.Information);
    }

    private static string Quote(string value)
    {
        return "\"" + value.Replace("\"", "\\\"") + "\"";
    }
}

internal static class SteamLocator
{
    internal static string FindHavenMoon()
    {
        foreach (string root in GetSteamRoots())
        {
            string candidate = Path.Combine(root, "steamapps", "common", "Haven Moon");
            if (File.Exists(Path.Combine(candidate, "HavenMoon.exe"))) return Path.GetFullPath(candidate);
        }
        return string.Empty;
    }

    private static IEnumerable<string> GetSteamRoots()
    {
        List<string> roots = new List<string>();
        try
        {
            using (RegistryKey key = Registry.CurrentUser.OpenSubKey(@"Software\Valve\Steam"))
            {
                string path = key == null ? null : key.GetValue("SteamPath") as string;
                AddRoot(roots, path);
            }
        }
        catch { }

        AddRoot(roots, Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86), "Steam"));
        string[] initial = roots.ToArray();
        foreach (string root in initial)
        {
            string vdf = Path.Combine(root, "steamapps", "libraryfolders.vdf");
            if (!File.Exists(vdf)) continue;
            try
            {
                string text = File.ReadAllText(vdf);
                foreach (Match match in Regex.Matches(text, "\"path\"\\s+\"([^\"]+)\""))
                    AddRoot(roots, match.Groups[1].Value.Replace("\\\\", "\\"));
            }
            catch { }
        }
        return roots;
    }

    private static void AddRoot(List<string> roots, string path)
    {
        if (string.IsNullOrEmpty(path)) return;
        try
        {
            string full = Path.GetFullPath(path.Replace('/', Path.DirectorySeparatorChar));
            if (!Directory.Exists(full)) return;
            foreach (string existing in roots)
                if (string.Equals(existing, full, StringComparison.OrdinalIgnoreCase)) return;
            roots.Add(full);
        }
        catch { }
    }
}
