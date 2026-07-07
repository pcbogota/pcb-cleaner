# Obtiene todas las unidades de disco fijas y llama a Measure-SingleDrive para cada una.
function Measure-AllDrives {
	<#
	.SYNOPSIS
		Obtiene métricas de todas las unidades de disco fijas del sistema.
	.OUTPUTS
		Array de PSCustomObject con métricas de cada unidad.
	#>

	# Obtener solo discos locales fijos (DriveType = 3)
	$logicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk `
		-Filter "DriveType=3" `
		-ErrorAction SilentlyContinue

	if (-not $logicalDisks) {
		return @()
	}

	$resultados = foreach ($disk in $logicalDisks) {
		Measure-SingleDrive -DriveLetter $disk.DeviceID
	}

	# Filtrar nulos (unidades sin datos) y devolver como array limpio
	return @($resultados | Where-Object { $_ -ne $null })
}

# Mide espacio en un disco concreto y devuelve un PSCustomObject con métricas.
function Measure-SingleDrive {
	<#
	.SYNOPSIS
		Obtiene métricas de espacio para una unidad lógica.
	.PARAMETER DriveLetter
		Letra de la unidad (ej. "C:").
	.OUTPUTS
		PSCustomObject con Letra, TotalGB, LibreGB, PorcentajeUso, o $null si no se puede leer.
	#>
	param(
		[string]$DriveLetter
	)

	# Intentar obtener información de la unidad mediante CIM (compatible con PS 5.1)
	try {
		$disk = Get-CimInstance -ClassName Win32_LogicalDisk `
			-Filter "DeviceID='$DriveLetter'" `
			-ErrorAction Stop
	} catch {
		return $null
	}

	# Si no se encuentra o el tamaño es cero (ej. unidad de CD vacía), omitir
	if (-not $disk -or $disk.Size -le 0) {
		return $null
	}

	$totalBytes = $disk.Size
	$freeBytes = $disk.FreeSpace
	$usedBytes = $totalBytes - $freeBytes

	$totalGB = [math]::Round($totalBytes / 1GB, 2)
	$freeGB = [math]::Round($freeBytes / 1GB, 2)
	$usePercent = [math]::Round(($usedBytes / $totalBytes) * 100, 2)

	return [PSCustomObject]@{
		Letter = $DriveLetter
		Total  = $totalGB
		Free   = $freeGB
		"Used" = $usePercent
	}
}

function Test-DrivesCritical {
	param(
		[object[]]$Drives,
		[double]$Threshold = $global:Threshold
	)
	# ¿Alguna unidad supera o iguala el umbral?
	foreach ($d in $Drives) {
		if ($d.Used -ge $Threshold) {
			return $true
		}
	}
	return $false
}


function Get-CriticalDrivesLetter {
	param(
		[object[]]$Drives,
		[double]$Threshold = $global:Threshold
	)
	$CriticalDrives = @()
	foreach ($d in $Drives) {
		if ($d.Used -ge $Threshold) {
			$CriticalDrives += $d.Letter
		}
	}
	if ($CriticalDrives.Count -ge 1) {
		return $CriticalDrives
	}
	return $false
}
