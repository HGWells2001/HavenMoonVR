param(
    [switch]$Diagnostic,
    [switch]$NoLaunch,
    [string]$GamePath
)

$ErrorActionPreference = 'Stop'
$host.UI.RawUI.WindowTitle = "HavenMoonVR OpenVR Input Bridge 1.1 Experimental"

function Get-SteamRoots {
    $roots = New-Object System.Collections.Generic.List[string]
    try {
        $steam = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        if ($steam -and (Test-Path $steam)) { $roots.Add($steam) }
    } catch {}
    $fallback = 'C:\Program Files (x86)\Steam'
    if ((Test-Path $fallback) -and -not $roots.Contains($fallback)) { $roots.Add($fallback) }

    foreach ($root in @($roots)) {
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            $txt = Get-Content $vdf -Raw
            foreach ($m in [regex]::Matches($txt, '"path"\s+"([^"]+)"')) {
                $p = $m.Groups[1].Value -replace '\\\\','\'
                if ((Test-Path $p) -and -not $roots.Contains($p)) { $roots.Add($p) }
            }
        }
    }
    return @($roots)
}

function Resolve-SteamVR64 {
    foreach ($root in Get-SteamRoots) {
        $p = Join-Path $root 'steamapps\common\SteamVR\bin\win64\openvr_api.dll'
        if (Test-Path $p) { return (Resolve-Path $p).Path }
    }
    throw 'SteamVR win64 openvr_api.dll not found.'
}


function Resolve-SteamVRStartup {
    foreach ($root in Get-SteamRoots) {
        $p = Join-Path $root 'steamapps\common\SteamVR\bin\win64\vrstartup.exe'
        if (Test-Path $p) { return (Resolve-Path $p).Path }
    }
    return $null
}

function Test-SteamVRRunning {
    return [bool](
        (Get-Process vrserver -ErrorAction SilentlyContinue) -or
        (Get-Process vrmonitor -ErrorAction SilentlyContinue)
    )
}

function Ensure-SteamVR {
    if(Test-SteamVRRunning){
        Write-Host 'SteamVR is already running.' -ForegroundColor DarkGray
        return
    }

    Write-Host 'SteamVR is not running. Starting it automatically...' -ForegroundColor Cyan

    $startup = Resolve-SteamVRStartup
    if($startup){
        Start-Process -FilePath $startup -WorkingDirectory (Split-Path $startup -Parent)
    }else{
        # Official Steam AppID fallback.
        Start-Process 'steam://rungameid/250820'
    }

    $deadline=(Get-Date).AddSeconds(45)
    while((Get-Date)-lt $deadline){
        if(Test-SteamVRRunning){
            Write-Host 'SteamVR runtime detected.' -ForegroundColor Green
            Start-Sleep -Milliseconds 1200
            return
        }
        Start-Sleep -Milliseconds 500
    }

    throw 'SteamVR did not start within 45 seconds.'
}

function Resolve-HavenMoon {
    if ($GamePath) {
        $p=$GamePath.Trim('"')
        if ((Split-Path $p -Leaf) -ieq 'HavenMoon.exe') {$p=Split-Path $p -Parent}
        if (Test-Path (Join-Path $p 'HavenMoon.exe')) {return (Resolve-Path $p).Path}
    }
    foreach ($root in Get-SteamRoots) {
        $p = Join-Path $root 'steamapps\common\Haven Moon'
        if (Test-Path (Join-Path $p 'HavenMoon.exe')) {return (Resolve-Path $p).Path}
    }
    throw 'Haven Moon not found.'
}

$code = @'
using System;
using System.Runtime.InteropServices;

[StructLayout(LayoutKind.Sequential)]
public struct VRAxis {
    public float x;
    public float y;
}

[StructLayout(LayoutKind.Sequential)]
public struct VRState {
    public uint packet;
    public ulong pressed;
    public ulong touched;
    public VRAxis axis0;
    public VRAxis axis1;
    public VRAxis axis2;
    public VRAxis axis3;
    public VRAxis axis4;
}

[StructLayout(LayoutKind.Sequential)]
public struct HmdMatrix34 {
    public float m0, m1, m2, m3;
    public float m4, m5, m6, m7;
    public float m8, m9, m10, m11;
}

[StructLayout(LayoutKind.Sequential)]
public struct HmdVector3 {
    public float x, y, z;
}

