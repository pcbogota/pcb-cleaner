# Lee las fechas desde HKLM:\SOFTWARE\PCBogota\PCB-Cleaner y las devuelve en un objeto pequeño.
function Get-RegistryDates {
	# Ruta del registro donde se guardan las fechas
	$regPath = 'HKLM:\SOFTWARE\PCBogota\PCB-Cleaner'

	# Intentar leer ambos valores de una vez
	$prop = Get-ItemProperty -Path $regPath -Name 'LastNormalClean', 'LastAgressiveClean' -ErrorAction SilentlyContinue

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
	#$regPath = 'HKLM:\SOFTWARE\PCBogota\PCB-Cleaner'
	#$props = @('LastNormalClean', 'LastAgressiveClean')

}
