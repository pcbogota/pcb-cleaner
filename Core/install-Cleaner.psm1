function Get-BleachBit {
	# BleachBit download information
	try {
		# Get download URL
		$BleachBitData.OutputFile = Join-Path -Path $CleanerRootPath -ChildPath (Split-Path -Path $BleachBitData.OutputFile -Leaf)
		$BleachBitData = Get-DownloadURL $BleachBitData

		# Download portable file
		winfo "Descargando $($BleachBitData.name)..."
		Invoke-WebRequest -Uri ($BleachBitData.url) -OutFile ($BleachBitData.outputFile) -TimeoutSec 30
		winfo "Descomprimiendo archivo..."
		# unzip portable files
		Expand-Archive -Path $BleachBitData.outputFile -DestinationPath $CleanerRootPath -Force

		if (Test-Path $BleachBitData.outputFile) {
			Remove-Item -Path $BleachBitData.outputFile -Force
		}

		wok "Descarga completada."
	} catch {
		$title = "Error al obtener BleachBit"
		$text = "Se recomienda descargar la versión portable de BleachBit manualmente."
		wError $title
		wWarning $text
		if ($Auto) {
			Show-Notification $title $text -Type error -Duration long
		} else {
			Pause
		}
	}
}

function Get-DownloadURL {
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
		$Text = "No fue posible realizar la descarga del programa.`n`nInstalación terminada."
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

#endregion variables

function New-BleachBitConfig {
	try {
		wInfo "Generando archivo de configuración 'BleachBit.ini'..."
		$BleachBitiniFile = "$bleachbitPath\BleachBit.ini"

		# Generating BleachBit.ini File
		$configData = Import-PowerShellDataFile -Path "$PSScriptRoot\IniData.psd1"

		# initialize BleachBit.ini file
		"[Portable]`r`n" | Out-File -FilePath $BleachBitiniFile -Encoding utf8

		Add-Content $BleachBitiniFile "[bleachbit]"
		Add-Content $BleachBitiniFile ($configData.bleachbitIni.bleachbit -replace ("\|", "`r`n"))
		Add-Content $BleachBitiniFile "`r`n[tree]"
		Add-Content $BleachBitiniFile ($configData.bleachbitIni.tree -replace ("\|", "`r`n"))

		wInfo "Configurando archivo 'winapp2.ini'..."
		# Getting winamp2.ini
		$BleachBitWinApp2Path = "$bleachbitPath\cleaners"
		$BleachBitWinApp2File = "$BleachBitWinApp2Path\winapp2.ini"
		if (-not (Test-Path $BleachBitWinApp2Path ) ) {
			New-Item $BleachBitWinApp2Path -ItemType Directory | Out-Null
		}

		Invoke-WebRequest -Uri $WinappUrl -OutFile $BleachBitWinApp2File -TimeoutSec 30

		# Modifying Winamp2.ini (Comment lines with 'FileExts')
		$outputText = ((Get-Content $BleachBitWinApp2File) -replace '^.*FileExts.*$', ';$&') -join "`r`n"
		$utf8NoBom = New-Object System.Text.UTF8Encoding $false
		[System.IO.File]::WriteAllText($BleachBitWinApp2File, $outputText, $utf8NoBom)

		wok "Archivos de configuración completados."
	} catch {
		$text = $_
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

function New-CleanerScheduledTask {
	try {
		$scriptFullPath = "$CleanerRootPath\Start-BasicClean.ps1"
		$taskName = "PCBogota_Limpieza-De-Temporales"
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
		$text = "Hubo un fallo al inttenar registrar la tarea"
		$title = "Error al registrar la tarea para $($BleachBitData.Name)"
		wError $title
		wWarning $text
		if ($Auto) {
			Show-Notification $title $text -Type error -Duration long
		} else {
			Pause
		}
	}
}
