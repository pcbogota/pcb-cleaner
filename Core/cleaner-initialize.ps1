# ============================================================
# Initialize-Cleaner.ps1
# Prepara el entorno del Cleaner:
#   - Carga las clases
#   - Importa los módulos
#   - Define variables globales si son necesarias
# ============================================================

#region Modules
# --- Cargar módulos ---
# Lista de módulos que se necesitan para el cleaner
Write-Host "`nCargando modulos de PCB Cleaner..."
$Libs = @(
	'cleaner-display.psm1',
	'cleaner-drive-utils.psm1',
	'cleaner-install.psm1',
	'cleaner-registry.psm1',
	'cleaner-snapshot.psm1',
	'cleaner-utils.psm1'
)
Register-Libraries $Libs
Remove-Variable -Name Libs -ErrorAction SilentlyContinue

# Aquí podrías definir variables de sesión si hicieran falta,
# pero con [CleanerState] probablemente no necesites muchas.
#endregion Modules

#region Variables

# --- Variables iniciales de espacio en unidad de sistema---
$global:snapshots = @()
$global:Threshold = 70
$global:AgressiveMode = $false

# Paths
$global:bleachbitPath = "$CleanerRootPath\BleachBit-Portable"

#endregion Variables
