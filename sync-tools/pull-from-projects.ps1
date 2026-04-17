# Pull xLib from Processing projects (to xlib repo)
# Usage: .\.pull-from-projects.ps1 [all|ProjectName] [-dry]
# Example: .\.pull-from-projects.ps1 all
# Example: .\.pull-from-projects.ps1 spiral -dry

[CmdletBinding()]
param(
    [string]$ProjectName = "",
    [switch]$dry = $false
)

# Configuration - relative to sync-tools directory
$xlibDir = Split-Path -Parent $PSScriptRoot
$processingDir = Split-Path -Parent $xlibDir

# Load projects configuration
. (Join-Path $PSScriptRoot "projects.ps1")

# Get xLib files dynamically from the xlib repo
$xlibFiles = Get-ChildItem (Join-Path $xlibDir "xLib_*.pde") -File | Select-Object -ExpandProperty Name | Sort-Object

Write-Host ""
Write-Host "==== Pull from Projects ====" -ForegroundColor Cyan
Write-Host ""

# Determine which project to pull from
$targetProject = $null

if ($ProjectName) {
    # Specific project provided
    if ($projectPaths.ContainsKey($ProjectName)) {
        $targetProject = $ProjectName
    } else {
        Write-Host "ERROR: Unknown project: $ProjectName" -ForegroundColor Red
        Write-Host "Available: $($projectNames -join ', ')" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
} else {
    # Interactive menu - choose ONE project only
    Write-Host "Select project to pull from:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $projectNames.Count; $i++) {
        Write-Host "  $($i+1). $($projectNames[$i])"
    }
    Write-Host ""
    $choice = Read-Host "Enter number (1-$($projectNames.Count))"
    
    $choiceIndex = [int]$choice - 1
    if ($choiceIndex -lt 0 -or $choiceIndex -ge $projectNames.Count) {
        Write-Host "ERROR: Invalid choice" -ForegroundColor Red
        exit 1
    }
    $targetProject = $projectNames[$choiceIndex]
}

Write-Host ""
Write-Host "Pulling from $targetProject..." -ForegroundColor Yellow
Write-Host ""

# Process the single project
$projPath = $projectPaths[$targetProject]

if (-not (Test-Path $projPath)) {
    Write-Host "ERROR: Project not found: $targetProject" -ForegroundColor Red
    exit 1
}

# Check for changes
$changedFiles = @()
foreach ($file in $xlibFiles) {
    $srcFile = Join-Path $projPath $file
    $dstFile = Join-Path $xlibDir $file
    
    if (Test-Path $srcFile) {
        $srcHash = (Get-FileHash $srcFile).Hash
        $dstHash = if (Test-Path $dstFile) { (Get-FileHash $dstFile).Hash } else { "" }
        
        if ($srcHash -ne $dstHash) {
            $changedFiles += @{
                File = $file
                Source = $srcFile
                Dest = $dstFile
            }
        }
    }
}

if ($changedFiles.Count -eq 0) {
    Write-Host "OK: No changes detected. $targetProject is up to date." -ForegroundColor Green
    Write-Host ""
    exit 0
}

# Display changes
Write-Host "Found $($changedFiles.Count) file(s) to pull:" -ForegroundColor Cyan
foreach ($item in $changedFiles) {
    Write-Host "  - $($item.File)" -ForegroundColor Gray
}
Write-Host ""

# Apply changes
if ($dry) {
    Write-Host "Dry run:" -ForegroundColor Gray
    foreach ($item in $changedFiles) {
        Write-Host "  [dry run] $($item.File)" -ForegroundColor DarkGray
    }
} else {
    $confirm = Read-Host "Pull changes from $targetProject? (y/n)"
    if ($confirm -eq "y") {
        foreach ($item in $changedFiles) {
            Copy-Item $item.Source $item.Dest -Force
            Write-Host "  OK $($item.File)" -ForegroundColor Green
        }
    } else {
        Write-Host "Cancelled" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
if ($dry) {
    Write-Host "Dry run: $($changedFiles.Count) file(s) would be updated" -ForegroundColor Gray
} else {
    Write-Host "SUCCESS! Pull complete." -ForegroundColor Green
}
Write-Host ""
