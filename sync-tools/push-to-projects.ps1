# Push xLib to Processing projects (from xlib repo)
# Usage: .\.push-to-projects.ps1 [all|ProjectName] [-dry]
# Example: .\.push-to-projects.ps1 all
# Example: .\.push-to-projects.ps1 spiral -dry

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
Write-Host "==== Push to Projects ====" -ForegroundColor Cyan
Write-Host ""

# Determine which projects to sync
$targetProjects = @()

if ($ProjectName -eq "all") {
    $targetProjects = $projectNames
    Write-Host "Pushing to all $($projectNames.Count) projects..." -ForegroundColor Yellow
} elseif ($ProjectName) {
    if ($projectPaths.ContainsKey($ProjectName)) {
        $targetProjects = @($ProjectName)
    } else {
        Write-Host "ERROR: Unknown project" -ForegroundColor Red
        Write-Host "Available: all, $($projectNames -join ', ')" -ForegroundColor Yellow
        exit 1
    }
} else {
    # Interactive menu
    Write-Host "Select project(s) to push to:" -ForegroundColor Yellow
    Write-Host "  0. all (all projects)"
    for ($i = 0; $i -lt $projectNames.Count; $i++) {
        Write-Host "  $($i+1). $($projectNames[$i])"
    }
    Write-Host ""
    $choice = Read-Host "Enter number (0-$($projectNames.Count))"
    
    if ($choice -eq "0") {
        $targetProjects = $projectNames
    } else {
        $choiceIndex = [int]$choice - 1
        if ($choiceIndex -lt 0 -or $choiceIndex -ge $projectNames.Count) {
            Write-Host "ERROR: Invalid choice" -ForegroundColor Red
            exit 1
        }
        $targetProjects = @($projectNames[$choiceIndex])
    }
}

Write-Host ""

# Verify xlib repo has the files
$missingFiles = @()
foreach ($file in $xlibFiles) {
    if (-not (Test-Path (Join-Path $xlibDir $file))) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "ERROR: Missing files in xlib repo:" -ForegroundColor Red
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""

# Process each project
$totalChanged = 0

foreach ($projName in $targetProjects) {
    $projPath = $projectPaths[$projName]
    
    if (-not (Test-Path $projPath)) {
        Write-Host "ERROR: Project not found: $projName" -ForegroundColor Red
        continue
    }
    
    # Check what will change
    $changedFiles = @()
    foreach ($file in $xlibFiles) {
        $srcFile = Join-Path $xlibDir $file
        $dstFile = Join-Path $projPath $file
        
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
    
    if ($changedFiles.Count -eq 0) {
        Write-Host "$projName : OK (up to date)" -ForegroundColor Green
        continue
    }
    
    # Display changes for this project
    Write-Host "$projName : Found $($changedFiles.Count) file(s)" -ForegroundColor Cyan
    foreach ($item in $changedFiles) {
        Write-Host "     - $($item.File)" -ForegroundColor Gray
    }
    
    # Apply changes
    if ($dry) {
        foreach ($item in $changedFiles) {
            Write-Host "     [dry run] $($item.File)" -ForegroundColor DarkGray
        }
    } else {
        foreach ($item in $changedFiles) {
            Copy-Item $item.Source $item.Dest -Force
        }
        Write-Host "     Updated!" -ForegroundColor Green
    }
    
    $totalChanged += $changedFiles.Count
}

Write-Host ""
if ($dry) {
    Write-Host "Dry run: $totalChanged file(s) would be updated" -ForegroundColor Gray
} else {
    Write-Host "SUCCESS! Push complete." -ForegroundColor Green
}
Write-Host ""
