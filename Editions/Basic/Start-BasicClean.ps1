[CmdletBinding()]
param (
	[switch]$Install,
	[switch]$Task,
	[switch]$Auto
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
#$global:connected = $false
if ($Install) {
	Import-Module -DisableNameChecking "$CleanerCorePath\Modules\Cleaner-Install.psm1" -Global -Force
	Import-Module -DisableNameChecking "$CleanerCorePath\Modules\Cleaners\bleachbit-portable.psm1" -Global -Force
	Install-BleachBit -Task:$Task -Auto:$Auto
	exit
}
#endregion Bleachbit Installation


#region Execution

# Importar TODOS los modulos de limpiadores comunes
Get-ChildItem "$CleanerCorePath\Modules\Cleaners\*.psm1" | Import-Module -DisableNameChecking -Force

# --- Area de pruebas

$dataToAnalyze = @"
Inicial                            {@{Letter=C:; Total=464,92; Free=424,46; Used=8,7}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}}  @{start=6/07/2026 3:10:43 pm; LastNormal=1/01/0001 12:00:00 am; LastAgressive=1/01/0001 12:00:00 am;...
PreLimpieza                        {@{Letter=C:; Total=464,92; Free=424,46; Used=8,7}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}}  @{start=6/07/2026 3:10:43 pm; finish=1/01/0001 12:00:00 am}
Google Chrome                      {@{Letter=C:; Total=464,92; Free=424,51; Used=8,69}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}} @{start=6/07/2026 3:10:49 pm; finish=1/01/0001 12:00:00 am}
Limpieza profunda de Google Chrome {@{Letter=C:; Total=464,92; Free=424,53; Used=8,69}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}} @{start=6/07/2026 3:10:49 pm; finish=1/01/0001 12:00:00 am}
BleachBit                          {@{Letter=C:; Total=464,92; Free=424,54; Used=8,69}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}} @{start=6/07/2026 3:10:53 pm; finish=1/01/0001 12:00:00 am}
Papelera de reciclaje              {@{Letter=C:; Total=464,92; Free=424,54; Used=8,69}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}} @{start=6/07/2026 3:10:55 pm; finish=1/01/0001 12:00:00 am}
Caché de Windows Update            {@{Letter=C:; Total=464,92; Free=424,54; Used=8,69}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}} @{start=6/07/2026 3:10:57 pm; finish=1/01/0001 12:00:00 am}
WU Delivery Optimization           {@{Letter=C:; Total=464,92; Free=424,54; Used=8,69}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}} @{start=6/07/2026 3:10:59 pm; finish=1/01/0001 12:00:00 am}
Limpieza de careptas temporales    {@{Letter=C:; Total=464,92; Free=424,54; Used=8,69}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}} @{start=6/07/2026 3:10:59 pm; finish=1/01/0001 12:00:00 am}
Informes de errores de Windows     {@{Letter=C:; Total=464,92; Free=424,54; Used=8,69}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}} @{start=6/07/2026 3:11:10 pm; finish=1/01/0001 12:00:00 am}
WinSxS (DISM)                      {@{Letter=C:; Total=464,92; Free=424,49; Used=8,7}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}}  @{start=6/07/2026 3:11:21 pm; finish=1/01/0001 12:00:00 am}
Liberador de espacio de Windows    {@{Letter=C:; Total=464,92; Free=424,49; Used=8,7}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}}  @{start=6/07/2026 3:11:56 pm; finish=1/01/0001 12:00:00 am}
Compactación de Sistema Operativo  {@{Letter=C:; Total=464,92; Free=424,49; Used=8,7}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}}  @{start=6/07/2026 3:11:56 pm; finish=1/01/0001 12:00:00 am}
Finalización                       {@{Letter=C:; Total=464,92; Free=424,48; Used=8,7}, @{Letter=D:; Total=465,76; Free=264,35; Used=43,24}, @{Letter=E:; Total=931,51; Free=225,37; Used=75,81}}  @{start=6/07/2026 3:11:58 pm; Finish=6/07/2026 3:11:58 pm}
"@

exit




# --- Fase 0: Evaluación del sistema ---

$initialShot = Set-Snapshot -Name "Inicial" -Dates (Get-RegistryDates) -Return
$global:AggressiveMode = Test-DrivesCritical -Drives $initialShot.Drives
Set-Snapshot -Name "PreLimpieza"
Show-PreCleanSystemSnapshot -Snapshot $initialShot

# --- Fase 1: Cierre de procesos comunes ---

Write-Host "`n$("="*([console]::WindowWidth - 1) )`n"
wRun "CIERRE INICIAL DE PROCESOS"
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

wInfo "Limpieza finalizado."
# Reapertura de procesos cerrados durante la ejecución
Write-Host "`n$("="*([console]::WindowWidth - 1) )`n"
Start-ReopenedProcesses
Start-Sleep 2
Set-Snapshot -Name "Finalización"
Set-SnapshotFinishTime
Get-Snapshot | select *

exit

# Obtener resumen de espacio
#Set-SnapshotFinishTime -Name "Initial"
exit

Get-SpaceMark
Get-Snapshot

Pause
exit
#endregion Execution
