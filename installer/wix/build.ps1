# Builds the Windows amd64 MSI installer from an unpacked release tree.
#
# Prerequisites (Windows only; WiX does not support building on Linux):
#   dotnet tool install --global wix --version 6.0.2
#   wix extension add -g WixToolset.UI.wixext/6.0.2
#
# Usage:
#   .\installer\wix\build.ps1 -SourceDir release\go-legacy-win7 -Version 1.27.3
#   .\installer\wix\build.ps1 -SourceDir release\go-legacy-win7 -Version 1.27.3-2 `
#       -Output go-legacy-win7-1.27.3-2.windows_amd64.msi

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SourceDir,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Version,

    [Parameter(Position = 2)]
    [string]$Output
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$here = $PSScriptRoot

if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) {
    throw "Release directory not found: $SourceDir"
}
$source = (Resolve-Path -LiteralPath $SourceDir).Path

# Windows Installer only accepts three numeric version fields. Release builds
# may append a fork revision (for example 1.27.3-2); keep it in the product
# name but drop it from ProductVersion.
if ($Version -notmatch '^(\d+)\.(\d+)\.(\d+)') {
    throw "Version must start with major.minor.patch: $Version"
}
$major = [int]$Matches[1]
$minor = [int]$Matches[2]
$build = [int]$Matches[3]
if ($major -gt 255 -or $minor -gt 255 -or $build -gt 65535) {
    throw "Version is outside the range Windows Installer supports: $Version"
}
$productVersion = "$major.$minor.$build"

if (-not $Output) {
    $Output = "go-legacy-win7-$Version.windows_amd64.msi"
}

if (-not (Get-Command wix -ErrorAction SilentlyContinue)) {
    throw "wix was not found. Install it with: dotnet tool install --global wix --version 6.0.2"
}

& wix build (Join-Path $here "go.wxs") `
    -arch x64 `
    -ext WixToolset.UI.wixext `
    -d "Version=$Version" `
    -d "ProductVersion=$productVersion" `
    -d "SourceDir=$source" `
    -d "LicenseRtf=$(Join-Path $here 'LICENSE.rtf')" `
    -o $Output

if ($LASTEXITCODE -ne 0) {
    throw "wix build failed with exit code $LASTEXITCODE"
}

Write-Host "Built $Output"
