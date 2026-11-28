# Builds MyBrowser from source with AutoIt3.
# Runs on Windows (GitHub Actions windows-latest or a local Windows box).
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root 'src'
$res  = Join-Path $root 'resources'
$dist = Join-Path $root 'dist'
$tool = Join-Path $root '.build'

$Version = (Select-String -Path (Join-Path $src 'MyBrowser.au3') -Pattern 'Global Const \$APPVERSION = "([^"]+)"').Matches[0].Groups[1].Value
if (-not $Version) { throw 'Could not read $APPVERSION from src/MyBrowser.au3' }

# H2: the version lives in four places. Nothing may disagree with the source.
$checks = @(
    @{ Name = 'resources/en-US.ini'; Value = (Select-String -Path (Join-Path $res 'en-US.ini') -Pattern '^Version=(.+)$').Matches[0].Groups[1].Value.Trim() },
    @{ Name = 'resources/zh-TW.ini'; Value = (Select-String -Path (Join-Path $res 'zh-TW.ini') -Pattern '^Version=(.+)$' -Encoding Unicode).Matches[0].Groups[1].Value.Trim() },
    @{ Name = 'update.txt (latest=)'; Value = (Select-String -Path (Join-Path $root 'update.txt') -Pattern '^latest=(.+)$').Matches[0].Groups[1].Value.Trim() }
)
foreach ($c in $checks) {
    if ($c.Value -ne $Version) {
        throw "Version mismatch: src/MyBrowser.au3 says $Version, $($c.Name) says $($c.Value)"
    }
}
Write-Host "Version $Version agrees in 4 places (source, 2 language files, update.txt)"
Write-Host "Building MyBrowser $Version"

New-Item -ItemType Directory -Force -Path $dist, $tool | Out-Null

# ---------------------------------------------------------------- AutoIt3 SDK
$au = Join-Path $tool 'autoit'
if (-not (Test-Path (Join-Path $au 'ok.marker'))) {
    $zip = Join-Path $tool 'autoit.zip'
    $url = 'https://www.autoitscript.com/autoit3/files/archive/autoit/autoit-v3.3.16.1.zip'
    Write-Host "Downloading $url"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    if (Test-Path $au) { Remove-Item $au -Recurse -Force }
    Expand-Archive -Path $zip -DestinationPath $au -Force
    New-Item -ItemType File -Force -Path (Join-Path $au 'ok.marker') | Out-Null
}

$au3check = (Get-ChildItem -Path $au -Filter 'Au3Check.exe' -Recurse | Select-Object -First 1).FullName
$aut2exe  = (Get-ChildItem -Path $au -Filter 'Aut2Exe.exe' -Recurse | Select-Object -First 1).FullName
$aut2exe64 = (Get-ChildItem -Path $au -Filter 'Aut2Exe_x64.exe' -Recurse | Select-Object -First 1).FullName
if (-not $au3check -or -not $aut2exe) { throw 'AutoIt SDK not found after extraction' }

# ------------------------------------------------- resources next to the script
# FileInstall() resolves paths relative to the .au3 file at compile time.
Get-ChildItem -Path $res -File | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $src $_.Name) -Force
}

# ---------------------------------------------------------------- syntax check
Write-Host 'Au3Check:'
& $au3check -q (Join-Path $src 'MyBrowser.au3')
$checkExit = $LASTEXITCODE
# 0 = clean, 1 = warnings only; 2 = syntax errors, 3 = usage
# 0 = clean, 1 = warnings, 2 = syntax errors, 3 = usage. Warnings are errors here.
if ($checkExit -ne 0) { throw "Au3Check failed with exit code $checkExit" }

# ---------------------------------------------------------------- compile
$au3 = Join-Path $src 'MyBrowser.au3'

