<#
update-impSimDing.ps1
Usage:
  .\update-impSimDing.ps1 -PatchDir .\patch_files -Branch automated/patches

Behavior:
  - Backups original files to backups\impSimDing-<timestamp>
  - Copies files from PatchDir into repo paths listed in $files
  - Normalizes CRLF -> LF and writes UTF8 (no BOM)
  - Ensures .gitattributes contains "*.lua text eol=lf"
  - Creates/updates branch, commits, and pushes
#>

param(
  [string]$PatchDir = ".\patch_files",
  [string]$Branch = "automated/patches"
)

function Write-ErrAndExit($msg) {
  Write-Error $msg
  exit 1
}

# Ensure running from repo root
if (-not (Test-Path ".git")) { Write-ErrAndExit "This script must be run from the repository root (where .git is)." }

# Validate patch dir
if (-not (Test-Path $PatchDir)) { Write-ErrAndExit "PatchDir not found: $PatchDir" }

# Timestamped backup folder
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$backup = Join-Path ".\backups" ("impSimDing-$ts")
New-Item -ItemType Directory -Force -Path $backup | Out-Null

# Files to update (relative repo paths). Edit this list if you have other files.
$files = @("Core\Core.lua","Core\SpellHandlers.lua")

# Helper: write file as UTF8 without BOM and with LF line endings
function Write-FileUtf8Lf($path, $content) {
  # Normalize CRLF -> LF
  $norm = $content -replace "`r`n","`n"
  # Ensure directory exists
  $dir = Split-Path $path -Parent
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  # Write bytes for UTF8 without BOM
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  $bytes = $utf8NoBom.GetBytes($norm)
  [System.IO.File]::WriteAllBytes($path, $bytes)
}

# Process each file: backup existing, copy from patch dir, normalize, write
foreach ($rel in $files) {
  $patchFileName = Split-Path $rel -Leaf
  $src = Join-Path $PatchDir $patchFileName
  if (-not (Test-Path $src)) { Write-ErrAndExit "Missing patch file: $src" }

  $dst = Join-Path (Get-Location) $rel
  if (Test-Path $dst) {
    $dstBackup = Join-Path $backup (Split-Path $rel -Leaf)
    Copy-Item -Force $dst $dstBackup
  }

  $content = Get-Content -Raw -Encoding UTF8 $src
  Write-FileUtf8Lf -path $dst -content $content
  Write-Host "Updated: $rel"
}

# Ensure .gitattributes enforces LF for lua files
$gitattributes = ".gitattributes"
$entry = "*.lua text eol=lf"
if (-not (Test-Path $gitattributes)) {
  Set-Content -Path $gitattributes -Value $entry -Encoding UTF8
  Write-Host "Created .gitattributes with LF rule"
} else {
  $has = Select-String -Path $gitattributes -Pattern "^\s*\*\.(lua)\s+text\s+eol=lf\s*$" -SimpleMatch -Quiet
  if (-not $has) {
    Add-Content -Path $gitattributes -Value "`n$entry"
    Write-Host "Appended LF rule to .gitattributes"
  } else {
    Write-Host ".gitattributes already contains LF rule"
  }
}

# Git operations: fetch, create branch, add, commit, push
Write-Host "Running git operations..."
git fetch origin 2>$null

# Create or reset local branch to current HEAD (safe)
git checkout -B $Branch

# Stage changes
git add -A

# Commit if there are staged changes
$commitOutput = git commit -m "Automated: apply hardened Core/Core.lua and Core/SpellHandlers.lua; normalize LF" 2>&1
if ($LASTEXITCODE -ne 0) {
  if ($commitOutput -match "nothing to commit") {
    Write-Host "Nothing to commit (no changes)."
  } else {
    Write-Host $commitOutput
  }
} else {
  Write-Host "Committed changes."
}

# Push branch (set upstream)
git push -u origin $Branch

Write-Host "Done. Backup folder: $backup"
