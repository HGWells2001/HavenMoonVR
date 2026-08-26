$ErrorActionPreference='Stop'

$cfg=Join-Path $PSScriptRoot 'HavenMoonVR_Display.ini'
$regPath='HKCU:\Software\FrancoisRoussel\HavenMoon'

function Read-Current {
    $r=@{Width=1280;Height=720;Fullscreen=0}
    if(Test-Path -LiteralPath $cfg){
        foreach($line in Get-Content -LiteralPath $cfg){
            if($line -match '^\s*(Width|Height|Fullscreen)\s*=\s*(\d+)\s*$'){
                $r[$matches[1]]=[int]$matches[2]
            }
        }
    }
    return $r
}

function Write-UnityDisplayRegistry([int]$w,[int]$h,[int]$fs){
    if(-not (Test-Path -LiteralPath $regPath)){
        New-Item -Path $regPath -Force | Out-Null
    }

    $values=@{
        'Screenmanager Resolution Width' = $w
        'Screenmanager Resolution Height' = $h
        'Screenmanager Is Fullscreen mode' = $fs

        'Screenmanager Resolution Width_h182942802' = $w
        'Screenmanager Resolution Height_h2627697771' = $h
        'Screenmanager Is Fullscreen mode_h3981298716' = $fs
    }

    foreach($name in $values.Keys){
        New-ItemProperty -Path $regPath -Name $name -Value ([int]$values[$name]) `
            -PropertyType DWord -Force | Out-Null
    }
}

function Save-Config([int]$w,[int]$h,[int]$fs){
    @(
        '# HavenMoonVR desktop mirror settings'
        '# Stored here and synchronized into Unity registry preferences.'
        '# This does NOT set SteamVR per-eye resolution.'
        ('Width={0}' -f $w)
        ('Height={0}' -f $h)
        ('Fullscreen={0}' -f $fs)
    ) | Set-Content -LiteralPath $cfg -Encoding ASCII

    Write-UnityDisplayRegistry $w $h $fs
}

$c=Read-Current
Write-Host ''
Write-Host 'HavenMoonVR 1.2.0 Community Patch - Display / mirror configuration' -ForegroundColor Cyan
Write-Host ('Current: {0}x{1}, {2}' -f $c.Width,$c.Height,($(if($c.Fullscreen){'fullscreen'}else{'windowed'})))
Write-Host ''
Write-Host '1  1280 x 720'
Write-Host '2  1600 x 900'
Write-Host '3  1920 x 1080'
Write-Host '4  2560 x 1440'
Write-Host '5  3840 x 2160'
Write-Host '6  Custom'
Write-Host ''
$choice=Read-Host 'Resolution'

switch($choice){
    '1' {$w=1280;$h=720}
    '2' {$w=1600;$h=900}
    '3' {$w=1920;$h=1080}
    '4' {$w=2560;$h=1440}
    '5' {$w=3840;$h=2160}
    '6' {
        $w=[int](Read-Host 'Width')
        $h=[int](Read-Host 'Height')
        if($w-lt 320 -or $h-lt 240){throw 'Resolution too small.'}
    }
    default {
        Write-Host 'No changes.' -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ''
$mode=Read-Host 'Windowed [W] or fullscreen [F]? (recommended for VR: W)'
$fs=if($mode -match '^[Ff]'){1}else{0}
Save-Config $w $h $fs

Write-Host ''
Write-Host ('Saved: {0}x{1}, {2}' -f $w,$h,($(if($fs){'fullscreen'}else{'windowed'}))) -ForegroundColor Green
Write-Host 'Haven Moon will start without custom resolution command-line parameters.' -ForegroundColor Green
Write-Host 'SteamVR headset resolution remains separate.' -ForegroundColor DarkGray
