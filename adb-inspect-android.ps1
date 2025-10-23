<#
adb-inspect-android.ps1

Safe, read-only helper to inspect an Android device via ADB and optionally pull candidate backup files to your PC.

Usage:
  1) Ensure ADB (Android Platform-Tools) is installed and in PATH, or input its full path when prompted.
  2) Enable USB debugging on your phone and connect via USB. Accept the RSA prompt on the phone if shown.
  3) Run this script in PowerShell:
       .\adb-inspect-android.ps1

This script is intentionally interactive and will always ask your confirmation before copying (pulling) any file.
Do NOT share any seed phrases, private keys, or file contents with anyone.
#>

Set-StrictMode -Version Latest

function Get-ADBPath {
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if ($adb) {
        return $adb.Path
    }
    Write-Host "ADB not found in PATH." -ForegroundColor Yellow
    $inputPath = Read-Host "Enter full path to adb.exe (or press Enter to exit)"
    if ([string]::IsNullOrWhiteSpace($inputPath)) { throw "ADB not available. Install Android Platform-Tools and retry." }
    if (-not (Test-Path $inputPath)) { throw "Provided adb path not found: $inputPath" }
    return $inputPath
}

function Run-ADB ($adbPath, [string[]]$args) 
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $adbPath
    $psi.Arguments = $args -join ' '
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true                                                                                                                                                                                                                                                                                                                                                                                                               powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Missh\OneDrive\Documents\GitHub\btc-hack\adb-inspect-android.ps1"    powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\Missh\OneDrive\Documents\GitHub\btc-hack\adb-inspect-android.ps1"
    $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    return @{ StdOut = $stdout.Trim(); StdErr = $stderr.Trim(); ExitCode = $proc.ExitCode }
}

