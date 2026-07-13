function Get-BleachBit {
	param(
		[switch]$Auto,
		[object]$DownloadData
	)
	# BleachBit download process
	try {
		# Get download URL
		$DownloadData = Get-BleachBitDownloadURL $DownloadData

		# Download portable file
		winfo "Descargando $($DownloadData.name)..."
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

		$DownloadData.OutputFile = Join-Path -Path $global:CleanerRootPath $DownloadData.OutputFile
		Invoke-WebRequest -Uri ($DownloadData.url) -OutFile $DownloadData.OutputFile -TimeoutSec 30 -ErrorAction Stop

		# unzip portable files
		winfo "Descomprimiendo archivo..."

		Expand-Archive -Path $DownloadData.OutputFile -DestinationPath (Split-Path $DownloadData.OutputFile -Parent) -Force

		if (Test-Path $DownloadData.OutputFile) {
			Remove-Item -Path $DownloadData.OutputFile -Force
		}

		wok "Descarga completada."
	} catch {
		$title = "Error al obtener BleachBit"
		$text = $_.Exception.Message
		wError $title
		wWarning $text
		if ($Auto) {
			Show-Notification $title $text -Type error -Duration long
		} else {
			Pause
		}
	}
}

function Get-BleachBitDownloadURL {
	param(
		[object]$ProgramData
	)
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
				$ProgramData.Url = "$($ProgramData.DownloadDomain)/$fileName"
			}
		} else {
			wWarning "No se encontró un archivo compatible para $($ProgramData.Name)."
		}
	} catch {
		wWarning "No fue posible conectar a la web de $($ProgramData.Name)."
		$title = "Descarga de $($ProgramData.Name)"
		$Text = $_.Exception.Message
		if ($Auto) {
			Show-Notification -Title $title -Text $text -duration long -Type error
		} else {
			Pause
		}
		exit 1
	}
	$BleachBitHref = $BleachBitHref -replace "/get", ""
	$ProgramData.url = $BleachBitHref
	return $ProgramData
}

function New-BleachBitConfig {
	param(
		[object]$ConfigData,
		[string]$WinAppUrl,
		[switch]$Auto
	)
	if (-not $configData -or -not $WinAppUrl) {
		$bleachBitData = (Import-PowerShellDataFile -Path "$CleanerCorePath\Data\bleachbit-config.psd1")
		$configData = $bleachBitData.bleachbitIni
		$WinAppUrl = $bleachBitData.WinappUrl
	}

	$BleachBitiniFile = "$global:bleachbitPath\BleachBit.ini"
	try {
		# Generar BleachBit.ini y Winapp2.ini
		wInfo "Generando archivo de configuración 'BleachBit.ini'..."

		# Inizializar el archivo BleachBit.ini
		"[Portable]`r`n" | Out-File -FilePath $BleachBitiniFile -Encoding utf8

		Add-Content $BleachBitiniFile "[bleachbit]"
		Add-Content $BleachBitiniFile ($configData.bleachbit -replace ("\|", "`r`n"))
		Add-Content $BleachBitiniFile "`r`n[tree]"
		Add-Content $BleachBitiniFile ($configData.tree -replace ("\|", "`r`n"))

		wInfo "Configurando archivo 'winapp2.ini'..."

		# Obtener winamp2.ini
		$BleachBitWinApp2Path = "$global:bleachbitPath\cleaners"
		$BleachBitWinApp2File = "$BleachBitWinApp2Path\winapp2.ini"
		if (-not (Test-Path $BleachBitWinApp2Path ) ) {
			New-Item $BleachBitWinApp2Path -ItemType Directory | Out-Null
		}
		if ($global:connected) {
			Invoke-WebRequest -Uri $WinAppUrl -OutFile $BleachBitWinApp2File -TimeoutSec 30

			# Modificar Winamp2.ini (Comment lines with 'FileExts')
			$outputText = ((Get-Content $BleachBitWinApp2File) -replace '^.*FileExts.*$', ';$&') -join "`r`n"
			$utf8NoBom = New-Object System.Text.UTF8Encoding $false
			[System.IO.File]::WriteAllText($BleachBitWinApp2File, $outputText, $utf8NoBom)
		}
		wok "Archivos de configuración completados."
	} catch {
		$text = $_.Exception.Message
		$title = "Error al configurar $($BleachBitData.Name)"
		wError $title
		wWarning $text
		if ($Auto) {
			Show-Notification $title $text -Type error -Duration long
		} else {
			Pause
		}
	}
}

function Install-BleachBit {
	param(
		[switch]$Auto
	)
	#importar modulo de limpieza de bleachbit para configuración de configuradores (bleachbit.ini + winapp2.ini)
	#Import-Module -DisableNameChecking "$global:CleanerCorePath\Modules\cleaners\bleachbit-portable.psm1" -Force

	$oldProgressPreference = $ProgressPreference
	$global:ProgressPreference = 'SilentlyContinue'
	$global:connected = Test-Connection 1.1.1.1 -Delay 1 -Count 4 -ErrorAction SilentlyContinue

	#Cargar modulo y datos para instalación
	$ConfigData = Import-PowerShellDataFile -Path "$CleanerCorePath\Data\bleachbit-config.psd1"

	# Descargar BleachBit Portable
	wrun "Configurar $($ConfigData.bleachbitDownload.name)"
	$BBPortPath = "$global:bleachbitPath"

	# Descarga de BleachBit
	if ($global:connected) {
		Get-BleachBit -Auto:$Auto -DownloadData $ConfigData.bleachbitDownload
	} else {
		$Auto = $true
		$instructionsPath = "$CleanerCorePath\Data\bleachbit-manual-instructions.txt"
		$ErrTitle = "Error al descargar Bleachbit"
		$ErrText = "Sigue las instrucciones en el archivo de texto"
		if ($Auto) {
			Show-Notification $ErrTitle $ErrText -Type error -Duration long
		} else {
			Wwarning "$ErrTitle. $ErrText."

		}
		do {
			if (-not (Test-Path $BBPortPath -PathType Container)) {
				New-Item $BBPortPath -ItemType Directory | Out-Null
			}
			if (Test-Path $instructionsPath) {
				Start-Process notepad.exe -ArgumentList $instructionsPath -Wait
			}
		}while (-not (Test-Path "$BBPortPath\bleachbit.exe"))
	}

	# Configuración de bleachbit.ini + Winapp2.ini
	if (Test-Path "$BBPortPath\bleachbit.exe") {
		New-BleachBitConfig -ConfigData $ConfigData.bleachbitIni -WinAppUrl $ConfigData.WinappUrl -Auto:$Auto
	}
	$global:ProgressPreference = $oldProgressPreference
	wWarning "Configuración de $($BleachBitData.Name) terminada."
}

function New-CleanerScheduledTask {
	param(
		[switch]$Auto
	)
	try {
		$scriptFullPath = "$CleanerRootPath\Start-BasicClean.ps1"
		$taskName = "PCBogota_Limpieza-de-temporales"
		wInfo "Registrando la tarea '$taskName'..."
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
		Register-ScheduledTask -TaskName $taskName -Xml $xml -Force -ErrorAction Stop | Out-Null
		wok "Tarea '$taskName' registrada con éxito."
	} catch {
		$text = $_.Exception.Message
		$title = "Error al registrar la tarea para $taskName"
		wError $title
		wWarning $text
		if ($Auto) {
			Show-Notification $title $text -Type error -Duration long
		} else {
			Pause
		}
	}
}
