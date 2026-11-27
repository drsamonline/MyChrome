# Brings the Scoop and winget manifests in line with the release that was just published.
# Runs on a tag build; no-op when they already agree.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$au3 = Join-Path $root 'src\MyBrowser.au3'
$version = ([regex]::Match((Get-Content $au3 -Raw), 'APPVERSION = "([\d.]+)"')).Groups[1].Value
$base = "https://github.com/drsamonline/MyChrome/releases/download/v$version"

$scoopPath = Join-Path $root 'bucket\mybrowser.json'
$scoop = Get-Content $scoopPath -Raw | ConvertFrom-Json
if ($scoop.version -eq $version) { Write-Host "manifests already at $version"; exit 0 }

$sums = (Invoke-WebRequest "$base/SHA256SUMS.txt" -UseBasicParsing).Content
function HashOf([string]$name) {
    $m = [regex]::Match($sums, "(?m)^([0-9a-fA-F]{64})\s+$([regex]::Escape($name))`$")
    if (-not $m.Success) { throw "no checksum for $name in SHA256SUMS.txt" }
    $m.Groups[1].Value.ToLower()
}

$h7z64 = HashOf "MyBrowser_v$version`_x64.7z"
$h7z32 = HashOf "MyBrowser_v$version.7z"
$hzip64 = HashOf "MyBrowser_v$version`_x64.zip"
$hzip32 = HashOf "MyBrowser_v$version.zip"

# ---- Scoop
$scoop.version = $version
$scoop.architecture.'64bit'.url = "$base/MyBrowser_v$version`_x64.7z"
$scoop.architecture.'64bit'.hash = $h7z64
$scoop.architecture.'32bit'.url = "$base/MyBrowser_v$version.7z"
$scoop.architecture.'32bit'.hash = $h7z32
$scoop | ConvertTo-Json -Depth 8 | Set-Content $scoopPath -Encoding utf8
Write-Host "scoop manifest -> $version"

# ---- winget: emit the three files for this version, drop the older set
$parent = Join-Path $root 'manifests\d\drsamonline\MyBrowser'
$dir = Join-Path $parent $version
New-Item -ItemType Directory -Force -Path $dir | Out-Null

@"
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.version.1.6.0.schema.json
PackageIdentifier: drsamonline.MyBrowser
PackageVersion: $version
DefaultLocale: en-US
ManifestType: version
ManifestVersion: 1.6.0
"@ | Set-Content (Join-Path $dir 'drsamonline.MyBrowser.yaml') -Encoding utf8

@"
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.installer.1.6.0.schema.json
PackageIdentifier: drsamonline.MyBrowser
PackageVersion: $version
InstallerLocale: en-US
Platform:
  - Windows.Desktop
MinimumOSVersion: 10.0.0.0
InstallerType: zip
NestedInstallerType: portable
NestedInstallerFiles:
  - RelativeFilePath: MyBrowser.exe
    PortableCommandAlias: mybrowser
InstallModes:
  - interactive
  - silent
UpgradeBehavior: install
Installers:
  - Architecture: x64
    InstallerUrl: $base/MyBrowser_v$version`_x64.zip
    InstallerSha256: $hzip64
  - Architecture: x86
    InstallerUrl: $base/MyBrowser_v$version.zip
    InstallerSha256: $hzip32
ManifestType: installer
ManifestVersion: 1.6.0
"@ | Set-Content (Join-Path $dir 'drsamonline.MyBrowser.installer.yaml') -Encoding utf8

@"
# yaml-language-server: `$schema=https://aka.ms/winget-manifest.defaultLocale.1.6.0.schema.json
PackageIdentifier: drsamonline.MyBrowser
PackageVersion: $version
PackageLocale: en-US
Publisher: Dr Sohil Momin
PublisherUrl: https://github.com/drsamonline
PublisherSupportUrl: https://github.com/drsamonline/MyChrome/issues
PackageName: MyBrowser
PackageUrl: https://github.com/drsamonline/MyChrome
License: GPL-3.0-only
LicenseUrl: https://github.com/drsamonline/MyChrome/blob/master/LICENSE
Copyright: GPL-3.0. Derived from cnjackchen/my-chrome.
ShortDescription: Portable browser launcher for Windows. Downloads Chrome, Chromium, Brave, Firefox, Vivaldi, Edge or Cent and runs it with its own profile.
Description: A portable launcher that resolves the current build of a browser from the vendor's own feed, downloads it, unpacks it beside the executable and runs it with its own profile. No installer, no registry writes, no admin rights.
Moniker: mybrowser
Tags:
  - browser
  - portable
  - chrome
  - chromium
  - firefox
ReleaseNotesUrl: https://github.com/drsamonline/MyChrome/releases
ManifestType: defaultLocale
ManifestVersion: 1.6.0
"@ | Set-Content (Join-Path $dir 'drsamonline.MyBrowser.locale.en-US.yaml') -Encoding utf8

Get-ChildItem $parent -Directory | Where-Object { $_.Name -ne $version } | Remove-Item -Recurse -Force
Write-Host "winget manifests -> $version"
