<#
apply-imp-patch.ps1
Usage:
  1) Put imp_midnight_patch.txt in repo root (or rename file and pass -PatchFile)
  2) Run from repo root: .\apply-imp-patch.ps1
#>

param(
  [string]$PatchFile = ".\imp_midnight_patch.txt",
  [string]$Branch = "automated/patches"
)

function ErrExit($m) { Write-Error $m; exit 1 }

# Resolve repo root from script location if possible
$scriptPath = $MyInvocation.MyCommand.Definition
if ([string]::IsNullOrEmpty($scriptPath)) {
  $repoRoot = (Get-Location).Path
} else {
  $repoRoot = Split-Path -Parent $scriptPath
}
Set-Location $repoRoot

if (-not (Test-Path ".git")) { ErrExit "Run this script from the repository root (where .git is)." }
if (-not (Test-Path $PatchFile)) { ErrExit "Patch file not found: $PatchFile" }

# Read entire patch file
$raw = Get-Content -Raw -Encoding UTF8 $PatchFile

# Split into file blocks
$pattern = "(?m)^===== FILE: (.+?) =====\r?\n"
$matches = [regex]::Matches($raw, $pattern)
if ($matches.Count -eq 0) { ErrExit "No file blocks found in patch file." }

# Build list of (path, content)
$blocks = @()
$lastIndex = 0
for ($i = 0; $i -lt $matches.Count; $i++) {
  $m = $matches[$i]
  $path = $m.Groups[1].Value.Trim()
  $start = $m.Index + $m.Length
  $end = if ($i -lt $matches.Count - 1) { $matches[$i+1].Index } else { $raw.Length }
  $content = $raw.Substring($start, $end - $start)
  # Trim leading newline if present
  if ($content.StartsWith("`n")) { $content = $content.Substring(1) }
  if ($content.StartsWith("`r`n")) { $content = $content.Substring(2) }
  $blocks += [PSCustomObject]@{ Path = $path; Content = $content }
}

# Backup folder
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$backupRoot = Join-Path $repoRoot ("backups\imp_patch-$ts")
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

# UTF8 no BOM encoder
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

foreach ($b in $blocks) {
  $dst = Join-Path $repoRoot $b.Path
  $dstDir = Split-Path $dst -Parent
  if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }

  # Backup existing file if present
  if (Test-Path $dst) {
    $rel = $b.Path -replace "[:\\\/]","_"
    $bk = Join-Path $backupRoot $b.Path
    $bkDir = Split-Path $bk -Parent
    if (-not (Test-Path $bkDir)) { New-Item -ItemType Directory -Force -Path $bkDir | Out-Null }
    Copy-Item -Force $dst $bk
  }

  # Normalize CRLF -> LF
  $norm = $b.Content -replace "`r`n","`n"
  # Write UTF8 no BOM
  $bytes = $utf8NoBom.GetBytes($norm)
  [System.IO.File]::WriteAllBytes($dst, $bytes)
  Write-Host "Wrote: $b.Path"
}

# Ensure .gitattributes contains LF rule for lua
$gitattributes = Join-Path $repoRoot ".gitattributes"
$entry = "*.lua text eol=lf"
if (-not (Test-Path $gitattributes)) {
  Set-Content -Path $gitattributes -Value $entry -Encoding UTF8
  Write-Host "Created .gitattributes"
} else {
  $has = Select-String -Path $gitattributes -Pattern "^\s*\*\.(lua)\s+text\s+eol=lf\s*$" -Quiet
  if (-not $has) {
    Add-Content -Path $gitattributes -Value "`n$entry"
    Write-Host "Appended LF rule to .gitattributes"
  } else {
    Write-Host ".gitattributes already contains LF rule"
  }
}

# Git operations
git fetch origin 2>$null
git checkout -B $Branch
git add -A
$commit = git commit -m "Automated: apply Midnight 12.0.5 hardened ImpSimDing files" 2>&1
if ($LASTEXITCODE -ne 0) {
  if ($commit -match "nothing to commit") {
    Write-Host "Nothing to commit."
  } else {
    Write-Host $commit
  }
} else {
  Write-Host "Committed changes."
}
git push -u origin $Branch

Write-Host "Done. Backups stored in: $backupRoot"
