[CmdletBinding()]
param (
	[switch]$Install,
	[switch]$Task,
	[switch]$Auto,
	[switch]$DisableHibernation
)

#region PivilegesCheck
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
		[Security.Principal.WindowsBuiltInRole]::Administrator
	)) {
	Write-Host "Elevando privilegios..."
	Start-Process powershell.exe `
		-ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($PSCommandPath)`"" `
		-Verb RunAs
	exit
}
Clear-Host
#endregion PivilegesCheck


#region PCB bootstrap
$global:CleanerCorePath = "$PSScriptRoot\Core"
$global:CleanerRootPath = "$PSScriptRoot"
# Verificación de rutas dentro de carpeta de creación del proyecto
if ($CleanerRootPath -imatch "\\Editions\\Basic") {
	$CleanerCorePath = (Resolve-Path "$PSScriptRoot\..\..\Core").Path
	$CleanerRootPath = (Resolve-Path "$PSScriptRoot\..\..").Path
}
Import-Module -DisableNameChecking "$CleanerCorePath\Modules\pcb-00-bootstrap.psm1" -Global -Force
Initialize-PcbCleanerExecution

# Cargar modulos adicionales del proyecto y variables globales
. "$CleanerCorePath\cleaner-initialize.ps1"
#endregion PCB bootstrap


#region Bleachbit Installation
if ($Install) {
	Import-Module -DisableNameChecking "$CleanerCorePath\Modules\Cleaner-Install.psm1" -Global -Force
	Import-Module -DisableNameChecking "$CleanerCorePath\Modules\Cleaners\bleachbit-portable.psm1" -Global -Force
	Initialize-PCBRegistryPath -Auto:$Auto
	Set-InstallationDate -Auto:$Auto
	Set-CleanerHibernationStatus -Auto:$Auto -DisableHibernation:$DisableHibernation
	Install-BleachBit -Task:$Task -Auto:$Auto
	if ($Task) {
		New-CleanerScheduledTask -Auto:$Auto
	}
	exit
}
#endregion Bleachbit Installation


#region Execution

# Importar TODOS los modulos de limpiadores comunes
Get-ChildItem "$CleanerCorePath\Modules\Cleaners\*.psm1" | Import-Module -DisableNameChecking -Force

# --- Fase 0: Evaluación del sistema ---
$initialSnapshotName = "Inicio de limpiador"
$initialShot = Set-Snapshot -Name $initialSnapshotName -Dates (Get-RegistryDates) -Return
$global:AggressiveMode = Test-DrivesCritical -Drives $initialShot.Drives
Show-PreCleanSystemSnapshot -Snapshot $initialShot
Set-SnapshotFinishTime -Name $initialSnapshotName

# --- Fase 1: Cierre de procesos comunes ---

Write-Host "`n$("="*([console]::WindowWidth - 1) )`n"
$processList = (Import-PowerShellDataFile "$CleanerCorePath\Data\processes-core.psd1").Processes
Stop-CleanerProcesses $processList -ask


# --- Fase 2: Limpiadores especializados ---
Write-Host "`n$("="*([console]::WindowWidth - 1) )`n"
wRun "INICIANDO LIMPIEZA DE ALMACENAMIENTO"

# Limpiador de Google Chrome
Start-CleanGoogleChrome -ProcessData $processList
Start-CleanGoogleChromeDeep -PreserveSessions

# Ejecución de BleachBit basada en preferencias (bleachbit.ini)
Start-BleachBitClean -ProcessData $processList


# --- Fase 3 : # Limpieza con componentes de Windows

# Vaciar Papeleras de Reciclaje
Clear-AllRecycleBins -Drives $initialShot.Drives

# Deshabilitar hibernación (Hay comantarios con instrucciones)
Disable-HibernationIfConfigured

# Limpieza de la carpetas de descargas de Windows Update (SoftwareDistribution y Delivery Optiomization)
Clear-WindowsUpdateDownloads
Clear-DeliveryOptimizationCache

# Limpiar archivos de carpetas temporales y thumbnails de cache.
Clear-SystemTemp

# Limpiar Logs de eventos del sistema
Clear-SystemLogs

# Limpiar el informe de errores de Windows
Clear-ErrorReports

# Limpia puntos de restauración antiguos
Clear-SystemRestorePoints

# Limpieza de componentes obsoletos de window (WinSxS)
Clear-WinSxSComponents

# Limpieza con el liberador de espacio de Windows
Start-WindowsDiskCleanup

# Compactación del sistema operativo (CompactOS)
Set-compactOS

wInfo "Limpieza finalizada."
Set-SnapshotFinishTime -Name $initialSnapshotName
Set-RegistryDates

# Reapertura de procesos cerrados durante la ejecución
Start-ReopenedProcesses
Start-Sleep 2
Write-Host "`n$("="*([console]::WindowWidth - 1) )`n"
Show-FinalReport
Write-Host "`n$("="*([console]::WindowWidth - 1) )`n"
#endregion Execution
