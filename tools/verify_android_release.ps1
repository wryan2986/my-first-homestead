[CmdletBinding()]
param(
    [string]$ArtifactPath = ""
)

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PresetPath = Join-Path $ProjectRoot "export_presets.cfg"

function Write-Section($Text) {
    Write-Host ""
    Write-Host "== $Text =="
}

function Find-AndroidTool($ToolName) {
    $sdkRoot = $env:ANDROID_HOME
    if ([string]::IsNullOrWhiteSpace($sdkRoot)) {
        $sdkRoot = Join-Path $env:LOCALAPPDATA "Android\Sdk"
    }
    if (-not (Test-Path $sdkRoot)) {
        return $null
    }
    $matches = Get-ChildItem -Path (Join-Path $sdkRoot "build-tools") -Recurse -Filter $ToolName -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending
    if ($matches.Count -gt 0) {
        return $matches[0].FullName
    }
    return $null
}

if ([string]::IsNullOrWhiteSpace($ArtifactPath) -and (Test-Path $PresetPath)) {
    $presetText = Get-Content -Raw -Path $PresetPath
    $match = [regex]::Match($presetText, 'export_path="([^"]+\.aab)"')
    if ($match.Success) {
        $ArtifactPath = $match.Groups[1].Value
    }
}

if ([string]::IsNullOrWhiteSpace($ArtifactPath)) {
    $ArtifactPath = "Android game\MyFirstHomestead-v0.1.1-release-signed.aab"
}

if (-not [System.IO.Path]::IsPathRooted($ArtifactPath)) {
    $ArtifactPath = Join-Path $ProjectRoot $ArtifactPath
}

Write-Section "Expected Artifact"
Write-Host $ArtifactPath

if (-not (Test-Path -LiteralPath $ArtifactPath)) {
    Write-Warning "Expected AAB was not found. Export the Android preset from Godot first."
    $apkFiles = Get-ChildItem -Path (Join-Path $ProjectRoot "Android game") -Filter *.apk -ErrorAction SilentlyContinue
    if ($apkFiles.Count -gt 0) {
        Write-Warning "APK files exist, but Google Play release upload should use an AAB:"
        $apkFiles | Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
    }
    exit 1
}

$extension = [System.IO.Path]::GetExtension($ArtifactPath).ToLowerInvariant()
if ($extension -eq ".apk") {
    Write-Warning "This is an APK. Use an AAB for Google Play release upload."
}

Write-Section "Preset Summary"
if (Test-Path $PresetPath) {
    Select-String -Path $PresetPath -Pattern 'export_path=|gradle_build/export_format=|gradle_build/target_sdk=|version/code=|version/name=|package/unique_name=|package/name=|architectures/arm64-v8a=' |
        ForEach-Object { Write-Host $_.Line }
}

if ($extension -eq ".aab") {
    Write-Section "AAB Signature"
    $jarsigner = Get-Command jarsigner -ErrorAction SilentlyContinue
    if ($jarsigner -eq $null) {
        Write-Warning "jarsigner was not found on PATH. Install/configure a JDK to verify AAB signatures."
    } else {
        $verifyOutput = & $jarsigner.Source -verify -verbose -certs $ArtifactPath 2>&1
        $verifyOutput | Select-String -Pattern "jar verified|CN=|Warning|Error|invalid|unsigned" -Context 0,1
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "jarsigner verification failed."
        }
        if ($verifyOutput -match "CN=Godot") {
            Write-Warning "Artifact appears to be signed with the Godot debug certificate. Do not upload as a release."
        }
    }
} elseif ($extension -eq ".apk") {
    Write-Section "APK Signature And Badging"
    $apksigner = Find-AndroidTool "apksigner.bat"
    if ($apksigner -eq $null) {
        Write-Warning "apksigner was not found under the Android SDK."
    } else {
        $verifyOutput = & $apksigner verify --verbose --print-certs $ArtifactPath 2>&1
        $verifyOutput
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "apksigner verification failed."
        }
        if ($verifyOutput -match "CN=Godot") {
            Write-Warning "Artifact appears to be signed with the Godot debug certificate. Do not upload as a release."
        }
    }

    $aapt2 = Find-AndroidTool "aapt2.exe"
    if ($aapt2 -ne $null) {
        & $aapt2 dump badging $ArtifactPath |
            Select-String -Pattern "package:|sdkVersion|targetSdkVersion|application-label|native-code|uses-permission"
    }
}

Write-Section "Done"
Write-Host "Release verification completed. Review warnings before uploading."
