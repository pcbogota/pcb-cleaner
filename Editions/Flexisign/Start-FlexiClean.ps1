[CmdletBinding()]
param (
	[switch]$Install,
	[switch]$Task,
	[switch]$Auto,
	[switch]$DisableHibernation
)



# Design Colors RIP temporales


<#

##Obtener espacio en disco actual

## obtener carpetas

Las conocidas
C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Temp\_PPS_tempAMJob
C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Temp\

HKEY_CURRENT_USER\SOFTWARE\Amiable\Production-3684


[HKEY_CURRENT_USER\SOFTWARE\Amiable\Production-3684]
"JobFolderPath"="C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Jobs"
"TempFolderPath"="C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Temp"

C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Program(64)\App2.exe


C:\Printexp\PrintExp\PrintExp.exe



¿¿ carpetas de temporales para printexp???

¿¿ carpeta de trabajos de clientes ?? (Para eliminar la ultima fecha automáticamente)


### --- HOJA DE RUTA DEFINITIVA — LIMPIADOR RIP + SISTEMA --- ###

🔧 CONFIGURACIÓN PREVIA REQUERIDA (UNA SOLA VEZ)
	- Parametros para el script
		auto: define si se invoca desde tarea programada, omitirá preguntas interactivas (excepto cierre forzado de programas).
	- Variables configurables al inicio del script:
		- Ruta de elementos temporales para flexisign y printexpert (C: y D:).
		- Carpeta raiz de trabajos de clientes (opcional, puede no existir).
		- Meses hacia atrás para conservar trabajos de clientes (ej. 5)
		- Umbral para el porcenaje de uso de disco que activa modo de limpieza agresiva (por defecto 70).
		- Ruta de BleachBit.
		- Clave en el registro para guardar datos de ejecución (HKLM:\SOFTWARE\PCBogota)

--- 🛫 EJECUCION!

Hoja de ruta definitiva (implementación)

Ajustes finales
- Integrar todo en clean-flexisign.ps1, probar, y verificar que Start-FlexiClean.ps1 apunte bien.
Commit: 8	Start-FlexiClean.ps1 / instalador	"Ajustes finales de integración y empaquetado"

2. Configuración de limpieza de carpetas: flexi-folders.psd1
Un solo archivo con un array de definiciones de carpetas a limpiar. Cada entrada será un hashtable con estas propiedades:


#>

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
if ($CleanerRootPath -imatch "\\Editions\\Flexisign") {
	$global:CleanerCorePath = (Resolve-Path "$PSScriptRoot\..\..\Core").Path
	$global:CleanerRootPath = (Resolve-Path "$PSScriptRoot\..\..").Path
}

Import-Module -DisableNameChecking "$global:CleanerCorePath\Modules\pcb-00-bootstrap.psm1" -Global -Force
Initialize-PcbCleanerExecution

# Cargar modulos adicionales del proyecto y variables globales
. "$global:CleanerCorePath\cleaner-initialize.ps1"
#endregion PCB bootstrap

# Flexisign edition initializer
$global:FlexiCleanerPath = "$PSScriptRoot\Flexisign-Cleaner"
. "$global:FlexiCleanerPath\flexiCleaner-initalize.ps1"



#region Bleachbit Installation
if ($Install) {
	Import-Module -DisableNameChecking "$global:CleanerCorePath\Modules\Cleaner-Install.psm1" -Global -Force
	Import-Module -DisableNameChecking "$global:CleanerCorePath\Modules\Cleaners\bleachbit-portable.psm1" -Global -Force
	Initialize-PCBRegistryPath -Auto:$Auto
	Set-InstallationDate -Auto:$Auto
	Set-CleanerHibernationStatus -Auto:$Auto -DisableHibernation:$DisableHibernation
	Install-BleachBit -Task:$Task -Auto:$Auto
	if ($Task) {
		New-CleanerScheduledTask -Auto:$Auto
	}
	exit
}

# Flexisign exclusive Test Area
# Flexisign exclusive Test Area
# Flexisign exclusive Test Area


# Importar TODOS los modulos de limpiadores para la edición flexisign
Get-ChildItem "$global:FlexiCleanerPath\Modules\*.psm1" | Import-Module -DisableNameChecking -Force

# Importar las carpetas de los limpiadores
$foldersList = (Import-PowerShellDataFile "$global:FlexiCleanerPath\Data\flexi-cleaner-folders.psd1").Folders
$foldersList | Remove-TempFolderSet

exit

if (Test-DrivesCritical -Drives Measure-alldrives) {
	$global:AggressiveMode = $true
	# Remover los temporales de flexisign en modo agresivo
	$foldersList | Remove-TempFolderSet
}



# Flexisign exclusive Test Area
# Flexisign exclusive Test Area
# Flexisign exclusive Test Area




#region Execution

# Importar TODOS los modulos de limpiadores comunes
Get-ChildItem "$global:CleanerCorePath\Modules\Cleaners\*.psm1" | Import-Module -DisableNameChecking -Force


# --- Fase 0: Evaluación del sistema ---
$initialSnapshotName = "Inicio de limpiador"
$initialShot = Set-Snapshot -Name $initialSnapshotName -Dates (Get-RegistryDates) -Return
$global:AggressiveMode = Test-DrivesCritical -Drives $initialShot.Drives
Show-PreCleanSystemSnapshot -Snapshot $initialShot
Set-SnapshotFinishTime -Name $initialSnapshotName

# --- Fase 1: Cierre de procesos comunes ---

Write-Host "`n$("="*([console]::WindowWidth - 1) )`n"
$processList = (Import-PowerShellDataFile "$CleanerCorePath\Data\processes-core.psd1").Processes

$flexiData = Import-PowerShellDataFile "$FlexiCleanerPath\Data\flexi-processes.psd1" -ErrorAction SilentlyContinue
if ($flexiData -and $flexiData.Processes) {
	$processList += $flexiData.Processes
}
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

# Flexisign edition initializer
##  Colocar funciones y ejecucuines de flexisign aqui!
##  Colocar funciones y ejecucuines de flexisign aqui!
##  Colocar funciones y ejecucuines de flexisign aqui!
##  Colocar funciones y ejecucuines de flexisign aqui!
##  Colocar funciones y ejecucuines de flexisign aqui!
##  Colocar funciones y ejecucuines de flexisign aqui!



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
