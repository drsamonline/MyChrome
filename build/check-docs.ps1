# Documentation gate: the numbers and names in the docs must match the repository.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$fail = @()

function Bad([string]$msg) { Write-Host "FAIL  $msg"; $script:fail += $msg }
function Ok([string]$msg)   { Write-Host "PASS  $msg" }

$au3 = Join-Path $root 'src\MyBrowser.au3'
$version = ([regex]::Match((Get-Content $au3 -Raw), 'APPVERSION = "([\d.]+)"')).Groups[1].Value

# 1. README asset names must carry the current version
$readme = Get-Content (Join-Path $root 'README.md') -Raw
$names = [regex]::Matches($readme, 'MyBrowser_v([\d.]+)(?:_x64)?(?:\.7z|_source\.7z)') | ForEach-Object { $_.Groups[1].Value }
$stale = @($names | Where-Object { $_ -ne $version } | Sort-Object -Unique)
if ($stale.Count -gt 0) { Bad "README names reference $($stale -join ', '), source is $version" }
else { Ok "README asset names match $version" }

# 2. ROADMAP claimed counts must match its own status board
$road = Get-Content (Join-Path $root 'ROADMAP.md') -Raw
$start = $road.IndexOf('## Status board')
$end   = $road.IndexOf('## A. Download integrity')
if ($start -lt 0 -or $end -le $start) { Bad 'ROADMAP status board not found' }
else {
    $board = $road.Substring($start, $end - $start)
    $rows = @($board -split "`n" | Where-Object { $_ -match '^\| [A-L]\d+ \|' })
    $done = @($rows | Where-Object { $_ -match '✅' }).Count
    $part = @($rows | Where-Object { $_ -match '🟡' }).Count
    $open = @($rows | Where-Object { $_ -match '⬜' }).Count
    $total = $rows.Count

    $claimed = [regex]::Match($road, 'Progress: (\d+) of (\d+) done \((\d+)%\), (\d+) partial, (\d+) open')
    if (-not $claimed.Success) { Bad 'ROADMAP has no progress line' }
    else {
        $cd, $ct, $cp, $co = [int]$claimed.Groups[1].Value, [int]$claimed.Groups[2].Value, [int]$claimed.Groups[4].Value, [int]$claimed.Groups[5].Value
        if ($cd -ne $done)  { Bad "ROADMAP claims $cd done, table has $done" }
        if ($ct -ne $total) { Bad "ROADMAP claims $ct items, table has $total" }
        if ($cp -ne $part)  { Bad "ROADMAP claims $cp partial, table has $part" }
        if ($co -ne $open)  { Bad "ROADMAP claims $co open, table has $open" }
        if (-not $fail) { Ok "ROADMAP counts agree: $done done, $part partial, $open open of $total" }
    }
}

# 3. CHANGELOG must mention every release tag
$tags = @(git -C $root tag | Where-Object { $_ -match '^v\d' } | ForEach-Object { $_.Substring(1) })
if ($tags.Count -eq 0) { Write-Host 'SKIP  no tags in this checkout (fetch-depth)' }
else {
    $log = Get-Content (Join-Path $root 'CHANGELOG.md') -Raw
    $missing = @($tags | Where-Object { $log -notmatch "(?m)^## $([regex]::Escape($_))$" })
    if ($missing.Count -gt 0) { Bad "CHANGELOG missing: $($missing -join ', ')" }
    else { Ok "CHANGELOG covers $($tags.Count) tags" }
}

# 4. Every relative link in the docs must exist (fragments are not files)
$broken = @()
foreach ($doc in @('README.md','SUPPORT.md','SECURITY.md','PRIVACY.md','TERMS.md')) {
    $t = Get-Content (Join-Path $root $doc) -Raw
    foreach ($m in [regex]::Matches($t, '\]\(([^)]+)\)')) {
        $link = $m.Groups[1].Value
        if ($link -match '^(https?:|mailto:)' -or $link.StartsWith('#')) { continue }
        $path = ($link -split '#')[0]
        if (-not $path) { continue }
        if (-not (Test-Path (Join-Path $root $path))) { $broken += "$doc -> $link" }
    }
}
if ($broken.Count -gt 0) { Bad "broken relative links: $($broken -join '; ')" }
else { Ok 'no broken relative links' }

if ($fail.Count -gt 0) { throw ("Documentation gate failed: " + ($fail -join '; ')) }
Write-Host 'All documentation checks passed.'
