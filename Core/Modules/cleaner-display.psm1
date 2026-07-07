
# ============================================================
# Módulo: cleaner-display.psm1
# Propósito: Funciones de presentación para PCB Cleaner
# ============================================================

# ============================================================
# Funciones auxiliares privadas
# ============================================================


function _PadString {
	param([string]$Text, [int]$Width, [string]$Align = 'Left')
	$len = $Text.Length
	if ($len -ge $Width) { return $Text.Substring(0, $Width) }
	$diff = $Width - $len
	switch ($Align) {
		'Right' { return (' ' * $diff) + $Text }
		'Center' {
			$left = [math]::Floor($diff / 2); $right = $diff - $left
			return (' ' * $left) + $Text + (' ' * $right)
		}
		default { return $Text + (' ' * $diff) }
	}
}

function _Format-Duration {
	param([TimeSpan]$Duration)
	if ($Duration.TotalHours -ge 1) {
		return "{0:hh\:mm\:ss}" -f $Duration
	}
	return "{0:mm\:ss}" -f $Duration
}

function _Get-UnitString {
	param($Unit, [double]$FreeGB, [double]$UsedPercent)
	$freeStr = Format-ReadableSize $FreeGB
	$pctStr = "{0:N2} %" -f $UsedPercent
	return "$($Unit.Letter): $freeStr ($pctStr)"
}

function _Get-MaxWidths {
	param([object[]]$Snapshots)
	$widths = @{}
	foreach ($snap in $Snapshots) {
		foreach ($d in $snap.Drives) {
			$str = _Get-UnitString -Unit $d -FreeGB $d.Free -UsedPercent $d.Used
			$len = $str.Length
			if (-not $widths.ContainsKey($d.Letter)) { $widths[$d.Letter] = $len }
			elseif ($len -gt $widths[$d.Letter]) { $widths[$d.Letter] = $len }
		}
	}
	return $widths
}

function _Build-LiberadoCell {
	param(
		[object[]]$Drives,
		[hashtable]$MaxWidths,
		[int]$MaxPerRow = 3
	)
	$lines = @()
	$batch = @()
	for ($i = 0; $i -lt $Drives.Count; $i++) {
		$batch += $Drives[$i]
		if ($batch.Count -eq $MaxPerRow -or $i -eq $Drives.Count - 1) {
			$parts = foreach ($d in $batch) {
				$str = _Get-UnitString -Unit $d -FreeGB $d.Free -UsedPercent $d.Used
				$w = $MaxWidths[$d.Letter]
				_PadString $str $w 'Left'
			}
			$lines += $parts -join " $($script:ANSI.Reset)║ "
			$batch = @()
		}
	}
	return $lines
}