function Confirm-Or-Exit($message) {
    $choice = Read-Host "$message [Y/N]"
    if ($choice -match '^[Yy]') { return $true }
    <#
    adb-inspect-android.ps1

    Safe, read-only helper to inspect an Android device via ADB and optionally pull candidate backup files to your PC.

    Usage:
      1) Ensure ADB (Android Platform-Tools) is installed and in PATH, or input its full path when prompted.
      2) Enable USB debugging on your phone and connect via USB. Accept the RSA prompt on the phone if shown.
      3) Run this script in PowerShell:
           .\adb-inspect-android.ps1

    This script is intentionally interactive and will always ask your confirmation before copying (pulling) any file.
    Do NOT share any seed phrases, private keys, or file contents with anyone.
    #>

    Set-StrictMode -Version Latest

    function Get-ADBPath {
        $adb = Get-Command adb -ErrorAction SilentlyContinue
        if ($adb) {
            return $adb.Path
        }
        Write-Host "ADB not found in PATH." -ForegroundColor Yellow
        $inputPath = Read-Host "Enter full path to adb.exe (or press Enter to exit)"
        if ([string]::IsNullOrWhiteSpace($inputPath)) { throw "ADB not available. Install Android Platform-Tools and retry." }
        if (-not (Test-Path $inputPath)) { throw "Provided adb path not found: $inputPath" }
        return $inputPath
    }

    function Run-ADB ($adbPath, [string[]]$args) {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $adbPath
        $psi.Arguments = $args -join ' '
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()
        return @{ StdOut = $stdout.Trim(); StdErr = $stderr.Trim(); ExitCode = $proc.ExitCode }
    }

    function Confirm-Or-Exit($message) {
        $choice = Read-Host "$message [Y/N]"
        if ($choice -match '^[Yy]') { return $true }
        Write-Host "Operation cancelled by user." -ForegroundColor Cyan
        exit 0
    }

    # Main
    try {
        $ADB = Get-ADBPath
    } catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        exit 1
    }

    Write-Host "Using ADB: $ADB`n"

    # 1) devices
    $dev = Run-ADB $ADB @('devices')
    if ($dev.StdErr) { Write-Host "ADB stderr: $($dev.StdErr)" -ForegroundColor Yellow }
    Write-Host "Connected devices (raw):`n$($dev.StdOut)`n"

    # Parse devices
    $deviceLines = $dev.StdOut -split "`n" | Where-Object { ($_ -match '\S') -and ($_ -notmatch 'List of devices') }
    if (-not $deviceLines) {
        Write-Host "No devices found. Make sure USB debugging is enabled and device is connected." -ForegroundColor Red
        exit 1
    }

    $deviceLines | ForEach-Object { Write-Host $_ }

    # 2) define list of directories to inspect
    $dirsToCheck = @('/sdcard/Download', '/sdcard/Downloads', '/sdcard/Documents', '/sdcard/Pictures', '/sdcard/DCIM/Screenshots', '/sdcard/Android/data')

    # Package-presets: offer a menu of common wallet/dApp package keywords
    $presets = @('uniswap','metamask','trust','rainbow','coinbase','exodus','walletconnect')
    Write-Host "\nPackage presets available:" -ForegroundColor Cyan
    $i = 0
    foreach ($p in $presets) { $i++; Write-Host "  [$i] $p" }
    Write-Host "  [C] Custom keyword"
    Write-Host "  [Enter] Skip package-specific checks (default: uniswap)"

    $selPkg = Read-Host "Choose a preset number, 'C' for custom, or press Enter to use default ('uniswap')"
    if ([string]::IsNullOrWhiteSpace($selPkg)) {
        $pkgKeyword = 'uniswap'
    } elseif ($selPkg -match '^[0-9]+$' -and [int]$selPkg -ge 1 -and [int]$selPkg -le $presets.Count) {
        $pkgKeyword = $presets[[int]$selPkg - 1]
    } elseif ($selPkg -match '^[Cc]') {
        $pkgKeyword = Read-Host "Enter custom package keyword (e.g. 'uniswap' or 'metamask')"
        if ([string]::IsNullOrWhiteSpace($pkgKeyword)) { Write-Host "Empty custom keyword; defaulting to 'uniswap'"; $pkgKeyword = 'uniswap' }
    } else {
        Write-Host "Unrecognized selection; defaulting to 'uniswap'" -ForegroundColor Yellow
        $pkgKeyword = 'uniswap'
    }

    Write-Host "Searching installed packages for keyword: $pkgKeyword" -ForegroundColor Cyan
     $pkgRes = Run-ADB $ADB @('shell','pm','list','packages')
     if ($pkgRes.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($pkgRes.StdOut)) {
        $allPkgs = $pkgRes.StdOut -split "`n" | ForEach-Object { $_ -replace '^package:' , '' }
        $matching = $allPkgs | Where-Object { $_ -match [Regex]::Escape($pkgKeyword) }
        if ($matching) {
            Write-Host "Found matching packages:" -ForegroundColor Green
            $i = 0
            foreach ($m in $matching) { $i++; Write-Host "[$i] $m" }
            # Offer to add their external data paths to the inspection list
            if (Confirm-Or-Exit "Add the Android/data paths for these packages to the inspection list? (you will be prompted to confirm pulling files later)") {
                foreach ($m in $matching) {
                    $path = "/sdcard/Android/data/$m"
                    if (-not ($dirsToCheck -contains $path)) { $dirsToCheck += $path }
                    # Also add a best-effort internal data path for informational ls (may require root)
                    $internal = "/data/data/$m"
                    if (-not ($dirsToCheck -contains $internal)) { $dirsToCheck += $internal }
                }
            }
        } else {
            Write-Host "No installed packages matched the keyword '$pkgKeyword'." -ForegroundColor Yellow
        }
     } else {
        Write-Host "Could not retrieve package list from device." -ForegroundColor Yellow
     }

    Write-Host "`nWill inspect these directories on the device:`n" -NoNewline
    $dirsToCheck | ForEach-Object { Write-Host " - $_" }

    if (-not (Confirm-Or-Exit "Proceed to list contents of these directories?")) { exit 0 }

    $candidateFiles = @()

    foreach ($d in $dirsToCheck) {
        Write-Host "`nListing $d ..." -ForegroundColor Green
        $res = Run-ADB $ADB @('shell', 'ls', '-la', """$d""")
        if ($res.ExitCode -ne 0 -or $res.StdOut -match 'No such file or directory') {
            Write-Host "  (missing or inaccessible: $d)" -ForegroundColor DarkYellow
            continue
        }
        # show first 100 lines to avoid huge output
        $lines = $res.StdOut -split "`n"
        $linesToShow = $lines | Select-Object -First 100
        $linesToShow | ForEach-Object { Write-Host "  $_" }

        # Try a 'find' for candidate filenames in that directory (better precision)
        Write-Host "  Searching for candidate filenames in $d ..." -ForegroundColor Cyan
        $findCmd = "find '$d' -type f -iname '*wallet*' -o -iname '*keystore*' -o -iname '*backup*' -o -iname '*mnemonic*' -o -iname '*seed*' -o -iname '*phrase*' -o -iname '*.json' -o -iname '*.dat' 2>/dev/null"
        $findRes = Run-ADB $ADB @('shell', $findCmd)
        if ($findRes.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($findRes.StdOut)) {
            $found = $findRes.StdOut -split "`n" | Where-Object { $_ -and ($_ -notmatch 'Permission denied') }
            foreach ($f in $found) {
                if (-not ($candidateFiles -contains $f)) { $candidateFiles += $f }
            }
        } else {
            # Fallback: list recursively and filter locally
            Write-Host "  'find' not available or returned nothing; doing recursive ls fallback (may be slower)..." -ForegroundColor DarkYellow
            $lsRec = Run-ADB $ADB @('shell', 'ls', '-R', """$d""" )
            if ($lsRec.ExitCode -eq 0 -and $lsRec.StdOut) {
                $matches = $lsRec.StdOut -split "`n" | Where-Object { $_ -match '(?i)wallet|keystore|backup|mnemonic|seed|phrase|\.json$|\.dat$' }
                foreach ($m in $matches) {
                    # Attempt to reconstruct path lines if possible (best effort)
                    $line = $m.Trim()
                    if ($line -and ($line -notmatch '^d|^total')) {
                        if (-not ($candidateFiles -contains $line)) { $candidateFiles += $line }
                    }
                }
            }
        }
    }

    if (-not $candidateFiles) {
        Write-Host "\nNo candidate files found in the checked directories." -ForegroundColor Yellow
    } else {
        Write-Host "\nCandidate files found (number): $($candidateFiles.Count)`n" -ForegroundColor Green
        $i = 0
        $candidateFiles | ForEach-Object { $i++; Write-Host "[$i] $_" }

        # Prompt user to select which files to pull
        $sel = Read-Host "Enter comma-separated numbers to pull, or press Enter to skip pulling (e.g. 1,3)"
        if (-not [string]::IsNullOrWhiteSpace($sel)) {
            $indices = $sel -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^[0-9]+$' } | ForEach-Object { [int]$_ }
            $valid = $indices | Where-Object { $_ -ge 1 -and $_ -le $candidateFiles.Count }
            if (-not $valid) { Write-Host "No valid selections." -ForegroundColor Yellow } else {
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $outDir = Join-Path -Path (Join-Path -Path $env:USERPROFILE -ChildPath 'Desktop') -ChildPath "android-backup-inspect-$timestamp"
                New-Item -Path $outDir -ItemType Directory | Out-Null
                Write-Host "Pulling selected files to: $outDir" -ForegroundColor Cyan

                foreach ($idx in $valid) {
                    $remote = $candidateFiles[$idx - 1]
                    Write-Host "Pulling $remote ..." -NoNewline
                    $pullRes = Run-ADB $ADB @('pull', """$remote""", """$outDir\\""")
                    if ($pullRes.ExitCode -eq 0) { Write-Host " Done." -ForegroundColor Green } else { Write-Host " Failed: $($pullRes.StdErr)" -ForegroundColor Red }
                }

                Write-Host "\nPull complete. Inspect files locally in: $outDir" -ForegroundColor Green
                Write-Host "IMPORTANT: Do not upload any file that might contain a seed or private key. If you find a potential seed, keep it offline and tell me only the filename, not its content." -ForegroundColor Yellow
            }
        }
    }

    Write-Host "\nFinished. If you want to search other locations, re-run the script and edit the `\$dirsToCheck` array at the top." -ForegroundColor Cyan

    # End
