
# ============================================================
# Módulo: cleaner-display.psm1
# Propósito: Funciones de presentación para PCB Cleaner
# ============================================================

# ============================================================
# Funciones auxiliares privadas
# ============================================================

function Format-CustomDate {
	param(
		[Parameter(Mandatory)]
		[datetime]$Date,

		[switch]$LongDate,
		[switch]$LongTime,
		[switch]$NoTime,
		[switch]$OnlyTime
	)

	# Meses en español (primera letra mayúscula)
	$months = @('Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio',
		'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre')

	# --- Parte de fecha ---
	$anio = $Date.Year

	if ($LongDate) {
		# Formato largo: "Abril 29 de 2026"
		$fechaStr = "{0} {1} de {2}" -f ($months[$Date.Month - 1]), $Date.Day, $anio
	} else {
		# Formato corto: "29/Abr/2026"
		$mesAbreviado = $months[$Date.Month - 1].Substring(0, 3)  # "Abr"
		$fechaStr = "{0}/{1}/{2}" -f $Date.Day, $mesAbreviado, $anio
	}

	# --- Parte de hora ---
	$horaStr = $Date.ToString('h:mm tt').ToUpper()  # "3:40 PM" (sin segundos)
	if ($LongTime) {
		$horaStr = $Date.ToString('HH:mm:ss').ToUpper()  # "3:40:13 PM" (con segundos y formato 24 horas)
	}

	# --- Combinación según switches ---
	if ($OnlyTime) {
		return $horaStr
	}
	if ($NoTime) {
		return $fechaStr
	}

	return "{0} - {1}" -f $fechaStr, $horaStr
}

function Format-ElapsedTime {
	param(
		[Parameter(Mandatory)]
		[datetime]$Start,
		[datetime]$End = (Get-Date),
		[switch]$Short
	)

	$diff = $End - $Start

	$parts = @()
	if ($diff.Days -gt 0) {
		$parts += if ($Short) {
			"$($diff.Days)d"
		} else {
			"$($diff.Days) $(Get-Pluralize ($diff.Days) 'día')"
  }
	}
	if ($diff.Hours -gt 0) {
		$parts += if ($Short) {
			"$($diff.Hours)h"
		} else {
			"$($diff.Hours) $(Get-Pluralize ($diff.Hours) 'hora')"
  }
	}
	if ($diff.Minutes -gt 0) {
		$parts += if ($Short) {
			"$($diff.Minutes)m"
		} else {
			"$($diff.Minutes) $(Get-Pluralize ($diff.Minutes) 'minuto')"
		}
	}
	if ($diff.Seconds -gt 0 -or $parts.Count -eq 0) {
		$parts += if ($Short) {
			"$($diff.Seconds)s"
		} else {
			"$($diff.Seconds) $(Get-Pluralize ($diff.Seconds) 'segundo')"
		}
	}

	$result = if ($Short) { $parts -join ' ' } else { $parts -join ', ' }
	return $result
}

function Format-ReadableSize {
	param([double]$GB)
	if ($GB -ge 1024) { return "{0:N2} TB" -f ($GB / 1024) }
	return "{0:N2} GB" -f $GB
}

function Format-TimeSince {
	param(
		[Parameter(Mandatory)]
		[datetime]$Since
	)
	$diff = (Get-Date) - $Since
	$relativeText = "Hace "
	if ($diff.TotalDays -ge 1) {
		$cantidad = [math]::Floor($diff.TotalDays)
		$relativeText += "$cantidad $(Get-Pluralize $cantidad 'día')"
	} elseif ($diff.TotalHours -ge 1) {
		$cantidad = [math]::Floor($diff.TotalHours)
		$relativeText += "$cantidad $(Get-Pluralize $cantidad 'hora')"
	} elseif ($diff.TotalMinutes -ge 1) {
		$cantidad = [math]::Floor($diff.TotalMinutes)
		$relativeText += "$cantidad $(Get-Pluralize $cantidad 'minuto')"
	} else {
		$relativeText += 'unos instantes'
	}
	return $relativeText
}

