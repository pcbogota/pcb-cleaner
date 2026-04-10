[CmdletBinding()]
param (
	[switch]$Install,
	[switch]$Auto
)
#region Functions

function Get-BleachBit {
	param (
		[object]$ProgramData,
		[switch]$Install,
		[switch]$Download
	)
	try {

		# Get download URL
		$ProgramData.OutputFile = Join-Path -Path $PSScriptRoot -ChildPath (Split-Path -Path $ProgramData.OutputFile -Leaf)

		$ProgramData = Get-DownloadURL $ProgramData

		# Download portable file
		Write-Verbose "Descargando $($ProgramData.name)..."
		Invoke-WebRequest -Uri ($ProgramData.url) -OutFile ($ProgramData.outputFile) -TimeoutSec 30
		Write-Host "Descomprimiendo archivo..."

		# unzip portable files
		Expand-Archive -Path $ProgramData.outputFile -DestinationPath $PSScriptRoot -Force

		if (Test-Path $ProgramData.outputFile) {
			Remove-Item -Path $ProgramData.outputFile -Force
		}

		Write-Host "Descarga completada. Espere..." -ForegroundColor Cyan
	} catch {
		$duration = Get-ItemProperty -Path 'HKCU:\Control Panel\Accessibility' -Name 'MessageDuration' -ErrorAction SilentlyContinue
		$totalTime = if ($duration.MessageDuration -is [int] -and $duration.MessageDuration -gt 0) {
			$duration.MessageDuration
		} else {
			5
		}
		Add-Type -AssemblyName System.Windows.Forms
		$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
		$notifyIcon.BalloonTipText = "Se recomienda descargar la versión portable de BleachBit manualmente."
		$notifyIcon.BalloonTipTitle = "❌ Error al obtener BleachBit"
		$notifyIcon.Icon = [System.Drawing.SystemIcons]::Error
		$notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Error
		$notifyIcon.Visible = $true
		$notifyIcon.ShowBalloonTip(($totalTime * 1000) * 2)
		$notifyIcon.Dispose()
	}
}

function Get-DownloadURL {
	param(
		[object]$ProgramData
	)
	$downloadDomain = 'https://download.bleachbit.org'
	$response = (Invoke-WebRequest -Uri $ProgramData.url).Links | Where-Object { $_.href -match $ProgramData.FileRegex }
	$BleachBitHref = $response.href
	try {
		$baseUrl = "^(https?://[^/]+)"
		if ($BleachBitHref) {
			# Get abosulte URL
			if ($BleachBitHref -notmatch $baseUrl) {
				if ($ProgramData.Url -match $baseUrl) {
					$domain = $matches[1]
					$BleachBitHref = "$domain$($BleachBitHref)"
				}
			}

			# Get File name from query (?file=...)
			if ($BleachBitHref -match "file=([^&]+)") {
				$fileName = $matches[1]
				# Construir URL final real de descarga
				$ProgramData.Url = "$downloadDomain/$fileName"
			}
		} else {
			Write-Warning "No se encontró un archivo compatible para $($ProgramData.Name)."
		}
	} catch {
		Write-Warning "No se pudo conectar a web de $($ProgramData.Name)."
	}
	return $ProgramData


}

function Get-FreeSpaceGB {
	$drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'"
	return [math]::Round($drive.FreeSpace / 1GB, 2)
}

function Set-SpaceMark {
	[CmdletBinding()]
	param (
		[string] $Name
	)
	$global:currentSpace = Get-FreeSpaceGB
	$global:results += "Limpieza de $($Name): $([math]::Round($global:currentSpace - $global:lastMark, 2)) GB"
	$global:lastMark = $global:currentSpace
}

function Get-SpaceMark {
	# --- FINAL LOG ---
	$global:currentSpace = Get-FreeSpaceGB
	$netGain = [math]::Round($global:currentSpace - $global:initialFreeSpace, 2)
	Write-Host "`n"
	Write-Host ("=" * 40) -ForegroundColor White
	Write-Host "RESUMEN DE LIMPIEZA" -ForegroundColor Green
	Write-Host ("=" * 40) -ForegroundColor White

	foreach ($line in $global:results) {
		Write-Host $line
	}
	Write-Host ("-" * 40) -ForegroundColor White

	$format = "{0,-25} | {1,7:N2} GB"
	Write-Host ($format -f "Espacio libre al iniciar", $global:initialFreeSpace) -ForegroundColor Cyan
	Write-Host ($format -f "Ganancia neta de espacio", $netGain) -ForegroundColor Yellow
	Write-Host ($format -f "Espacio libre actual", $global:currentSpace) -ForegroundColor Green
}
#endregion Functions

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

#region Variables
# --- Initial space variables ---
$global:initialFreeSpace = Get-FreeSpaceGB
$global:lastMark = $initialFreeSpace
$global:currentSpace = 0
$global:results = @()

