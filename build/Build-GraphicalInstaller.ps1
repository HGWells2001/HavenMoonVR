[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$PayloadZip,
    [Parameter(Mandatory=$true)]
    [string]$OutputExe
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'

$repo=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$payload=(Resolve-Path -LiteralPath $PayloadZip).Path
$output=[IO.Path]::GetFullPath($OutputExe)
$outputDir=Split-Path -Parent $output
if(-not(Test-Path -LiteralPath $outputDir)){New-Item -ItemType Directory -Path $outputDir|Out-Null}

$source=Join-Path $repo 'src\HavenMoonVR.Setup.cs'
$manifest=Join-Path $repo 'src\HavenMoonVR.Setup.manifest'
$icon=Join-Path $repo 'installer\Artwork\HavenMoonVR_LauncherIcon.ico'
$hero=Join-Path $repo 'installer\Artwork\HavenMoonVR_LibraryHero_3840x1240.png'
$logo=Join-Path $repo 'installer\Artwork\HavenMoonVR_LibraryLogo_720x720.png'
$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
if(-not(Test-Path -LiteralPath $csc)){$csc=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'}
foreach($required in @($source,$manifest,$icon,$hero,$logo,$csc)){if(-not(Test-Path -LiteralPath $required)){throw "Required build input missing: $required"}}

$temp=Join-Path ([IO.Path]::GetTempPath()) ('HavenMoonVR-SetupBuild-'+[Guid]::NewGuid().ToString('N'))
try{
    New-Item -ItemType Directory -Path $temp|Out-Null
    $hash=(Get-FileHash -LiteralPath $payload -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashFile=Join-Path $temp 'payload.sha256'
    Set-Content -LiteralPath $hashFile -Value $hash -Encoding ASCII

    $compilerArgs=@(
        '/nologo','/target:winexe','/optimize+','/platform:anycpu',
        "/out:$output",
        "/win32icon:$icon",
        "/win32manifest:$manifest",
        '/reference:System.dll',
        '/reference:System.Core.dll',
        '/reference:System.Drawing.dll',
        '/reference:System.Windows.Forms.dll',
        '/reference:System.IO.Compression.dll',
        '/reference:System.IO.Compression.FileSystem.dll',
        "/resource:$payload,HavenMoonVR.Payload.zip",
        "/resource:$hashFile,HavenMoonVR.Payload.sha256",
        "/resource:$hero,HavenMoonVR.Hero.png",
        "/resource:$logo,HavenMoonVR.Logo.png",
        $source
    )
    & $csc $compilerArgs
    if($LASTEXITCODE-ne0){throw "Graphical installer compilation failed with exit code $LASTEXITCODE."}

    $exeHash=(Get-FileHash -LiteralPath $output -Algorithm SHA256).Hash.ToLowerInvariant()
    $checksumPath=[IO.Path]::Combine($outputDir,([IO.Path]::GetFileNameWithoutExtension($output)+'_SHA256.txt'))
    Set-Content -LiteralPath $checksumPath -Value ($exeHash+'  '+[IO.Path]::GetFileName($output)) -Encoding ASCII
    Write-Host "Built: $output"
    Write-Host "Payload SHA-256: $hash"
    Write-Host "Installer SHA-256: $exeHash"
    Write-Host "Checksum: $checksumPath"
}finally{
    if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Recurse -Force}
}