function Get-SimpleDriveTable {
	param(
		[object[]]$Drives,
		[double]$Threshold = $global:Threshold
	)
	$Lines = @()
	$ColorText = $global:TerminalColor.txt
	$ColorReset = $global:TerminalColor.reset
	foreach ($d in $Drives) {
		$color = if ($d.Used -ge $Threshold) { $ColorText.Orange }else { $ColorReset }
		$lines += [PSCustomObject]@{
			Letra = Write-ColoredText -Text ($d.Letter) -AnsiColor $color -Return
			Total = Write-ColoredText -Text (Format-ReadableSize $d.Total) -AnsiColor $color -Return
			Libre = Write-ColoredText -Text (Format-ReadableSize $d.Free) -AnsiColor $color -Return
			Uso   = Write-ColoredText -Text ("{0:N2} %" -f $d.Used) -AnsiColor $color -Return
		}
	}
	Write-DynamicTable -Data $lines -Header -Separator "  ║  "
}

function Get-Pluralize {
	param(
		[double]$Number,
		[string]$Singular
	)

	# Diccionario de plurales (solo las palabras usadas en el proyecto)
	$pluralMap = @{
		'dia'      = 'días'
		'día'      = 'días'
		'hora'     = 'horas'
		'minuto'   = 'minutos'
		'segundo'  = 'segundos'
		'instante' = 'instantes'
		'giga'     = 'gigas'
		'programa' = 'programas'
	}

	# Si es 1, devolver singular tal cual
	if ($Number -eq 1) {
		return $Singular
	}

	# Si está en el diccionario, devolver plural
	if ($pluralMap.ContainsKey($Singular)) {
		return $pluralMap[$Singular]
	}

	# Regla genérica: añadir 's' o 'es'
	if ($Singular -match '[aeiouáéíóú]$') {
		return $Singular + 's'
	}

	if ($Singular -match '[z]$') {
		$word = $Singular.Substring(0, $Singular.Length - 1)
		return $word + 'ces'
	}

	return $Singular + 'es'
}

function Get-VisibleLength {
	param([string]$Text)
	# Elimina códigos de escape ANSI para medir longitud real
	$plain = $Text -replace '\e\[[0-9;]*m', ''
	return $plain.Length
}

function New-TableLine {
	param(
		[string[]]$Columns,
		[hashtable]$MaxWidths,
		[hashtable]$Values,
		[string]$Separator = ' | ',
		[switch]$header
	)
	$parts = @()

	foreach ($col in $Columns) {
		$w = $MaxWidths[$col]
		$raw = $Values[$col]
		$val = if ($null -eq $raw) { '' } else { [string]$raw }
		$lenVisible = Get-VisibleLength $val
		$padNeeded = $w - $lenVisible
		if ($padNeeded -gt 0) {
			$val += ' ' * $padNeeded
		}
		$parts += $val
	}

	$line = ($parts -join $Separator)
	if (-not $header) {
		$line = $line.TrimEnd().TrimEnd($Separator)
	}
	return $line
}

function Show-CleaningContext {
	param(
		[object]$snapshop
	)
	# Simplifación de la valiable de colores de texto globales
	$color = $global:TerminalColor.txt
	$agress = $global:AggressiveMode

	# Array para almacenar las líneas a mostrar
	$lines = @()

	# Datos de limpiezas anteriores registradas
	$lastNormal = $Snapshot.Dates.LastNormal
	$lastAggres = $Snapshot.Dates.LastAgressive

	$last = if ($lastNormal -gt $lastAggres) { $lastNormal } else { $lastAggres }
	# Línea de información de "última limpieza"
	if ($last -eq [datetime]::MinValue) {
		$value = Write-ColoredText -Text "Nunca" -AnsiColor $Color.Red -Return
		$lastDate = $null
	} else {
		$diff = (Get-Date) - $last
		if ($diff.Totaldays -ge 7) {
			$cl = $Color.red
		} elseif ($diff.Totaldays -ge 4) {
			$cl = $Color.Orange
		} elseif ($diff.Totaldays -ge 2) {
			$cl = $Color.Yellow
		} else {
			$cl = $global:TerminalColor.Reset
		}

		$text = Format-TimeSince $last
		$lastDate = Format-CustomDate $last -LongDate
		$value = Write-ColoredText -Text $text -AnsiColor $cl -Return
	}

	# Agregar información de 'última limpieza' al arreglo de lineas
	$lines += [PSCustomObject]@{
		Label = "Última limpieza: "
		Value = $value
		Info  = $lastDate
	}

	# Modo de limpieza (Agresivo/Normal)
	if ($agress) {
		$value = Write-ColoredText -Text 'AGRESIVA*' -AnsiColor $Color.Orange -Return
		$Reason = Write-ColoredText -Text "Más de $global:Threshold% de uso en alguna unidad" -AnsiColor $Color.Orange -Return
	} else {
		$value = Write-ColoredText -Text 'NORMAL' -AnsiColor $Color.cyan -Return
	}
	# Agregar información de 'modo' al arreglo de lineas
	$lines += [PSCustomObject]@{ Label = "Modo requerido: "; Value = ("Limpieza " + $value) ; Info = $Reason }

	# Información en modo agresivo de ultimo modo agresivo realizado
	if ($agress -and $lastAggres -ne [datetime]::MinValue -and $lastAggres -ne $last) {
		$text = Format-TimeSince $lastAggres
		$lastDate = Format-CustomDate $lastAggres -LongDate
		$calcTime = Write-ColoredText -Text $text -AnsiColor $Color.green -Return
		# Agregar información de 'última agresiva' al arreglo de lineas
		$lines += [PSCustomObject]@{ Label = "Última limpieza agresiva: "; Value = $calcTime; Info = "$lastDate" }
	}
	Write-DynamicTable $lines
	if ($agress) {
		$ColorInfo = Write-ColoredText -Text '*La limpieza agresiva' -AnsiColor $Color.Orange -NoNewline -Return
		Write-Host "$ColorInfo NO GARANTIZA que se reduzca el uso en una unidad."
	}
}

