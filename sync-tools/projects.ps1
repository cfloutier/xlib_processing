# Configuration des projets Processing dépendants de xLib
# À mettre à jour UNIQUEMENT quand la liste des projets évolue

# Liste des noms de projets (ordre pour le menu interactif)
# Les chemins se construisent automatiquement à partir de ces noms
$projectNames = @("spiral", "perlin_mountains", "image_lines", "gravity", "image_dots")

# Construire les chemins automatiquement depuis les noms
$projectPaths = @{}
$projectNames | ForEach-Object { $projectPaths[$_] = Join-Path $processingDir $_ }
