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
$stale = $names | Where-Object { $_ -ne $version } | Sort-Object -Unique
if ($stale) { Bad "README names reference $($stale -join ', '), source is $version" }
else { Ok "README asset names match $version" }

# 2. ROADMAP claimed counts must match its own status board
$road = Get-Content (Join-Path $root 'ROADMAP.md') -Raw
$board = $road.Substring($road.IndexOf('## Status board'), $road.IndexOf('## A. Download integrity') - $road.IndexOf('## Status board'))
$rows = [regex]::Matches($board, '(?m)^\| ([A-L]\d+) \| .*? \| (P\d) \| (.+?) \| (.+?) \|$')
$done = @($rows | Where-Object { $_.Groups[3].Value.StartsWith('✅') }).Count
$part = @($rows | Where-Object { $_.Groups[3].Value.StartsWith('🟡') }).Count
$open = @($rows | Where-Object { $_.Groups[3].Value.StartsWith('⬜') }).Count
$total = $rows.Count
$claimed = [regex]::Match($road, 'Progress: (\d+) of (\d+) done \((\d+)%\), (\d+) partial, (\d+) open')
if (-not $claimed.Success) { Bad 'ROADMAP has no progress line' }
else {
    if ([int]$claimed.Groups[1].Value -ne $done)  { Bad "ROADMAP claims $($claimed.Groups[1].Value) done, table has $done" }
    if ([int]$claimed.Groups[2].Value -ne $total) { Bad "ROADMAP claims $($claimed.Groups[2].Value) items, table has $total" }
    if ([int]$claimed.Groups[4].Value -ne $part)  { Bad "ROADMAP claims $($claimed.Groups[4].Value) partial, table has $part" }
    if ([int]$claimed.Groups[5].Value -ne $open)  { Bad "ROADMAP claims $($claimed.Groups[5].Value) open, table has $open" }
    if (-not $fail) { Ok "ROADMAP counts agree: $done done, $part partial, $open open of $total" }
}

# 3. CHANGELOG must mention every release tag
$tags = (git -C $root tag) | Where-Object { $_ -match '^v\d' } | ForEach-Object { $_.Substring(1) }
$log = Get-Content (Join-Path $root 'CHANGELOG.md') -Raw
$missing = $tags | Where-Object { $log -notmatch "(?m)^## $([regex]::Escape($_))$" }
if ($missing) { Bad "CHANGELOG missing: $($missing -join ', ')" }
else { Ok "CHANGELOG covers $($tags.Count) tags" }

# 4. Every relative link in the docs must exist
foreach ($doc in @('README.md','SUPPORT.md','SECURITY.md','PRIVACY.md','TERMS.md')) {
    $t = Get-Content (Join-Path $root $doc) -Raw
    foreach ($m in [regex]::Matches($t, '\]\(([^)#][^)]*)\)')) {
        $link = $m.Groups[1].Value
        if ($link -match '^(https?:|mailto:|#)') { continue }
        if (-not (Test-Path (Join-Path $root $link))) { Bad "$doc has a broken link: $link" }
    }
}
if (-not ($fail | Where-Object { $_ -like '*broken link*' })) { Ok 'no broken relative links' }

if ($fail.Count -gt 0) { throw ("Documentation gate failed: " + ($fail -join '; ')) }
Write-Host 'All documentation checks passed.'
