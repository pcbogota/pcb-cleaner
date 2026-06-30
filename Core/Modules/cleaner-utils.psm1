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
			[datetime]'1970-01-01Z'.AddSeconds($seconds),
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