function Show-ReportHeader {
	param(
		[object[]]$Snapshots = $global:snapshots
	)
	$color = $global:TerminalColor.txt
	if ($Snapshots.Count -eq 0) { return }

	$endTime = ($Snapshots | Where-Object { $_.Dates.finish -ne [datetime]::MinValue } | Select-Object -Last 1).Dates.finish
	if (-not $endTime) { $endTime = Get-Date }

	# Tiempo de ejecución
	$timeElapsed = Format-ElapsedTime -Start ($Snapshots[0].Dates.start) -End $endTime -Short
	Write-Host " -- Tiempo total de ejecución : " -NoNewline
	Write-ColoredText -Text $timeElapsed -AnsiColor $color.blue

	# Espacio total liberado (entre el último y el primer snapshot)
	$firstDrives = $Snapshots[0].Drives
	$lastDrives = $Snapshots[-1].Drives
	$totalLiberado = 0
	foreach ($ld in $lastDrives) {
		$fd = $firstDrives | Where-Object Letter -EQ $ld.Letter
		if ($fd) { $totalLiberado += ($ld.Free - $fd.Free) }
	}

	Write-Host " -- Espacio total liberado : " -NoNewline
	$FreeSpaceText = @{
		Text = Format-ReadableSize $totalLiberado
	}
	if ($totalLiberado -gt 0) {
		$FreeSpaceText.AnsiColor = $color.green
	} elseif ($totalLiberado -lt -1) {
		$FreeSpaceText.AnsiColor = $color.red
	} else {
		$FreeSpaceText.AnsiColor = $color.yellow
	}
	Write-ColoredText @FreeSpaceText
	Write-Host ""
}

function Write-ColoredText {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Text,
		[string]$AnsiColor = $global:TerminalColor.Reset,
		[switch]$NoNewLine,
		[switch]$Return
	)

	$ColoredText = "$AnsiColor$($Text)$($global:TerminalColor.txt.Reset)$($global:TerminalColor.Reset)"
	if ($Return) {
		return $ColoredText
	} else {
		Write-Host $ColoredText -NoNewline:$NoNewLine
	}
}

