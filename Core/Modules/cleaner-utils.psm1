# ============================================================
# Módulo: cleaner-utils.psm1
# Propósito: Funciones genéricas de utilidad para el Cleaner.
# ============================================================

function ConvertFrom-UnixTime {
	<#
	.SYNOPSIS
		Convierte un timestamp Unix (segundos desde 1970-01-01 UTC) a DateTime local.
	.PARAMETER Timestamp
		String o entero con el timestamp en segundos.
	.OUTPUTS
		[datetime] Fecha en hora local, o [datetime]::MinValue si la conversión falla.
	#>
	param(
		[Parameter(Mandatory)]
		[string]$Timestamp
	)
	if (-not $Timestamp) { return [datetime]::MinValue }
	try {
		$seconds = [long]$Timestamp
		return [datetime]::SpecifyKind(
			([datetime]'1970-01-01Z').AddSeconds($seconds),
			[DateTimeKind]::Utc
		).ToLocalTime()
	} catch {
		return [datetime]::MinValue
	}
}

function ConvertTo-UnixTime {
	<#
	.SYNOPSIS
		Convierte un DateTime a timestamp Unix (segundos desde 1970-01-01 UTC).
	.PARAMETER Date
		Fecha a convertir. Por defecto, ahora.
	.PARAMETER AsUtc
		Si se especifica, trata la fecha como UTC sin conversión adicional.
	.OUTPUTS
		[long] Timestamp Unix en segundos.
	#>
	param(
		[datetime]$Date = [datetime]::Now,
		[switch]$AsUtc
	)
	if ($AsUtc) {
		$utcDate = $Date
	} else {
		$utcDate = $Date.ToUniversalTime()
	}
	return [long]($utcDate - [datetime]'1970-01-01Z').TotalSeconds
}

function Invoke-ConsoleTool {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$FilePath,
		[string]$ArgumentList,

		[ValidateSet('Normal', 'Hidden', 'Minimized')]
		[string]$WindowStyle = 'Normal',
		[switch]$Wait,

		[switch]$Log,
		[string]$LogPath,
		[string]$ProcessName
	)

	# --- Si -Log está activo, derivar ProcessName si no se ha indicado ---
	if ($Log -and -not $ProcessName) {
		$ProcessName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
	}

	# --- Preparar ruta de log si es necesario ---
	$logFullPath = $null
	if ($Log) {
		$logDir = if ($LogPath) { $LogPath } else { Join-Path $global:CleanerRootPath "Logs" }
		if (-not (Test-Path $logDir)) {
			New-Item -ItemType Directory -Path $logDir -Force | Out-Null
		}
		$timestamp = Get-Date -Format "yyyy_MM_dd__HH-mm-ss"
		$logFileName = "${timestamp}__$ProcessName.txt"
		$logFullPath = Join-Path $logDir $logFileName
	}

	# --- Ejecución según necesidad ---
	if (-not $Log) {
		# Sin log: ejecución directa, sencilla
		$startParams = @{
			FilePath    = $FilePath
			WindowStyle = $WindowStyle
			Wait        = $Wait
		}
		if ($ArgumentList) {
			$startParams.ArgumentList = $ArgumentList
		}

		Start-Process @startParams
		return
	}

	if ($ArgumentList) {
		$psArgsPart = " $ArgumentList"
	} else {
		$psArgsPart = ""
	}

	# Construir comando PowerShell que ejecuta la herramienta y divide la salida
	$psCommand = "[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(1252); & '$FilePath'$psArgsPart 2>&1 | Tee-Object -FilePath '$logFullPath'"

	# Codificar en Base64 para evitar problemas con comillas y caracteres especiales
	$bytes = [System.Text.Encoding]::Unicode.GetBytes($psCommand)
	$encodedCmd = [Convert]::ToBase64String($bytes)

	$psArgs = "-NoProfile -WindowStyle $WindowStyle -EncodedCommand $encodedCmd"
	$proc = Start-Process powershell.exe -ArgumentList $psArgs -Wait:$Wait -PassThru

	if ($Wait -and $proc.ExitCode -ne 0) {
		wWarning "$ProcessName finalizó con código de error $($proc.ExitCode)."
		Winfo "   Detalles en: $logFullPath"
	}
}


function Clear-FolderContent {
	param(
		[string]$Path,
		[string]$LogPrefix
	)
	$txt = "Limpiando "
	$txt += if ($null -eq $LogPrefix) { $path } else { $LogPrefix }
	$txt += "..."
	if (Test-Path $Path) {
		wWarning "$txt" -Wider
		Remove-Item -Path "$Path\*" -Recurse -Force -ErrorAction SilentlyContinue
	}
}
