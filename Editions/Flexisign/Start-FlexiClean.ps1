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
- Crear flexi-processes.psd1 con los procesos Flexisign/PrintExpert que quieras incluir de fábrica (aunque luego se editen).
Commit: 1	flexi-processes.psd1 (nuevo)	"Agrega configuración de procesos RIP para edición Flexisign"

- Crear flexi-folders.psd1 con las entradas de carpetas temporales del RIP y de trabajos de clientes (valores por defecto).
Commit: 2	flexi-folders.psd1 (nuevo)	"Añade definición de carpetas a limpiar (sesiones y antigüedad)"


Fase 1 – Cierre de procesos
- En clean-flexisign.ps1, cargar flexi-processes.psd1, filtrar por Scope='Initial' y llamar a Stop-ProcessGracefully por cada uno.
Commit: 3	clean-flexisign.ps1 (Fase 1)	"Implementa cierre controlado de procesos desde flexi-processes.psd1"

Fase 2 – Limpieza de temporales RIP (sesiones)
- Recorrer flexi-folders.psd1 donde RetentionUnit = 'Sessions'.
Commit: 4	clean-flexisign.ps1 (Fase 2, solo normal)	"Limpieza de temporales RIP por sesiones (4 en modo normal)"

- Crear función Clear-RIPSessionFolders que implemente el agrupamiento diario y borre según RetentionValueNormal o Aggressive.
Commit: 5	mismo script (Fase 2, agresivo)	"Soporte para modo agresivo en limpieza por sesiones (1 sesión)"

Fase 3 – Trabajos de clientes (días)
- Mismo bucle sobre las entradas con RetentionUnit = 'Days', llamar a una función que elimine carpetas/archivos antiguos (puede reutilizar Clear-FolderContent si conviene, o directamente Remove-Item filtrado).
Commit: 6	clean-flexisign.ps1 (Fase 3)	"Eliminación de trabajos de clientes por antigüedad configurable"

Fase 4 – Reintento agresivo
- Si el modo es agresivo, volver a ejecutar la limpieza de las entradas de sesiones pero forzando RetentionValueAggressive (1 sesión).
Commit: 7	clean-flexisign.ps1 (Fase 4)	"Reintento de limpieza de sesiones en modo agresivo"

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


$targetFolder = "e:\.MyBackup"
$ActivityDays = 3  # Hoy + 2 días de trabajo
$SecureSessions = 10  # Tu límite de 10 sesiones de uso

function Remove-TempElements {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateSet("File", "Directory")]
		[string]$type
	)
	# 1. Obtener todas las fechas de actividad disponibles en la carpeta

	$params = @{
		Path    = $Path
		Recurse = $true
	}
	if ($type.ToLower() -eq "file") {
		$params.File = $true
	} else {
		$params.Directory = $true
	}

	# 1. Obtener todas las fechas de actividad disponibles en la carpeta
	$elements = Get-ChildItem @params | Select-Object FullName, @{Name = "Fecha"; Expression = { $_.LastWriteTime.Date } }
	$ActivitySessions = $elements | Select-Object -ExpandProperty Fecha -Unique | Sort-Object -Descending

	# 2. Borrado de archivos basándose solo en sesiones"
	if ($ActivitySessions.Count -gt $ActivityDays) {
		# Borrar archivos que pertenezcan a sesiones más antiguas que las 3 guardadas
		$RemoveFilesDates = $ActivitySessions | Select-Object -Skip $ActivityDays

		foreach ($Date in $RemoveFilesDates) {
			$elements | Where-Object { $_.Fecha -eq $Date } | ForEach-Object {
				Write-Host $_.FullName
				# Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
			}
		}
	}
}
# Remove-TempElements -Path $targetFolder -Type "File"


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


Start-ReopenedProcesses

# Flexisign exclusive Test Area
# Flexisign exclusive Test Area
# Flexisign exclusive Test Area


# Importar TODOS los modulos de limpiadores para la edición flexisign
Get-ChildItem "$global:FlexiCleanerPath\Modules\*.psm1" | Import-Module -DisableNameChecking -Force



exit



# Flexisign exclusive Test Area
# Flexisign exclusive Test Area
# Flexisign exclusive Test Area




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
