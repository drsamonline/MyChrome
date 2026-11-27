# Smoke test: proves the things that can be proved without a desktop.
#  1. every download source the app knows about answers with a usable URL
#  2. the built executable starts and stays alive
# Runs on Windows (GitHub Actions) or locally with PowerShell 7.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root 'dist'
$fail = @()
$skip = @()

function Check([string]$Name, [scriptblock]$Body) {
    try {
        $result = & $Body
        if (-not $result) { throw 'empty result' }
        Write-Host ("PASS  {0}  {1}" -f $Name, $result)
    } catch {
        $msg = $_.Exception.Message
        # A rate limit or an unreachable third party is not a defect in this build.
        if ($msg -match '403|429|rate limit|timed out|Name resolution') {
            Write-Host ("SKIP  {0}  {1}" -f $Name, $msg)
            $script:skip += $Name
        } else {
            Write-Host ("FAIL  {0}  {1}" -f $Name, $msg)
            $script:fail += $Name
        }
    }
}

# Authenticated GitHub API calls when a token is available (CI), so the 60/hour
# anonymous limit on a shared runner IP does not turn into a red build.
$ghHeaders = @{ 'User-Agent' = 'MyBrowser-CI' }
if ($env:GITHUB_TOKEN) { $ghHeaders['Authorization'] = "Bearer $env:GITHUB_TOKEN" }

# ---------------------------------------------------------------- sources
Check 'Chrome for Testing (stable win64)' {
    $j = Invoke-RestMethod 'https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json'
    $u = ($j.channels.Stable.downloads.chrome | Where-Object platform -eq 'win64').url
    if (-not $u) { throw 'no win64 asset' }
    $null = Invoke-WebRequest $u -Method Head -UseBasicParsing
    "$($j.channels.Stable.version) $u"
}

Check 'Chromium snapshot (win64)' {
    $rev = (Invoke-WebRequest 'https://storage.googleapis.com/chromium-browser-snapshots/Win_x64/LAST_CHANGE' -UseBasicParsing).Content.Trim()
    $u = "https://storage.googleapis.com/chromium-browser-snapshots/Win_x64/$rev/chrome-win.zip"
    $null = Invoke-WebRequest $u -Method Head -UseBasicParsing
    "rev $rev"
}

Check 'Brave release ZIP' {
    $r = Invoke-RestMethod 'https://api.github.com/repos/brave/brave-browser/releases/latest' -Headers $ghHeaders
    $a = $r.assets | Where-Object { $_.name -match '^brave-v[\d.]+-win32-x64\.zip$' } | Select-Object -First 1
    if (-not $a) { throw 'no win32-x64 asset' }
    "$($r.tag_name) $($a.name)"
}

Check 'Firefox version feed' {
    $j = Invoke-RestMethod 'https://product-details.mozilla.org/1.0/firefox_versions.json'
    if (-not $j.LATEST_FIREFOX_VERSION) { throw 'no LATEST_FIREFOX_VERSION' }
    $null = Invoke-WebRequest 'https://download.mozilla.org/?product=firefox-latest&os=Win64&lang=zh-CN' -Method Head -UseBasicParsing
    "release $($j.LATEST_FIREFOX_VERSION), esr $($j.FIREFOX_ESR)"
}

Check 'Vivaldi appcast' {
    $x = (Invoke-WebRequest 'https://update.vivaldi.com/update/1.0/public/appcast.x64.xml' -UseBasicParsing).Content
    $u = [regex]::Match($x, 'url="([^"]+\.exe)"').Groups[1].Value
    if (-not $u) { throw 'no full installer in the appcast' }
    $v = [regex]::Match($x, 'sparkle:version="([\d.]+)"').Groups[1].Value
    "v$v $u"
}

Check 'Update manifest is reachable' {
    $t = (Invoke-WebRequest 'https://raw.githubusercontent.com/drsamonline/MyChrome/master/update.txt' -UseBasicParsing).Content
    if ($t -notmatch 'latest=([\d.]+)') { throw 'no latest= line' }
    "latest=$($Matches[1])"
}

