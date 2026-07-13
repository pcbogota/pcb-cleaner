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
	'cleaner-process.psm1',
	'cleaner-registry.psm1',
	'cleaner-snapshot.psm1',
	'cleaner-utils.psm1'

)
Register-Libraries $Libs
Remove-Variable -Name Libs -ErrorAction SilentlyContinue
#endregion Modules

#region Variables
# --- Variables iniciales usadas globalmente---
$global:snapshots = @()
$global:Threshold = 70


# Paths
# Ruta de BleachBit Portable
$global:bleachbitPath = "$CleanerRootPath\BleachBit-Portable"

# Ruta del registro donde se guardan las fechas
$global:PCBregPath = 'HKLM:\SOFTWARE\PCBogota\PCB-Cleaner'
#endregion Variables

# inicialización visual (impresion de logo)
Clear-Host
Write-Logo