[StructLayout(LayoutKind.Sequential)]
public struct TrackedPose {
    public HmdMatrix34 deviceToAbsolute;
    public HmdVector3 velocity;
    public HmdVector3 angularVelocity;
    public int trackingResult;
    [MarshalAs(UnmanagedType.I1)] public bool poseIsValid;
    [MarshalAs(UnmanagedType.I1)] public bool deviceIsConnected;
}

public static class K32 {
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern IntPtr LoadLibrary(string path);
}

public static class OVR {
    [DllImport("openvr_api.dll", CallingConvention=CallingConvention.Cdecl)]
    public static extern uint VR_InitInternal(ref int error, int appType);

    [DllImport("openvr_api.dll", CallingConvention=CallingConvention.Cdecl)]
    public static extern void VR_ShutdownInternal();

    [DllImport("openvr_api.dll", CallingConvention=CallingConvention.Cdecl)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool VR_IsHmdPresent();

    [DllImport("openvr_api.dll", CallingConvention=CallingConvention.Cdecl, CharSet=CharSet.Ansi)]
    [return: MarshalAs(UnmanagedType.I1)]
    public static extern bool VR_IsInterfaceVersionValid(string version);

    [DllImport("openvr_api.dll", CallingConvention=CallingConvention.Cdecl, CharSet=CharSet.Ansi)]
    public static extern IntPtr VR_GetGenericInterface(string version, ref int error);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate void FnGetDeviceToAbsoluteTrackingPose(
        int origin,
        float predictedSeconds,
        [In, Out] TrackedPose[] poses,
        uint poseCount);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate uint FnGetTrackedDeviceIndexForControllerRole(int role);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate int FnGetControllerRoleForTrackedDeviceIndex(uint device);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate int FnGetTrackedDeviceClass(uint device);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    public delegate int FnGetInt32TrackedDeviceProperty(uint device, int prop, ref int error);

    [UnmanagedFunctionPointer(CallingConvention.StdCall)]
    [return: MarshalAs(UnmanagedType.I1)]
    public delegate bool FnGetControllerState(uint device, ref VRState state, uint stateSize);

    static IntPtr GetFnPtr(IntPtr table, int index) {
        IntPtr p = Marshal.ReadIntPtr(table, index * IntPtr.Size);
        if (p == IntPtr.Zero) throw new InvalidOperationException("Null OpenVR function pointer at IVRSystem index " + index);
        return p;
    }

    public static FnGetDeviceToAbsoluteTrackingPose GetPosesFn(IntPtr table, int index) {
        return (FnGetDeviceToAbsoluteTrackingPose)Marshal.GetDelegateForFunctionPointer(
            GetFnPtr(table,index), typeof(FnGetDeviceToAbsoluteTrackingPose));
    }

    public static FnGetTrackedDeviceIndexForControllerRole GetByRoleFn(IntPtr table, int index) {
        return (FnGetTrackedDeviceIndexForControllerRole)Marshal.GetDelegateForFunctionPointer(
            GetFnPtr(table,index), typeof(FnGetTrackedDeviceIndexForControllerRole));
    }

    public static FnGetControllerRoleForTrackedDeviceIndex GetRoleFn(IntPtr table, int index) {
        return (FnGetControllerRoleForTrackedDeviceIndex)Marshal.GetDelegateForFunctionPointer(
            GetFnPtr(table,index), typeof(FnGetControllerRoleForTrackedDeviceIndex));
    }

    public static FnGetTrackedDeviceClass GetClassFn(IntPtr table, int index) {
        return (FnGetTrackedDeviceClass)Marshal.GetDelegateForFunctionPointer(
            GetFnPtr(table,index), typeof(FnGetTrackedDeviceClass));
    }

    public static FnGetInt32TrackedDeviceProperty GetIntPropFn(IntPtr table, int index) {
        return (FnGetInt32TrackedDeviceProperty)Marshal.GetDelegateForFunctionPointer(
            GetFnPtr(table,index), typeof(FnGetInt32TrackedDeviceProperty));
    }

    public static FnGetControllerState GetStateFn(IntPtr table, int index) {
        return (FnGetControllerState)Marshal.GetDelegateForFunctionPointer(
            GetFnPtr(table,index), typeof(FnGetControllerState));
    }

    public static uint ControllerStateSize() {
        return (uint)Marshal.SizeOf(typeof(VRState));
    }
}

public class PoseReader {
    private OVR.FnGetDeviceToAbsoluteTrackingPose getPoses;
    private TrackedPose[] poses = new TrackedPose[64];

    public PoseReader(IntPtr table, int functionIndex) {
        getPoses = OVR.GetPosesFn(table, functionIndex);
    }

