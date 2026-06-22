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

Write-Host "go-Install"
exit
$BleachBitiniFile = "$bleachbitPath\BleachBit.ini"
$BleachBitWinApp2Path = "$bleachbitPath\cleaners"
$BleachBitWinApp2File = "$BleachBitWinApp2Path\winapp2.ini"

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

$taskName = "PCB_Limpieza De Windows"
Write-Host "Instalando $taskName..."

exit

<#

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
#>