Check 'Upgrade path from 3.8.50' {
    # I5: an install of 3.8.50 must see a newer version and be able to fetch it.
    $t = (Invoke-WebRequest 'https://raw.githubusercontent.com/drsamonline/MyChrome/master/update.txt' -UseBasicParsing).Content
    $latest = [version](([regex]::Match($t, 'latest=([\d.]+)')).Groups[1].Value)
    $old = [version]'3.8.50'
    if ($latest -le $old) { throw "latest $latest is not newer than 3.8.50" }
    # The manifest on master may already point at the release this very run is building,
    # so only assets from an older version are expected to exist yet.
    $au3 = Join-Path $root 'src\MyBrowser.au3'
    $builtVer = if (Test-Path $au3) { ([regex]::Match((Get-Content $au3 -Raw), 'APPVERSION = "([\d.]+)"')).Groups[1].Value } else { '' }
    foreach ($m in [regex]::Matches($t, '^url(?:_x64)?=(\S+)$', 'Multiline')) {
        $u = $m.Groups[1].Value
        if ($builtVer -and $u -match [regex]::Escape("v$builtVer/")) { continue }
        $r = Invoke-WebRequest $u -Method Head -UseBasicParsing
        if ($r.StatusCode -ne 200) { throw "asset not reachable: $u" }
    }
    "3.8.50 -> $latest, assets reachable"
}

# ---------------------------------------------------------------- binaries
Check 'Package manifests match their release' {
    # A manifest that points at a stale hash fails the user's install, not ours.
    $manifest = Join-Path $root 'bucket\mybrowser.json'
    if (-not (Test-Path $manifest)) { throw 'scoop manifest missing' }
    $m = Get-Content $manifest -Raw | ConvertFrom-Json
    $v = $m.version
    $checks = @(
        @{ Url = $m.architecture.'64bit'.url; Hash = $m.architecture.'64bit'.hash },
        @{ Url = $m.architecture.'32bit'.url; Hash = $m.architecture.'32bit'.hash }
    )
    $tmp = Join-Path $env:TEMP ('scoopcheck-' + [guid]::NewGuid().ToString('N') + '.bin')
    try {
        foreach ($c in $checks) {
            Invoke-WebRequest $c.Url -OutFile $tmp -UseBasicParsing
            $actual = (Get-FileHash $tmp -Algorithm SHA256).Hash.ToLower()
            if ($actual -ne $c.Hash.ToLower()) {
                throw "scoop manifest hash for $v does not match $($c.Url)"
            }
        }
    } finally {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    }
    $au3 = Join-Path $root 'src\MyBrowser.au3'
    $builtVer = ([regex]::Match((Get-Content $au3 -Raw), 'APPVERSION = "([\d.]+)"')).Groups[1].Value
    if ($v -ne $builtVer) { Write-Host "      note: scoop manifest is at $v, source is at $builtVer" }
    "scoop manifest $v matches both assets"
}

Check 'x64 executable starts' {
    $exe = Join-Path $dist 'MyBrowser.exe'
    if (-not (Test-Path $exe)) { throw 'dist/MyBrowser.exe missing' }
    $p = Start-Process $exe -PassThru
    Start-Sleep -Seconds 6
    if ($p.HasExited) { throw "exited with code $($p.ExitCode)" }
    Stop-Process -Id $p.Id -Force
    'stayed alive for 6s'
}

