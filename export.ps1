<#
make-all-lua-safe.ps1
Creates all-lua.txt in the same folder as this script (or a subfolder you choose).
Run from the repo root by double-clicking the script file or from PowerShell:
  cd C:\path\to\repo
  .\make-all-lua-safe.ps1
#>

param(
  [string]$OutFileName = "all-lua.txt",
  [string]$OutDir = ""   # optional: relative path under script folder, e.g. "exports"
)

# Resolve script directory robustly
$scriptPath = $MyInvocation.MyCommand.Definition
if ([string]::IsNullOrEmpty($scriptPath)) {
  # interactive session fallback to current location
  $repoRoot = (Get-Location).Path
} else {
  $repoRoot = Split-Path -Parent $scriptPath
}

if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

# If OutDir provided, create it under repoRoot
if ($OutDir -ne "") {
  $targetDir = Join-Path $repoRoot $OutDir
} else {
  $targetDir = $repoRoot
}

# Ensure target dir exists
if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }

$outFile = Join-Path $targetDir $OutFileName

Write-Host "Writing combined file to: $outFile"

# Remove existing output file if present
if (Test-Path $outFile) { Remove-Item $outFile -Force }

# UTF8 no BOM encoder
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Find .lua files under repoRoot, excluding .git and the output file
$luaFiles = Get-ChildItem -Path $repoRoot -Recurse -File -Include *.lua |
            Where-Object { $_.FullName -notlike "*\$($outFileName)" -and $_.FullName -notmatch "\\.git\\" }

if ($luaFiles.Count -eq 0) {
  Write-Host "No .lua files found under $repoRoot"
  exit 0
}

foreach ($f in $luaFiles) {
  $rel = $f.FullName.Substring($repoRoot.Length).TrimStart('\','/')
  $sep = "`n===== FILE: $rel =====`n"
  # Append separator
  $sepBytes = $utf8NoBom.GetBytes($sep)
  if (-not (Test-Path $outFile)) {
    [System.IO.File]::WriteAllBytes($outFile, $sepBytes)
  } else {
    $existing = [System.IO.File]::ReadAllBytes($outFile)
    [System.IO.File]::WriteAllBytes($outFile, ($existing + $sepBytes))
  }

  # Read file, normalize CRLF -> LF, append
  $content = Get-Content -Raw -Encoding UTF8 $f.FullName
  $norm = $content -replace "`r`n","`n"
  $bytes = $utf8NoBom.GetBytes($norm)
  $existing = [System.IO.File]::ReadAllBytes($outFile)
  [System.IO.File]::WriteAllBytes($outFile, ($existing + $bytes))

  Write-Host "Appended: $rel"
}

Write-Host "Done. Combined file: $outFile"