# Paths
$bleachbitPath = "$PSScriptRoot\BleachBit-Portable"
$BleachBitiniFile = "$bleachbitPath\BleachBit.ini"
$bleachbitExec = "$bleachbitPath\bleachbit_console.exe"
$BleachBitWinApp2Path = "$bleachbitPath\cleaners"
$BleachBitWinApp2File = "$BleachBitWinApp2Path\winapp2.ini"
$chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
$windowsUpdateDownloadPath = "$($env:SystemRoot)\SoftwareDistribution\Download"

# BleachBit download information
$BleachBitData = @{
	Name       = "BleachBit Portable"
	Url        = "https://www.bleachbit.org/download/windows"
	FileRegex  = "BleachBit-.*-portable\.zip"
	OutputFile = "BleachBit_portable.zip"
}

#WinApp2 URL
$WinappUrl = "https://raw.githubusercontent.com/MoscaDotTo/Winapp2/master/Non-CCleaner/BleachBit/Winapp2.ini"
#endregion variables

#region Installation
if ($Install) {
	$taskName = "PCB_Limpieza De Windows"
	Write-Host "Instalando $taskName..."
	$scriptFullPath = "$PSScriptRoot\CleanTemps.ps1"
	$xml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Author>PCBogota</Author>
	<Description>Limpieza de Windows para equipo de Vanesa con 32GB de almacenamiento</Description>
    <URI>\$taskName</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <GroupId>S-1-5-32-544</GroupId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT30M</ExecutionTimeLimit>
    <Priority>4</Priority>
    <RestartOnFailure>
      <Interval>PT3H</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -ExecutionPolicy Bypass -File "$scriptFullPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
	Write-Warning "Registrando la tarea '$taskName'..."
	try {
		# Preparing BleachBit Portable
		Write-Host "Obteniendo BleachBit..." -ForegroundColor Cyan
		Get-BleachBit $BleachBitData

		# Generating BleachBit.ini File
		$configData = Import-PowerShellDataFile -Path "$PSScriptRoot\IniData.psd1"

		# initialize BleachBit.ini file
		"[Portable]`r`n" | Out-File -FilePath $BleachBitiniFile -Encoding utf8

		Add-Content $BleachBitiniFile "[bleachbit]"
		Add-Content $BleachBitiniFile ($configData.bleachbitIni.bleachbit -replace ("\|", "`r`n"))
		Add-Content $BleachBitiniFile "`r`n[tree]"
		Add-Content $BleachBitiniFile ($configData.bleachbitIni.tree -replace ("\|", "`r`n"))

		# Getting winamp2.ini
		if (-not (Test-Path $BleachBitWinApp2Path ) ) { New-Item $BleachBitWinApp2Path -ItemType Directory | Out-Null }
		Invoke-WebRequest -Uri $WinappUrl -OutFile $BleachBitWinApp2File -TimeoutSec 30

		# Modifying Winamp2.ini (Comment lines with 'FileExts')
		$outputText = ((Get-Content $BleachBitWinApp2File) -replace '^.*FileExts.*$', ';$&') -join "`r`n"
		$utf8NoBom = New-Object System.Text.UTF8Encoding $false
		[System.IO.File]::WriteAllText($BleachBitWinApp2File, $outputText, $utf8NoBom)
	} catch {
		Write-Host $_
		exit 1
	}
	try {
		Register-ScheduledTask -TaskName $taskName -Xml $xml -Force -ErrorAction Stop | Out-Null
		Write-Host "Tarea '$taskName' registrada con éxito." -ForegroundColor Green
		exit 0
	} catch {
		Write-Host "`n[!] ERROR CRÍTICO AL REGISTRAR LA TAREA" -ForegroundColor Red -BackgroundColor Black
		Write-Error "Detalle técnico: $($_.Exception.Message)"
		Write-Host "Ejecución terminada." -ForegroundColor Yellow
		if (-not $Auto) {
			Pause
		}
		exit 1
	}
}
#endregion installation

#region Execution

Write-Host "Iniciando mantenimiento preventivo de almacenamiento..." -ForegroundColor Yellow

# 0. Cerrar Chrome si está abierto (para poder borrar su caché)
$activeChromeProcesses = Get-Process -Name "chrome" -ErrorAction SilentlyContinue
if ($activeChromeProcesses) {
	Write-Host "Cerrando Google Chrome, necesario para liberar la caché..." -ForegroundColor Cyan
	$activeChromeProcesses | Stop-Process -Force
	Start-Sleep -Seconds 3  # Pequeña pausa para que suelte los archivos
}

# 1. Limpieza manual de Caché de Chrome (para no tocar el resto del perfil)
if (Test-Path $chromeCache) {
	Write-Host "Eliminando caché de Google Chrome..." -ForegroundColor Cyan
	Get-ChildItem -Path "$chromeCache\*" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}
Set-SpaceMark -Name "Google Chrome"

# 2. Ejecución de BleachBit basada en tus preferencias (.ini)
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

Set-SpaceMark -Name "Compatación de Sistema Operativo"  # Marca para espacio

# 7. Limpieza de la carpeta de descargas de Windows Update (SoftwareDistribution)
Write-Host "Verificando carpeta de descargas de Windows Update..." -ForegroundColor Cyan
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
Get-SpaceMark

Pause
exit
#endregion Execution