Check 'Firefox installer unpacks to the layout the launcher expects' {
    # The app assumes firefox.exe lands at the archive root. Download the real
    # installer and prove it, instead of trusting the assumption.
    $seven = 'C:\Program Files\7-Zip\7z.exe'
    if (-not (Test-Path $seven)) { throw '7-Zip is not available on this runner' }
    $dir = Join-Path $env:TEMP ('ffcheck-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    try {
        $exe = Join-Path $dir 'ff.exe'
        Invoke-WebRequest 'https://download.mozilla.org/?product=firefox-latest-ssl&os=win&lang=en-US' -OutFile $exe -UseBasicParsing
        & $seven x $exe "-o$dir\out" -y | Out-Null
        # The launcher extracts the installer, then moves core\* up into App\, so the
        # file it checks for is core\firefox.exe inside the temp folder.
        if (-not (Test-Path (Join-Path $dir 'out\core\firefox.exe'))) {
            $top = (Get-ChildItem (Join-Path $dir 'out') -Name | Select-Object -First 5) -join ', '
            throw "core\firefox.exe is missing after extraction; found: $top"
        }
        "core\firefox.exe present, which is what the launcher moves into App\"
    } finally {
        Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Check 'First run writes its settings file' {
    $exe = Join-Path $dist 'MyBrowser.exe'
    $ini = Join-Path $dist 'MyBrowser.ini'
    Remove-Item $ini -Force -ErrorAction SilentlyContinue
    $p = Start-Process $exe -PassThru
    $p.WaitForExit(9000) | Out-Null
    if (-not $p.HasExited) { Stop-Process -Id $p.Id -Force }
    if (-not (Test-Path $ini)) { throw 'no MyBrowser.ini was created' }
    $ver = ([regex]::Match((Get-Content $ini -Raw), 'AppVersion=([\d.]+)')).Groups[1].Value
    if (-not $ver) { throw 'AppVersion was not written' }
    "ini created, AppVersion=$ver"
}

Check 'x86 executable starts' {
    $exe = Join-Path $dist 'MyBrowser_x86.exe'
    if (-not (Test-Path $exe)) { throw 'dist/MyBrowser_x86.exe missing' }
    $p = Start-Process $exe -PassThru
    Start-Sleep -Seconds 6
    if ($p.HasExited) { throw "exited with code $($p.ExitCode)" }
    Stop-Process -Id $p.Id -Force
    'stayed alive for 6s'
}

# ---------------------------------------------------------------- verdict
Check 'App self-test (every wired source)' {
    $exe = Join-Path $dist 'MyBrowser.exe'
    $rep = Join-Path $dist 'MyBrowser.selftest.txt'
    Remove-Item $rep -Force -ErrorAction SilentlyContinue
    $p = Start-Process $exe -ArgumentList '/selftest' -PassThru
    $done = $p.WaitForExit(120000)
    if (-not $done) {
        Stop-Process -Id $p.Id -Force
        $partial = if (Test-Path $rep) { Get-Content $rep -Raw } else { '(no report)' }
        throw "self-test hung for 120s. Last probe:`n$partial"
    }
    if (-not (Test-Path $rep)) { throw 'the self-test wrote no report' }
    $txt = Get-Content $rep -Raw
    Write-Host $txt
    if ($p.ExitCode -ne 0) { throw "self-test reported $($p.ExitCode) failure(s)" }
    "$(([regex]::Matches($txt,'(?m)^PASS')).Count) sources ok"
}

Check 'Self-test survives a proxy that drops the connection' {
    # I3: accept the connection and close it immediately - the closest a CI step can
    # get to a transfer that dies in flight.
    $probe = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
    $probe.Start()
    $port = $probe.LocalEndpoint.Port
    $probe.Stop()

    $dropper = Start-Job -ScriptBlock {
        param($p)
        $l = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $p)
        $l.Start()
        $end = (Get-Date).AddMinutes(4)
        while ((Get-Date) -lt $end) {
            if ($l.Pending()) { $c = $l.AcceptTcpClient(); $c.Close() } else { Start-Sleep -Milliseconds 50 }
        }
        $l.Stop()
    } -ArgumentList $port
    Start-Sleep -Milliseconds 500

    $exe = Join-Path $dist 'MyBrowser.exe'
    $ini = Join-Path $dist 'MyBrowser.ini'
    $text = Get-Content $ini -Raw
    if ($text -notmatch 'SelfTestProxy=') {
        $text = $text -replace '\[Settings\]', "[Settings]`r`nSelfTestProxy=HTTP:127.0.0.1:$port"
    } else {
        $text = $text -replace 'SelfTestProxy=[^\r\n]*', "SelfTestProxy=HTTP:127.0.0.1:$port"
    }
    Set-Content $ini $text -NoNewline

    try {
        $p = Start-Process $exe -ArgumentList '/selftest' -PassThru
        if (-not $p.WaitForExit(120000)) { Stop-Process -Id $p.Id -Force; throw 'self-test hung when the proxy dropped connections' }
        if ($p.ExitCode -eq 0) { throw 'self-test reported success although every connection was dropped' }
        "failed cleanly against a dropping proxy, exit $($p.ExitCode)"
    } finally {
        Stop-Job $dropper -ErrorAction SilentlyContinue
        Remove-Job $dropper -Force -ErrorAction SilentlyContinue
        Set-Content $ini ($text -replace 'SelfTestProxy=[^\r\n]*', '') -NoNewline
    }
}

Check 'Self-test fails cleanly behind a dead proxy' {
    # I3: point every probe at an unreachable endpoint and require a clean, bounded failure.
    $exe = Join-Path $dist 'MyBrowser.exe'
    $ini = Join-Path $dist 'MyBrowser.ini'
    if (-not (Test-Path $ini)) { throw 'no settings file to configure' }
    $text = Get-Content $ini -Raw
    if ($text -notmatch 'SelfTestProxy') {
        $text = $text -replace '\[Settings\]', "[Settings]`r`nSelfTestProxy=HTTP:127.0.0.1:9"
        Set-Content $ini $text -NoNewline
    }
    $p = Start-Process $exe -ArgumentList '/selftest' -PassThru
    if (-not $p.WaitForExit(120000)) { Stop-Process -Id $p.Id -Force; throw 'self-test hung with an unreachable proxy' }
    if ($p.ExitCode -eq 0) { throw 'self-test reported success with an unreachable proxy' }
    "failed cleanly after a bounded wait, exit $($p.ExitCode)"
}

if ($skip.Count -gt 0) {
    Write-Host ("Skipped (external): " + ($skip -join ', '))
}
if ($fail.Count -gt 0) {
    throw ("Smoke test failed: " + ($fail -join ', '))
}
Write-Host 'All smoke checks passed.'
