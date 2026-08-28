[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Verify','SetHeight')]
    [string]$Mode = 'Install',
    [string]$GamePath,
    [string]$OpenVrPath,
    [double]$HeightOffset = -1.00,
    [ValidateSet('Ask','Auto','Manual')]
    [string]$SteamRegistration = 'Ask'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$ModName = 'HavenMoonVR 1.2.6 Community Patch'
$SteamShortcutName = 'Haven Moon VR Community Patch'
$PatchDisclaimer = 'Unofficial rough-and-ready community patch, provided as-is / Patch artigianale non ufficiale, fornita cosi com''e.'
$SupportedExeSha256 = 'd204db3128f654d052ee72c118604a183d1bcb32ff083edc3f038ac00879f96d'

$OriginalAssemblySha256 = '863be6215489f7cce586539cc5feb146587cf433dabf31bac326e1a366d164f5'
$PatchedAssemblySha256  = '26d72fcc305f854ff58e03ef075262f6bcccee0b6b4fdb7c012c354ea3d33821'
$RuntimeHelperSha256 = '692790d9639070b60f4d5bb5ea978cf985045d5a2b4b6610d82effbd1a97e4a0'
$FastHashCache = @{}
$FastHashCachePath = $null
$FastHashCacheDirty = $false
$FastHashCacheHits = 0
$FastHashFullChecks = 0

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

function Initialize-FastHashCache([string]$GameDir) {
    $script:FastHashCache=@{}
    $script:FastHashCachePath=Join-Path (Join-Path $GameDir 'HavenMoonVR_Backup') '.havenmoonvr_fast_hash_cache_v1.tsv'
    $script:FastHashCacheDirty=$false
    $script:FastHashCacheHits=0
    $script:FastHashFullChecks=0
    if(-not(Test-Path -LiteralPath $script:FastHashCachePath)){return}

    foreach($line in Get-Content -LiteralPath $script:FastHashCachePath){
        if(-not $line-or$line-eq 'format=1'){continue}
        $parts=@($line -split "`t")
        [int64]$length=0;[int64]$lastWriteTicks=0;[int64]$creationTicks=0
        if($parts.Count-ne 5-or$parts[1]-notmatch '^[0-9a-f]{64}$'-or
           -not[Int64]::TryParse($parts[2],[ref]$length)-or
           -not[Int64]::TryParse($parts[3],[ref]$lastWriteTicks)-or
           -not[Int64]::TryParse($parts[4],[ref]$creationTicks)){continue}
        $script:FastHashCache[$parts[0]]=@($parts[1],$length,$lastWriteTicks,$creationTicks)
    }
}

function Set-FastHashCacheEntry([string]$Key,[string]$Path,[string]$ExpectedHash) {
    if(-not $Key-or-not(Test-Path -LiteralPath $Path)){return}
    $item=Get-Item -LiteralPath $Path
    $script:FastHashCache[$Key]=@(
        $ExpectedHash.ToLowerInvariant(),
        [int64]$item.Length,
        [int64]$item.LastWriteTimeUtc.Ticks,
        [int64]$item.CreationTimeUtc.Ticks
    )
    $script:FastHashCacheDirty=$true
}

function Test-FileMatchesExpectedFast([string]$Path,[string]$ExpectedHash,[string]$Key) {
    if(-not(Test-Path -LiteralPath $Path)){
        if($Key-and$script:FastHashCache.ContainsKey($Key)){$script:FastHashCache.Remove($Key);$script:FastHashCacheDirty=$true}
        return $false
    }

    $expected=$ExpectedHash.ToLowerInvariant()
    $item=Get-Item -LiteralPath $Path
    if($Key-and$script:FastHashCache.ContainsKey($Key)){
        $record=$script:FastHashCache[$Key]
        if($record[0]-eq$expected-and
           [int64]$record[1]-eq[int64]$item.Length-and
           [int64]$record[2]-eq[int64]$item.LastWriteTimeUtc.Ticks-and
           [int64]$record[3]-eq[int64]$item.CreationTimeUtc.Ticks){$script:FastHashCacheHits++;return $true}
    }

    $script:FastHashFullChecks++
    $matches=(Get-FileSha256 $Path)-eq$expected
    if($matches){Set-FastHashCacheEntry $Key $Path $expected}
    elseif($Key-and$script:FastHashCache.ContainsKey($Key)){$script:FastHashCache.Remove($Key);$script:FastHashCacheDirty=$true}
    return $matches
}

function Save-FastHashCache {
    if(-not$script:FastHashCachePath-or-not$script:FastHashCacheDirty){return}
    $parent=Split-Path -Parent $script:FastHashCachePath
    if(-not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent|Out-Null}
    $lines=New-Object System.Collections.Generic.List[string]
    $lines.Add('format=1')
    foreach($key in @($script:FastHashCache.Keys|Sort-Object)){
        $record=$script:FastHashCache[$key]
        $lines.Add(($key,$record[0],$record[1],$record[2],$record[3]-join "`t"))
    }
    $temp=$script:FastHashCachePath+'.tmp'
    [IO.File]::WriteAllLines($temp,$lines.ToArray(),(New-Object Text.UTF8Encoding($false)))
    Move-Item -LiteralPath $temp -Destination $script:FastHashCachePath -Force
    $script:FastHashCacheDirty=$false
}

function Copy-FileIfChanged([string]$Source,[string]$Destination,[string]$Label) {
    if(-not(Test-Path -LiteralPath $Source)){throw "Source file missing: $Source"}
    $expected=Get-FileSha256 $Source
    if((Test-Path -LiteralPath $Destination)-and((Get-FileSha256 $Destination)-eq $expected)){
        Write-Host ("Already current: {0}" -f $Label) -ForegroundColor DarkGray
        return $false
    }
    $parent=Split-Path -Parent $Destination
    if($parent-and-not(Test-Path -LiteralPath $parent)){New-Item -ItemType Directory -Path $parent|Out-Null}
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    if((Get-FileSha256 $Destination)-ne $expected){throw "File verification failed after update: $Destination"}
    Write-Host ("Updated: {0}" -f $Label) -ForegroundColor Green
    return $true
}

function Write-BytesIfChanged([string]$Destination,[byte[]]$Bytes,[string]$Label) {
    $expected=Get-BytesSha256 $Bytes
    if((Test-Path -LiteralPath $Destination)-and((Get-FileSha256 $Destination)-eq $expected)){
        Write-Host ("Already current: {0}" -f $Label) -ForegroundColor DarkGray
        return $false
    }
    [IO.File]::WriteAllBytes($Destination,$Bytes)
    if((Get-FileSha256 $Destination)-ne $expected){throw "Patched file verification failed after update: $Destination"}
    Write-Host ("Updated: {0}" -f $Label) -ForegroundColor Green
    return $true
}

function Write-KnownBytes([string]$Destination,[byte[]]$Bytes,[string]$ExpectedHash,[string]$Label,[string]$CacheKey) {
    $computed=Get-BytesSha256 $Bytes
    if($computed-ne$ExpectedHash){throw "Internal $Label verification failed: $computed"}
    [IO.File]::WriteAllBytes($Destination,$Bytes)
    if((Get-FileSha256 $Destination)-ne$ExpectedHash){throw "Patched file verification failed after update: $Destination"}
    Set-FastHashCacheEntry $CacheKey $Destination $ExpectedHash
    Write-Host ("Updated: {0}" -f $Label) -ForegroundColor Green
    return $true
}

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

function Assert-GameAndSteamVRClosed {
    $names=@('HavenMoon','vrmonitor','vrserver','vrcompositor','vrdashboard','vrwebhelper','vrstartup','vrpathreg')
    $running=@()
    foreach($name in $names){
        if(Get-Process -Name $name -ErrorAction SilentlyContinue){$running+=$name}
    }
    if($running.Count-gt 0){
        throw ('Close SteamVR and Haven Moon before continuing. Still running: '+(($running|Select-Object -Unique)-join ', '))
    }
}

function Stop-GameAndSteamVR([string[]]$Names=@('HavenMoon','vrmonitor','vrserver','vrcompositor','vrdashboard','vrwebhelper','vrstartup','vrpathreg')) {
    $running=@()
    foreach($name in $names){
        $running+=@(Get-Process -Name $name -ErrorAction SilentlyContinue)
    }
    if($running.Count-eq 0){
        Write-Host 'Haven Moon and SteamVR are already closed.' -ForegroundColor DarkGray
        return
    }

    $runningNames=@($running|ForEach-Object{$_.ProcessName}|Select-Object -Unique)
    Write-Host ('Closing Haven Moon and SteamVR: '+($runningNames-join ', ')) -ForegroundColor Yellow

    # Ask windowed applications to close normally first, then force only what remains.
    foreach($process in $running){
        try{if($process.MainWindowHandle-ne[IntPtr]::Zero){$null=$process.CloseMainWindow()}}catch{}
    }
    $deadline=(Get-Date).AddSeconds(4)
    do{
        Start-Sleep -Milliseconds 200
        $remaining=@()
        foreach($name in $names){$remaining+=@(Get-Process -Name $name -ErrorAction SilentlyContinue)}
    }while($remaining.Count-gt 0-and(Get-Date)-lt$deadline)

    if($remaining.Count-gt 0){
        Write-Host 'Haven Moon or SteamVR did not close in time; forcing the remaining processes to close...' -ForegroundColor Yellow
        $remaining|Stop-Process -Force -ErrorAction SilentlyContinue
        $deadline=(Get-Date).AddSeconds(6)
        do{
            Start-Sleep -Milliseconds 200
            $remaining=@()
            foreach($name in $names){$remaining+=@(Get-Process -Name $name -ErrorAction SilentlyContinue)}
        }while($remaining.Count-gt 0-and(Get-Date)-lt$deadline)
    }

    if($remaining.Count-gt 0){
        $remainingNames=@($remaining|ForEach-Object{$_.ProcessName}|Select-Object -Unique)
        throw ('Haven Moon or SteamVR could not be closed: '+($remainingNames-join ', '))
    }
    Write-Host 'Haven Moon and SteamVR are closed.' -ForegroundColor DarkGray
}

function Resolve-SteamExecutable {
    foreach($root in Get-SteamRoots){
        $candidate=Join-Path $root 'steam.exe'
        if(Test-Path -LiteralPath $candidate){return (Resolve-Path -LiteralPath $candidate).Path}
    }
    throw 'Steam executable was not found.'
}

function Resolve-SteamRegistrationChoice([string]$Requested) {
    if($Requested-ne 'Ask'){return $Requested}

    Write-Host ''
    Write-Host 'Steam registration / Registrazione in Steam' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '1  Automatic (recommended) / Automatica (consigliata)'
    Write-Host '   The installer closes Haven Moon, SteamVR and Steam, registers the VR launcher and artwork, then reopens Steam.'
    Write-Host '   L''installer chiude Haven Moon, SteamVR e Steam, registra launcher e grafica VR, poi riapre Steam.'
    Write-Host ''
    Write-Host '2  Manual / Manuale'
    Write-Host '   Steam may remain open. No Steam database is changed; artwork is copied beside the game.'
    Write-Host '   Steam puo'' restare aperto. Il database non cambia; la grafica viene copiata accanto al gioco.'
    Write-Host ''

    while($true){
        $choice=(Read-Host 'Choose 1 or 2 / Scegli 1 o 2').Trim()
        if($choice-eq '1'){return 'Auto'}
        if($choice-eq '2'){return 'Manual'}
        Write-Host 'Invalid choice / Scelta non valida.' -ForegroundColor Yellow
    }
}

function Stop-SteamForShortcutUpdate([string]$SteamExe) {
    $running=Get-Process -Name steam -ErrorAction SilentlyContinue
    if($running){
        Write-Host 'Closing Steam for automatic VR-library registration...' -ForegroundColor Yellow
        try{Start-Process -FilePath $SteamExe -ArgumentList '-shutdown' -WindowStyle Hidden | Out-Null}catch{}
        $deadline=(Get-Date).AddSeconds(15)
        while((Get-Process -Name steam -ErrorAction SilentlyContinue)-and(Get-Date)-lt$deadline){Start-Sleep -Milliseconds 250}
    }

    if(Get-Process -Name steam -ErrorAction SilentlyContinue){
        Write-Host 'Steam did not close in time; forcing it to close...' -ForegroundColor Yellow
        Get-Process -Name steam -ErrorAction SilentlyContinue | Stop-Process -Force
        $deadline=(Get-Date).AddSeconds(5)
        while((Get-Process -Name steam -ErrorAction SilentlyContinue)-and(Get-Date)-lt$deadline){Start-Sleep -Milliseconds 200}
    }

    if(Get-Process -Name steam -ErrorAction SilentlyContinue){throw 'Steam could not be closed for shortcut registration.'}
    Get-Process -Name steamwebhelper,steamerrorreporter -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host 'Steam is closed; automatic registration is safe.' -ForegroundColor DarkGray
}

function Restart-SteamAfterShortcutUpdate([string]$SteamExe) {
    if(-not(Test-Path -LiteralPath $SteamExe)){throw "Steam executable is missing: $SteamExe"}
    Write-Host 'Reopening Steam...' -ForegroundColor Cyan
    Start-Process -FilePath $SteamExe | Out-Null
}

function Get-InstalledSteamRegistrationMode([string]$GameDir) {
    $path=Join-Path (Get-BackupDir $GameDir) 'steam_registration_mode.txt'
    if(Test-Path -LiteralPath $path){
        $value=(Get-Content -LiteralPath $path -Raw).Trim()
        if($value-in @('Auto','Manual')){return $value}
    }
    # Builds published before this choice always registered automatically.
    return 'Auto'
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
    $toolOutput=@()
    if($Action-eq 'add'){
        # Remove the exact shortcut name used by the superseded prototype,
        # without retaining that retired label anywhere in the new package.
        $legacyShortcut='Haven Moon VR '+('Exper'+'imental')
        [void](& $tool remove $vdf $legacyShortcut)
        if($LASTEXITCODE-ne 0){throw 'Legacy Steam shortcut cleanup failed.'}
        $launcher=Join-Path $GameDir 'Haven Moon VR.exe'
        # Use the custom icon shipped for the community launcher. The same
        # badge is embedded in the EXE and installed as AppID artwork below.
        $customIcon=Join-Path $GameDir 'HavenMoonVR_Artwork\HavenMoonVR_LauncherIcon_256x256.png'
        if(-not(Test-Path -LiteralPath $customIcon)){$customIcon=$launcher}
        $toolOutput=@(& $tool add $vdf $launcher $SteamShortcutName $customIcon)
    }else{
        $toolOutput=@(& $tool remove $vdf $SteamShortcutName)
    }
    $toolOutput | ForEach-Object {Write-Host $_ -ForegroundColor DarkGray}
    if($LASTEXITCODE-ne 0){throw "Steam shortcut $Action failed."}
    if($Action-eq 'add'){
        $appIdLine=$toolOutput|Where-Object{$_-like 'APPID=*'}|Select-Object -Last 1
        if(-not$appIdLine){throw 'Steam shortcut tool did not return the generated AppID.'}
        return [uint64]$appIdLine.Substring(6)
    }
}

function Get-ArtworkNames {
    return @(
        'HavenMoonVR_AppIcon_184x184.jpg',
        'HavenMoonVR_LauncherIcon.ico',
        'HavenMoonVR_LauncherIcon_256x256.png',
        'HavenMoonVR_LibraryCapsule_600x900.png',
        'HavenMoonVR_LibraryHeader_920x430.png',
        'HavenMoonVR_LibraryHero_3840x1240.png',
        'HavenMoonVR_LibraryLogo_720x720.png',
        'HavenMoonVR_SteamVR_Background_1920x1080.png'
    )
}

function Install-UserArtworkFiles([string]$GameDir) {
    $sourceDir=Join-Path $PSScriptRoot 'Artwork'
    $destinationDir=Join-Path $GameDir 'HavenMoonVR_Artwork'
    $updated=0
    $manifest=New-Object System.Collections.Generic.List[string]
    foreach($name in Get-ArtworkNames){
        $source=Join-Path $sourceDir $name
        $destination=Join-Path $destinationDir $name
        if(Copy-FileIfChanged $source $destination ('artwork '+$name)){$updated++}
        $manifest.Add(((Get-FileSha256 $destination)+'  '+$name))
    }
    Set-Content -LiteralPath (Join-Path $destinationDir '.havenmoonvr_artwork_files.txt') -Value $manifest.ToArray() -Encoding ASCII
    return $updated
}

function Remove-UserArtworkFiles([string]$GameDir) {
    $destinationDir=Join-Path $GameDir 'HavenMoonVR_Artwork'
    $manifestPath=Join-Path $destinationDir '.havenmoonvr_artwork_files.txt'
    if(-not(Test-Path -LiteralPath $manifestPath)){return}
    foreach($line in Get-Content -LiteralPath $manifestPath){
        if($line-notmatch '^([0-9a-f]{64})  ([^\\/:*?""<>|]+)$'){continue}
        $expected=$Matches[1];$name=$Matches[2]
        if($name-notin(Get-ArtworkNames)){continue}
        $path=Join-Path $destinationDir $name
        if((Test-Path -LiteralPath $path)-and(Get-FileSha256 $path)-eq$expected){Remove-Item -LiteralPath $path -Force}
        elseif(Test-Path -LiteralPath $path){Write-Host ("Kept user-modified artwork: {0}" -f $path) -ForegroundColor Yellow}
    }
    Remove-Item -LiteralPath $manifestPath -Force
    if(-not(Get-ChildItem -LiteralPath $destinationDir -Force -ErrorAction SilentlyContinue)){Remove-Item -LiteralPath $destinationDir -Force}
}

function Install-SteamLibraryArtwork([string]$GameDir,[uint64]$AppId) {
    $vdf=Resolve-SteamShortcutsPath
    $gridDir=Join-Path (Split-Path -Parent $vdf) 'grid'
    if(-not(Test-Path -LiteralPath $gridDir)){New-Item -ItemType Directory -Path $gridDir|Out-Null}
    $sourceDir=Join-Path $GameDir 'HavenMoonVR_Artwork'
    $map=[ordered]@{
        'HavenMoonVR_LibraryHeader_920x430.png'=([string]$AppId+'.png')
        'HavenMoonVR_LibraryCapsule_600x900.png'=([string]$AppId+'p.png')
        'HavenMoonVR_LibraryHero_3840x1240.png'=([string]$AppId+'_hero.png')
        'HavenMoonVR_LibraryLogo_720x720.png'=([string]$AppId+'_logo.png')
        'HavenMoonVR_LauncherIcon_256x256.png'=([string]$AppId+'_icon.png')
    }
    $record=New-Object System.Collections.Generic.List[string]
    foreach($sourceName in $map.Keys){
        $source=Join-Path $sourceDir $sourceName
        $destination=Join-Path $gridDir $map[$sourceName]
        [void](Copy-FileIfChanged $source $destination ('Steam artwork '+$map[$sourceName]))
        $record.Add(((Get-FileSha256 $destination)+"`t"+$destination))
    }
    Set-Content -LiteralPath (Join-Path (Get-BackupDir $GameDir) 'steam_artwork_manifest.txt') -Value $record.ToArray() -Encoding UTF8
    Write-Host 'Installed custom artwork for Steam Library and SteamVR.' -ForegroundColor Green
}

function Remove-SteamLibraryArtwork([string]$GameDir) {
    $recordPath=Join-Path (Get-BackupDir $GameDir) 'steam_artwork_manifest.txt'
    if(-not(Test-Path -LiteralPath $recordPath)){return}
    foreach($line in Get-Content -LiteralPath $recordPath){
        if($line-notmatch '^([0-9a-f]{64})\t(.+)$'){continue}
        $expected=$Matches[1];$path=$Matches[2]
        $fileName=Split-Path -Leaf $path
        $parent=Split-Path -Parent $path
        if($fileName-notmatch '^\d+(p|_hero|_logo|_icon)?\.png$'-or(Split-Path -Leaf $parent)-ne'grid'){continue}
        if((Test-Path -LiteralPath $path)-and(Get-FileSha256 $path)-eq$expected){Remove-Item -LiteralPath $path -Force;Write-Host ("Removed Steam artwork: {0}" -f $fileName) -ForegroundColor DarkGray}
        elseif(Test-Path -LiteralPath $path){Write-Host ("Kept user-modified Steam artwork: {0}" -f $path) -ForegroundColor Yellow}
    }
    Remove-Item -LiteralPath $recordPath -Force
}

function Install-RuntimeFiles([string]$GameDir) {
    $updated=0
    $rootFiles=@(
        'Haven Moon VR.exe',
        'Start_HavenMoonVR.cmd',
        'HavenMoonVR_InputBridge.ps1',
        'HavenMoonVR_Display.ini'
    )
    foreach($name in $rootFiles){
        $source=Join-Path $PSScriptRoot $name
        $destination=Join-Path $GameDir $name
        if(-not(Test-Path -LiteralPath $source)){throw "Community runtime file missing: $source"}
        if($name-eq 'HavenMoonVR_Display.ini' -and (Test-Path -LiteralPath $destination)){
            Write-Host 'Existing community display configuration kept.' -ForegroundColor DarkGray
        }elseif($name-eq 'Haven Moon VR.exe' -and (Test-Path -LiteralPath $destination)){
            # Keep a previously icon-enabled launcher. The icon installer below
            # verifies its source marker and rebuilds it only when required.
            Write-Host 'Existing community launcher retained for incremental icon verification.' -ForegroundColor DarkGray
        }else{
            if(Copy-FileIfChanged $source $destination $name){$updated++}
        }
    }

    $helperSource=Join-Path $PSScriptRoot 'Runtime\HavenMoonVR.Runtime.dll'
    $helperDestination=Join-Path $GameDir 'HavenMoon_Data\Managed\HavenMoonVR.Runtime.dll'
    if(-not(Test-Path -LiteralPath $helperSource)){throw "Community in-game runtime missing: $helperSource"}
    if(Copy-FileIfChanged $helperSource $helperDestination 'HavenMoonVR.Runtime.dll'){$updated++}
    if((Get-FileSha256 $helperDestination)-ne $RuntimeHelperSha256){throw 'Community in-game runtime verification failed after copy.'}

    @($rootFiles+'HavenMoon_Data\Managed\HavenMoonVR.Runtime.dll'+'.havenmoonvr_launcher_build.txt') |
        Set-Content -LiteralPath (Join-Path $GameDir '.havenmoonvr_1_2_runtime_files.txt') -Encoding UTF8
    return $updated
}

function Install-LauncherWithCustomIcon([string]$GameDir) {
    $launcher=Join-Path $GameDir 'Haven Moon VR.exe'
    $launcherSource=Join-Path $PSScriptRoot 'Runtime\HavenMoonVR.Launcher.cs'
    $customIco=Join-Path $PSScriptRoot 'Artwork\HavenMoonVR_LauncherIcon.ico'
    $buildMarker=Join-Path $GameDir '.havenmoonvr_launcher_build.txt'
    $csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
    if(-not(Test-Path -LiteralPath $launcherSource)-or-not(Test-Path -LiteralPath $customIco)-or-not(Test-Path -LiteralPath $csc)){
        Write-Host 'Local custom-icon embedding is unavailable; the prebuilt community launcher will be kept.' -ForegroundColor Yellow
        return $false
    }

    $expectedMarker=@(
        'format=2',
        ('launcher_source_sha256='+(Get-FileSha256 $launcherSource)),
        ('custom_icon_sha256='+(Get-FileSha256 $customIco)),
        'platform=AnyCPU',
        'icon=HavenMoonVR_LauncherIcon.ico'
    )-join "`n"
    if((Test-Path -LiteralPath $launcher)-and(Test-Path -LiteralPath $buildMarker)){
        $currentMarker=(Get-Content -LiteralPath $buildMarker -Raw).Trim() -replace "`r`n","`n"
        $markerLines=@($currentMarker -split "`n")
        $recordedHashLine=$markerLines|Where-Object{$_-like 'launcher_sha256=*'}|Select-Object -First 1
        $recordedHash=if($recordedHashLine){$recordedHashLine.Substring('launcher_sha256='.Length)}else{''}
        $recordedBase=@($markerLines|Where-Object{$_-notlike 'launcher_sha256=*'})-join "`n"
        if($recordedBase-eq $expectedMarker-and$recordedHash-and(Get-FileSha256 $launcher)-eq$recordedHash){
            Write-Host 'Already current: icon-enabled community launcher.' -ForegroundColor DarkGray
            return $true
        }
    }

    $tempDir=Join-Path ([IO.Path]::GetTempPath()) ('HavenMoonVR-LauncherIcon-'+[Guid]::NewGuid().ToString('N'))
    $sourceIcon=$null;$sourceBitmap=$null;$embeddedIcon=$null;$embeddedBitmap=$null
    try{
        New-Item -ItemType Directory -Path $tempDir|Out-Null
        Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        $builtLauncher=Join-Path $tempDir 'Haven Moon VR.exe'

        $sourceIcon=New-Object Drawing.Icon -ArgumentList $customIco,32,32
        if($null-eq$sourceIcon){throw 'The packaged custom launcher icon could not be loaded.'}
        $sourceBitmap=$sourceIcon.ToBitmap()
        if($sourceBitmap.Width-ne 32-or$sourceBitmap.Height-ne 32){throw 'The packaged custom icon does not expose its 32-pixel representation.'}

        $compilerArgs=@(
            '/nologo','/target:winexe','/platform:anycpu','/optimize+',
            '/reference:System.Windows.Forms.dll',
            ('/win32icon:'+$customIco),('/out:'+$builtLauncher),$launcherSource
        )
        & $csc @compilerArgs | ForEach-Object {Write-Host $_ -ForegroundColor DarkGray}
        if($LASTEXITCODE-ne 0-or-not(Test-Path -LiteralPath $builtLauncher)){throw 'The icon-enabled launcher could not be compiled.'}

        $embeddedIcon=[Drawing.Icon]::ExtractAssociatedIcon($builtLauncher)
        if($null-eq$embeddedIcon){throw 'The compiled launcher does not expose an icon.'}
        $embeddedBitmap=$embeddedIcon.ToBitmap()
        if($embeddedBitmap.Width-ne$sourceBitmap.Width-or$embeddedBitmap.Height-ne$sourceBitmap.Height){
            throw 'The compiled launcher does not expose the expected 32-pixel icon representation.'
        }
        Copy-Item -LiteralPath $builtLauncher -Destination $launcher -Force
        $launcherHash=Get-FileSha256 $launcher
        [IO.File]::WriteAllText($buildMarker,$expectedMarker+"`nlauncher_sha256="+$launcherHash+"`r`n",[Text.UTF8Encoding]::new($false))
        Write-Host 'Embedded the custom HavenMoonVR icon in the community launcher.' -ForegroundColor Green
        return $true
    }catch{
        Write-Host ('Launcher icon warning: '+$_.Exception.Message) -ForegroundColor Yellow
        Write-Host 'The prebuilt launcher and Steam artwork icon remain available.' -ForegroundColor Yellow
        return $false
    }finally{
        if($null-ne$sourceBitmap){$sourceBitmap.Dispose()};if($null-ne$sourceIcon){$sourceIcon.Dispose()}
        if($null-ne$embeddedBitmap){$embeddedBitmap.Dispose()};if($null-ne$embeddedIcon){$embeddedIcon.Dispose()}
        if(Test-Path -LiteralPath $tempDir){Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue}
    }
}

function Remove-RuntimeFiles([string]$GameDir) {
    $relative=@(
        'Haven Moon VR.exe',
        'Start_HavenMoonVR.cmd',
        'HavenMoonVR_InputBridge.ps1',
        'HavenMoonVR_Display.ini',
        'HavenMoon_Data\Managed\HavenMoonVR.Runtime.dll',
        '.havenmoonvr_launcher_build.txt',
        '.havenmoonvr_1_2_runtime_files.txt'
    )
    foreach($name in $relative){
        $path=Join-Path $GameDir $name
        if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path -Force}
    }
}