Write-Host 'Compiling x64 ...'
$out64 = Join-Path $dist 'MyBrowser.exe'
Remove-Item $out64 -Force -ErrorAction SilentlyContinue
# Aut2Exe is a GUI-subsystem binary: use Start-Process -Wait so we do not race it.
$p64 = Start-Process -FilePath $aut2exe64 -ArgumentList @('/in', "`"$au3`"", '/out', "`"$out64`"", '/x64', '/comp', '4') -Wait -PassThru
if ($p64.ExitCode -ne 0 -or -not (Test-Path $out64)) {
    throw "x64 compile failed (exit $($p64.ExitCode))"
}

Write-Host 'Compiling x86 ...'
$out86 = Join-Path $dist 'MyBrowser_x86.exe'
Remove-Item $out86 -Force -ErrorAction SilentlyContinue
$p86 = Start-Process -FilePath $aut2exe -ArgumentList @('/in', "`"$au3`"", '/out', "`"$out86`"", '/x86', '/comp', '4') -Wait -PassThru
if ($p86.ExitCode -ne 0 -or -not (Test-Path $out86)) {
    throw "x86 compile failed (exit $($p86.ExitCode))"
}

# ---------------------------------------------------------------- signing (optional)
# Set SIGNING_PFX (base64 .pfx) and SIGNING_PFX_PASSWORD as repository secrets to ship
# signed binaries. Without them the build is unsigned, as before.
if ($env:SIGNING_PFX) {
    $pfx = Join-Path $tool 'sign.pfx'
    [IO.File]::WriteAllBytes($pfx, [Convert]::FromBase64String($env:SIGNING_PFX))
    $signtool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin" -Filter 'signtool.exe' -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like '*x64*' } | Select-Object -Last 1
    if (-not $signtool) { throw 'signtool.exe not found; cannot sign' }
    foreach ($f in @($out64, $out86)) {
        & $signtool.FullName sign /fd SHA256 /f $pfx /p $env:SIGNING_PFX_PASSWORD /tr 'http://timestamp.digicert.com' /td SHA256 $f
        if ($LASTEXITCODE -ne 0) { throw "signing failed for $f" }
    }
    Remove-Item $pfx -Force

    # C1: do not trust the signer's exit code alone - verify what was produced.
    foreach ($f in @($out64, $out86)) {
        $sig = Get-AuthenticodeSignature $f
        if ($sig.Status -ne 'Valid') {
            throw "signature on $(Split-Path -Leaf $f) is $($sig.Status), not Valid"
        }
        if (-not $sig.TimeStamperCertificate) {
            throw "signature on $(Split-Path -Leaf $f) carries no timestamp"
        }
        Write-Host ("Signed and timestamped: {0} by {1}" -f (Split-Path -Leaf $f), $sig.SignerCertificate.Subject)
    }
} else {
    # C1: an unsigned release is a choice, not an accident. Say so loudly and record it
    # in the build summary so it cannot be overlooked.
    Write-Warning 'No SIGNING_PFX secret configured; shipping unsigned binaries.'
    Write-Host '### Signing' >> $env:GITHUB_STEP_SUMMARY
    Write-Host 'Unsigned build: no `SIGNING_PFX` secret is configured for this repository.' >> $env:GITHUB_STEP_SUMMARY
}

# ---------------------------------------------------------------- package
# The self-updater extracts "MyBrowser.exe" from the archive, so both packages
# must carry that exact name at the archive root.
$sevenZip = Join-Path $res '7z.exe'
$x64Archive = Join-Path $dist "MyBrowser_v$Version`_x64.7z"
$x86Archive = Join-Path $dist "MyBrowser_v$Version.7z"

foreach ($pkg in @(
    @{ Archive = $x64Archive; Source = (Join-Path $dist 'MyBrowser.exe') },
    @{ Archive = $x86Archive; Source = (Join-Path $dist 'MyBrowser_x86.exe') }
)) {
    $stage = Join-Path $tool ('pkg-' + [IO.Path]::GetFileNameWithoutExtension($pkg.Archive))
    if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    Copy-Item $pkg.Source (Join-Path $stage 'MyBrowser.exe') -Force
    # Ship the desktop check with the app: it is the only way a user on a real machine
    # can collect the evidence CI cannot produce, and the source tree is not in the zip.
    $toolsDir = Join-Path $stage 'tools'
    New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
    Copy-Item (Join-Path $PSScriptRoot 'desktop-check.ps1') (Join-Path $toolsDir 'desktop-check.ps1') -Force
    Remove-Item $pkg.Archive -Force -ErrorAction SilentlyContinue
    Push-Location $stage
    & $sevenZip a -t7z -mx=9 $pkg.Archive 'MyBrowser.exe' 'tools' | Out-Null
    $code = $LASTEXITCODE
    Pop-Location
    if ($code -ne 0) { throw "7z packaging failed for $($pkg.Archive)" }

    # F3: a .zip alongside the .7z - winget cannot install a .7z, and not every
    # user has 7-Zip.
    $zip = [IO.Path]::ChangeExtension($pkg.Archive, '.zip')
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    Compress-Archive -Path (Join-Path $stage 'MyBrowser.exe'), (Join-Path $stage 'tools') -DestinationPath $zip -CompressionLevel Optimal
}

# ---------------------------------------------------------------- checksums
$sums = Join-Path $dist 'SHA256SUMS.txt'
Remove-Item $sums -Force -ErrorAction SilentlyContinue
Get-ChildItem (Join-Path $dist '*') -Include '*.7z','*.zip' -File | ForEach-Object {
    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    "$hash  $($_.Name)"
} | Set-Content -Path $sums -Encoding ascii
Write-Host "Wrote $sums"

Get-ChildItem $dist | Format-Table Name, Length
Write-Host "Done: MyBrowser $Version"