    // Returns { forwardX, forwardZ, rightX, rightZ } in the HMD's
    // horizontal tracking plane. OpenVR is +Y up and -Z forward.
    public float[] GetHmdHorizontalBasis() {
        getPoses(1, 0.0f, poses, (uint)poses.Length); // TrackingUniverseStanding
        TrackedPose hmd = poses[0];
        if (!hmd.deviceIsConnected || !hmd.poseIsValid) return null;

        float fx = -hmd.deviceToAbsolute.m2;
        float fz = -hmd.deviceToAbsolute.m10;
        float len = (float)Math.Sqrt(fx * fx + fz * fz);
        if (len < 0.0001f) return null;

        fx /= len;
        fz /= len;

        // Horizontal right vector, perpendicular to forward.
        float rx = -fz;
        float rz = fx;

        return new float[] { fx, fz, rx, rz };
    }

    // Returns two controller aims in HMD-local Unity coordinates:
    // { valid, posXYZ, forwardXYZ } for left, then right.
    // OpenVR uses -Z as forward; Unity camera-local space uses +Z.
    public float[] GetRelativeControllerAims(uint left, uint right) {
        getPoses(1, 0.0f, poses, (uint)poses.Length);
        TrackedPose hmd = poses[0];
        if (!hmd.deviceIsConnected || !hmd.poseIsValid) return null;

        float[] result = new float[14];
        FillRelativeAim(result, 0, hmd, left);
        FillRelativeAim(result, 7, hmd, right);
        return result;
    }

    private void FillRelativeAim(float[] result, int start, TrackedPose hmd, uint device) {
        if (device >= poses.Length) return;
        TrackedPose controller = poses[device];
        if (!controller.deviceIsConnected || !controller.poseIsValid) return;

        float dx = controller.deviceToAbsolute.m3 - hmd.deviceToAbsolute.m3;
        float dy = controller.deviceToAbsolute.m7 - hmd.deviceToAbsolute.m7;
        float dz = controller.deviceToAbsolute.m11 - hmd.deviceToAbsolute.m11;

        float px = hmd.deviceToAbsolute.m0 * dx + hmd.deviceToAbsolute.m4 * dy + hmd.deviceToAbsolute.m8 * dz;
        float py = hmd.deviceToAbsolute.m1 * dx + hmd.deviceToAbsolute.m5 * dy + hmd.deviceToAbsolute.m9 * dz;
        float pz = hmd.deviceToAbsolute.m2 * dx + hmd.deviceToAbsolute.m6 * dy + hmd.deviceToAbsolute.m10 * dz;

        float ax = -controller.deviceToAbsolute.m2;
        float ay = -controller.deviceToAbsolute.m6;
        float az = -controller.deviceToAbsolute.m10;
        float fx = hmd.deviceToAbsolute.m0 * ax + hmd.deviceToAbsolute.m4 * ay + hmd.deviceToAbsolute.m8 * az;
        float fy = hmd.deviceToAbsolute.m1 * ax + hmd.deviceToAbsolute.m5 * ay + hmd.deviceToAbsolute.m9 * az;
        float fz = hmd.deviceToAbsolute.m2 * ax + hmd.deviceToAbsolute.m6 * ay + hmd.deviceToAbsolute.m10 * az;
        float length = (float)Math.Sqrt(fx * fx + fy * fy + fz * fz);
        if (length < 0.0001f) return;

        result[start] = 1.0f;
        result[start + 1] = px;
        result[start + 2] = py;
        result[start + 3] = -pz;
        result[start + 4] = fx / length;
        result[start + 5] = fy / length;
        result[start + 6] = -fz / length;
    }
}

public static class InputOut {
    const uint INPUT_MOUSE=0;
    const uint INPUT_KEYBOARD=1;
    const uint KEYEVENTF_KEYUP=0x0002;
    const uint MOUSEEVENTF_MOVE=0x0001;
    const uint MOUSEEVENTF_LEFTDOWN=0x0002;
    const uint MOUSEEVENTF_LEFTUP=0x0004;

    [StructLayout(LayoutKind.Sequential)]
    struct INPUT {
        public uint type;
        public UNION u;
    }

