# xLib Sync Tools

Tools to synchronize shared xLib files between three Processing projects (spiral, perlin_mountains, image_processor) and the centralized xlib repository.

## Architecture

```
xlib/ (centralized repo - source of truth)
├── xLib_*.pde (shared files)
├── .git/
└── sync-tools/
    ├── push-to-projects.ps1
    ├── pull-from-projects.ps1
    ├── projects.ps1
    └── README.md

spiral/, perlin_mountains/, image_processor/
├── xLib_*.pde (synchronized copies)
└── [other project files]
```

## Usage

### Interface for Push and Pull

Both scripts have a similar interface but different scopes:

**Push xLib to projects** — Can target all projects:
```powershell
.\push-to-projects.ps1 all              # Send xlib to all projects
.\push-to-projects.ps1 spiral           # Send xlib to spiral only
.\push-to-projects.ps1                  # Menu: 0=all, 1=spiral, 2=perlin_mountains, 3=image_processor
```

**Pull from ONE unique project** — Always one project at a time:
```powershell
.\pull-from-projects.ps1 spiral         # Pull from spiral to xlib
.\pull-from-projects.ps1                # Menu: 1=spiral, 2=perlin_mountains, 3=image_processor
```

### Options

- `-dry` : Dry run (shows what would be changed without making changes)
- Any other parameter: returns an error

### Examples

**Push xlib to all projects:**
```powershell
.\push-to-projects.ps1 all
```

**Pull changes from a project to xlib:**
```powershell
.\pull-from-projects.ps1 spiral          # Pull from spiral
.\pull-from-projects.ps1                 # Interactive menu to choose project
```

**Interactive menu to choose:**
```powershell
.\push-to-projects.ps1              # Menu with "0. all" option
.\pull-from-projects.ps1            # Menu with only projects (1, 2, 3)
```

**Simulate before executing (dry run):**
```powershell
.\push-to-projects.ps1 all -dry             # Shows what would be sent to all projects
.\pull-from-projects.ps1 spiral -dry        # Shows what would be pulled from spiral
```

**Error if invalid parameter:**
```powershell
.\push-to-projects.ps1 -badparam       # ✗ ERROR: Parameter not found
```

## Recommended Workflow

### When you modify xLib in a project:

```powershell
# 1. Test the changes in the project
# (edit and test in spiral/, perlin_mountains/ or image_processor/)

# 2. Pull the project changes back to the xlib repo
# Note: pull-from-projects works with ONE project at a time
.\pull-from-projects.ps1 spiral          # Pull from spiral to xlib

# 3. Commit to the xlib repo
cd C:\dev\__tracer\processing\xlib
git add xLib_*.pde
git commit -m "Update xLib: description of changes"
git push
```

### When there are changes in xlib to distribute:

```powershell
# Send xlib to all projects
# Note: push-to-projects can send to "all" (everyone) or a specific project
.\push-to-projects.ps1 all          # Send to all projects
# or for a specific project:
.\push-to-projects.ps1 spiral       # Send to spiral only
```

### Adding a new project:

If you add a new Processing project that depends on xLib:

1. Add its name to `projects.ps1` in `$projectNames`
2. The path is constructed automatically
3. The scripts recognize the new project immediately

## How It Works

The scripts use **SHA256 hash** comparison to automatically detect changes:

- **push-to-projects.ps1** : Sends xlib TO projects (can target all or a single one)
  - Menu: `0. all` (all projects) + `1-3` (individual projects)
  - Compares xlib repo files with those of selected projects
  - If different → asks for confirmation before copying
  - If identical → nothing to do

- **pull-from-projects.ps1** : Retrieves from projects TO xlib (always ONE ONLY)
  - Menu: `1-3` (individual projects only, no "all" option)
  - Compares a project's files with those in the xlib repo
  - If different → asks for confirmation before copying to xlib
  - If identical → nothing to do
  
**Why does pull only accept one project?** 
- Prevents merge conflicts
- You consciously decide which project is the source of truth
- Pull from one project → commit → push to xlib repo (clean workflow)

## Configuration Files

### `projects.ps1`

Centralized configuration file for the list of dependent projects. **Update ONLY when the project list changes.**

```powershell
$projectNames = @("spiral", "perlin_mountains", "image_processor")

# Paths are constructed automatically from names
$projectPaths = @{}
$projectNames | ForEach-Object { $projectPaths[$_] = Join-Path $processingDir $_ }
```

**Ajouter un nouveau projet:**
1. Ajouter simplement le nom à `$projectNames` (dans l'ordre souhaité)
2. Le chemin se construit automatiquement (le dossier doit avoir le même nom que le projet)
3. Les scripts reconnaissent immédiatement le nouveau projet dans le menu

## Fichiers gérés

Les scripts synchronisent automatiquement **tous les fichiers** correspondant à `xLib_*.pde`, peu importe combien il y en a. Pas besoin de modifier les scripts si de nouveaux xLib_*.pde sont ajoutés.

Actuellement (v2.2.11):
- xLib_ClippingUtils.pde
- xLib_ColorRef.pde
- xLib_DataGlobal.pde
- xLib_ExportUtils.pde
- xLib_FileUI.pde
- xLib_GenericData.pde
- xLib_GenericDataList.pde
- xLib_GUIPanel.pde
- xLib_KeyMoves.pde
- xLib_MainPanel.pde
- xLib_MyPerlin.pde
- xLib_Polyline.pde
- xLib_StringUtils.pde
- xLib_Style.pde
- xLib_version.pde

## Notes

- Les scripts sont **non-destructifs** : ils proposent une confirmation avant d'agir
- Utilise `-dry` pour prévisualiser sans risque
- Les fichiers sont comparés par contenu (hash), pas par date de modification
- Les fichiers d'export/résultats ne sont jamais synchronisés (seulement les xLib_*.pde)

## Troubleshooting

**Erreur: "Project not found"**
- Vérifier que le nom du projet est correct (spiral, perlin_mountains, image_processor)

**Erreur: "Missing files in xlib repo"**
- Le repo xlib n'a pas encore tous les xLib_*.pde
- Faire un push depuis un projet d'abord

**Script ne s'exécute pas**
- Vérifier: `Get-ExecutionPolicy`
- Si restreint, autoriser temporairement: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`
