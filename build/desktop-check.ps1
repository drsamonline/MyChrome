# Desktop check - run this on a real Windows machine, in the folder where you unzipped
# MyBrowser. It exercises the paths that cannot be tested in CI and writes a report you
# can attach to an issue.
#
#   ./build/desktop-check.ps1                  # everything, one browser after another
#   ./build/desktop-check.ps1 -SkipVisual      # automated parts only
#
# Nothing here is mocked: it starts the launcher with a real configuration and looks for
# the browser process it should have started.

param(
    [string]$App = '',
    [switch]$SkipVisual,
    [switch]$KeepFiles
)

$ErrorActionPreference = 'Stop'

if (-not $App) { $App = (Get-Location).Path }
$exe = Join-Path $App 'MyBrowser.exe'
if (-not (Test-Path $exe)) { throw "no MyBrowser.exe in $App - unzip the release first, or pass -App <folder>" }

$ini = Join-Path $App 'MyBrowser.ini'
$report = Join-Path $App 'desktop-check.txt'
$version = (Get-Item $exe).VersionInfo.FileVersion

$results = New-Object System.Collections.Generic.List[string]
function Note([string]$line) { $results.Add($line); Write-Host $line }

Note "MyBrowser desktop check"
Note "date     : $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
Note "app      : $App"
Note "version  : $version"
Note "windows  : $((Get-CimInstance Win32_OperatingSystem).Caption) $([Environment]::OSVersion.Version)"
Note ''

# The browsers the launcher can install, and the process each one leaves running.
$browsers = @(
    @{ Name = 'Chrome';   Process = 'chrome';   Channel = 'Stable' }
    @{ Name = 'Brave';    Process = 'brave';    Channel = 'Stable' }
    @{ Name = 'Vivaldi';  Process = 'vivaldi';  Channel = 'Stable' }
    @{ Name = 'Firefox';  Process = 'firefox';  Channel = 'Release' }
    @{ Name = 'Edge';     Process = 'msedge';   Channel = 'Stable' }
    @{ Name = 'Cent';     Process = 'chrome';   Channel = '' }
)

function Backup-Ini {
    if (Test-Path $ini) { Copy-Item $ini "$ini.desktopcheck.bak" -Force; return $true }
    return $false
}
function Restore-Ini([bool]$existed) {
    if ($existed) { Move-Item "$ini.desktopcheck.bak" $ini -Force }
    elseif (Test-Path $ini) { Remove-Item $ini -Force }
}

$backed = Backup-Ini
$summary = @{}

try {
    foreach ($b in $browsers) {
        Note "--- $($b.Name) ---"

        # Start from a clean, complete configuration: no Settings dialog, no update check.
        $lines = @(
            '[Settings]'
            "AppVersion=$version"
            'Platform=win'
            "BrowserType=$($b.Name)"
            $(if ($b.Channel) { "Channel=$($b.Channel)" } else { 'Channel=' })
            'UpdateInterval=-1'
            'AppUpdate=0'
        )
        Set-Content $ini ($lines -join "`r`n") -Encoding ASCII

        $before = @(Get-Process $b.Process -ErrorAction SilentlyContinue)
        Write-Host "starting the launcher; it will download and unpack $($b.Name) - this can take a few minutes"
        $app = Start-Process $exe -WorkingDirectory $App -PassThru

        $started = $false
        for ($i = 0; $i -lt 600; $i++) {          # up to 10 minutes: a real download
            Start-Sleep -Seconds 1
            $now = @(Get-Process $b.Process -ErrorAction SilentlyContinue)
            if ($now.Count -gt $before.Count) { $started = $true; break }
            if ($app.HasExited) { break }
        }

        if ($started) {
            Note "PASS  $($b.Name) installed and started"
            $summary[$b.Name] = 'PASS'
        } else {
            $log = Join-Path $App 'MyBrowser.log'
            $tail = if (Test-Path $log) { (Get-Content $log -Tail 6) -join ' / ' } else { '(no log)' }
            Note "FAIL  $($b.Name) did not start. Log: $tail"
            $summary[$b.Name] = 'FAIL'
        }

        Get-Process $b.Process -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        if (-not $app.HasExited) { Stop-Process -Id $app.Id -Force -ErrorAction SilentlyContinue }
        Start-Sleep -Seconds 2
        Note ''
    }
} finally {
    Restore-Ini $backed
}

if (-not $SkipVisual) {
    Note '--- what only a person can check ---'
    $questions = @(
        'The settings window opens and everything is readable (no clipped text)',
        'Tab moves through the settings window in a sensible order',
        'Enter or Esc does what you expect in the settings window',
        'The tray menu opens and its items work',
        'While downloading, the progress is visible and the ETA looks right',
        'After a cancel, no ~update folder is left behind'
    )
    foreach ($q in $questions) {
        $a = Read-Host "$q [y/n/?]"
        Note ("{0}  {1}" -f $(if ($a -match '^y') { 'PASS' } elseif ($a -match '^\?') { 'TODO' } else { 'FAIL' }), $q)
    }
    Note ''
}

Note '--- summary ---'
foreach ($k in $summary.Keys) { Note ("{0,-10} {1}" -f $k, $summary[$k]) }
Note ''
Note "report written to $report"

$results -join "`r`n" | Set-Content $report -Encoding UTF8
Write-Host ''
Write-Host "Attach $report to an issue: https://github.com/drsamonline/MyChrome/issues/new"