    [StructLayout(LayoutKind.Explicit)]
    struct UNION {
        [FieldOffset(0)] public MOUSEINPUT mi;
        [FieldOffset(0)] public KEYBDINPUT ki;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct MOUSEINPUT {
        public int dx,dy;
        public uint mouseData,dwFlags,time;
        public IntPtr extra;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct KEYBDINPUT {
        public ushort vk,scan;
        public uint flags,time;
        public IntPtr extra;
    }

    [DllImport("user32.dll", SetLastError=true)]
    static extern uint SendInput(uint n, INPUT[] inputs, int size);

    public static void Key(ushort vk, bool down) {
        INPUT i=new INPUT();
        i.type=INPUT_KEYBOARD;
        i.u.ki.vk=vk;
        i.u.ki.flags=down ? 0u : KEYEVENTF_KEYUP;
        SendInput(1,new INPUT[]{i},Marshal.SizeOf(typeof(INPUT)));
    }

    public static void MouseMove(int dx) {
        if(dx==0) return;
        INPUT i=new INPUT();
        i.type=INPUT_MOUSE;
        i.u.mi.dx=dx;
        i.u.mi.dwFlags=MOUSEEVENTF_MOVE;
        SendInput(1,new INPUT[]{i},Marshal.SizeOf(typeof(INPUT)));
    }

    public static void LeftButton(bool down) {
        INPUT i=new INPUT();
        i.type=INPUT_MOUSE;
        i.u.mi.dwFlags=down ? MOUSEEVENTF_LEFTDOWN : MOUSEEVENTF_LEFTUP;
        SendInput(1,new INPUT[]{i},Marshal.SizeOf(typeof(INPUT)));
    }

    public static void LeftClick() {
        LeftButton(true);
        LeftButton(false);
    }
}

public sealed class SharedPoseWriter : IDisposable {
    const int PAGE_READWRITE=0x04;
    const int FILE_MAP_ALL_ACCESS=0x000F001F;
    const int MAGIC=0x31564D48;
    const string NAME="Local\\HavenMoonVR_1_1_ControllerState";
    IntPtr mapping;
    IntPtr view;
    int sequence;

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    static extern IntPtr CreateFileMapping(IntPtr file, IntPtr attributes, int protect, int sizeHigh, int sizeLow, string name);

    [DllImport("kernel32.dll", SetLastError=true)]
    static extern IntPtr MapViewOfFile(IntPtr mapping, int access, int offsetHigh, int offsetLow, UIntPtr bytesToMap);

