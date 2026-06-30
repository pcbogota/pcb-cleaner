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
$install = $true
#region Bleachbit Installation
if ($Install) {
	Import-Module -DisableNameChecking "$CleanerCorePath\Modules\Cleaner-Install.psm1" -Global -Force
	Install-BleachBit -Task:$Task
	exit
}
#endregion installation

#region Execution

<#
🔴 FASE 0 — EVALUACIÓN INICIAL (SIEMPRE)
	- leer del registro en HKLM:\SOFTWARE\PCBogota
		- Ultima limpieza normal (fecha)
		- Ultima limpieza agresiva (fecha)
		(Si ninguno colocar 0)
		- Mostrar en pantalla ultima vez que se ejecutó la limpieza normal y agresiva
 			Si es 0, texto que demuestre que es la primera ejecución, si hay fechas mostrar y guardar tipo 2020-Jun-20 16:48)
			Mostrar tiempo desde última ejecución, si el tiempo es menor a 1 día, mostrar horas.
		- Medir espacio total, usado y libre por cada disco (C:, D:, etc.).
	- Calcular % de uso para cada Unidad.
	- Guardar estas cifras para el informe final (en memoria/variable).
	- Decidir modo de ejecución:
		- Normal: todas las unidades de almacenamiento con uso menor a umbral de porcentaje de uso.
		- Modo Agresivo: si algún disco ≥ umbral → activa automáticamente limpiezas extra y reducción de sesiones a 1.
#>



# --- Fase -1: Pruebas Locas ---


# --- Fase 0: Evaluación del sistema---
$initialShot = Set-Snapshot -Name "Inicial" -Dates (Get-RegistryDates) -Return

Set-Snapshot -Name "PreLimpieza"
$global:AgressiveMode = Test-DrivesCritical -Drives $initialShot.Drives

# Mostrar en pantalla el resumen inicial
Show-PreCleanSystemSnapshot -Snapshot $initialShot



exit

wError "¿Hay cositas en 'basic-clean.psm1'?"
exit

Write-Host "Iniciando mantenimiento preventivo de almacenamiento..." -ForegroundColor Yellow

# 0. Cerrar Chrome si está abierto (para poder borrar su caché)
$activeChromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
if ($activeChromeProcesses) {
	Write-Host "Cerrando Google Chrome, necesario para liberar la caché..." -ForegroundColor Cyan
	$activeChromeProcesses | Stop-Process -Force
	Start-Sleep -Seconds 3  # Pequeña pausa para que suelte los archivos
}


$global:AgressiveMode = Test-DrivesCritical -Drives (Measure-AllDrives) -Threshold $global:Threshold
exit

# 1. Limpieza manual de Caché de Chrome (para no tocar el resto del perfil)
$chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
if (Test-Path $chromeCache) {
	Write-Host "Eliminando caché de Google Chrome..." -ForegroundColor Cyan
	Get-ChildItem -Path "$chromeCache\*" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}
Set-SpaceMark -Name "Google Chrome"

# 2. Ejecución de BleachBit basada en tus preferencias (.ini)
$bleachbitExec = "$bleachbitPath\bleachbit_console.exe"
if (Test-Path $bleachbitExec) {
	Write-Host "Ejecutando limpieza programada en BleachBit. Espera..." -ForegroundColor Cyan
	# --preset carga las casillas marcadas.
	# --clean ejecuta la limpieza.
	Start-Process -FilePath $bleachbitExec -ArgumentList "--clean", "--preset" -Wait
}
Set-SpaceMark -Name "Bleachbit" # Marca para espacio

# 3. Limpieza de componentes de Windows (WinSxS)
# Es la parte más lenta pero la que más espacio recupera
Write-Host "Compactando almacén de componentes de Windows (DISM). Espera..." -ForegroundColor Cyan
dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
Set-SpaceMark -Name "WinSxS (DISM)"  # Marca para espacio

# 4. Vaciar Papelera de Reciclaje
Write-Host "Vaciando papelera..." -ForegroundColor Cyan
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Set-SpaceMark -Name "Papelera de Reciclaje"  # Marca para espacio

# 5. Desactivar hibernación si está activa (ahorra espacio = tamaño de la RAM)
Write-Host "Verificando estado de la hibernación..." -ForegroundColor Cyan
Write-Host "  Desactivando para liberar espacio..." -ForegroundColor Yellow
powercfg /h off
Write-Host "  Hibernación desactivada." -ForegroundColor Green
Set-SpaceMark -Name "Hibernacion"  # Marca para espacio

# 6. Compactación del sistema operativo (CompactOS)
Write-Host "Verificando estado de compactación del sistema..." -ForegroundColor Cyan
$compactStatus = compact /compactos:query
if ($compactStatus -imatch "El sistema se encuentra en el estado compacto") {
	Write-Host "compactación ya está activo. Omitiendo..." -ForegroundColor Green
} else {
	Write-Host "compactación no está activo. Comprimiendo sistema para ganar espacio..." -ForegroundColor Yellow
	compact /compactos:always
	Write-Host "Compactación completada." -ForegroundColor Green
}

#Forzar el mantenimiento de limpieza de WinSxS de forma silenciosa:
schtasks /run /tn "\Microsoft\Windows\Servicing\StartComponentCleanup" | Out-Null

Set-SpaceMark -Name "Compactación de Sistema Operativo"  # Marca para espacio

# 7. Limpieza de la carpeta de descargas de Windows Update (SoftwareDistribution)
Write-Host "Verificando carpeta de descargas de Windows Update..." -ForegroundColor Cyan
$windowsUpdateDownloadPath = "$($env:SystemRoot)\SoftwareDistribution\Download"
if (Test-Path $windowsUpdateDownloadPath) {
	# Comprobar si hay actualizaciones pendientes (método simple: ver si el servicio wuauserv está procesando)
	Write-Host "Eliminando contenido de actualizaciones de Windows..." -ForegroundColor Cyan
	# Detener el servicio Windows Update para poder borrar sin problemas
	Stop-Service -Name "wuauserv", "bits" -Force -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 2
	if (Test-Path $windowsUpdateDownloadPath) {
		Get-ChildItem -Path $windowsUpdateDownloadPath -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
	}
	# Reiniciar el servicio (Windows lo reiniciará cuando necesite, no es necesario hacerlo).
}
Set-SpaceMark -Name "carpeta de descargas de Windows Update"  # Marca para espacio

# 8. Limpieza con el limpiador de sistema de Windows
Write-Host "Ejecutando el limpiador de sistema de Windows. Espera..." -ForegroundColor Cyan
$volumeCaches = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
foreach ($key in $volumeCaches) {
	Set-ItemProperty -Path $key.PSPath -Name "StateFlags0001" -Value 2 -Type DWord -ErrorAction SilentlyContinue
}

Start-Process -FilePath "cleanmgr" -ArgumentList "/sagerun:1" -Wait -NoNewWindow

Set-SpaceMark -Name "con el limpiador de sistema de Windows"  # Marca para espacio
Write-Host "Proceso finalizado. Espacio optimizado." -ForegroundColor Green

if ($activeChromeProcesses) {
	Start-Process chrome
}

# Obtener resumen de espacio
#Set-SnapshotFinishTime -Name "Initial"

Get-SpaceMark

Pause
exit
#endregion Execution
