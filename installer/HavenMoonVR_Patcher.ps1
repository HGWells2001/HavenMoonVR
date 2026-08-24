[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Verify','SetHeight')]
    [string]$Mode = 'Install',
    [string]$GamePath,
    [string]$OpenVrPath,
    [double]$HeightOffset = -1.00
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$ModName = 'HavenMoonVR 1.1.1 Experimental'
$SteamShortcutName = 'Haven Moon VR Experimental'
$SupportedExeSha256 = 'd204db3128f654d052ee72c118604a183d1bcb32ff083edc3f038ac00879f96d'

$OriginalAssemblySha256 = '863be6215489f7cce586539cc5feb146587cf433dabf31bac326e1a366d164f5'
$PatchedAssemblySha256  = '8c540e2a09199dc9ca7c4145e2fc98b3e1c4b626c2b810e67e21f946061bbe4b'
$ExperimentalHelperSha256 = '8c79a588fc28c13f875390d8ccd0afd231c744c8efbadfbab8e0686dc520ffc4'

$OriginalHashes = @{
    'globalgamemanagers' = 'c3197fd383bdfb90d88883123ccc3dfd8410a2f7f24d186771b76edd626cd9bc'
    'level0' = 'c61a21080b04dd22b54c25834b9c766c8e53bd23e611d5353804a47c6d5ee8f7'
    'level1' = 'e324dcb79d4282c3181f05dd6b37c09fc97e6eb7d9a9aff532278292c26ccf29'
    'level2' = '8c4e133d5c52e59bae680e21159f8deb3be2394895eac5545dff7bf6affbdd99'
    'level3' = 'bdb56d6f623404f56ccf76143c3936ac183a45550637fdb0778b862ed7b578f9'
    'level4' = '25ad43c9d2c4aea9c06abfafbb9ee29392b73cba159ab54b2571085dfdec7c07'
    'level5' = '496ea82f574bd808a09d58af2b3bfe73143322a30be433cd430eeafbd0c8be21'
    'level6' = '759eab0f16e17b5ebace6580676c0372f43347004ee0067fa8eab36bee32c367'
    'sharedassets1.assets' = '809ced2d731372cd7ef47a4659de7e6a04a38d279bdedfa233184ec503911d66'
}

$DefaultFinalHashes = @{
    'globalgamemanagers' = '33623c39b8d61d1206ec3bc33df5c4f8f19e38a206f503c62c6b1e2e9874a22a'
    'level0' = '05a8c5076bff43655657e968d5ac2ffbcca38c458a4e493931f70045e074a751'
    'level1' = 'ee63a273483432e5f59fbff81ec27e1734647aa058a65d897443719ddd6139ac'
    'level2' = '9f64697fe3ac04fa0748bf811b4f58bf011e3f3d3acab2a9733d1c31b0264ec2'
    'level3' = '329cfdd9f32eb14b50fc526053b6a2ddaa3544619821ac0a04694048461972ce'
    'level4' = 'c564decd0c4e5097ecd8023eb91b9500d39a0c4aa0a0f7a95a4ba57dd36f6193'
    'level5' = 'fbf5a05222f8bc5cbb9896edad7a60390be5306735f908379e12fc64dcffa2c5'
    'level6' = 'eb4342a179f6cd8fe7e2ef6183cbfb39a0950f2c1c5abce89a4d8f0f74d1c4ce'
    'sharedassets1.assets' = 'bd4393b224032d8b864720e81e90c48b32322560d4cdc19060754fbf6ae4e1a2'
}

$LevelPatches = @{
    'level0' = @(
        @{ Offset = 6576; Bytes = [byte[]](1) },
        @{ Offset = 6584; Bytes = [byte[]](20) },
        @{ Offset = 6592; Bytes = [byte[]](51,51,179,62) }
    )
    'level1' = @(
        @{ Offset = 14759720; Bytes = [byte[]](1) },
        @{ Offset = 14759728; Bytes = [byte[]](18,3) },
        @{ Offset = 14759736; Bytes = [byte[]](51,51,179,62) }
    )
    'level2' = @(
        @{ Offset = 4291168; Bytes = [byte[]](1) },
        @{ Offset = 4291176; Bytes = [byte[]](198,4) },
        @{ Offset = 4291184; Bytes = [byte[]](51,51,179,62) }
    )
    'level3' = @(
        @{ Offset = 22539880; Bytes = [byte[]](1) },
        @{ Offset = 22539888; Bytes = [byte[]](118,3) },
        @{ Offset = 22539896; Bytes = [byte[]](51,51,179,62) }
    )
    'level4' = @(
        @{ Offset = 21594856; Bytes = [byte[]](1) },
        @{ Offset = 21594864; Bytes = [byte[]](141,3) },
        @{ Offset = 21594872; Bytes = [byte[]](51,51,179,62) }
    )
    'level5' = @(
        @{ Offset = 18733048; Bytes = [byte[]](1) },
        @{ Offset = 18733056; Bytes = [byte[]](179,1) },
        @{ Offset = 18733064; Bytes = [byte[]](51,51,179,62) }
    )
    'level6' = @(
        @{ Offset = 12732912; Bytes = [byte[]](1) },
        @{ Offset = 12732920; Bytes = [byte[]](69,1) },
        @{ Offset = 12732928; Bytes = [byte[]](51,51,179,62) }
    )
}

# Exact serialized-file layout of the supported Unity 5.4.6f3 scenes.
# The stable patch line inserts a new GameObject + Transform named "VR Origin"
# between FPSControllerHM and FirstPersonCharacter.
$SceneInfo = @{
    'level1' = @{ DataOffset=52464; MetadataEnd=52449; ObjectCountOff=2657; ObjectTableEnd=51521; ObjectCount=1745; MaxPid=1745; PlayerTransform=610; ParentTransform=648; ChildFatherPathOff=14467708; ParentChildPathOff=14471388 }
    'level2' = @{ DataOffset=72464; MetadataEnd=72463; ObjectCountOff=2449; ObjectTableEnd=71529; ObjectCount=2467; MaxPid=2467; PlayerTransform=967; ParentTransform=836; ChildFatherPathOff=3828476; ParentChildPathOff=3817516 }
    'level3' = @{ DataOffset=55280; MetadataEnd=55273; ObjectCountOff=2289; ObjectTableEnd=54345; ObjectCount=1859; MaxPid=1859; PlayerTransform=832; ParentTransform=730; ChildFatherPathOff=21927052; ParentChildPathOff=21918748 }
    'level4' = @{ DataOffset=58176; MetadataEnd=58175; ObjectCountOff=2493; ObjectTableEnd=57181; ObjectCount=1953; MaxPid=1953; PlayerTransform=547; ParentTransform=712; ChildFatherPathOff=21347964; ParentChildPathOff=21361692 }
    'level5' = @{ DataOffset=27328; MetadataEnd=27327; ObjectCountOff=1617; ObjectTableEnd=26597; ObjectCount=892; MaxPid=892; PlayerTransform=406; ParentTransform=353; ChildFatherPathOff=18691068; ParentChildPathOff=18686780 }
    'level6' = @{ DataOffset=21888; MetadataEnd=21885; ObjectCountOff=1561; ObjectTableEnd=21221; ObjectCount=702; MaxPid=702; PlayerTransform=317; ParentTransform=239; ChildFatherPathOff=12692220; ParentChildPathOff=12685788 }
}

$ControllerPayloadBase64 = 'CgAAAEhvcml6b250YWwAAA8AAABWUiBMZWZ0IFN0aWNrIFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzcxMPgAAgD8AAAAAAgAAAAAAAAAAAAAACAAAAFZlcnRpY2FsDwAAAFZSIExlZnQgU3RpY2sgWQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADNzEw+AACAPwAAAAACAAAAAQAAAAAAAAAHAAAATW91c2UgWAATAAAAVlIgUmlnaHQgU3RpY2sgVHVybgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIA+AACAPwAAAAACAAAAAwAAAAAAAAAFAAAARmlyZTEAAAAQAAAAVlIgUmlnaHQgVHJpZ2dlcgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM3MTD4AAIA/AAAAAAIAAAAJAAAAAAAAAAUAAABGaXJlMQAAAAsAAABWUiBBY3Rpb24gQQAAAAAAAAAAABEAAABqb3lzdGljayBidXR0b24gMAAAAAAAAAAAAAAAAAB6RG8SgzoAAHpEAAAAAAAAAAAAAAAAAAAAAAUAAABGaXJlMgAAAA8AAABWUiBMZWZ0IFRyaWdnZXIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzcxMPgAAgD8AAAAAAgAAAAgAAAAAAAAABQAAAEZpcmUyAAAACwAAAFZSIEFjdGlvbiBYAAAAAAAAAAAAEQAAAGpveXN0aWNrIGJ1dHRvbiAyAAAAAAAAAAAAAAAAAHpEbxKDOgAAekQAAAAAAAAAAAAAAAAAAAAABgAAAFN1Ym1pdAAACwAAAFZSIFN1Ym1pdCBBAAAAAAAAAAAAEQAAAGpveXN0aWNrIGJ1dHRvbiAwAAAAAAAAAAAAAAAAAHpEbxKDOgAAekQAAAAAAAAAAAAAAAAAAAAABgAAAENhbmNlbAAACwAAAFZSIENhbmNlbCBYAAAAAAAAAAAAEQAAAGpveXN0aWNrIGJ1dHRvbiAyAAAAAAAAAAAAAAAAAHpEbxKDOgAAekQAAAAAAAAAAAAAAAAAAAAABQAAAEZpcmUxAAAAEgAAAEFjdGl2YXRlL0luY3JlbWVudAAAAAAAAAAAAAABAAAAZQAAAAAAAAAAAAAAAAB6RG8SgzoAAHpEAAAAAAAAAAAAAAAAAAAAAAUAAABGaXJlMgAAAAkAAABEZWNyZW1lbnQAAAAAAAAAAAAAAAEAAABxAAAAAAAAAAAAAAAAAHpEbxKDOgAAekQAAAAAAAAAAAAAAAAAAAAA'

function Get-BytesSha256([byte[]]$Bytes) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Get-FileSha256([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }

function Write-U32LE([byte[]]$Bytes,[int]$Offset,[uint32]$Value) {
    [byte[]]$v=[BitConverter]::GetBytes($Value); [Array]::Copy($v,0,$Bytes,$Offset,4)
}
function Write-I64LE([byte[]]$Bytes,[int]$Offset,[int64]$Value) {
    [byte[]]$v=[BitConverter]::GetBytes($Value); [Array]::Copy($v,0,$Bytes,$Offset,8)
}
function Write-U32BE([byte[]]$Bytes,[int]$Offset,[uint32]$Value) {
    $Bytes[$Offset]=[byte](($Value -shr 24)-band 255); $Bytes[$Offset+1]=[byte](($Value -shr 16)-band 255); $Bytes[$Offset+2]=[byte](($Value -shr 8)-band 255); $Bytes[$Offset+3]=[byte]($Value-band 255)
}
function Align4([int64]$Value) { return (($Value + 3) -band (-bnot 3)) }
function Align16([int64]$Value) { return (($Value + 15) -band (-bnot 15)) }

function Get-PeMachine([string]$Path) {
    [byte[]]$b=[IO.File]::ReadAllBytes($Path)
    if($b.Length -lt 64 -or $b[0]-ne 0x4d -or $b[1]-ne 0x5a){return 0}
    $pe=[BitConverter]::ToInt32($b,0x3c)
    if($pe -lt 0 -or ($pe+6)-gt $b.Length){return 0}
    return [BitConverter]::ToUInt16($b,$pe+4)
}

function Get-SteamRoots {
    $roots=New-Object System.Collections.Generic.List[string]
    try{$steam=(Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath;if($steam -and (Test-Path -LiteralPath $steam)){$roots.Add($steam)}}catch{}
    $fallback='C:\Program Files (x86)\Steam';if((Test-Path -LiteralPath $fallback)-and -not $roots.Contains($fallback)){$roots.Add($fallback)}
    $initial=@($roots)
    foreach($root in $initial){
        $vdf=Join-Path $root 'steamapps\libraryfolders.vdf'
        if(Test-Path -LiteralPath $vdf){
            $text=Get-Content -LiteralPath $vdf -Raw
            foreach($m in [regex]::Matches($text,'"path"\s+"([^"]+)"')){
                $p=$m.Groups[1].Value -replace '\\\\','\'
                if((Test-Path -LiteralPath $p)-and -not $roots.Contains($p)){$roots.Add($p)}
            }
        }
    }
    return @($roots)
}

function Assert-HavenMoonVRProcessesClosed {
    $names=@('steam','vrserver','vrmonitor','HavenMoon')
    $running=@()
    foreach($name in $names){
        if(Get-Process -Name $name -ErrorAction SilentlyContinue){$running+=$name}
    }
    if($running.Count-gt 0){
        throw ('Close Steam, SteamVR and Haven Moon before continuing. Still running: '+(($running|Select-Object -Unique)-join ', '))
    }
}

function Resolve-SteamShortcutsPath {
    $steamRoot=$null
    foreach($root in Get-SteamRoots){
        if(Test-Path -LiteralPath (Join-Path $root 'steam.exe')){$steamRoot=$root;break}
    }
    if(-not $steamRoot){throw 'Steam installation root was not found.'}

    $userdata=Join-Path $steamRoot 'userdata'
    if(-not(Test-Path -LiteralPath $userdata)){throw "Steam userdata directory was not found: $userdata"}

    $active=0
    try{$active=[int64](Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam\ActiveProcess' -ErrorAction Stop).ActiveUser}catch{}
    if($active-gt 0){
        $activeConfig=Join-Path (Join-Path $userdata ([string]$active)) 'config'
        if(Test-Path -LiteralPath $activeConfig){return (Join-Path $activeConfig 'shortcuts.vdf')}
    }

    $candidates=@()
    foreach($userDir in Get-ChildItem -LiteralPath $userdata -Directory -ErrorAction SilentlyContinue){
        $config=Join-Path $userDir.FullName 'config'
        if(-not(Test-Path -LiteralPath $config)){continue}
        $vdf=Join-Path $config 'shortcuts.vdf'
        $stamp=if(Test-Path -LiteralPath $vdf){(Get-Item -LiteralPath $vdf).LastWriteTime}else{(Get-Item -LiteralPath $config).LastWriteTime}
        $candidates+=[pscustomobject]@{Path=$vdf;Stamp=$stamp}
    }
    if($candidates.Count-eq 0){throw 'No Steam user config directory was found.'}
    return (($candidates|Sort-Object Stamp -Descending|Select-Object -First 1).Path)
}

function Invoke-SteamShortcut([ValidateSet('add','remove')][string]$Action,[string]$GameDir) {
    $tool=Join-Path $PSScriptRoot 'Runtime\HavenMoonVR.SteamShortcutTool.exe'
    if(-not(Test-Path -LiteralPath $tool)){throw "Steam shortcut tool missing: $tool"}
    $vdf=Resolve-SteamShortcutsPath
    if($Action-eq 'remove' -and -not(Test-Path -LiteralPath $vdf)){return}
    if($Action-eq 'add'){
        $launcher=Join-Path $GameDir 'Haven Moon VR Experimental.exe'
        # Keep the experimental launcher as Steam's executable while using the
        # original, locally installed game executable as its icon source. This
        # gives the non-Steam entry the authentic Haven Moon icon without
        # redistributing game artwork in the HavenMoonVR package.
        $gameIcon=Join-Path $GameDir 'HavenMoon.exe'
        & $tool add $vdf $launcher $SteamShortcutName $gameIcon | ForEach-Object {Write-Host $_ -ForegroundColor DarkGray}
    }else{
        & $tool remove $vdf $SteamShortcutName | ForEach-Object {Write-Host $_ -ForegroundColor DarkGray}
    }
    if($LASTEXITCODE-ne 0){throw "Steam shortcut $Action failed."}
}

function Install-ExperimentalRuntimeFiles([string]$GameDir) {
    $rootFiles=@(
        'Haven Moon VR Experimental.exe',
        'Start_HavenMoonVR_Experimental.cmd',
        'HavenMoonVR_InputBridge_Experimental.ps1',
        'HavenMoonVR_Experimental_Display.ini'
    )
    foreach($name in $rootFiles){
        $source=Join-Path $PSScriptRoot $name
        $destination=Join-Path $GameDir $name
        if(-not(Test-Path -LiteralPath $source)){throw "Experimental runtime file missing: $source"}
        if($name-eq 'HavenMoonVR_Experimental_Display.ini' -and (Test-Path -LiteralPath $destination)){
            Write-Host 'Existing experimental display configuration kept.' -ForegroundColor DarkGray
        }else{
            Copy-Item -LiteralPath $source -Destination $destination -Force
        }
    }

    $helperSource=Join-Path $PSScriptRoot 'Runtime\HavenMoonVR.Experimental.dll'
    $helperDestination=Join-Path $GameDir 'HavenMoon_Data\Managed\HavenMoonVR.Experimental.dll'
    if(-not(Test-Path -LiteralPath $helperSource)){throw "Experimental in-game runtime missing: $helperSource"}
    Copy-Item -LiteralPath $helperSource -Destination $helperDestination -Force
    if((Get-FileSha256 $helperDestination)-ne $ExperimentalHelperSha256){throw 'Experimental in-game runtime verification failed after copy.'}

    @($rootFiles+'HavenMoon_Data\Managed\HavenMoonVR.Experimental.dll') |
        Set-Content -LiteralPath (Join-Path $GameDir '.havenmoonvr_1_1_experimental_runtime_files.txt') -Encoding UTF8
}

function Install-LauncherWithLocalGameIcon([string]$GameDir) {
    $gameExe=Join-Path $GameDir 'HavenMoon.exe'
    $launcher=Join-Path $GameDir 'Haven Moon VR Experimental.exe'
    $launcherSource=Join-Path $PSScriptRoot 'Runtime\HavenMoonVR.ExperimentalLauncher.cs'
    $csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
    if(-not(Test-Path -LiteralPath $launcherSource)-or-not(Test-Path -LiteralPath $csc)){
        Write-Host 'Local launcher-icon embedding is unavailable; Steam will still use the original game icon.' -ForegroundColor Yellow
        return $false
    }

    $tempDir=Join-Path ([IO.Path]::GetTempPath()) ('HavenMoonVR-LauncherIcon-'+[Guid]::NewGuid().ToString('N'))
    $sourceIcon=$null;$sourceBitmap=$null;$embeddedIcon=$null;$embeddedBitmap=$null;$writer=$null;$stream=$null
    try{
        New-Item -ItemType Directory -Path $tempDir|Out-Null
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $sourcePng=Join-Path $tempDir 'HavenMoon.png'
        $icoPath=Join-Path $tempDir 'HavenMoon.ico'
        $builtLauncher=Join-Path $tempDir 'Haven Moon VR Experimental.exe'
        $embeddedPng=Join-Path $tempDir 'Embedded.png'

        $sourceIcon=[Drawing.Icon]::ExtractAssociatedIcon($gameExe)
        if($null-eq$sourceIcon){throw 'The original Haven Moon icon could not be extracted.'}
        $sourceBitmap=$sourceIcon.ToBitmap()
        $sourceBitmap.Save($sourcePng,[Drawing.Imaging.ImageFormat]::Png)
        $width=$sourceBitmap.Width;$height=$sourceBitmap.Height
        if($width-lt 1-or$width-gt 256-or$height-lt 1-or$height-gt 256){throw 'Unexpected original icon dimensions.'}

        # Wrap the lossless PNG in a one-image ICO container. Icon.Save can
        # reduce extracted icons to a 16-colour bitmap; the PNG form preserves
        # the original artwork and transparency exactly.
        [byte[]]$pngBytes=[IO.File]::ReadAllBytes($sourcePng)
        $stream=New-Object IO.MemoryStream
        $writer=New-Object IO.BinaryWriter($stream)
        $writer.Write([uint16]0);$writer.Write([uint16]1);$writer.Write([uint16]1)
        $writer.Write([byte]$(if($width-eq 256){0}else{$width}))
        $writer.Write([byte]$(if($height-eq 256){0}else{$height}))
        $writer.Write([byte]0);$writer.Write([byte]0);$writer.Write([uint16]1);$writer.Write([uint16]32)
        $writer.Write([uint32]$pngBytes.Length);$writer.Write([uint32]22);$writer.Write($pngBytes);$writer.Flush()
        [IO.File]::WriteAllBytes($icoPath,$stream.ToArray())
        $writer.Dispose();$writer=$null;$stream.Dispose();$stream=$null

        $compilerArgs=@(
            '/nologo','/target:winexe','/platform:anycpu','/optimize+',
            '/reference:System.Windows.Forms.dll',
            ('/win32icon:'+$icoPath),('/out:'+$builtLauncher),$launcherSource
        )
        & $csc @compilerArgs | ForEach-Object {Write-Host $_ -ForegroundColor DarkGray}
        if($LASTEXITCODE-ne 0-or-not(Test-Path -LiteralPath $builtLauncher)){throw 'The icon-enabled launcher could not be compiled.'}

        $embeddedIcon=[Drawing.Icon]::ExtractAssociatedIcon($builtLauncher)
        if($null-eq$embeddedIcon){throw 'The compiled launcher does not expose an icon.'}
        $embeddedBitmap=$embeddedIcon.ToBitmap();$embeddedBitmap.Save($embeddedPng,[Drawing.Imaging.ImageFormat]::Png)
        if((Get-FileSha256 $sourcePng)-ne(Get-FileSha256 $embeddedPng)){throw 'The embedded launcher icon does not match the original game icon.'}
        Copy-Item -LiteralPath $builtLauncher -Destination $launcher -Force
        Write-Host 'Embedded the locally installed Haven Moon icon in the experimental launcher.' -ForegroundColor Green
        return $true
    }catch{
        Write-Host ('Launcher icon warning: '+$_.Exception.Message) -ForegroundColor Yellow
        Write-Host 'Steam will still use the icon directly from the original HavenMoon.exe.' -ForegroundColor Yellow
        return $false
    }finally{
        if($null-ne$writer){$writer.Dispose()};if($null-ne$stream){$stream.Dispose()}
        if($null-ne$sourceBitmap){$sourceBitmap.Dispose()};if($null-ne$sourceIcon){$sourceIcon.Dispose()}
        if($null-ne$embeddedBitmap){$embeddedBitmap.Dispose()};if($null-ne$embeddedIcon){$embeddedIcon.Dispose()}
        if(Test-Path -LiteralPath $tempDir){Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue}
    }
}

function Remove-ExperimentalRuntimeFiles([string]$GameDir) {
    $relative=@(
        'Haven Moon VR Experimental.exe',
        'Start_HavenMoonVR_Experimental.cmd',
        'HavenMoonVR_InputBridge_Experimental.ps1',
        'HavenMoonVR_Experimental_Display.ini',
        'HavenMoon_Data\Managed\HavenMoonVR.Experimental.dll',
        '.havenmoonvr_1_1_experimental_runtime_files.txt'
    )
    foreach($name in $relative){
        $path=Join-Path $GameDir $name
        if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path -Force}
    }
}
function Resolve-GamePath([string]$Requested) {
    if($Requested){$p=$Requested.Trim('"');if((Split-Path -Leaf $p)-ieq 'HavenMoon.exe'){$p=Split-Path -Parent $p};if(Test-Path -LiteralPath (Join-Path $p 'HavenMoon.exe')){return (Resolve-Path -LiteralPath $p).Path};throw "HavenMoon.exe was not found in: $p"}
    foreach($root in Get-SteamRoots){$candidate=Join-Path $root 'steamapps\common\Haven Moon';if(Test-Path -LiteralPath (Join-Path $candidate 'HavenMoon.exe')){return (Resolve-Path -LiteralPath $candidate).Path}}
    throw 'Haven Moon was not found automatically. Re-run with -GamePath "X:\...\Haven Moon".'
}
function Resolve-OpenVrPath([string]$Requested) {
    if($Requested){$p=$Requested.Trim('"');if(-not(Test-Path -LiteralPath $p)){throw "openvr_api.dll was not found: $p"};if((Get-PeMachine $p)-ne 0x14c){throw 'The supplied openvr_api.dll is not x86/Win32.'};return (Resolve-Path -LiteralPath $p).Path}
    foreach($root in Get-SteamRoots){$candidate=Join-Path $root 'steamapps\common\SteamVR\bin\win32\openvr_api.dll';if((Test-Path -LiteralPath $candidate)-and((Get-PeMachine $candidate)-eq 0x14c)){return (Resolve-Path -LiteralPath $candidate).Path}}
    throw 'SteamVR Win32 openvr_api.dll was not found. Install SteamVR or provide -OpenVrPath.'
}

function Patch-GlobalManagersVR([byte[]]$Src) {
    # Unity 5.4 PlayerSettings.displayResolutionDialog:
    # 0=Disabled, 1=Enabled, 2=HiddenByDefault.
    # Supported Haven Moon build stores this Int32 at file offset 4284 (0x10BC).
    if([BitConverter]::ToUInt32($Src,4284)-ne 1){throw 'Unexpected PlayerSettings resolution-dialog value; refusing patch.'}
    Write-U32LE $Src 4284 0

    $replacements=@{7=184;736=112;760=236;788=196;816=156;844=196;872=196;900=228;928=180;956=92;984=92}
    foreach($k in $replacements.Keys){$Src[[int]$k]=[byte]$replacements[$k]}
    [byte[]]$tail=[byte[]](0,6,0,0,0,79,112,101,110,86,82)
    [byte[]]$Dst=New-Object byte[] ($Src.Length+12)
    [Array]::Copy($Src,0,$Dst,0,19332);$Dst[19332]=1;[Array]::Copy($Src,19332,$Dst,19333,2);[Array]::Copy($tail,0,$Dst,19335,$tail.Length);[Array]::Copy($Src,19334,$Dst,19346,$Src.Length-19334)
    return $Dst
}
function Patch-Controllers([byte[]]$Src) {
    if([BitConverter]::ToUInt32($Src,4488)-ne 10){throw 'Unexpected InputManager layout; refusing controller patch.'}
    [byte[]]$payload=[Convert]::FromBase64String($ControllerPayloadBase64)
    if($payload.Length-ne 960){throw 'Internal controller payload error.'}
    [byte[]]$Dst=New-Object byte[] ($Src.Length+$payload.Length)
    [Array]::Copy($Src,0,$Dst,0,5328);[Array]::Copy($payload,0,$Dst,5328,$payload.Length);[Array]::Copy($Src,5328,$Dst,5328+$payload.Length,$Src.Length-5328)
    Write-U32LE $Dst 4488 21;Write-U32LE $Dst 484 1800
    for($i=2;$i-lt 20;$i++){$startField=444+(28*$i)+8;$old=[BitConverter]::ToUInt32($Src,$startField);Write-U32LE $Dst $startField ([uint32]($old+960))}
    Write-U32BE $Dst 4 ([uint32]$Dst.Length)
    return $Dst
}
function Patch-Level([byte[]]$Src,$Ops){foreach($op in $Ops){[Array]::Copy([byte[]]$op.Bytes,0,$Src,[int]$op.Offset,([byte[]]$op.Bytes).Length)};return $Src}

function New-VROriginGameObject([int64]$GoPid,[int64]$TransformPid) {
    $ms=New-Object IO.MemoryStream;$bw=New-Object IO.BinaryWriter($ms)
    try{
        $bw.Write([int]1);$bw.Write([int]4);$bw.Write([int]0);$bw.Write([int64]$TransformPid);$bw.Write([int]0)
        [byte[]]$name=[Text.Encoding]::ASCII.GetBytes('VR Origin');$bw.Write([int]$name.Length);$bw.Write($name)
        while(($ms.Position%4)-ne 0){$bw.Write([byte]0)}
        $bw.Write([uint16]0);$bw.Write([byte]1);$bw.Flush();return $ms.ToArray()
    }finally{$bw.Dispose();$ms.Dispose()}
}
function New-VROriginTransform([int64]$GoPid,[int64]$ChildPid,[int64]$FatherPid,[single]$Y) {
    $ms=New-Object IO.MemoryStream;$bw=New-Object IO.BinaryWriter($ms)
    try{
        $bw.Write([int]0);$bw.Write([int64]$GoPid)
        $bw.Write([single]0);$bw.Write([single]0);$bw.Write([single]0);$bw.Write([single]1)
        $bw.Write([single]0);$bw.Write([single]$Y);$bw.Write([single]0)
        $bw.Write([single]1);$bw.Write([single]1);$bw.Write([single]1)
        $bw.Write([int]1);$bw.Write([int]0);$bw.Write([int64]$ChildPid);$bw.Write([int]0);$bw.Write([int64]$FatherPid)
        $bw.Flush();[byte[]]$r=$ms.ToArray();if($r.Length-ne 80){throw 'Internal VR Origin Transform size error.'};return $r
    }finally{$bw.Dispose();$ms.Dispose()}
}
function Write-ObjectInfoEntry($BW,[int64]$PathId,[uint32]$RelativeStart,[uint32]$Size,[int]$TypeId,[uint16]$ClassId) {
    while(($BW.BaseStream.Position%4)-ne 0){$BW.Write([byte]0)}
    $BW.Write([int64]$PathId);$BW.Write([uint32]$RelativeStart);$BW.Write([uint32]$Size);$BW.Write([int]$TypeId);$BW.Write([uint16]$ClassId);$BW.Write([int16]-1);$BW.Write([byte]0)
}

function Patch-SceneWithVROrigin([byte[]]$Clean,[string]$Name,[single]$Y) {
    $cfg=$SceneInfo[$Name]
    [byte[]]$src=New-Object byte[] $Clean.Length;[Array]::Copy($Clean,0,$src,0,$Clean.Length)
    $src=Patch-Level $src $LevelPatches[$Name]
    $newGo=[int64]$cfg.MaxPid+1;$newTr=[int64]$cfg.MaxPid+2
    Write-I64LE $src ([int]$cfg.ChildFatherPathOff) $newTr
    Write-I64LE $src ([int]$cfg.ParentChildPathOff) $newTr

    $oldDataLen=$src.Length-[int]$cfg.DataOffset
    $goRel=[int](Align4 $oldDataLen);[byte[]]$goData=New-VROriginGameObject $newGo $newTr
    $trRel=[int](Align4 ($goRel+$goData.Length));[byte[]]$trData=New-VROriginTransform $newGo ([int64]$cfg.PlayerTransform) ([int64]$cfg.ParentTransform) $Y

    $meta=New-Object IO.MemoryStream;$bw=New-Object IO.BinaryWriter($meta)
    try{
        $bw.Write($src,0,[int]$cfg.ObjectTableEnd)
        Write-ObjectInfoEntry $bw $newGo ([uint32]$goRel) ([uint32]$goData.Length) 1 1
        Write-ObjectInfoEntry $bw $newTr ([uint32]$trRel) ([uint32]$trData.Length) 4 4
        $tailLen=[int]$cfg.MetadataEnd-[int]$cfg.ObjectTableEnd
        $bw.Write($src,[int]$cfg.ObjectTableEnd,$tailLen);$bw.Flush()
        [byte[]]$metaBytes=$meta.ToArray()
    }finally{$bw.Dispose();$meta.Dispose()}

    Write-U32LE $metaBytes ([int]$cfg.ObjectCountOff) ([uint32]([int]$cfg.ObjectCount+2))
    $newMetadataSize=$metaBytes.Length-20;$newDataOffset=[int](Align16 $metaBytes.Length)

    $data=New-Object IO.MemoryStream;$dbw=New-Object IO.BinaryWriter($data)
    try{
        $dbw.Write($src,[int]$cfg.DataOffset,$oldDataLen)
        while($data.Position-lt $goRel){$dbw.Write([byte]0)};$dbw.Write($goData)
        while($data.Position-lt $trRel){$dbw.Write([byte]0)};$dbw.Write($trData);$dbw.Flush();[byte[]]$dataBytes=$data.ToArray()
    }finally{$dbw.Dispose();$data.Dispose()}

    $newFileSize=$newDataOffset+$dataBytes.Length
    Write-U32BE $metaBytes 0 ([uint32]$newMetadataSize);Write-U32BE $metaBytes 4 ([uint32]$newFileSize);Write-U32BE $metaBytes 12 ([uint32]$newDataOffset)
    [byte[]]$out=New-Object byte[] $newFileSize
    [Array]::Copy($metaBytes,0,$out,0,$metaBytes.Length);[Array]::Copy($dataBytes,0,$out,$newDataOffset,$dataBytes.Length)
    return $out
}


function Get-AssemblyPath([string]$GameDir) {
    return (Join-Path $GameDir 'HavenMoon_Data\Managed\Assembly-CSharp.dll')
}

function Patch-AssemblyExperimental([byte[]]$Src,[string]$ManagedDir) {
    if((Get-BytesSha256 $Src)-ne $OriginalAssemblySha256){throw 'Unsupported Assembly-CSharp.dll; refusing experimental runtime patch.'}

    $tool=Join-Path $PSScriptRoot 'Runtime\HavenMoonVR.AssemblyPatcher.exe'
    $cecil=Join-Path $PSScriptRoot 'Runtime\Mono.Cecil.dll'
    if(-not(Test-Path -LiteralPath $tool)){throw "Experimental assembly patcher missing: $tool"}
    if(-not(Test-Path -LiteralPath $cecil)){throw "Mono.Cecil runtime missing: $cecil"}

    $tempDir=Join-Path ([IO.Path]::GetTempPath()) ('HavenMoonVR-1.1-'+[Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $input=Join-Path $tempDir 'Assembly-CSharp.clean.dll'
    $output=Join-Path $tempDir 'Assembly-CSharp.experimental.dll'
    try{
        [IO.File]::WriteAllBytes($input,$Src)
        & $tool $input $output $ManagedDir | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
        if($LASTEXITCODE-ne 0 -or -not(Test-Path -LiteralPath $output)){throw 'Experimental assembly patcher failed.'}
        [byte[]]$Dst=[IO.File]::ReadAllBytes($output)
        $h=Get-BytesSha256 $Dst
        if($h-ne $PatchedAssemblySha256){throw "Internal experimental Assembly-CSharp.dll verification failed: $h"}
        return $Dst
    }finally{
        Remove-Item -LiteralPath $input,$output -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tempDir -Force -ErrorAction SilentlyContinue
    }
}


function Patch-PostProcessingAA([byte[]]$Src) {
    if($Src.Length-ne 49306640){throw 'Unexpected sharedassets1.assets size.'}

    # Exact Haven Moon Unity 5.4.6f3 PostProcessingProfile validation.
    # Method 0 = FXAA. Preset 0 = ExtremePerformance, preset 4 = ExtremeQuality.
    if([BitConverter]::ToUInt32($Src,49304716)-ne 1){throw 'Unexpected Light AA enabled field.'}
    if([BitConverter]::ToUInt32($Src,49304720)-ne 0){throw 'Unexpected Light AA method; expected FXAA.'}
    if([BitConverter]::ToUInt32($Src,49304724)-ne 0){throw 'Unexpected Light FXAA preset.'}

    if([BitConverter]::ToUInt32($Src,49305728)-ne 1){throw 'Unexpected Normal AA enabled field.'}
    if([BitConverter]::ToUInt32($Src,49305732)-ne 0){throw 'Unexpected Normal AA method; expected FXAA.'}
    if([BitConverter]::ToUInt32($Src,49305736)-ne 4){throw 'Unexpected Normal FXAA preset; expected ExtremeQuality.'}

    # Bring the Light profile up to the same FXAA quality as Normal.
    Write-U32LE $Src 49304724 4

    $h=Get-BytesSha256 $Src
    if($h-ne 'bd4393b224032d8b864720e81e90c48b32322560d4cdc19060754fbf6ae4e1a2'){throw "Internal sharedassets1.assets AA verification failed: $h"}
    return $Src
}

function Ensure-HeightRange([double]$Y){if($Y-lt -2.0 -or $Y-gt 0.25){throw 'HeightOffset must be between -2.0 and +0.25 metres.'}}

function Get-BackupDir([string]$GameDir){return (Join-Path $GameDir 'HavenMoonVR_Backup')}
function Restore-CleanFromBackup([string]$GameDir,[bool]$Required) {
    $dataDir=Join-Path $GameDir 'HavenMoon_Data';$backupDir=Get-BackupDir $GameDir
    if(-not(Test-Path -LiteralPath $backupDir)){if($Required){throw "Clean HavenMoonVR backup not found: $backupDir"}else{return $false}}

    $backupMembers=@('globalgamemanagers','level0','level1','level2','level3','level4','level5','level6','sharedassets1.assets')

    # Upgrade compatibility:
    # Older HavenMoonVR backups legitimately lack files that newer releases
    # only started modifying in later stable builds.
    # Add a missing member ONLY if the live game file is exactly the registered
    # clean original. Never promote an unknown/modified live file into the backup.
    foreach($name in $backupMembers){
        $src=Join-Path $backupDir $name

        if(-not(Test-Path -LiteralPath $src)){
            $live=Join-Path $dataDir $name
            if(-not(Test-Path -LiteralPath $live)){throw "Backup file missing and live game file missing: $name"}

            $liveHash=Get-FileSha256 $live
            if($liveHash-ne $OriginalHashes[$name]){
                throw ("Backup file missing: {0}`nThe live file is not the supported clean original, so it cannot be added safely.`nLive SHA-256: {1}`nExpected clean SHA-256: {2}") -f $src,$liveHash,$OriginalHashes[$name]
            }

            Copy-Item -LiteralPath $live -Destination $src -Force
            if((Get-FileSha256 $src)-ne $OriginalHashes[$name]){
                Remove-Item -LiteralPath $src -Force -ErrorAction SilentlyContinue
                throw "Failed to create a verified clean backup for newly-supported file: $name"
            }

            Write-Host ("Added missing clean file to existing backup: {0}" -f $name) -ForegroundColor Green
        }

        if((Get-FileSha256 $src)-ne $OriginalHashes[$name]){throw "Backup is not the supported clean file: $src"}
    }

    foreach($name in $backupMembers){
        Copy-Item -LiteralPath (Join-Path $backupDir $name) -Destination (Join-Path $dataDir $name) -Force
    }

    # Later stable builds also back up the managed gameplay assembly; upgrade older backups safely.
    $asmBackup=Join-Path $backupDir 'Assembly-CSharp.dll'
    if(Test-Path -LiteralPath $asmBackup){
        if((Get-FileSha256 $asmBackup)-ne $OriginalAssemblySha256){throw "Backup is not the supported clean Assembly-CSharp.dll: $asmBackup"}
        Copy-Item -LiteralPath $asmBackup -Destination (Get-AssemblyPath $GameDir) -Force
    }
    return $true
}
function Ensure-CleanFilesAndBackup([string]$GameDir) {
    $dataDir=Join-Path $GameDir 'HavenMoon_Data';$backupDir=Get-BackupDir $GameDir
    $allClean=$true
    foreach($name in $OriginalHashes.Keys){$p=Join-Path $dataDir $name;if(-not(Test-Path -LiteralPath $p) -or (Get-FileSha256 $p)-ne $OriginalHashes[$name]){$allClean=$false;break}}
    if(-not $allClean){
        Write-Host 'Existing HavenMoonVR/modified files detected. Restoring the clean backup first...' -ForegroundColor Yellow
        [void](Restore-CleanFromBackup $GameDir $true)
    }
    if(-not(Test-Path -LiteralPath $backupDir)){New-Item -ItemType Directory -Path $backupDir|Out-Null}
    foreach($name in $OriginalHashes.Keys){
        $p=Join-Path $dataDir $name;if((Get-FileSha256 $p)-ne $OriginalHashes[$name]){throw "Unsupported clean file: $name"}
        $dest=Join-Path $backupDir $name;if(-not(Test-Path -LiteralPath $dest)){Copy-Item -LiteralPath $p -Destination $dest}
        if((Get-FileSha256 $dest)-ne $OriginalHashes[$name]){throw "Backup validation failed: $dest"}
    }

    $asmPath=Get-AssemblyPath $GameDir
    if(-not(Test-Path -LiteralPath $asmPath)){throw "Assembly-CSharp.dll missing: $asmPath"}
    $asmHash=Get-FileSha256 $asmPath
    $asmBackup=Join-Path $backupDir 'Assembly-CSharp.dll'

    if($asmHash-ne $OriginalAssemblySha256){
        if((Test-Path -LiteralPath $asmBackup)-and((Get-FileSha256 $asmBackup)-eq $OriginalAssemblySha256)){
            Copy-Item -LiteralPath $asmBackup -Destination $asmPath -Force
            $asmHash=Get-FileSha256 $asmPath
        }else{
            throw "Assembly-CSharp.dll is already modified and no verified clean backup exists. Restore the game assembly with Steam, then run the installer again."
        }
    }
    if($asmHash-ne $OriginalAssemblySha256){throw 'Unsupported clean Assembly-CSharp.dll.'}
    if(-not(Test-Path -LiteralPath $asmBackup)){Copy-Item -LiteralPath $asmPath -Destination $asmBackup}
    if((Get-FileSha256 $asmBackup)-ne $OriginalAssemblySha256){throw "Assembly backup validation failed: $asmBackup"}
}

function Install-Patch([string]$GameDir,[double]$Y) {
    Assert-HavenMoonVRProcessesClosed
    Ensure-HeightRange $Y
    $exe=Join-Path $GameDir 'HavenMoon.exe';if((Get-FileSha256 $exe)-ne $SupportedExeSha256){throw 'Unsupported HavenMoon.exe build. No files changed.'}
    foreach($required in @(
        'Haven Moon VR Experimental.exe',
        'Start_HavenMoonVR_Experimental.cmd',
        'HavenMoonVR_InputBridge_Experimental.ps1',
        'HavenMoonVR_Experimental_Display.ini',
        'Runtime\HavenMoonVR.Experimental.dll',
        'Runtime\HavenMoonVR.AssemblyPatcher.exe',
        'Runtime\Mono.Cecil.dll',
        'Runtime\HavenMoonVR.SteamShortcutTool.exe',
        'Runtime\HavenMoonVR.ExperimentalLauncher.cs'
    )){if(-not(Test-Path -LiteralPath (Join-Path $PSScriptRoot $required))){throw "Package file missing: $required"}}
    [void](Resolve-SteamShortcutsPath)
    Ensure-CleanFilesAndBackup $GameDir
    $dataDir=Join-Path $GameDir 'HavenMoon_Data';$backupDir=Get-BackupDir $GameDir

    [byte[]]$g=[IO.File]::ReadAllBytes((Join-Path $backupDir 'globalgamemanagers'));$g=Patch-GlobalManagersVR $g;$g=Patch-Controllers $g
    if((Get-BytesSha256 $g)-ne $DefaultFinalHashes['globalgamemanagers']){throw 'Internal globalgamemanagers verification failed.'}
    [IO.File]::WriteAllBytes((Join-Path $dataDir 'globalgamemanagers'),$g)

    [byte[]]$l0=[IO.File]::ReadAllBytes((Join-Path $backupDir 'level0'));$l0=Patch-Level $l0 $LevelPatches['level0']
    if((Get-BytesSha256 $l0)-ne $DefaultFinalHashes['level0']){throw 'Internal level0 verification failed.'}
    [IO.File]::WriteAllBytes((Join-Path $dataDir 'level0'),$l0)

    foreach($name in @('level1','level2','level3','level4','level5','level6')){
        [byte[]]$clean=[IO.File]::ReadAllBytes((Join-Path $backupDir $name));[byte[]]$patched=Patch-SceneWithVROrigin $clean $name ([single]$Y)
        if([Math]::Abs($Y+1.0)-lt 0.000001){$h=Get-BytesSha256 $patched;if($h-ne $DefaultFinalHashes[$name]){throw "Internal $name verification failed: $h"}}
        [IO.File]::WriteAllBytes((Join-Path $dataDir $name),$patched);Write-Host "Patched $name (VR Origin $Y m)"
    }

    # VR anti-aliasing profile patch. The Normal profile is already FXAA
    # ExtremeQuality; the Light profile is upgraded from ExtremePerformance
    # to ExtremeQuality so both quality modes use the strongest built-in FXAA.
    [byte[]]$sharedClean=[IO.File]::ReadAllBytes((Join-Path $backupDir 'sharedassets1.assets'))
    [byte[]]$sharedPatched=Patch-PostProcessingAA $sharedClean
    [IO.File]::WriteAllBytes((Join-Path $dataDir 'sharedassets1.assets'),$sharedPatched)
    Write-Host 'Patched sharedassets1.assets: FXAA ExtremeQuality enabled for both PostProcessing profiles.'

    # Experimental runtime hook: the original centre-screen interaction block is
    # bypassed and replaced by two independent controller rays. Height recenter
    # remains automatic per scene and available manually with F8/Y.
    [byte[]]$asmClean=[IO.File]::ReadAllBytes((Join-Path $backupDir 'Assembly-CSharp.dll'))
    [byte[]]$asmPatched=Patch-AssemblyExperimental $asmClean (Join-Path $GameDir 'HavenMoon_Data\Managed')
    [IO.File]::WriteAllBytes((Get-AssemblyPath $GameDir),$asmPatched)
    Write-Host 'Patched Assembly-CSharp.dll: experimental dual-controller interaction hook enabled.'

    $plugins=Join-Path $dataDir 'Plugins';if(-not(Test-Path -LiteralPath $plugins)){New-Item -ItemType Directory -Path $plugins|Out-Null}
    $openVrDest=Join-Path $plugins 'openvr_api.dll'
    if(Test-Path -LiteralPath $openVrDest){if((Get-PeMachine $openVrDest)-ne 0x14c){throw 'Existing openvr_api.dll is not Win32/x86.'};Write-Host 'Existing Win32 openvr_api.dll kept.'}
    else{$srcOpenVr=Resolve-OpenVrPath $OpenVrPath;Copy-Item -LiteralPath $srcOpenVr -Destination $openVrDest;$copiedHash=Get-FileSha256 $openVrDest;Set-Content -LiteralPath (Join-Path $plugins '.havenmoonvr_openvr_copied') -Value $copiedHash -Encoding ASCII;Write-Host 'Copied Win32 openvr_api.dll from the local SteamVR installation.'}

    Install-ExperimentalRuntimeFiles $GameDir
    [bool]$launcherIconEmbedded=Install-LauncherWithLocalGameIcon $GameDir
    Invoke-SteamShortcut add $GameDir

    Set-Content -LiteralPath (Join-Path $backupDir 'height_offset.txt') -Value ([string]::Format([Globalization.CultureInfo]::InvariantCulture,'{0:0.000}',$Y)) -Encoding ASCII
    @(
        $ModName,
        ('Installed: '+(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
        ('Initial VR Origin height offset: '+$Y+' m'),
        'Experimental interaction: independent left/right tracked rays; left trigger/X=Fire2; right trigger/A=Fire1',
        'Eye height: original 0.683 m camera baseline with tracked-height compensation; F7/F9 adjust by 0.05 m; automatic per scene + Y/F8 reset',
        ('Launcher icon embedded locally from original HavenMoon.exe: '+$launcherIconEmbedded),
        'Ocean rendering: low Water4 shader, planar reflection and edge blend disabled (VR horizon-roll fix)',
        'FXAA profiles=ExtremeQuality'
    )|Set-Content -LiteralPath (Join-Path $backupDir 'HavenMoonVR_install_info.txt') -Encoding UTF8
    Write-Host ''
    Write-Host "$ModName installed." -ForegroundColor Green
    Write-Host 'Steam shortcut: Haven Moon VR Experimental (VR library enabled, original game icon).'
    Write-Host 'IMPORTANT: start the exact entry "Haven Moon VR Experimental", not the older stable shortcut.' -ForegroundColor Yellow
}

function Uninstall-Patch([string]$GameDir) {
    Assert-HavenMoonVRProcessesClosed
    [void](Restore-CleanFromBackup $GameDir $true)
    $plugins=Join-Path (Join-Path $GameDir 'HavenMoon_Data') 'Plugins';$marker=Join-Path $plugins '.havenmoonvr_openvr_copied';$dll=Join-Path $plugins 'openvr_api.dll'
    if((Test-Path -LiteralPath $marker)-and(Test-Path -LiteralPath $dll)){$expected=(Get-Content -LiteralPath $marker -Raw).Trim().ToLowerInvariant();if((Get-FileSha256 $dll)-eq $expected){Remove-Item -LiteralPath $dll -Force;Write-Host 'Removed openvr_api.dll copied by HavenMoonVR.'};Remove-Item -LiteralPath $marker -Force}
    Remove-ExperimentalRuntimeFiles $GameDir
    Invoke-SteamShortcut remove $GameDir
    Write-Host 'HavenMoonVR 1.1.1 Experimental removed; clean game backups kept.' -ForegroundColor Green
}

function Verify-Patch([string]$GameDir) {
    $dataDir=Join-Path $GameDir 'HavenMoon_Data';$backupDir=Get-BackupDir $GameDir
    $height='unknown';$hp=Join-Path $backupDir 'height_offset.txt';if(Test-Path -LiteralPath $hp){$height=(Get-Content -LiteralPath $hp -Raw).Trim()}
    Write-Host "Configured VR Origin offset: $height m"
    foreach($name in @('globalgamemanagers','level0','level1','level2','level3','level4','level5','level6','sharedassets1.assets')){
        $p=Join-Path $dataDir $name;if(-not(Test-Path -LiteralPath $p)){Write-Host "$name : MISSING" -ForegroundColor Red;continue}
        $h=Get-FileSha256 $p
        if($h-eq $OriginalHashes[$name]){Write-Host "$name : ORIGINAL" -ForegroundColor Yellow}
        elseif($name-eq 'sharedassets1.assets' -and $DefaultFinalHashes.ContainsKey($name)-and $h-eq $DefaultFinalHashes[$name]){Write-Host "$name : FXAA EXTREME QUALITY (Normal + Light)" -ForegroundColor Green}
        elseif($DefaultFinalHashes.ContainsKey($name)-and $h-eq $DefaultFinalHashes[$name]){Write-Host "$name : HavenMoonVR default (height -1.00 m, UI 0.35 m, VR-safe ocean horizon)" -ForegroundColor Green}
        elseif($name-like 'level[1-6]'){Write-Host "$name : PATCHED/CUSTOM HEIGHT (SHA $h)" -ForegroundColor Cyan}
        else{Write-Host "$name : MODIFIED/UNKNOWN (SHA $h)" -ForegroundColor Red}
    }
    $asm=Get-AssemblyPath $GameDir
    if(Test-Path -LiteralPath $asm){
        $ah=Get-FileSha256 $asm
        if($ah-eq $PatchedAssemblySha256){Write-Host 'Assembly-CSharp.dll : HavenMoonVR 1.1.1 EXPERIMENTAL DUAL POINTERS' -ForegroundColor Green}
        elseif($ah-eq $OriginalAssemblySha256){Write-Host 'Assembly-CSharp.dll : ORIGINAL (live reset missing)' -ForegroundColor Yellow}
        else{Write-Host "Assembly-CSharp.dll : MODIFIED/UNKNOWN ($ah)" -ForegroundColor Red}
    }else{Write-Host 'Assembly-CSharp.dll : MISSING' -ForegroundColor Red}

    $dll=Join-Path $dataDir 'Plugins\openvr_api.dll';if(Test-Path -LiteralPath $dll){if((Get-PeMachine $dll)-eq 0x14c){Write-Host 'openvr_api.dll : Win32/x86 OK' -ForegroundColor Green}else{Write-Host 'openvr_api.dll : wrong architecture' -ForegroundColor Red}}else{Write-Host 'openvr_api.dll : MISSING' -ForegroundColor Red}
    $helper=Join-Path $dataDir 'Managed\HavenMoonVR.Experimental.dll'
    if(Test-Path -LiteralPath $helper){
        $helperHash=Get-FileSha256 $helper
        if($helperHash-eq $ExperimentalHelperSha256){Write-Host 'HavenMoonVR.Experimental.dll : 1.1.1 HOTFIX OK' -ForegroundColor Green}
        else{Write-Host "HavenMoonVR.Experimental.dll : WRONG BUILD ($helperHash)" -ForegroundColor Red}
    }else{Write-Host 'HavenMoonVR.Experimental.dll : MISSING' -ForegroundColor Red}
    foreach($runtimeName in @('HavenMoonVR_InputBridge_Experimental.ps1','Start_HavenMoonVR_Experimental.cmd','Haven Moon VR Experimental.exe')){
        $runtimePath=Join-Path $GameDir $runtimeName
        if(Test-Path -LiteralPath $runtimePath){Write-Host "$runtimeName : PRESENT" -ForegroundColor Green}else{Write-Host "$runtimeName : MISSING" -ForegroundColor Red}
    }
}

try{
    Write-Host "$ModName`n";$resolvedGame=Resolve-GamePath $GamePath;Write-Host "Game: $resolvedGame"
    switch($Mode){'Install'{Install-Patch $resolvedGame $HeightOffset};'SetHeight'{Install-Patch $resolvedGame $HeightOffset};'Uninstall'{Uninstall-Patch $resolvedGame};'Verify'{Verify-Patch $resolvedGame}}
}catch{Write-Host '';Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red;exit 1}