    [DllImport("kernel32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool UnmapViewOfFile(IntPtr address);

    [DllImport("kernel32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    static extern bool CloseHandle(IntPtr handle);

    public SharedPoseWriter() {
        mapping=CreateFileMapping(new IntPtr(-1),IntPtr.Zero,PAGE_READWRITE,0,80,NAME);
        if(mapping==IntPtr.Zero) throw new InvalidOperationException("CreateFileMapping failed: "+Marshal.GetLastWin32Error());
        view=MapViewOfFile(mapping,FILE_MAP_ALL_ACCESS,0,0,new UIntPtr(80));
        if(view==IntPtr.Zero) throw new InvalidOperationException("MapViewOfFile failed: "+Marshal.GetLastWin32Error());
        Marshal.WriteInt32(view,0,MAGIC);
        Marshal.WriteInt32(view,4,1);
        Marshal.WriteInt32(view,8,0);
    }

    public void Write(float[] aims, bool leftAction, bool rightAction) {
        int flags=0;
        float[] values=new float[12];
        if(aims!=null && aims.Length>=14) {
            if(aims[0]>0.5f) flags|=1;
            if(aims[7]>0.5f) flags|=2;
            for(int i=0;i<6;i++) values[i]=aims[i+1];
            for(int i=0;i<6;i++) values[i+6]=aims[i+8];
        }
        if(leftAction) flags|=4;
        if(rightAction) flags|=8;

        int even=sequence+2;
        int odd=even-1;
        Marshal.WriteInt32(view,8,odd);
        System.Threading.Thread.MemoryBarrier();
        Marshal.WriteInt32(view,12,flags);
        Marshal.WriteInt64(view,16,DateTime.UtcNow.Ticks);
        Marshal.Copy(values,0,Plus(view,24),values.Length);
        System.Threading.Thread.MemoryBarrier();
        Marshal.WriteInt32(view,8,even);
        sequence=even;
    }

    static IntPtr Plus(IntPtr pointer, int offset) {
        return new IntPtr(pointer.ToInt64()+offset);
    }

    public void Dispose() {
        if(view!=IntPtr.Zero) { UnmapViewOfFile(view); view=IntPtr.Zero; }
        if(mapping!=IntPtr.Zero) { CloseHandle(mapping); mapping=IntPtr.Zero; }
    }
}
'@

Add-Type -TypeDefinition $code -Language CSharp

function Get-HavenMoonDisplaySettings {
    $cfg=Join-Path $PSScriptRoot 'HavenMoonVR_Experimental_Display.ini'
    $r=@{Width=1280;Height=720;Fullscreen=0}

    if(Test-Path -LiteralPath $cfg){
        foreach($line in Get-Content -LiteralPath $cfg){
            if($line -match '^\s*(Width|Height|Fullscreen)\s*=\s*(\d+)\s*$'){
                $r[$matches[1]]=[int]$matches[2]
            }
        }
    }

    if($r.Width-lt 320){$r.Width=1280}
    if($r.Height-lt 240){$r.Height=720}
    if($r.Fullscreen-ne 1){$r.Fullscreen=0}
    return $r
}

function Set-HavenMoonDisplayRegistry($display){
    $regPath='HKCU:\Software\FrancoisRoussel\HavenMoon'

    if(-not (Test-Path -LiteralPath $regPath)){
        New-Item -Path $regPath -Force | Out-Null
    }

    $values=@{
        'Screenmanager Resolution Width' = [int]$display.Width
        'Screenmanager Resolution Height' = [int]$display.Height
        'Screenmanager Is Fullscreen mode' = [int]$display.Fullscreen

        'Screenmanager Resolution Width_h182942802' = [int]$display.Width
        'Screenmanager Resolution Height_h2627697771' = [int]$display.Height
        'Screenmanager Is Fullscreen mode_h3981298716' = [int]$display.Fullscreen
    }

    foreach($name in $values.Keys){
        New-ItemProperty -Path $regPath -Name $name -Value ([int]$values[$name]) `
            -PropertyType DWord -Force | Out-Null
    }
}

# SteamVR may already be running when launched from its library; otherwise start
# the locally installed runtime before Haven Moon attaches as the Scene app.
if(-not $NoLaunch){Ensure-SteamVR}

# Quest/SteamVR runtimes can report no HMD to a Background app until a Scene app
# has actually attached to the headset. Launch Haven Moon first so its native
# Unity/OpenVR scene connection wakes/claims the HMD, then attach the bridge.
if(-not $NoLaunch){
    $game=Resolve-HavenMoon
    $exe=Join-Path $game 'HavenMoon.exe'
    if(-not(Get-Process HavenMoon -ErrorAction SilentlyContinue)){
        $display=Get-HavenMoonDisplaySettings
        Set-HavenMoonDisplayRegistry $display

        $mode=if($display.Fullscreen-eq 1){'fullscreen'}else{'windowed'}
        Write-Host ("Launching Haven Moon: {0}x{1} {2} desktop mirror (no custom launch arguments)..." -f `
            $display.Width,$display.Height,$mode)

        Start-Process -FilePath $exe -WorkingDirectory $game
    }else{
        Write-Host 'Haven Moon is already running.'
    }
}

$dll = Resolve-SteamVR64
if([IntPtr]::Size-ne 8){
    throw 'The OpenVR bridge requires 64-bit PowerShell. Reinstall the Steam Icon hotfix or start it with 64-bit Windows PowerShell.'
}
Write-Host 'OpenVR bridge process: 64-bit PowerShell.' -ForegroundColor DarkGray
$openVrModule=[K32]::LoadLibrary($dll)
if ($openVrModule -eq [IntPtr]::Zero) {
    $loadError=[Runtime.InteropServices.Marshal]::GetLastWin32Error()
    throw "Cannot load SteamVR OpenVR DLL: $dll (Windows error $loadError)"
}

# Wait for the runtime to report an HMD. This is particularly useful with
# Quest Link/Air Link/Steam Link, where the device can be active in SteamVR
# but presence becomes true only after the scene application attaches.
$presenceDeadline=(Get-Date).AddSeconds(30)
$presenceShown=$false
while((Get-Date)-lt $presenceDeadline){
    if([OVR]::VR_IsHmdPresent()){break}
    if(-not $presenceShown){
        Write-Host 'Waiting for SteamVR HMD presence... put on/wake the headset if needed.' -ForegroundColor Yellow
        $presenceShown=$true
    }
    Start-Sleep -Milliseconds 500
}

# Attach as a Background application. Error 126 is
# VRInitError_Init_HmdNotFoundPresenceFailed: retry briefly rather than aborting.
$token=0
$err=126
for($attempt=1;$attempt-le 20;$attempt++){
    $err=0
    $token=[OVR]::VR_InitInternal([ref]$err,3) # VRApplication_Background
    if($err-eq 0){break}

    if($err-eq 126){
        Write-Host ("OpenVR HMD presence not ready yet (126), retry {0}/20..." -f $attempt) -ForegroundColor Yellow
        Start-Sleep -Milliseconds 750
        continue
    }

    throw "OpenVR init failed: $err"
}
if($err-ne 0){
    throw "OpenVR init failed after retries: $err (126 = HMD presence not detected)."
}

$table=[IntPtr]::Zero
$iface=$null
foreach($v in @('026','025','024','023','022','021','020','019')) {
    $name="IVRSystem_$v"
    if([OVR]::VR_IsInterfaceVersionValid($name)) {
        $e=0
        $p=[OVR]::VR_GetGenericInterface("FnTable:$name",[ref]$e)
        if($p-ne [IntPtr]::Zero -and $e-eq 0) {$table=$p;$iface=$name;break}
    }
}
if($table-eq [IntPtr]::Zero){throw 'No compatible IVRSystem function table found.'}

# IVRSystem_026 function-table indices, matching Valve's generated openvr_api.cs:
# 12 GetDeviceToAbsoluteTrackingPose
# 18 GetTrackedDeviceIndexForControllerRole
# 19 GetControllerRoleForTrackedDeviceIndex
# 20 GetTrackedDeviceClass
# 24 GetInt32TrackedDeviceProperty
# 37 GetControllerState
$poseReader=[PoseReader]::new($table,12)
$getByRole=[OVR]::GetByRoleFn($table,18)
$getRole=[OVR]::GetRoleFn($table,19)
$getClass=[OVR]::GetClassFn($table,20)
$getIntProp=[OVR]::GetIntPropFn($table,24)
$getState=[OVR]::GetStateFn($table,37)

Write-Host "OpenVR Input Bridge active ($iface function table)" -ForegroundColor Green
Write-Host "Direct SteamVR controller polling. Ctrl+C to stop."

$invalid=[UInt32]::MaxValue

function Find-OpenVRControllers {
    $result=@{
        Left=[UInt32]::MaxValue
        Right=[UInt32]::MaxValue
        All=@()
    }

    $l=[UInt32]$getByRole.Invoke(1)
    $r=[UInt32]$getByRole.Invoke(2)

    if($l-ne [UInt32]::MaxValue){$result.Left=$l}
    if($r-ne [UInt32]::MaxValue){$result.Right=$r}

    $controllers=@()
    for($d=[uint32]0;$d-lt 64;$d++){
        if($getClass.Invoke($d)-ne 2){continue}
        $controllers+=$d

        $role=$getRole.Invoke($d)
        if($role-eq 1 -and $result.Left-eq [UInt32]::MaxValue){
            $result.Left=$d
        }elseif($role-eq 2 -and $result.Right-eq [UInt32]::MaxValue){
            $result.Right=$d
        }
    }

    $result.All=$controllers

    # Last fallback for runtimes/drivers that enumerate controllers before
    # assigning a left/right role.
    if($result.Left-eq [UInt32]::MaxValue -and $controllers.Count-ge 1){
        $result.Left=[UInt32]$controllers[0]
    }
    if($result.Right-eq [UInt32]::MaxValue -and $controllers.Count-ge 2){
        $result.Right=[UInt32]$controllers[1]
    }

    return $result
}

# SteamVR's processes may be alive before tracked controllers are published.
# Wait here instead of aborting immediately.
$controllerDeadline=(Get-Date).AddSeconds(60)
$lastCount=-1
$found=$null

while((Get-Date)-lt $controllerDeadline){
    $found=Find-OpenVRControllers
    $count=@($found.All).Count

    if($count-ne $lastCount){
        if($count-eq 0){
            Write-Host 'SteamVR is running, waiting for VR controllers... wake/move them if needed.' -ForegroundColor Yellow
        }else{
            Write-Host ("SteamVR currently reports {0} controller device(s)..." -f $count) -ForegroundColor Yellow
        }
        $lastCount=$count
    }

    if($found.Left-ne $invalid -and $found.Right-ne $invalid){
        break
    }

    Start-Sleep -Milliseconds 500
}

$left=[UInt32]$found.Left
$right=[UInt32]$found.Right

if($left-eq $invalid -or $right-eq $invalid){
    $count=@($found.All).Count
    throw ("SteamVR started, but two controllers did not become available within 60 seconds. Controllers seen: {0}. Wake/move both controllers and retry." -f $count)
}

Write-Host 'Both VR controllers are ready.' -ForegroundColor Green
$sharedWriter=[SharedPoseWriter]::new()
Write-Host 'Experimental dual-pointer shared tracking is ready.' -ForegroundColor Green

function Get-AxisInfo([uint32]$device){
    $stick=-1
    $trigger=-1
    $types=@()
    for($a=0;$a-lt 5;$a++){
        $pe=0
        $t=$getIntProp.Invoke($device,3002+$a,[ref]$pe)
        $types+=$t
        if($stick-lt 0 -and ($t-eq 1 -or $t-eq 2)){$stick=$a}
        if($trigger-lt 0 -and $t-eq 3){$trigger=$a}
    }
    # Many modern SteamVR drivers keep legacy controller state but omit legacy_axis metadata.
    if($stick-lt 0){$stick=0}
    if($trigger-lt 0){$trigger=1}
    return @($stick,$trigger,$types)
}

$lInfo=Get-AxisInfo $left
$rInfo=Get-AxisInfo $right

Write-Host ("Left controller  : device={0} role={1} stickAxis={2} triggerAxis={3} axisTypes=[{4}]" -f `
    $left,$getRole.Invoke($left),$lInfo[0],$lInfo[1],($lInfo[2] -join ','))
Write-Host ("Right controller : device={0} role={1} stickAxis={2} triggerAxis={3} axisTypes=[{4}]" -f `
    $right,$getRole.Invoke($right),$rInfo[0],$rInfo[1],($rInfo[2] -join ','))

$keys=@{W=$false;A=$false;S=$false;D=$false}
$triggerHeld=$false
$decrementHeld=$false
$prevReset=$false
$lastDiag=[DateTime]::MinValue
$stateSize=[OVR]::ControllerStateSize()

function Set-Key($name,[bool]$down){
    if($keys[$name]-ne $down){
        $vk=@{W=0x57;A=0x41;S=0x53;D=0x44}[$name]
        [InputOut]::Key([uint16]$vk,$down)
        $keys[$name]=$down
    }
}

function Get-AxisValue($state,$idx){
    switch($idx){
        0 {return @($state.axis0.x,$state.axis0.y)}
        1 {return @($state.axis1.x,$state.axis1.y)}
        2 {return @($state.axis2.x,$state.axis2.y)}
        3 {return @($state.axis3.x,$state.axis3.y)}
        4 {return @($state.axis4.x,$state.axis4.y)}
        default {return @(0.0,0.0)}
    }
}

try {
    while($true){
        $ls=New-Object VRState
        $rs=New-Object VRState

        $leftAction=$false
        $rightAction=$false

        $lok=$getState.Invoke($left,[ref]$ls,$stateSize)
        $rok=$getState.Invoke($right,[ref]$rs,$stateSize)

        $moveStrafe=0.0
        $moveForward=0.0
        $hmdBasis=$null

        if($lok){
            $xy=Get-AxisValue $ls ([int]$lInfo[0])
            $x=[double]$xy[0]
            $y=[double]$xy[1]

            # Head-relative locomotion:
            # Convert the left-stick vector from HMD horizontal axes into the
            # player's body-local right/forward axes, then emit ordinary WASD.
            $hmdBasis=$poseReader.GetHmdHorizontalBasis()

            if($null-ne $hmdBasis){
                $fx=[double]$hmdBasis[0]
                $fz=[double]$hmdBasis[1]
                $rx=[double]$hmdBasis[2]
                $rz=[double]$hmdBasis[3]

                $moveStrafe=($x*$rx)+($y*$fx)
                $moveForward=-(($x*$rz)+($y*$fz))
            }else{
                # Safe fallback if HMD pose is momentarily invalid.
                $moveStrafe=$x
                $moveForward=$y
            }

            $moveDead=0.25
            Set-Key W ($moveForward -gt $moveDead)
            Set-Key S ($moveForward -lt -$moveDead)
            Set-Key A ($moveStrafe -lt -$moveDead)
            Set-Key D ($moveStrafe -gt $moveDead)
        } else {
            Set-Key W $false; Set-Key A $false; Set-Key S $false; Set-Key D $false
        }

        # Fire2 / decrement: the patched InputManager keeps Q as a second
        # Fire2 source, allowing the left VR trigger to drive the opposite direction.
        $ltv=0.0
        if($lok){
            $ltxy=Get-AxisValue $ls ([int]$lInfo[1])
            $ltv=[double]$ltxy[0]

            # EVRButtonId_A (bit 7) maps to the primary face button on each
            # controller family; on left Oculus Touch this is X.
            $xMask=[uint64]1 -shl 7
            $xPressed=(($ls.pressed-band $xMask)-ne 0)
            $wantDecrement=(($ltv -gt 0.55) -or $xPressed)
            $leftAction=$wantDecrement

            if((-not $decrementHeld) -and $wantDecrement){
                [InputOut]::Key(0x51,$true)   # Q down -> Fire2
                $decrementHeld=$true
            }elseif($decrementHeld -and (($ltv -lt 0.35) -and (-not $xPressed))){
                [InputOut]::Key(0x51,$false)  # Q up
                $decrementHeld=$false
            }
        }else{
            if($decrementHeld){
                [InputOut]::Key(0x51,$false)
                $decrementHeld=$false
            }
        }

        $tv=0.0
        if($rok){
            $xy=Get-AxisValue $rs ([int]$rInfo[0])
            $turn=[double]$xy[0]
            if([Math]::Abs($turn)-gt 0.20){
                [InputOut]::MouseMove([int]([Math]::Round($turn*10.0)))
            }

            $txy=Get-AxisValue $rs ([int]$rInfo[1])
            $tv=[double]$txy[0]

            # Fire1 is additionally mapped to keyboard E in the locally patched
            # Unity InputManager. Keyboard SendInput is already
            # proven by WASD locomotion, avoiding synthetic mouse-button issues.
            $aMask=[uint64]1 -shl 7
            $aPressed=(($rs.pressed-band $aMask)-ne 0)
            $wantInteract=(($tv -gt 0.55) -or $aPressed)
            $rightAction=$wantInteract

            if((-not $triggerHeld) -and $wantInteract){
                [InputOut]::Key(0x45,$true)   # E down
                $triggerHeld=$true
            }elseif($triggerHeld -and (($tv -lt 0.35) -and (-not $aPressed))){
                [InputOut]::Key(0x45,$false)  # E up
                $triggerHeld=$false
            }
        }else{
            if($triggerHeld){
                [InputOut]::Key(0x45,$false)
                $triggerHeld=$false
            }
        }

        # Height recenter button:
        # On Oculus/Meta Touch legacy OpenVR state the secondary left face button
        # (Y) is exposed as EVRButtonId_ApplicationMenu = 1.
        # X remains EVRButtonId_A = 7 and is already used for Fire2/decrement.
        $resetMask=[uint64]1 -shl 1
        $resetPressed=$lok -and (($ls.pressed-band $resetMask)-ne 0)
        if($resetPressed -and -not $prevReset){
            [InputOut]::Key(0x77,$true)  # F8 -> in-game height recenter
            [InputOut]::Key(0x77,$false)
        }
        $prevReset=$resetPressed

        # Publish both tracked controller rays and their independent action
        # states to the in-game experimental runtime. Keyboard E/Q remain held
        # so existing object scripts can keep reading Fire1/Fire2 unchanged.
        $aims=$poseReader.GetRelativeControllerAims($left,$right)
        $sharedWriter.Write($aims,$leftAction,$rightAction)

        if($Diagnostic -and ((Get-Date)-$lastDiag).TotalMilliseconds-ge 200){
            $lastDiag=Get-Date
            $lxy=Get-AxisValue $ls ([int]$lInfo[0])
            $rxy=Get-AxisValue $rs ([int]$rInfo[0])
            $basisText='HMD pose invalid'
            if($null-ne $hmdBasis){
                $basisText=("move F={0,5:N2} S={1,5:N2} headF=({2,5:N2},{3,5:N2})" -f `
                    $moveForward,$moveStrafe,$hmdBasis[0],$hmdBasis[1])
            }
            Write-Host ("L ok={0} {1,6:N2},{2,6:N2} trig={3:N2} {4} mask={5:X16} | R ok={6} {7,6:N2},{8,6:N2} trig={9:N2} mask={10:X16}" -f `
                $lok,$lxy[0],$lxy[1],$ltv,$basisText,$ls.pressed,$rok,$rxy[0],$rxy[1],$tv,$rs.pressed)
        }

        Start-Sleep -Milliseconds 10
    }
}
finally {
    foreach($k in @('W','A','S','D')){Set-Key $k $false}
    if($triggerHeld){[InputOut]::Key(0x45,$false)}
    if($decrementHeld){[InputOut]::Key(0x51,$false)}
    if($null-ne $sharedWriter){$sharedWriter.Dispose()}
    [OVR]::VR_ShutdownInternal()
}
