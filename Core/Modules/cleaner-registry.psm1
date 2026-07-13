# Lee las fechas desde HKLM:\SOFTWARE\PCBogota\PCB-Cleaner y las devuelve en un objeto pequeño.
function Get-RegistryDates {
	# Intentar leer ambos valores de una vez
	$prop = Get-ItemProperty -Path ($global:PCBregPath) -Name 'LastNormalClean', 'LastAgressiveClean' -ErrorAction SilentlyContinue

	# Construir objeto de retorno
	$Dates = [PSCustomObject]@{
		LastNormal    = if ($prop -and $prop.LastNormalClean) {
			ConvertFrom-UnixTime $prop.LastNormalClean
		} else {
			[datetime]::MinValue
		}
		LastAgressive = if ($prop -and $prop.LastAgressiveClean) {
			ConvertFrom-UnixTime $prop.LastAgressiveClean
		} else {
			[datetime]::MinValue
		}
	}
	return $Dates
}

function Set-RegistryDates {
	Initialize-PCBRegistryPath
	# Determinar qué propiedad actualizar
	if ($global:AggressiveMode) {
		$propName = 'LastAgressiveClean'
	} else {
		$propName = 'LastNormalClean'
	}

	# Obtener el timestamp Unix actual
	$timestamp = ConvertTo-UnixTime

	# Guardar como string en el registro
	Set-ItemProperty -Path $global:PCBregPath -Name $propName -Value $timestamp.ToString() -Type String
}

function Initialize-PCBRegistryPath {
	param([switch]$Auto)
	if (-not (Test-Path $global:PCBregPath)) {
		try {
			New-Item -Path $global:PCBregPath -Force | Out-Null
		} catch {
			wWarning "No se pudo crear la clave de registro $global:PCBregPath : $_"
			if (-not $auto) { Pause }
			return
		}
	}
}

function Set-CleanerHibernationStatus {
	param(
		[switch]$DisableHibernation,
		[switch]$Auto
	)
	Initialize-PCBRegistryPath -Auto:$Auto
	try {
		$value = if ($DisableHibernation) { 1 }else { 0 }
		Set-ItemProperty -Path $global:PCBregPath -Name 'DisableHibernation' -Value $value -Type DWord -Force
	} catch {
		$title = "Error al guardar dato de hibernación en el registro"
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

function Set-InstallationDate {
	<#
	.SYNOPSIS
		Crea la clave de registro del proyecto y guarda la fecha de instalación como timestamp Unix.
	.DESCRIPTION
		Usa la variable global $global:PCBregPath. Si la clave no existe, la crea.
		Guarda un valor 'InstallDate' de tipo REG_SZ con el timestamp actual.
	#>
	# Asegurarse de que la clave existe
	param([switch]$Auto)

	Initialize-PCBRegistryPath -Auto:$Auto

	$timestamp = ConvertTo-UnixTime   # asumiendo que esta función ya está disponible
	try {
		Set-ItemProperty -Path $global:PCBregPath -Name 'InstallDate' -Value $timestamp.ToString() -Type String
	} catch {
		$title = "Error al guardar InstallDate en el registro"
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