function _Format-ReportTable {
	param(
		[object[]]$Snapshots,
		[double]$Threshold,
		[int]$MaxUnitsPerRow = 3,
		[int]$ConsoleWidth = 120
	)
	$maxWidths = _Get-MaxWidths $Snapshots
	# Ancho columnas fijas
	$puntoW = [math]::Max(($Snapshots | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum, 10)
	$duracW = 8
	$borderChars = 6  # cuenta de bordes izquierdo + ║ + ║ + derecho (4 bordes) más espacios: ya veremos
	# Calculamos espacio para Liberado
	$libW = $ConsoleWidth - $puntoW - $duracW - 6  # 6 por los bordes ║ y espacios

	# Ver si con MaxUnitsPerRow cabe
	$neededWidth = ($maxWidths.Values | Measure-Object -Sum).Sum + (($maxWidths.Count - 1) * 3)  # 3 chars por " ║ "
	$perRow = $MaxUnitsPerRow
	while ($perRow -gt 1 -and $neededWidth -gt $libW) {
		$perRow--
		$neededWidth = ($maxWidths.Values | Measure-Object -Sum).Sum + (($maxWidths.Count - 1) * 3)
		# Recalcular neededWidth para el perRow? En realidad el ancho de una línea con perRow unidades es:
		# suma anchos de esas unidades + (perRow-1)*3. Pero el total de unidades es fijo, si bajamos perRow habrá más líneas,
		# pero el ancho máximo de una línea será con el perRow unidades más anchas. Esto es complejo.
		# Simplificamos: si el ancho de TODAS las unidades en una sola línea (con MaxUnitsPerRow) excede libW, reducimos perRow a 2.
		# Si aún así excede, a 1.
		$testWidth = 0
		$count = 0
		foreach ($w in $maxWidths.Values) {
			$testWidth += $w
			$count++
			if ($count -eq $perRow) { break }
		}
		$testWidth += ($count - 1) * 3
		if ($testWidth -le $libW) { break } else { $perRow-- }
	}

	$bTop = "╔$('═' * $puntoW)╦$('═' * $duracW)╦$('═' * $libW)╗"
	$bSep = "╠$('═' * $puntoW)╬$('═' * $duracW)╬$('═' * $libW)╣"
	$bBottom = "╚$('═' * $puntoW)╩$('═' * $duracW)╩$('═' * $libW)╝"

	$lines = @($bTop)
	# Cabecera
	$lines += "║$(_PadString 'Punto' $puntoW 'Center')║$(_PadString 'Duración' $duracW 'Center')║$(_PadString 'Liberado' $libW 'Center')║"
	$lines += $bSep

	for ($i = 0; $i -lt $Snapshots.Count; $i++) {
		$snap = $Snapshots[$i]
		$dur = if ($snap.Dates.finish -ne [datetime]::MinValue) {
			_Format-Duration ($snap.Dates.finish - $snap.Dates.start)
		} else { '--' }
		$liberadoLines = _Build-LiberadoCell -Drives $snap.Drives -MaxWidths $maxWidths -MaxPerRow $perRow

		for ($j = 0; $j -lt $liberadoLines.Count; $j++) {
			if ($j -eq 0) {
				$p = _PadString $snap.Name $puntoW 'Left'
				$d = _PadString $dur $duracW 'Center'
			} else {
				$p = ' ' * $puntoW
				$d = ' ' * $duracW
			}
			$libLine = _PadString $liberadoLines[$j] $libW 'Left'
			$lines += "║$p║$d║$libLine║"
		}
		if ($i -lt $Snapshots.Count - 1) { $lines += $bSep }
	}
	$lines += $bBottom
	return $lines
}

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
			Uso   = Write-ColoredText -Text ("{0:N2} %" -f $d.Used)-AnsiColor $color -Return
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
	if ($Snapshots.Count -eq 0) { return }

	$threshold = $global:Threshold
	$startTime = $Snapshots[0].Dates.start
	$endTime = ($Snapshots | Where-Object { $_.Dates.finish -ne [datetime]::MinValue } | Select-Object -Last 1).Dates.finish
	if (-not $endTime) { $endTime = Get-Date }
	$totalDuration = $endTime - $startTime

	# Título
	Write-Host "╔══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
	Write-Host "║ RESULTADO DE LA LIMPIEZA ║" -ForegroundColor Cyan
	Write-Host "╚══════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
	Write-Host ""

	Write-Host " Tiempo total de ejecución : " -NoNewline
	Write-Host (_Format-Duration $totalDuration) -ForegroundColor $script:ANSI.Cyan

	# Espacio total liberado (entre el último y el primer snapshot)
	$firstDrives = $Snapshots[0].Drives
	$lastDrives = $Snapshots[-1].Drives
	$totalLiberado = 0
	foreach ($ld in $lastDrives) {
		$fd = $firstDrives | Where-Object Letter -EQ $ld.Letter
		if ($fd) { $totalLiberado += ($ld.Free - $fd.Free) }
	}
	$totalLiberadoStr = Format-ReadableSize $totalLiberado
	Write-Host " Espacio total liberado : " -NoNewline
	Write-Host $totalLiberadoStr -ForegroundColor $script:ANSI.Green
	Write-Host ""

	# Tabla de snapshots
	$reportLines = _Format-ReportTable -Snapshots $Snapshots -Threshold $threshold -ConsoleWidth 120
	foreach ($line in $reportLines) {
		Write-Host $line
	}
}

# Exportar funciones públicas
Export-ModuleMember -Function Format-CustomDate, Get-Pluralize, Show-PreCleanSystemSnapshot, Show-FinalReport, Write-ColoredText