function Write-DynamicTable {
	param(
		[Parameter(Mandatory)]
		[object[]]$Data,

		[string]$Separator = ' | ',
		[switch]$Header
	)

	# 1. Descubrir todas las columnas únicas
	$columnsOrder = @()
	$allProps = @{}
	foreach ($item in $Data) {
		foreach ($prop in $item.PSObject.Properties) {
			if (-not $allProps.ContainsKey($prop.Name)) {
				$allProps[$prop.Name] = $true
				$columnsOrder += $prop.Name
			}
		}
	}
	$columns = $columnsOrder

	# 2. Calcular ancho máximo por columna
	$maxWidths = @{}
	foreach ($col in $columns) {
		$max = if ($Header) { $col.Length } else { 0 }
		foreach ($item in $Data) {
			$val = if ($null -ne $item.$col) { $item.$col.ToString() } else { '' }
			$len = Get-VisibleLength $val
			if ($len -gt $max) { $max = $len }
		}
		$maxWidths[$col] = $max
	}

	# 3. Mostrar cabecera si se requiere
	if ($Header) {
		$headerVals = @{}
		foreach ($col in $columns) { $headerVals[$col] = $col }
		Write-Host (New-TableLine -Columns $columns -MaxWidths $maxWidths -Values $headerVals -Separator $Separator -header:$Header )
		$totalTableWidth = ($maxWidths.Values | Measure-Object -Sum).Sum + (($columns.Count - 1) * $Separator.Length)
		# Línea separadora con ese ancho (ejemplo con guiones)
		Write-Host ('=' * $totalTableWidth)
	}

	# 4. Mostrar cada fila
	foreach ($item in $Data) {
		$rowVals = @{}
		foreach ($col in $columns) {
			$val = if ($null -ne $item.$col) { $item.$col.ToString() } else { '' }
			$rowVals[$col] = $val
		}
		Write-Host (New-TableLine -Columns $columns -MaxWidths $maxWidths -Values $rowVals -Separator $Separator -header:$Header )
	}
}


function Format-ReportTable {
	param(
		[object[]]$Snapshots = $global:snapshots,
		[double]$Threshold = $global:Threshold,
		[int]$MaxUnitsPerRow = 3,
		[int]$ConsoleWidth = 120
	)

	$Lines = @()
	$ColorText = $global:TerminalColor.txt
	$ColorReset = $global:TerminalColor.reset
	for ($i = 0; $i -lt $Snapshots.Count; $i++) {
		$shot = $Snapshots[$i]
		if ($i -eq 0) {
			$shot.Dates.Finish = $Snapshots[$i + 1].Dates.Start
		}

		if ($null -ne $shot.Dates.Finish -and $shot.Dates.Finish -ne [datetime]::MinValue) {
			$ElapsedTime = Format-ElapsedTime -Start ($shot.Dates.start) -End $shot.Dates.Finish -Short
		}

		$ClearedSpace = @()
		foreach ($d in $shot.Drives) {
			if ($i -eq 0) {
				$diff = 0
			} else {
				$lastone = $Snapshots[$i - 1].Drives | Where-Object Letter -EQ $d.Letter
				$diff = $d.free - $lastone.Free
			}
			$letter = $d.letter
			$Cleaned = (Format-ReadableSize ($diff)).PadLeft(9)
			if ($diff -lt 0) {
				$color = $ColorText.Yellow
			} elseif ($diff -ge 1) {
				$color = $ColorText.green
			} elseif ($diff -ge 0.1) {
				$color = $ColorText.cyan
			} elseif ($diff -gt 0) {
				$color = $ColorText.blue
			} else {
				$color = $ColorReset
			}
			$CleanText = Write-ColoredText -Text $cleaned -AnsiColor $color -Return
			$ClearedSpace += "$letter $CleanText"
		}
		if ($ClearedSpace.Count -gt 0) {
			$DrivesText = $ClearedSpace -join " ║  "
		} else {
			$DrivesText = "--"
		}

		$lines += [PSCustomObject]@{
			Punto    = $shot.Name
			Duración = $ElapsedTime
			Unidades = $DrivesText
		}
	}
	Write-DynamicTable -Data $lines -Separator " ║ " -Header
}

# ============================================================
# Funciones públicas
# ============================================================

function Show-PreCleanSystemSnapshot {
	param(
		[Parameter(Mandatory)]
		$Snapshot
	)

	# Impresión de resumen inicial
	Write-Host "`n"
	wrun "ESTADO DEL SISTEMA (PRE-LIMPIEZA)"

	# Impresión del informe
	Show-CleaningContext -snapshop $Snapshot
	Write-Host ""

	# Impresón de tabla de unidades de almacenamiento
	Get-SimpleDriveTable -Drives $Snapshot.Drives
	Write-Host ""
}

function Show-FinalReport {
	param(
		[object[]]$Snapshots = $global:snapshots
	)
	# Impresion de resumen de limpieza
	Write-Host "`n"
	wrun "RESULTADO DE LA LIMPIEZA"
	Show-ReportHeader

	# Tabla de Reporte de limpiadores
	Format-ReportTable
}
