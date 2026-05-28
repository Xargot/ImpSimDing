# apply_patches.ps1
# Wrapper to apply patch bundle for ImpSimDing
# Place this file in the repo root and run it from there.

$ErrorActionPreference = "Stop"

function Write-ErrAndExit($msg) {
    Write-Host "ERROR: $msg" -ForegroundColor Red
    exit 1
}

# Resolve repo root (the directory containing this script)
$scriptPath = $MyInvocation.MyCommand.Path
if (-not $scriptPath) {
    Write-ErrAndExit "Unable to determine script path. Run this script from the repo root."
}
$repoRoot = Split-Path -Parent $scriptPath
Set-Location $repoRoot

# Basic sanity checks
if (-not (Test-Path ".git")) {
    Write-ErrAndExit "No .git folder found in $repoRoot. Run this from the repository root."
}

$patchesDir = Join-Path $repoRoot "patches"
$scriptsDir = Join-Path $repoRoot "scripts"
$applierScript = Join-Path $scriptsDir "apply_patches.ps1"

Write-Host "Repository root:" $repoRoot
Write-Host "Patches folder:" $patchesDir
Write-Host "Scripts folder:" $scriptsDir

# Ensure working tree is clean or warn and stop
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "Working tree is not clean. Please commit or stash changes before running this script." -ForegroundColor Yellow
    Write-Host "Aborting to avoid accidental conflicts."
    exit 2
}

# If a scripts\apply_patches.ps1 exists, call it
if (Test-Path $applierScript) {
    Write-Host "Found scripts\apply_patches.ps1 — delegating to it."
    & $applierScript
    if ($LASTEXITCODE -ne 0) {
        Write-ErrAndExit "scripts\apply_patches.ps1 failed with exit code $LASTEXITCODE"
    }
    Write-Host "Delegated patch application completed successfully." -ForegroundColor Green
    exit 0
}

# Otherwise, apply patches from patches\*.patch using git apply --index
if (-not (Test-Path $patchesDir)) {
    Write-ErrAndExit "No patches directory found at $patchesDir. Create patches\\ and add .patch files."
}

$patchFiles = Get-ChildItem -Path $patchesDir -Filter "*.patch" | Sort-Object Name
if (-not $patchFiles -or $patchFiles.Count -eq 0) {
    Write-ErrAndExit "No .patch files found in $patchesDir."
}

Write-Host "Applying patches from $patchesDir in order:" -ForegroundColor Cyan
$patchFiles | ForEach-Object { Write-Host " - " $_.Name }

foreach ($p in $patchFiles) {
    $patchPath = $p.FullName
    Write-Host "Applying patch: $($p.Name)" -ForegroundColor Cyan

    # Try git apply --index first
    $applyCmd = "git apply --index --whitespace=fix `"$patchPath`""
    Write-Host "Running: $applyCmd"
    $applyResult = & git apply --index --whitespace=fix $patchPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "git apply failed for $($p.Name):" -ForegroundColor Red
        Write-Host $applyResult
        Write-Host "Attempting fallback: git am (patch format dependent)."
        try {
            & git am --3way $patchPath
            if ($LASTEXITCODE -ne 0) {
                Write-ErrAndExit "git am also failed for $($p.Name). Resolve manually."
            }
        } catch {
            Write-ErrAndExit "Both git apply and git am failed for $($p.Name). Resolve manually."
        }
    } else {
        Write-Host "Patch applied and indexed: $($p.Name)" -ForegroundColor Green
    }
}

Write-Host "All patches applied. Files are staged in the index." -ForegroundColor Green
Write-Host "Review changes with 'git status' and 'git diff --staged' before committing."
