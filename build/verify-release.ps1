# Verify a downloaded MyBrowser release before you run it.
#
#   ./build/verify-release.ps1 -Path .\MyBrowser_v3.9.26_x64.7z
#   ./build/verify-release.ps1 -Path .\MyBrowser_v3.9.26_x64.7z -Version 3.9.26
#
# Checks, in order:
#   1. the file's SHA256 against the SHA256SUMS.txt published with that release
#   2. the build provenance attestation, when the GitHub CLI is available
#
# Exit code 0 means both checks passed (or the attestation check was skipped because
# `gh` is not installed). Anything else means do not run the file.

param(
    [Parameter(Mandatory = $true)][string]$Path,
    [string]$Version = '',
    [string]$Repo = 'drsamonline/MyChrome'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Path)) { throw "no such file: $Path" }
$file = Get-Item $Path
$name = $file.Name

# Work out the version from the filename when it was not supplied:
# MyBrowser_v3.9.26_x64.7z -> 3.9.26
if (-not $Version) {
    $m = [regex]::Match($name, 'MyBrowser_v([\d.]+)')
    if (-not $m.Success) { throw "cannot read a version from '$name'; pass -Version" }
    $Version = $m.Groups[1].Value
}

Write-Host "File     : $name"
Write-Host "Version  : $Version"
Write-Host "SHA256   : $((Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLower())"
Write-Host ''

# 1. checksum against the published manifest
$sumsUrl = "https://github.com/$Repo/releases/download/v$Version/SHA256SUMS.txt"
Write-Host "Fetching $sumsUrl"
$resp = Invoke-WebRequest $sumsUrl -UseBasicParsing
$sums = if ($resp.Content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($resp.Content) } else { [string]$resp.Content }

$actual = (Get-FileHash $file.FullName -Algorithm SHA256).Hash.ToLower()

# Match by name first; if the file was renamed, match by the hash it actually has and
# say which published asset it is.
$line = ($sums -split "`n" | Where-Object { $_ -match [regex]::Escape($name) } | Select-Object -First 1)
if (-not $line) {
    $line = ($sums -split "`n" | Where-Object { $_ -match "^$actual" } | Select-Object -First 1)
    if ($line) {
        $published = ($line -split '\s+')[-1].Trim()
        Write-Host "Note     : '$name' is not a published name; its hash matches '$published'"
    }
}
if (-not $line) {
    Write-Host "FAIL  SHA256SUMS.txt for $Version lists neither '$name' nor this file's hash" -ForegroundColor Red
    exit 2
}

$expected = ([regex]::Match($line, '^([0-9a-fA-F]{64})')).Groups[1].Value.ToLower()

if ($expected -ne $actual) {
    Write-Host "FAIL  checksum mismatch" -ForegroundColor Red
    Write-Host "      published: $expected"
    Write-Host "      this file: $actual"
    exit 2
}
Write-Host 'PASS  checksum matches the published manifest' -ForegroundColor Green

# 2. build provenance, when gh is available
$gh = Get-Command gh -ErrorAction SilentlyContinue
if (-not $gh) {
    Write-Host 'SKIP  GitHub CLI not installed; the attestation was not checked'
    Write-Host ''
    Write-Host 'Verified: the file is the one that was published. Not verified: who built it.'
    exit 0
}

Write-Host "Checking the build attestation with $($gh.Source)"
& $gh.Source attestation verify $file.FullName --repo $Repo
if ($LASTEXITCODE -ne 0) {
    Write-Host 'FAIL  the attestation did not verify' -ForegroundColor Red
    exit 3
}
Write-Host 'PASS  attestation verified: this file was built by the release workflow' -ForegroundColor Green
exit 0