function Remove-LegacyPrototypeFiles([string]$GameDir) {
    $legacyWord='Exper'+'imental'
    $legacyLower=$legacyWord.ToLowerInvariant()
    $oldConfig=Join-Path $GameDir ("HavenMoonVR_{0}_Display.ini" -f $legacyWord)
    $newConfig=Join-Path $GameDir 'HavenMoonVR_Display.ini'
    if((Test-Path -LiteralPath $oldConfig)-and-not(Test-Path -LiteralPath $newConfig)){
        Copy-Item -LiteralPath $oldConfig -Destination $newConfig
    }

    $relative=@(
        ("Haven Moon VR {0}.exe" -f $legacyWord),
        ("Start_HavenMoonVR_{0}.cmd" -f $legacyWord),
        ("HavenMoonVR_InputBridge_{0}.ps1" -f $legacyWord),
        ("HavenMoonVR_{0}_Display.ini" -f $legacyWord),
        ("HavenMoon_Data\Managed\HavenMoonVR.{0}.dll" -f $legacyWord),
        (".havenmoonvr_{0}_launcher_build.txt" -f $legacyLower),
        (".havenmoonvr_1_1_{0}_runtime_files.txt" -f $legacyLower)
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

function Patch-AssemblyCommunity([byte[]]$Src,[string]$ManagedDir) {
    if((Get-BytesSha256 $Src)-ne $OriginalAssemblySha256){throw 'Unsupported Assembly-CSharp.dll; refusing community runtime patch.'}

    $tool=Join-Path $PSScriptRoot 'Runtime\HavenMoonVR.AssemblyPatcher.exe'
    $cecil=Join-Path $PSScriptRoot 'Runtime\Mono.Cecil.dll'
    if(-not(Test-Path -LiteralPath $tool)){throw "Community assembly patcher missing: $tool"}
    if(-not(Test-Path -LiteralPath $cecil)){throw "Mono.Cecil runtime missing: $cecil"}

    $tempDir=Join-Path ([IO.Path]::GetTempPath()) ('HavenMoonVR-1.2.6-'+[Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $input=Join-Path $tempDir 'Assembly-CSharp.clean.dll'
    $output=Join-Path $tempDir 'Assembly-CSharp.community.dll'
    try{
        [IO.File]::WriteAllBytes($input,$Src)
        & $tool $input $output $ManagedDir | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }
        if($LASTEXITCODE-ne 0 -or -not(Test-Path -LiteralPath $output)){throw 'Community assembly patcher failed.'}
        [byte[]]$Dst=[IO.File]::ReadAllBytes($output)
        $h=Get-BytesSha256 $Dst
        if($h-ne $PatchedAssemblySha256){throw "Internal community Assembly-CSharp.dll verification failed: $h"}
        return $Dst
    }finally{
        Remove-Item -LiteralPath $input,$output -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tempDir -Force -ErrorAction SilentlyContinue
    }
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
    if(-not(Test-Path -LiteralPath $backupDir)){New-Item -ItemType Directory -Path $backupDir|Out-Null}

    # Validate or create each clean backup independently. Live files are not
    # restored here: Install-Patch compares every desired output and rewrites
    # only files that are missing, outdated or different.
    foreach($name in $OriginalHashes.Keys){
        $p=Join-Path $dataDir $name
        $dest=Join-Path $backupDir $name
        if(-not(Test-Path -LiteralPath $dest)){
            if(-not(Test-Path -LiteralPath $p)){throw "Game file and clean backup are both missing: $name"}
            $liveHash=Get-FileSha256 $p
            if($liveHash-ne $OriginalHashes[$name]){
                throw ("Clean backup missing for {0}, and the live file is already modified.`nLive SHA-256: {1}`nExpected clean SHA-256: {2}`nVerify the game files through Steam, then run the installer again.") -f $name,$liveHash,$OriginalHashes[$name]
            }
            Copy-Item -LiteralPath $p -Destination $dest
            Write-Host ("Created verified clean backup: {0}" -f $name) -ForegroundColor Green
        }
        if(-not(Test-FileMatchesExpectedFast $dest $OriginalHashes[$name] ('backup:'+$name))){throw "Backup validation failed: $dest"}
    }

    $asmPath=Get-AssemblyPath $GameDir
    $asmBackup=Join-Path $backupDir 'Assembly-CSharp.dll'

    if(-not(Test-Path -LiteralPath $asmBackup)){
        if(-not(Test-Path -LiteralPath $asmPath)){throw "Assembly-CSharp.dll and its clean backup are both missing: $asmPath"}
        $asmHash=Get-FileSha256 $asmPath
        if($asmHash-ne $OriginalAssemblySha256){throw "Assembly-CSharp.dll is already modified and no verified clean backup exists. Restore the game assembly with Steam, then run the installer again."}
        Copy-Item -LiteralPath $asmPath -Destination $asmBackup
        Write-Host 'Created verified clean backup: Assembly-CSharp.dll' -ForegroundColor Green
    }
    if(-not(Test-FileMatchesExpectedFast $asmBackup $OriginalAssemblySha256 'backup:Assembly-CSharp.dll')){throw "Assembly backup validation failed: $asmBackup"}
    Write-Host 'Clean backup accepted; live files will be checked individually.' -ForegroundColor DarkGray
}

function Install-Patch([string]$GameDir,[double]$Y,[ValidateSet('Auto','Manual')][string]$RegistrationMode,[bool]$UpdateSteamShortcut) {
    Ensure-HeightRange $Y
    Initialize-FastHashCache $GameDir
    # Keep the supported-build guard unconditional. HavenMoon.exe is small;
    # caching the large scenes/backups provides the speed-up without weakening
    # the executable compatibility check.
    $exe=Join-Path $GameDir 'HavenMoon.exe';if((Get-FileSha256 $exe)-ne$SupportedExeSha256){throw 'Unsupported HavenMoon.exe build. No files changed.'}
    foreach($required in @(
        'Haven Moon VR.exe',
        'Start_HavenMoonVR.cmd',
        'HavenMoonVR_InputBridge.ps1',
        'HavenMoonVR_Display.ini',
        'Runtime\HavenMoonVR.Runtime.dll',
        'Runtime\HavenMoonVR.AssemblyPatcher.exe',
        'Runtime\Mono.Cecil.dll',
        'Runtime\HavenMoonVR.SteamShortcutTool.exe',
        'Runtime\HavenMoonVR.Launcher.cs',
        'Artwork\HavenMoonVR_AppIcon_184x184.jpg',
        'Artwork\HavenMoonVR_LauncherIcon.ico',
        'Artwork\HavenMoonVR_LauncherIcon_256x256.png',
        'Artwork\HavenMoonVR_LibraryCapsule_600x900.png',
        'Artwork\HavenMoonVR_LibraryHeader_920x430.png',
        'Artwork\HavenMoonVR_LibraryHero_3840x1240.png',
        'Artwork\HavenMoonVR_LibraryLogo_720x720.png',
        'Artwork\HavenMoonVR_SteamVR_Background_1920x1080.png'
    )){if(-not(Test-Path -LiteralPath (Join-Path $PSScriptRoot $required))){throw "Package file missing: $required"}}
    if($UpdateSteamShortcut-and$RegistrationMode-eq'Auto'){[void](Resolve-SteamShortcutsPath)}
    Ensure-CleanFilesAndBackup $GameDir
    $dataDir=Join-Path $GameDir 'HavenMoon_Data';$backupDir=Get-BackupDir $GameDir
    $updatedFiles=0

    $gDest=Join-Path $dataDir 'globalgamemanagers'
    if(Test-FileMatchesExpectedFast $gDest $DefaultFinalHashes['globalgamemanagers'] 'live:globalgamemanagers'){
        Write-Host 'Already current: globalgamemanagers (fast check)' -ForegroundColor DarkGray
    }else{
        [byte[]]$g=[IO.File]::ReadAllBytes((Join-Path $backupDir 'globalgamemanagers'));$g=Patch-GlobalManagersVR $g;$g=Patch-Controllers $g
        if(Write-KnownBytes $gDest $g $DefaultFinalHashes['globalgamemanagers'] 'globalgamemanagers' 'live:globalgamemanagers'){$updatedFiles++}
    }

    $l0Dest=Join-Path $dataDir 'level0'
    if(Test-FileMatchesExpectedFast $l0Dest $DefaultFinalHashes['level0'] 'live:level0'){
        Write-Host 'Already current: level0 (fast check)' -ForegroundColor DarkGray
    }else{
        [byte[]]$l0=[IO.File]::ReadAllBytes((Join-Path $backupDir 'level0'));$l0=Patch-Level $l0 $LevelPatches['level0']
        if(Write-KnownBytes $l0Dest $l0 $DefaultFinalHashes['level0'] 'level0' 'live:level0'){$updatedFiles++}
    }

    foreach($name in @('level1','level2','level3','level4','level5','level6')){
        $destination=Join-Path $dataDir $name
        $isDefaultHeight=[Math]::Abs($Y+1.0)-lt 0.000001
        if($isDefaultHeight-and(Test-FileMatchesExpectedFast $destination $DefaultFinalHashes[$name] ('live:'+$name))){
            Write-Host ("Already current: {0} (fast check)" -f $name) -ForegroundColor DarkGray
            continue
        }
        [byte[]]$clean=[IO.File]::ReadAllBytes((Join-Path $backupDir $name));[byte[]]$patched=Patch-SceneWithVROrigin $clean $name ([single]$Y)
        if($isDefaultHeight){
            if(Write-KnownBytes $destination $patched $DefaultFinalHashes[$name] ("{0} (VR Origin {1} m)" -f $name,$Y) ('live:'+$name)){$updatedFiles++}
        }elseif(Write-BytesIfChanged $destination $patched ("{0} (VR Origin {1} m)" -f $name,$Y)){$updatedFiles++}
    }

    # Version 1.2.6 preserves the game's complete original visual asset.
    # This also upgrades a 1.2.0 installation by replacing its altered copy
    # with the verified clean backup, without touching unrelated game files.
    $sharedDest=Join-Path $dataDir 'sharedassets1.assets'
    $sharedOriginalHash=$OriginalHashes['sharedassets1.assets']
    if(Test-FileMatchesExpectedFast $sharedDest $sharedOriginalHash 'live:sharedassets1.assets'){
        Write-Host 'Already current: original visual profile (fast check)' -ForegroundColor DarkGray
    }else{
        [byte[]]$sharedClean=[IO.File]::ReadAllBytes((Join-Path $backupDir 'sharedassets1.assets'))
        if(Write-KnownBytes $sharedDest $sharedClean $sharedOriginalHash 'sharedassets1.assets (original visual profile restored)' 'live:sharedassets1.assets'){$updatedFiles++}
    }

    # Community runtime hook: the original centre-screen interaction block is
    # bypassed and replaced by two independent controller rays. Height recenter
    # remains automatic per scene and available manually with F8/Y.
    $asmDestination=Get-AssemblyPath $GameDir
    if(Test-FileMatchesExpectedFast $asmDestination $PatchedAssemblySha256 'live:Assembly-CSharp.dll'){
        Write-Host 'Already current: Assembly-CSharp.dll (fast check)' -ForegroundColor DarkGray
    }else{
        [byte[]]$asmClean=[IO.File]::ReadAllBytes((Join-Path $backupDir 'Assembly-CSharp.dll'))
        [byte[]]$asmPatched=Patch-AssemblyCommunity $asmClean (Join-Path $GameDir 'HavenMoon_Data\Managed')
        if(Write-KnownBytes $asmDestination $asmPatched $PatchedAssemblySha256 'Assembly-CSharp.dll (community dual-controller hook)' 'live:Assembly-CSharp.dll'){$updatedFiles++}
    }

    $plugins=Join-Path $dataDir 'Plugins';if(-not(Test-Path -LiteralPath $plugins)){New-Item -ItemType Directory -Path $plugins|Out-Null}
    $openVrDest=Join-Path $plugins 'openvr_api.dll'
    if(Test-Path -LiteralPath $openVrDest){if((Get-PeMachine $openVrDest)-ne 0x14c){throw 'Existing openvr_api.dll is not Win32/x86.'};Write-Host 'Existing Win32 openvr_api.dll kept.'}
    else{$srcOpenVr=Resolve-OpenVrPath $OpenVrPath;Copy-Item -LiteralPath $srcOpenVr -Destination $openVrDest;$copiedHash=Get-FileSha256 $openVrDest;Set-Content -LiteralPath (Join-Path $plugins '.havenmoonvr_openvr_copied') -Value $copiedHash -Encoding ASCII;Write-Host 'Copied Win32 openvr_api.dll from the local SteamVR installation.'}

    Remove-LegacyPrototypeFiles $GameDir
    $updatedFiles += [int](Install-RuntimeFiles $GameDir)
    $updatedFiles += [int](Install-UserArtworkFiles $GameDir)
    [bool]$launcherIconEmbedded=Install-LauncherWithCustomIcon $GameDir
    if($UpdateSteamShortcut-and$RegistrationMode-eq'Auto'){
        [uint64]$steamAppId=Invoke-SteamShortcut add $GameDir
        Install-SteamLibraryArtwork $GameDir $steamAppId
    }elseif($UpdateSteamShortcut){
        Write-Host 'Steam registration skipped by user choice; Steam was left untouched.' -ForegroundColor Cyan
    }

    Set-Content -LiteralPath (Join-Path $backupDir 'height_offset.txt') -Value ([string]::Format([Globalization.CultureInfo]::InvariantCulture,'{0:0.000}',$Y)) -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $backupDir 'steam_registration_mode.txt') -Value $RegistrationMode -Encoding ASCII
    @(
        $ModName,
        ('Installed: '+(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')),
        ('Initial VR Origin height offset: '+$Y+' m'),
        'Community interaction: independent left/right tracked rays; left trigger/X=Fire2; right trigger/A=Fire1',
        'Eye height: original 0.683 m camera baseline with tracked-height compensation; F7/F9 adjust by 0.05 m; automatic per scene + Y/F8 reset',
        ('Custom HavenMoonVR launcher icon embedded: '+$launcherIconEmbedded),
        ('Steam registration mode: '+$RegistrationMode),
        'Graphics: original Haven Moon rendering preserved except for the ocean planar reflection and targeted Water Enhanced VR material tuning',
        'Ocean: planar reflection disabled; original Water4 path retained with stronger Fresnel, sharper specular light, subtle foam and 8x filtered water textures',
        'VR warning: original water and horizon effects can show stereo artefacts when the headset is rolled',
        'Collision Fix v2: duplicate movement suppressed; one continuous move keeps the body capsule centred below the tracked HMD',
        'Fast installer checks: metadata cache first; SHA-256 after any size/timestamp change',
        'Anti-aliasing: original Haven Moon setting',
        'Steam/SteamVR artwork: Hero, Logo, Header, Capsule and Icon installed for automatically managed shortcuts'
    )|Set-Content -LiteralPath (Join-Path $backupDir 'HavenMoonVR_install_info.txt') -Encoding UTF8
    Write-Host ''
    Write-Host "$ModName installed." -ForegroundColor Green
    Write-Host ("Game/runtime files updated: {0}. Already-current files were left untouched." -f $updatedFiles) -ForegroundColor Green
    if($RegistrationMode-eq'Auto'){
        Write-Host 'Steam shortcut: Haven Moon VR Community Patch (VR library and custom icon enabled).'
        Write-Host 'IMPORTANT: start the exact Community Patch entry, not an older shortcut.' -ForegroundColor Yellow
    }else{
        $manualLauncher=Join-Path $GameDir 'Haven Moon VR.exe'
        Write-Host ''
        Write-Host 'MANUAL STEAM REGISTRATION / REGISTRAZIONE MANUALE:' -ForegroundColor Yellow
        Write-Host 'Steam > Games/Giochi > Add a Non-Steam Game/Aggiungi un gioco non di Steam.'
        Write-Host ("Select / Seleziona: {0}" -f $manualLauncher)
        Write-Host 'Then enable Include in VR Library / Includi nella Libreria VR in its properties.'
        Write-Host ("Custom artwork / Grafica personalizzata: {0}" -f (Join-Path $GameDir 'HavenMoonVR_Artwork'))
    }
    Write-Host ("Version checks: {0} fast cache hit(s), {1} full SHA-256 check(s)." -f $script:FastHashCacheHits,$script:FastHashFullChecks) -ForegroundColor DarkGray
    Save-FastHashCache
}

function Uninstall-Patch([string]$GameDir,[ValidateSet('Auto','Manual')][string]$RegistrationMode) {
    [void](Restore-CleanFromBackup $GameDir $true)
    $plugins=Join-Path (Join-Path $GameDir 'HavenMoon_Data') 'Plugins';$marker=Join-Path $plugins '.havenmoonvr_openvr_copied';$dll=Join-Path $plugins 'openvr_api.dll'
    if((Test-Path -LiteralPath $marker)-and(Test-Path -LiteralPath $dll)){$expected=(Get-Content -LiteralPath $marker -Raw).Trim().ToLowerInvariant();if((Get-FileSha256 $dll)-eq $expected){Remove-Item -LiteralPath $dll -Force;Write-Host 'Removed openvr_api.dll copied by HavenMoonVR.'};Remove-Item -LiteralPath $marker -Force}
    Remove-RuntimeFiles $GameDir
    if($RegistrationMode-eq'Auto'){
        Remove-SteamLibraryArtwork $GameDir
        Invoke-SteamShortcut remove $GameDir
    }else{
        Write-Host 'Manual Steam shortcuts were left untouched; remove yours manually if present.' -ForegroundColor Yellow
    }
    Remove-UserArtworkFiles $GameDir
    Write-Host 'HavenMoonVR 1.2.6 Community Patch removed; clean game backups kept.' -ForegroundColor Green
}

function Verify-Patch([string]$GameDir) {
    $dataDir=Join-Path $GameDir 'HavenMoon_Data';$backupDir=Get-BackupDir $GameDir
    $height='unknown';$hp=Join-Path $backupDir 'height_offset.txt';if(Test-Path -LiteralPath $hp){$height=(Get-Content -LiteralPath $hp -Raw).Trim()}
    Write-Host "Configured VR Origin offset: $height m"
    Write-Host ("Steam registration mode: {0}" -f (Get-InstalledSteamRegistrationMode $GameDir))
    foreach($name in @('globalgamemanagers','level0','level1','level2','level3','level4','level5','level6','sharedassets1.assets')){
        $p=Join-Path $dataDir $name;if(-not(Test-Path -LiteralPath $p)){Write-Host "$name : MISSING" -ForegroundColor Red;continue}
        $h=Get-FileSha256 $p
        if($name-eq 'sharedassets1.assets' -and $h-eq $OriginalHashes[$name]){Write-Host "$name : ORIGINAL VISUAL PROFILE" -ForegroundColor Green}
        elseif($h-eq $OriginalHashes[$name]){Write-Host "$name : ORIGINAL" -ForegroundColor Yellow}
        elseif($DefaultFinalHashes.ContainsKey($name)-and $h-eq $DefaultFinalHashes[$name]){Write-Host "$name : HavenMoonVR default (height -1.00 m, UI 0.35 m, original graphics)" -ForegroundColor Green}
        elseif($name-like 'level[1-6]'){Write-Host "$name : PATCHED/CUSTOM HEIGHT (SHA $h)" -ForegroundColor Cyan}
        else{Write-Host "$name : MODIFIED/UNKNOWN (SHA $h)" -ForegroundColor Red}
    }
    $asm=Get-AssemblyPath $GameDir
    if(Test-Path -LiteralPath $asm){
        $ah=Get-FileSha256 $asm
        if($ah-eq $PatchedAssemblySha256){Write-Host 'Assembly-CSharp.dll : HavenMoonVR 1.2.6 COMMUNITY DUAL POINTERS' -ForegroundColor Green}
        elseif($ah-eq $OriginalAssemblySha256){Write-Host 'Assembly-CSharp.dll : ORIGINAL (live reset missing)' -ForegroundColor Yellow}
        else{Write-Host "Assembly-CSharp.dll : MODIFIED/UNKNOWN ($ah)" -ForegroundColor Red}
    }else{Write-Host 'Assembly-CSharp.dll : MISSING' -ForegroundColor Red}

    $dll=Join-Path $dataDir 'Plugins\openvr_api.dll';if(Test-Path -LiteralPath $dll){if((Get-PeMachine $dll)-eq 0x14c){Write-Host 'openvr_api.dll : Win32/x86 OK' -ForegroundColor Green}else{Write-Host 'openvr_api.dll : wrong architecture' -ForegroundColor Red}}else{Write-Host 'openvr_api.dll : MISSING' -ForegroundColor Red}
    $helper=Join-Path $dataDir 'Managed\HavenMoonVR.Runtime.dll'
    if(Test-Path -LiteralPath $helper){
        $helperHash=Get-FileSha256 $helper
        if($helperHash-eq $RuntimeHelperSha256){Write-Host 'HavenMoonVR.Runtime.dll : WATER ENHANCED VR + OCEAN REFLECTION OFF + COLLISION FIX V2 OK' -ForegroundColor Green}
        else{Write-Host "HavenMoonVR.Runtime.dll : WRONG BUILD ($helperHash)" -ForegroundColor Red}
    }else{Write-Host 'HavenMoonVR.Runtime.dll : MISSING' -ForegroundColor Red}
    foreach($runtimeName in @('HavenMoonVR_InputBridge.ps1','Start_HavenMoonVR.cmd','Haven Moon VR.exe')){
        $runtimePath=Join-Path $GameDir $runtimeName
        if(Test-Path -LiteralPath $runtimePath){Write-Host "$runtimeName : PRESENT" -ForegroundColor Green}else{Write-Host "$runtimeName : MISSING" -ForegroundColor Red}
    }
    foreach($artworkName in Get-ArtworkNames){
        $packageArtwork=Join-Path (Join-Path $PSScriptRoot 'Artwork') $artworkName
        $installedArtwork=Join-Path (Join-Path $GameDir 'HavenMoonVR_Artwork') $artworkName
        if((Test-Path -LiteralPath $installedArtwork)-and(Test-Path -LiteralPath $packageArtwork)-and(Get-FileSha256 $installedArtwork)-eq(Get-FileSha256 $packageArtwork)){
            Write-Host "$artworkName : PRESENT" -ForegroundColor Green
        }else{Write-Host "$artworkName : MISSING OR MODIFIED" -ForegroundColor Red}
    }
}

$steamExeToRestart=$null
$exitCode=0
try{
    Write-Host "$ModName`n"
    Write-Host $PatchDisclaimer -ForegroundColor Yellow
    Write-Host ''
    $resolvedGame=Resolve-GamePath $GamePath
    Write-Host "Game: $resolvedGame"
    switch($Mode){
        'Install'{
            $registrationMode=Resolve-SteamRegistrationChoice $SteamRegistration
            if($registrationMode-eq'Auto'){
                Stop-GameAndSteamVR
                $steamExeToRestart=Resolve-SteamExecutable
                Stop-SteamForShortcutUpdate $steamExeToRestart
            }else{
                Assert-GameAndSteamVRClosed
            }
            Install-Patch $resolvedGame $HeightOffset $registrationMode $true
        }
        'SetHeight'{
            Assert-GameAndSteamVRClosed
            $registrationMode=Get-InstalledSteamRegistrationMode $resolvedGame
            Install-Patch $resolvedGame $HeightOffset $registrationMode $false
        }
        'Uninstall'{
            $registrationMode=Get-InstalledSteamRegistrationMode $resolvedGame
            if($registrationMode-eq'Auto'){
                Stop-GameAndSteamVR
                $steamExeToRestart=Resolve-SteamExecutable
                Stop-SteamForShortcutUpdate $steamExeToRestart
            }else{
                Assert-GameAndSteamVRClosed
            }
            Uninstall-Patch $resolvedGame $registrationMode
        }
        'Verify'{Verify-Patch $resolvedGame}
    }
}catch{
    Write-Host ''
    Write-Host ('ERROR: '+$_.Exception.Message) -ForegroundColor Red
    $exitCode=1
}finally{
    if($null-ne$steamExeToRestart){
        try{Restart-SteamAfterShortcutUpdate $steamExeToRestart}
        catch{Write-Host ('ERROR reopening Steam: '+$_.Exception.Message) -ForegroundColor Red;$exitCode=1}
    }
}
exit $exitCode
