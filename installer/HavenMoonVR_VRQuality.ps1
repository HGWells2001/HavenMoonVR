$ErrorActionPreference='Stop'
$sectionName='steam.app.493720'

function Get-SteamRoot {
    try {
        $p=(Get-ItemProperty 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        if($p -and (Test-Path -LiteralPath $p)){ return (Resolve-Path $p).Path }
    } catch {}
    $fallback='C:\Program Files (x86)\Steam'
    if(Test-Path -LiteralPath $fallback){ return $fallback }
    throw 'Steam installation not found.'
}

function Test-SteamVRRunning {
    return [bool](
        (Get-Process vrserver -ErrorAction SilentlyContinue) -or
        (Get-Process vrmonitor -ErrorAction SilentlyContinue)
    )
}

if(Test-SteamVRRunning){
    Write-Host ''
    Write-Host 'SteamVR is currently running.' -ForegroundColor Yellow
    Write-Host 'Close SteamVR before changing its per-application resolution.'
    Write-Host 'Then run Configure_VR_Quality.cmd again.'
    exit 2
}

$steam=Get-SteamRoot
$settings=Join-Path $steam 'config\steamvr.vrsettings'
if(-not(Test-Path -LiteralPath $settings)){
    throw "steamvr.vrsettings not found: $settings. Start SteamVR once, close it, then retry."
}

Write-Host ''
Write-Host 'HavenMoonVR - SteamVR anti-aliasing / render resolution' -ForegroundColor Cyan
Write-Host ''
Write-Host 'This changes ONLY Haven Moon (Steam App 493720).'
Write-Host 'It does not change SteamVR global resolution.'
Write-Host ''
Write-Host '1  100%%  Native / Performance'
Write-Host '2  125%%  Balanced'
Write-Host '3  150%%  High       [recommended for RTX 3090 + Quest 2]'
Write-Host '4  175%%  Very High'
Write-Host '5  200%%  Ultra'
Write-Host '6  Custom percentage (50-500)'
Write-Host ''

$choice=Read-Host 'VR render resolution'

switch($choice){
    '1' {$scale=100}
    '2' {$scale=125}
    '3' {$scale=150}
    '4' {$scale=175}
    '5' {$scale=200}
    '6' {
        $scale=[int](Read-Host 'Percentage')
        if($scale-lt 50 -or $scale-gt 500){throw 'Percentage must be between 50 and 500.'}
    }
    default {
        Write-Host 'No changes.' -ForegroundColor Yellow
        exit 0
    }
}

$backupDir=Join-Path $PSScriptRoot 'SteamVR_Settings_Backup'
if(-not(Test-Path -LiteralPath $backupDir)){
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path $backupDir ("steamvr.vrsettings_{0}.bak" -f $stamp)
Copy-Item -LiteralPath $settings -Destination $backup -Force

$raw=[IO.File]::ReadAllText($settings)
try{
    $json=$raw | ConvertFrom-Json
}catch{
    throw "SteamVR settings are not valid JSON. Backup created at: $backup"
}

$prop=$json.PSObject.Properties[$sectionName]
if($null-eq $prop){
    $section=New-Object PSObject
    $json | Add-Member -MemberType NoteProperty -Name $sectionName -Value $section
}else{
    $section=$prop.Value
}

if($null-eq $section.PSObject.Properties['appName']){
    $section | Add-Member -MemberType NoteProperty -Name 'appName' -Value 'Haven Moon'
}else{
    $section.appName='Haven Moon'
}

if($null-eq $section.PSObject.Properties['resolutionScale']){
    $section | Add-Member -MemberType NoteProperty -Name 'resolutionScale' -Value ([int]$scale)
}else{
    $section.resolutionScale=[int]$scale
}

$out=$json | ConvertTo-Json -Depth 100
$utf8=New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($settings,$out,$utf8)

# Verify.
$verify=([IO.File]::ReadAllText($settings) | ConvertFrom-Json)
$vsection=$verify.PSObject.Properties[$sectionName].Value
if([int]$vsection.resolutionScale-ne $scale){
    Copy-Item -LiteralPath $backup -Destination $settings -Force
    throw 'SteamVR setting verification failed; original file restored.'
}

Write-Host ''
Write-Host ("Haven Moon SteamVR resolution set to {0}%." -f $scale) -ForegroundColor Green
Write-Host ("Backup: {0}" -f $backup) -ForegroundColor DarkGray
Write-Host ''
Write-Host 'Now start Haven Moon with Haven Moon VR Experimental.exe or from SteamVR.'
Write-Host 'If performance drops, try 125%. If GPU headroom remains, try 175%.'
