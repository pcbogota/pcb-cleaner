# Funciones para mostrar mensajes en colores
# Las configuraciónes de texto y/o fondo se deben colocar al inicio del texto. Al final de toda línea, si o si
# debe llevar $($TerminalColor.reset). Esto último para evitar cabios de color en textos subyacentes!
# Ej: Write-Host "$($TerminalColor.txt.green)fondo verde letras$($TerminalColor.reset) negras"
<#

Tabla de Categorías de Funciones

------------------------------------------------------------------------------
| Función                 | SYNOPSIS                                         |
------------------------------------------------------------------------------
| Find-TextFromEnd        | Extrae y/o trunca un texto desde el final,       |
|                         | ajustándolo a un ancho máximo.                   |
|                         |                                                  |
| Find-TextFromStart      | Extrae y/o trunca un texto desde el inicio,      |
|                         | ajustándolo a un ancho máximo.                   |
|                         |                                                  |
| Format-TextWrap         | Formatea un texto para ajustarlo al ancho de la  |
|                         | consola o a un ancho específico.                 |
|                         |                                                  |
| Get-CenteredText        | Genera texto centrado o devuelve el padding      |
|                         | lateral basado en el ancho de la consola.        |
|                         |                                                  |
| Preprint                | Muestra información de depuración sobre un       |
|                         | elemento y su contexto de ejecución.             |
|                         |                                                  |
| Reset-EndLine           | Añade un formato personalizado a las líneas de   |
|                         | texto, incluyendo un espaciado opcional.         |
|                         |                                                  |
| Show-Colors             | Muestra una tabla de colores ANSI y formatos de  |
|                         | texto disponibles en la consola de PowerShell.   |
|                         |                                                  |
| Stop                    | Muestra información de depuración y finaliza el  |
|                         | script.                                          |
|                         |                                                  |
| wError                  | Muestra un texto formateado simulando un error.  |
|                         |                                                  |
| WTitulo                 | Muestra un texto formateado como título.         |
|                         |                                                  |
| wInfo                   | Muestra un texto informativo.                    |
|                         |                                                  |
| wOk                     | Mostar un texto en formato de ejecución exitosa. |
|                         |                                                  |
| Write-Logo              | Imprime un logo personalizado en la consola      |
|                         | usando caracteres especiales y códigos ANSI.     |
|                         |                                                  |
| wRun                    | Muestra un texto formateado indicando el inicio  |
|                         | o la ejecución de un proceso.                    |
|                         |                                                  |
| wWarning                | Muestra un texto de advertencia o resaltado.     |
-------------------------------------------------------------------------------

Total Funciones 13

#>

function Find-TextFromEnd {
	<#
	.SYNOPSIS
		Extrae y/o trunca un texto desde el final, ajustándolo a un ancho máximo.

	.DESCRIPTION
		Esta función toma un texto y un ancho máximo. Si el texto excede el ancho máximo,
		lo trunca desde el principio (mostrando el final) y añade "..." al inicio.
		Si el texto es más corto que el ancho máximo, lo devuelve sin modificar.

	.PARAMETER Text
		El texto que se va a procesar. Este parámetro es obligatorio.

	.PARAMETER MaxWidth
		El ancho máximo permitido para el texto. Este parámetro es obligatorio.

	.EXAMPLE
		Find-TextFromEnd -Text "Este es un texto largo" -MaxWidth 10
		Devuelve: "...texto largo"

	.EXAMPLE
		Find-TextFromEnd -Text "Texto corto" -MaxWidth 20
		Devuelve: "Texto corto"

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-02-09
		Versión: 1.0.0

	.INPUTS
		System.String
		System.Int32

	.OUTPUTS
		System.String

	#>
	param (
		[Parameter(Mandatory = $true)]
		[string]$text,
		[Parameter(Mandatory = $true)]
		[int]$maxWidth
	)
	# Validar que $MaxWidth sea un entero positivo.
	if ($MaxWidth -le 0) {
		throw "El ancho máximo debe ser un entero positivo."
	}

	#validación y trucanmiento del texto
	if ($text.Length -gt $maxWidth) {
		return "..." + $text.Substring($text.Length - $maxWidth + 3)
	}
	return $text
}

# Función para truncar texto desde el principio (para la columna Llamada)
function Find-TextFromStart {
	<#
	.SYNOPSIS
		Extrae y/o trunca un texto desde el inicio, ajustándolo a un ancho máximo.

	.DESCRIPTION
		Esta función toma un texto y un ancho máximo. Si el texto excede el ancho máximo,
		lo trunca desde el final (mostrando el inicio) y añade "..." al final.
		Si el texto es más corto que el ancho máximo, lo devuelve sin modificar.

	.PARAMETER Text
		El texto que se va a procesar. Este parámetro es obligatorio.

	.PARAMETER MaxWidth
		El ancho máximo permitido para el texto. Este parámetro es obligatorio.

	.EXAMPLE
		Find-TextFromStart -Text "Este es un texto largo" -MaxWidth 10
		Devuelve: "Este es un..."

	.EXAMPLE
		Find-TextFromStart -Text "Texto corto" -MaxWidth 20
		Devuelve: "Texto corto"

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-02-09
		Versión: 1.0.0

	.INPUTS
		System.String
		System.Int32

	.OUTPUTS
		System.String
	#>
	param (
		[Parameter(Mandatory = $true)]
		[string]$text,
		[Parameter(Mandatory = $true)]
		[int]$maxWidth
	)
	# Validar que $MaxWidth sea un entero positivo.
	if ($MaxWidth -le 0) {
		throw "El ancho máximo debe ser un entero positivo."
	}

	#validación y trucanmiento del texto

	if ($text.Length -gt $maxWidth) {
		return ($text.Substring(0, $maxWidth - 3)).Trim() + "..."
	}
	return $text
}

function Format-TextWrap {
	<#
	.SYNOPSIS
		Formatea un texto para ajustarlo al ancho de la consola o a un ancho específico.

	.DESCRIPTION
		Esta función toma un texto y lo divide en líneas según el ancho de la consola o un ancho máximo especificado.
		El texto se divide por palabras, evitando que estas se corten al final de cada línea. Es útil para mejorar
		la legibilidad de textos largos en la consola de PowerShell.

	.PARAMETER Text
		Tipo: [string]
		Descripción: El texto que se desea formatear. Este parámetro es obligatorio.

	.PARAMETER Width
		Tipo: [int]
		Descripción: El ancho máximo de cada línea. Si no se especifica, se utiliza el ancho de la consola.
		Este parámetro es opcional y tiene un valor predeterminado de 120.

	.PARAMETER Max
		Tipo: [Switch]
		Descripción: Al estar presente toma el ancho de la consola como valor para dar formato al texto ignorando si se pasa el parametro Width.

	.EXAMPLE
		Format-TextWrap -Text "Este es un texto de ejemplo que será dividido en varias líneas."
		Divide el texto en líneas que no excedan el ancho de la consola.

	.EXAMPLE
		Format-TextWrap -Text "Este es un texto de ejemplo que será dividido en varias líneas." -Width 50
		Divide el texto en líneas que no excedan 50 caracteres de ancho.

	.EXAMPLE
		Format-TextWrap -Text "Este es un texto de ejemplo que será dividido en varias líneas." -Max
		Divide el texto en líneas que no excedan el ancho de la consola.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-03-06
		Fecha de modificación: 2025-03-06
		Versión: 1.1.0

	.INPUTS
		La función no acepta entradas desde la tubería.

	.OUTPUTS
		La función devuelve una cadena de texto formateada.

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-string
#>
	# Define los parámetros de la función: Texto a formatear y ancho máximo de línea.
	param (
		[string]$Text,
		[int]$Width = 120,
		[switch]$Max
	)

	if ($psISE) {
		$effectiveWidth = 120
	} else {
		#Verificación del ancho del texto que se va a utilizar
		if ([bool]$max) {
			#Si $max está presente, se toma el ancho de la consola como tamaño máximo
			$effectiveWidth = [Console]::WindowWidth
		} else {
			# Calcula el ancho efectivo de la línea, tomando el menor valor entre el ancho de la consola y el ancho especificado.
			$effectiveWidth = [math]::Min([Console]::WindowWidth, $Width)
		}
	}
	# Inicializa un array para almacenar las líneas formateadas y una variable para construir cada línea.
	$result = @()
	$line = ''

	# Divide el texto en palabras individuales utilizando el espacio como delimitador.
	$words = $Text -split ' '

	# Recorre cada palabra y la agrega a la línea actual si no excede el ancho efectivo.
	foreach ($word in $words) {
		if (($line.Length + $word.Length + 1) -le $effectiveWidth) {
			$line += "$word "
		} else {
			# Si la línea excede el ancho, la agrega al resultado y comienza una nueva línea.
			$result += $line.Trim()
			$line = "$word "
		}
	}

	# Agrega la última línea construida al resultado si no está vacía.
	if ($line) {
		$result += $line.Trim()
	}

	# Une las líneas formateadas con saltos de línea y devuelve el texto formateado.
	return $result -join "`n"
}

function Get-CenteredText {
	<#
	.SYNOPSIS
	Genera texto centrado o devuelve el padding lateral basado en el ancho de la consola.

	.DESCRIPTION
		La función calcula dinámicamente la cantidad de espacios necesarios para centrar un texto en la consola utilizando el ancho actual de la ventana ([console]::WindowWidth).
		Permite dos comportamientos: devolver únicamente el padding izquierdo o construir el texto centrado completo agregando espacios a ambos lados.
		El cálculo asegura que no se generen valores negativos utilizando [math]::Max.

	.PARAMETER Text
		[string] Obligatorio. Texto que se desea centrar en la consola.

	.PARAMETER SidePadding
		[switch] Opcional. Si se especifica, la función devuelve únicamente el padding izquierdo calculado en lugar del texto centrado completo.

	.EXAMPLE
		Get-CenteredText "Hola mundo"
		Devuelve el texto centrado en la consola.

	.EXAMPLE
		Get-CenteredText -Text "Hola mundo" -SidePadding
		Devuelve únicamente los espacios necesarios para el padding izquierdo.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2026-04-24
		Fecha de modificación: 2026-04-24
		Versión: 1.0.0

	.INPUTS
		System.String. No acepta entrada desde la tubería.

	.OUTPUTS
		System.String. Devuelve una cadena con el texto centrado o únicamente el padding.

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
		https://docs.microsoft.com/en-us/dotnet/api/system.console.windowwidth
		https://docs.microsoft.com/en-us/dotnet/api/system.math.max
	#>
	param(
		[Parameter(Mandatory = $true)]
		[string]$Text,
		[switch]$SidePadding
	)

	$padding = ' ' * [math]::Max(0, (([console]::WindowWidth - (($Text.length) + 1)) / 2))
	if ($SidePadding) { return $padding } else { return "$padding$text" }
}

function Preprint {
	<#
	.SYNOPSIS
		Muestra información de depuración sobre un elemento y su contexto de ejecución.

	.DESCRIPTION
		Muestra un elemento proporcionado, su tipo y la ubicación (archivo y línea)
		donde se llamó a la función Preprint. Útil para depurar scripts.

	.PARAMETER Data
		El dato (variable, objeto, valor, etc.) que se va a inspeccionar.  Este parámetro es obligatorio.

	.EXAMPLE
		Preprint $miVariable
		Muestra el valor y tipo de $miVariable, junto con la ubicación
		en el script donde se llamó a Preprint.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-10-22
		Versión: 1.0.2

	.INPUTS
		Cualquier tipo de dato.

	.OUTPUTS
		Nignuno (La función escribe directamente en la consola).

	#>
	param(
		[Parameter(Mandatory = $true)] # El parámetro $Data es obligatorio.
		[AllowNull()]
		[psobject] $Data
	)
	process {
		# Obtener la información de la pila de llamadas.
		$callStack = ((Get-PSCallStack  | Where-Object { $_.Location -ne "<sin archivo>" } | Select-Object -First 2 -Skip 1).Location).split(':')
		$file = $callStack[0]
		$line = [regex]::Match($callStack[1], '\d+').Value

		# Calcular el ancho del separador.
		$width = ([Math]::Min($Host.UI.RawUI.WindowSize.Width, 99))
		$separatorBlock = '-' * $width

		if ($null -ne $Data) {
			$type = $Data.GetType().Name
		} else {
			$type = "NULL"
		}
		if (($type -eq "String") -or ($type -eq "Char")) {
			$Data = $Data.Trim()
			if ('' -eq $Data) {
				$Data = "(EMPTY)"
			}
		}

		if (($type -notin ('Single', 'Double', 'Decimal', 'Char', 'Boolean', 'String', 'Int32', 'Int64'))) {
			$Data = ($Data | Format-List | Out-String).Trim()

		}
		# Crear la línea de llamada.
		$callData = ("Call: $($file) (ln $($line)) - $($type)")

		# Mostrar la información.
		# Separador superior
		WInfo("$($separatorBlock.Substring($calldata.Length))$($calldata)")

		# Datos
		if ($type -eq "NULL") {
			$dataShow = "$($TerminalColor.txt.yellow)`$null - (valor nulo)$($TerminalColor.reset)"
		} else {
			$dataShow = "$($TerminalColor.txt.yellow)$Data$($TerminalColor.reset)"
		}
		Write-Host $dataShow

		# Separador inferior
		WInfo("$separatorBlock")

		# Linea vacía de separación al final
		Write-Host ""
	}
}

#Función para dividir líneas con su respectivo fin de cambios de color ANSI
function Reset-EndLine {
	<#
	.SYNOPSIS
		Añade un formato personalizado a las líneas de texto, incluyendo un espaciado opcional.

	.DESCRIPTION
		Esta función toma un texto, un formato personalizado y un parámetro opcional de espaciado.
		Divide el texto en líneas, aplica el formato y el espaciado a cada línea, y devuelve el texto formateado.

	.PARAMETER Text
		El texto al que se le aplicará el formato. Este parámetro es obligatorio.

	.PARAMETER custom
		El formato personalizado que se aplicará a cada línea.

	.PARAMETER space
		Un interruptor (switch) opcional. Si se especifica, se añadirá un espacio después del formato personalizado y antes del texto de la línea.

	.PARAMETER wider
		Un interruptor (switch) opcional. Al especificarse, hará que el texto se vea al ancho de la consola.

	.EXAMPLE
		Reset-EndLine -Text "Línea 1`nLínea 2" -Custom "[color=red]" -Space
		Esto formateará las líneas con el color rojo y añadirá un espacio después del formato.

	.EXAMPLE
		Reset-EndLine -Text "Línea 1`nLínea 2" -Custom "[b]"
		Esto formateará las líneas con negrita sin añadir un espacio.

	.EXAMPLE
		Reset-EndLine -Text "Texto muy extenso..." -wider
		Esto hará que un texto ancho se divida en base al ancho de la consola.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-03-06
		Versión: 1.1.1
		Los ejemplos definene un modo de uso. Su uso real debe estar determinado por datos de color ANSI de la variable $TerminalColor

	.INPUTS
		System.String

	.OUTPUTS
		System.String
	#>

	param(
		[Parameter(Mandatory, Position = 0)]
		[string]
		$Text,
		[string]
		$Custom,
		[switch]
		$Space,
		[switch]
		$Wider = $false
	)

	# Definir el espaciador basado en el parámetro $space
	$spacer = if ($space) { " " } else { "" }
	$text = Format-TextWrap -Text $text -Max:([bool]$Wider)

	# Dividir el texto en líneas
	$lines = ($Text -split "`n")

	# Inicializar el texto formateado
	$formatedText = ""

	# Recorrer cada línea y aplicar el formato de color
	foreach ($line in $lines) {
		# Comprobar si la línea no está vacía o solo contiene espacios en blanco
		if (-not [string]::IsNullOrWhiteSpace($line)) {
			$formatedText += "$spacer$($custom)$($line)$spacer$($TerminalColor.reset)`n$spacer"
		}
	}

	# Eliminar el último salto de línea y devolver el texto formateado
	return $formatedText.TrimEnd("`r`n")
}

# Función para mostrar colores y formatos con códigos
function Show-Colors {
	<#
	.SYNOPSIS
		Muestra una tabla de colores ANSI y formatos de texto disponibles en la consola de PowerShell.

	.DESCRIPTION
		La función genera una visualización de los 256 colores ANSI para texto y presenta ejemplos de los formatos
		de estilo más comunes (negrita, cursiva, subrayado, intermitencia, inversión, entre otros). También muestra
		la forma correcta de aplicar colores de fondo y combinaciones de formato mediante secuencias de escape ANSI.

		La salida se produce únicamente en la consola utilizando Write-Host, por lo que no devuelve objetos al
		pipeline de PowerShell. Su propósito es servir como referencia visual rápida para personalización de texto
		en entornos compatibles con secuencias ANSI.

	.PARAMETER None
		Esta función no acepta parámetros de entrada.

	.EXAMPLE
		Show-Colors
		Ejecuta la función utilizando la llamada directa sin parámetros.

	.EXAMPLE
		Show-Colors | Out-Null
		Ejecuta la función ignorando la salida visual posterior en el flujo de la consola.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-02-09
		Versión: 1.0.0

	.INPUTS
		None. La función no acepta entrada desde la tubería.

	.OUTPUTS
		None. La función solo escribe información visual en la consola mediante Write-Host.

	.LINK
		https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/write-host?view=powershell-5.1
		https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
	#>

	# Colores de texto (38;5;n)
	Write-Host "`nColores de texto (256 colores):`n"
	for ($i = 0; $i -lt 256; $i++) {
		$escapedtxt = "`$([char]0x1b)[38;5;${i}m"
		Write-Host "$($escapedtxt) > $([char]0x1b)[38;5;$($i)mTexto de muestra$([char]0x1b)[0m"
	}

	# Formatos de texto
	Write-Host "`n`nFormatos de texto:`n"
	Write-Host "`$([char]0x1b)[0m    Borar formato       - $([char]0x1b)[0mTexto normal$([char]0x1b)[0m"
	Write-Host "`$([char]0x1b)[1m    Negrita             - $([char]0x1b)[1mTexto en negrita$([char]0x1b)[0m"
	Write-Host "`$([char]0x1b)[2m    Opaco               - $([char]0x1b)[2mTexto Opaco$([char]0x1b)[0m"
	Write-Host "`$([char]0x1b)[3m    Cursiva             - $([char]0x1b)[3mTexto en cursiva$([char]0x1b)[0m"
	Write-Host "`$([char]0x1b)[4m    Subrayado           - $([char]0x1b)[4mTexto subrayado$([char]0x1b)[0m"
	Write-Host "`$([char]0x1b)[5m    Intermitente lento  - $([char]0x1b)[5mTexto intermitente lento$([char]0x1b)[0m"
	Write-Host "`$([char]0x1b)[6m    Intermitente rápido - $([char]0x1b)[6mTexto intermitente rápido$([char]0x1b)[0m"
	Write-Host "`$([char]0x1b)[7m    Invertido           - $([char]0x1b)[7mTexto Invertido$([char]0x1b)[0m"
	Write-Host "`$([char]0x1b)[8m    Transparente        - $([char]0x1b)[8mTexto transparente$([char]0x1b)[0m"
	Write-Host "`$([char]0x1b)[9m    Tachado             - $([char]0x1b)[9mTexto tachado$([char]0x1b)[0m"

	Write-Host "`nPara los fondos usar: `$([char]0x1b)[48;5;<X>m donde <X> es el número de color`n`nPor ejemplo el código '$([char]0x1b)[3m`$([char]0x1b)[48;5;73mTexto de prueba' $([char]0x1b)[0m muestra:`n$([char]0x1b)[48;5;73mTexto de prueba$([char]0x1b)[0m"
	Write-Host "`nPara usar combinación de fondo y color se debe colocar primero el fondo y luego el color: "
	Write-Host '$([char]0x1b)[0m Se usa para eliminar la configuración de colores y fondo'

	Write-Host "`nCombinación de todo:`n$([char]0x1b)[4m$([char]0x1b)[48;5;27m$([char]0x1b)[38;5;226mTexto subrayado, fondo azul texto amarillo$([char]0x1b)[0m y sin formato.`nCódigo:`n`$([char]0x1b)[4m`$([char]0x1b)[48;5;27m`$([char]0x1b)[38;5;226mTexto subrayado, fondo azul, texto amarillo`$([char]0x1b)[0m y sin formato."
}

#Función para detener la ejecución del script y mostrar la trazabilidad del comando STOP (dónde se ejecutó)
function Stop {
	<#
	.SYNOPSIS
		Muestra información de depuración y finaliza el script.

	.DESCRIPTION
		Muestra un mensaje de ALTO!, la traza de ejecución y finaliza el script.
		Útil para detener la ejecución del script en puntos específicos durante la depuración.

	.PARAMETER Text
		El mensaje que se mostrará como ALTO!. Este parámetro es opcional.

	.PARAMETER pause
		Se detendrá la ejecución del script antes de la finalización del script

	.EXAMPLE
		Stop "Se ha producido un error crítico."
		Muestra el mensaje "ALTO!: Se ha producido un error crítico." y la traza de ejecución,
		luego finaliza el script.

	.EXAMPLE
		Stop "Leer muy bien antes de salir" -Pause
		Muestra el mensaje "ALTO!: Leer muy bien antes de salir." y la traza de ejecución,
		se solicitará que se presione una tecla o enter antes de terminar la ejecución de script

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-02-12
		Versión: 1.1.0

	.INPUTS
		System.String

	.OUTPUTS
		Ninguno (La función escribe directamente en la consola y finaliza el script).

	#>
	param(
		[string]$Text,
		[switch]$pause
	)

	# Obtener la traza de ejecución (call stack)
	$callStack = Get-PSCallStack | Where-Object { $_.Location -ne "<sin archivo>" } | Select-Object -Skip 1

	Write-Host "`n`n"

	# Mostrar mensaje de ALTO! (si se proporciona)
	if (-not ([string]::IsNullOrWhiteSpace($text))) {
		Write-Host "`n`n$($global:TerminalColor.txt.darkRed)ALTO!: $($text)"
	}

	$color = "$($global:TerminalColor.txt.yellow)"

	# Separador de columnas
	$sep = "$($global:TerminalColor.txt.brightWhite)|"

	# Encabezados de la tabla
	$offsetColumnLn_Header = -16
	$offsetScript_Header = -70
	Write-Host ("{0,$offsetColumnLn_Header} {1,$offsetScript_Header} {2,-1}" -f "$($color) Ln", "$($sep) $($color) Script", "$($sep) $($color) Llamada")

	# Línea separadora
	Write-Host ("-" * ([Math]::Min($Host.UI.RawUI.WindowSize.Width, 99))) -ForegroundColor gray

	# Mostrar cada entrada de la traza de ejecución
	$colorBright = "$($global:TerminalColor.txt.brightWhite)"
	$colorOpaque = "$($global:TerminalColor.txt.gray)"

	for ($i = 0; $i -lt $callStack.Count; $i++) {
		$entry = $callStack[$i]

		# Asignar colores y resaltes según el índice
		if ($i -eq 0) {
			$color = $colorBright
			$sign = "$($global:TerminalColor.txt.darkRed)**"
			# espacios adicionales por la diferencia entre códigos de color
			$dif = $colorOpaque.Length - $color.Length
			$dif = if ($dif -lt 0) { $dif * -1 }else { $dif }
			$offsetColumnLn = $offsetColumnLn_Header + $dif
			$offsetScript = $offsetScript_Header + $dif
		} else {
			$color = $colorOpaque
			$sign = ''
			$offsetColumnLn = $offsetColumnLn_Header
			$offsetScript = $offsetScript_Header
		}

		# Truncar el nombre del script desde el final (sin contar los caracteres de color)
		$scriptName = $entry.ScriptName
		$maxScriptWidth = 73 - ($sep.Length + $color.Length + 4)  # Ajustar para los caracteres de color
		$truncatedScript = Find-TextFromEnd -text $scriptName -maxWidth $maxScriptWidth

		# Truncar la columna Llamada desde el principio (sin contar los caracteres de color)
		$llamada = ($entry.Position.Text -replace '\s+', ' ') -replace "([\(\[\{])\s?", '$1'
		$maxLlamadaWidth = 60 - ($sep.Length + $color.Length + 4)  # Ajustar para los caracteres de color
		$truncatedLlamada = Find-TextFromStart -text $llamada -maxWidth $maxLlamadaWidth

		$line = "$($color)$($entry.ScriptLineNumber)"
		$script = "$($sep) $($color)$($truncatedScript)"
		$position = "$($sep) $($color)$($truncatedLlamada) $sign"
		Write-Host ("{0,$offsetColumnLn} {1,$offsetScript} {2,-1}" -f $line, $script, $position)

	}
	Write-Host ""
	if ($Pause) {
		Pause
	}
	exit
}

function Write-Logo {
	<#
	.SYNOPSIS
		Imprime un logo personalizado en la consola de PowerShell.

	.DESCRIPTION
		Esta función genera e imprime un logo en la consola, utilizando caracteres especiales y códigos de escape ANSI para colores y formatos.  El logo incluye el nombre "Camilo Salazar (ChyBeat)", el año actual y un mensaje de copyright.

	.EXAMPLE
		PS> Write-Logo

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2026-04-26
		Versión: 1.0.3
		El logo se adapta ligeramente en Windows 10 para asegurar una correcta visualización de los caracteres especiales.
		Los caracteres especiales utilizados son:
			- $([char]9608) / $([char]9209) para bloques sólidos.
			- $([char]9612) para bloques mitad derecha.
			- $([char]9616) para bloques mitad izquierda.
			- $([char]0x25CF) para puntos.

		Los códigos de escape ANSI utilizados para los colores son:
			- Negro: $([char]0x1b)[48;5;0m
			- Amarillo: $([char]0x1b)[38;5;214m
			- Rojo: $([char]0x1b)[38;5;196m
			- Blanco: $([char]0x1b)[38;5;15m
			- Opaco: $([char]0x1b)[2m
			- Intermitente rápido: $([char]0x1b)[6m

		.LINK
			https://jdhitsolutions.com/blog/powershell/7479/friday-fun-with-powershell-and-ansi/ (Códigos ANSI)
	#>

	$year = Get-Date -Format yyyy
	$copy = $([char]169) # Símbolo de derechos de autor
	$r = $([char]174) # Símbolo de Registrado

	# Símbolos de relleno
	$c = $([char]9608) # Cuadro completo
	$d = $([char]9612) # Cuadro con mitad derecha vacia

	if ($w10) {
		# Revisar en Windows10 como imprime tanto en terminal como en la ventana directa de powershell
		$c = $([char]9209) #Cuadro Completo
	}

	$cl = @{
		ty = $global:TerminalColor.txt.orange	# Texto naranja/amarillo
		tr = $global:TerminalColor.txt.red		# Texto rojo
		tw = $global:TerminalColor.txt.white	# Texto white/blanco
		to = $global:TerminalColor.txt.opaque	# Texto opaco
		ti = $global:TerminalColor.txt.blink	# Texto intermitente rápido
	}

	# Ancho del logo
	$logoWide = 65

	# Crea una cadena de espacios en blanco para el padding, evitando que se sea meno a cero (tomando el numero más grande)
	if ($psISE) {
		Write-Host 'LOGO - PCBOGOTA'
		return
	} else {
		$padd = ' ' * [math]::Max(0, (([console]::WindowWidth - ($logoWide + 1)) / 2))
	}

	# Color por letra
	$Logo_P = $($cl.ty)		# Letra P
	$Logo_C = $($cl.tr)		# Letra C
	$Logo_B = $($cl.tw)		# Letra B
	$Logo_o = $($cl.tw)		# Letra O (O bOgO)
	$Logo_G = $($cl.tw)		# Letra G
	$Logo_T = $($cl.tw)		# Letra T
	$Logo_A = $($cl.tw)		# Letra A
	$Logo_REG = $($cl.tw)	# Símbolo de registrado

	$textName = Get-CenteredText "                                       Camilo Salazar (ChyBeat)" # Requiere espacios al inicio y al final
	$textCopyright = Get-CenteredText "                              Limited Liability Partner - $($copy)$($year)" # Requiere espacios al inicio y al final

	# Código del logo
	$logo = "$($padd)$(" " * $logoWide)`n"
	$logo += "$($padd)$($Logo_P)$c$c$c$c$c$c$c$c $($Logo_C)$c$c$c$c$c$c$c$c`n"
	$logo += "$($padd)$($Logo_P)$c$c    $c$c $($Logo_C)$c$c       $($Logo_B)$c$c$c$c$c$c$d $($Logo_o)$c$c$c$c$c$c$c $($Logo_G)$c$c$c$c$c$c$c $($Logo_o2)$c$c$c$c$c$c$c $($Logo_T)$c$c$c$c$c$c $($Logo_A)$c$c$c$c$c$c$c$($Logo_REG)$r`n"
	$logo += "$($padd)$($Logo_P)$c$c    $c$c $($Logo_C)$c$c       $($Logo_B)$c$c   $c$d $($Logo_o)$c$c   $c$c $($Logo_G)$c$c      $($Logo_o2)$c$c   $c$c   $($Logo_T)$c$c   $($Logo_A)$c$c   $c$c `n"
	$logo += "$($padd)$($Logo_P)$c$c$c$c$c$c$c$c $($Logo_C)$c$c       $($Logo_B)$c$c$c$c$c$c$c $($Logo_o)$c$c   $c$c $($Logo_G)$c$c  $c$c$c $($Logo_o2)$c$c   $c$c   $($Logo_T)$c$c   $($Logo_A)$c$c$c$c$c$c$c `n"
	$logo += "$($padd)$($Logo_P)$c$c       $($Logo_C)$c$c       $($Logo_B)$c$c   $c$c $($Logo_o)$c$c   $c$c $($Logo_G)$c$c   $c$c $($Logo_o2)$c$c   $c$c   $($Logo_T)$c$c   $($Logo_A)$c$c   $c$c `n"
	$logo += "$($padd)$($Logo_P)$c$c       $($Logo_C)$c$c$c$c$c$c$c$c $($Logo_B)$c$c$c$c$c$c$c $($Logo_o)$c$c$c$c$c$c$c $($Logo_G)$c$c$c$c$c$c$c $($Logo_o2)$c$c$c$c$c$c$c   $($Logo_T)$c$c   $($Logo_A)$c$c   $c$c `n"
	$logo += "$($cl.tw)$($cl.ti)$textName`n"
	$logo += "$($cl.to)$textCopyright`n"
	$logo += "$($TerminalColor.reset)"

	# Escritura del logo
	Write-Host $logo
}

function wError {
	<#
	.SYNOPSIS
		Muestra un texto formateado simulando un error.

	.DESCRIPTION
		Muestra un texto con fondo rojo y letras blancas, simulando un mensaje de error.
		Utiliza la función Reset-EndLine para aplicar el formato.

	.PARAMETER Text
		El texto que se mostrará como error. Este parámetro es obligatorio.

	.PARAMETER wider
		Un interruptor (switch) opcional. Al especificarse, hará que el texto se vea al ancho de la consola.

	.EXAMPLE
		wError "Este es un mensaje de error."
		Muestra el texto "Este es un mensaje de error." con formato de error.

	.EXAMPLE
		wError -Text "Texto muy extenso..." -wider
		Esto hará que un texto ancho se divida en base al ancho de la consola.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-03-06
		Versión: 1.1.0

	.INPUTS
		System.String

	.OUTPUTS
		Ninguno (La función escribe directamente en la consola)
	#>
	param(
		[Parameter(Mandatory, Position = 0)]
		[string]
		$Text,
		[switch]
		$Wider = $false
	)
	process {

		# Convertir la primera letra a mayúscula
		$text = $text[0].ToString().ToUpper() + $text.Substring(1)

		# Mostrar el texto formateado
		Write-Host `n (Reset-EndLine -Text "$($Text) " -custom "$($TerminalColor.bg.red)$($TerminalColor.txt.white)" -Space -Wider:([bool]$wider))
	}
}

function wInfo {
	<#
	.SYNOPSIS
		Muestra un texto informativo.

	.DESCRIPTION
		Muestra un texto de color cian y opcionalmente con formato.
		Utiliza la función Reset-EndLine para aplicar el formato y controlar si se agrega un salto de línea al final..

	.PARAMETER Text
		El texto que se mostrará como información. Este parámetro es obligatorio.

	.PARAMETER wider
		Un interruptor (switch) opcional. Al especificarse, hará que el texto se vea al ancho de la consola.

	.PARAMETER NoNewline
		Un interruptor (switch) opcional. Indica si se debe evitar el salto de línea al final de la salida.

	.EXAMPLE
		wInfo "Este es un mensaje informativo."
		Muestra el texto "Este es un mensaje informativo." con formato de información.

	.EXAMPLE
		wInfo -Text "Texto muy extenso..." -wider
		Esto hará que un texto ancho se divida en base al ancho de la consola.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2026-02-04
		Versión: 1.2.0

	.INPUTS
		System.String

	.OUTPUTS
		Ninguno (La función escribe directamente en la consola)

	#>
	param(
		[Parameter(Mandatory, Position = 0)]
		[string]
		$Text,
		[switch]
		$Wider = $false,
		[switch] $NoNewline = $false
	)
	process {
		# Formatear y mostrar el texto usando Reset-EndLine
		Write-Host (Reset-EndLine -Text "$($Text)" -custom "$($TerminalColor.txt.bold)$($TerminalColor.txt.cyan)" -Wider:([bool]$wider)) -NoNewline:([bool]$NoNewline)

		[System.Threading.Thread]::Sleep(1)
	}
}

function wOk {
	<#
	.SYNOPSIS
		Mostar un texto en formato de ejecución exitosa

	.DESCRIPTION
		Muestra un texto con letras verdes indicando una ejecución exitosa

	.PARAMETER Text
		El texto a mostrar

	.PARAMETER wider
		Un interruptor (switch) opcional. Al especificarse, hará que el texto se vea al ancho de la consola.

	.EXAMPLE
		wOk -Text "La operación se completó correctamente."

	.EXAMPLE
		wOk -Text "Texto muy extenso..." -wider
		Esto hará que un texto ancho se divida en base al ancho de la consola.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-12-06
		Versión: 1.2.0
	#>
	param(
		[Parameter(Mandatory, Position = 0)]
		[string] $Text,
		[switch] $Wider,
		[switch] $oneLine

	)
	process {
		$end = "`n"
		if ($oneLine) {
			$end = ""
		}
		Write-Host (Reset-EndLine -Text "$($Text)" -custom "$($TerminalColor.txt.green)" -Wider:([bool]$wider))$end
	}
}

function wRun {
	<#
	.SYNOPSIS
		Muestra un texto formateado indicando el inicio o la ejecución de un proceso.

	.DESCRIPTION
		Muestra un texto con fondo verde y letras blancas, simulando un mensaje de inicio o ejecución.
		Utiliza la función Reset-EndLine para aplicar el formato.

	.PARAMETER wider
		Un interruptor (switch) opcional. Al especificarse, hará que el texto se vea al ancho de la consola.

	.PARAMETER Text
		El texto que se mostrará. Este parámetro es obligatorio.

	.EXAMPLE
		wRun "Iniciando proceso..."
		Muestra el texto "Iniciando proceso..." con formato de inicio.

	.EXAMPLE
		wRun -Text "Texto muy extenso..." -wider
		Esto hará que un texto ancho se divida en base al ancho de la consola.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-12-07
		Versión: 1.1.1

	.INPUTS
		System.String

	.OUTPUTS
		Ninguno (La función escribe directamente en la consola)

	#>
	param(
		[Parameter(Mandatory, Position = 0)]
		[string]
		$Text,
		[switch]
		$Wider = $false
	)
	process {
		Write-Host " $(Reset-EndLine -Text "$($Text) " -custom "$($TerminalColor.bg.green)$($TerminalColor.txt.white)" -Space -Wider:([bool]$wider))"
	}
}

#Función para escribir el logo de PCBogota.com
function wTitulo {
	<#
	.SYNOPSIS
		Muestra un texto formateado como título.

	.DESCRIPTION
		Muestra un texto con fondo blanco y letras negras, resaltado con líneas horizontales, simulando un título.

	.PARAMETER Text
		El texto que se mostrará como título. Este parámetro es obligatorio.

	.EXAMPLE
		WTitulo "Este es un título importante."
		Muestra el texto "Este es un título importante." con formato de título.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-12-07
		Versión: 1.0.2

	.INPUTS
		System.String

	.OUTPUTS
		Ninguno (La función escribe directamente en la consola)

	#>
	param(
		[Parameter(Mandatory, Position = 0)]
		[string]
		$Text
	)
	process {
		# Calcular el ancho total del título, incluyendo espacios.
		$width = $text.Length
		$Spaces = 8
		$width += ($spaces * 2)

		# Crear la línea horizontal.
		$clearLine = "-" * $width

		# Primera línea en blanco
		$finalText = "`n`n$clearLine"
		Write-Host $finalText

		# 2da linea. Espacios al lado izquierdo
		$finalText = "$('_' * $Spaces)"

		# 2da linea. Texto del título
		$finalText += "$($text.ToUpper())"

		# 2da linea. Espacios al lado derecho
		$finalText += "$('_' * $Spaces)"

		Write-Host $finalText

		# Ultima línea en blanco
		$finalText = "$clearLine"
		Write-Host "$finalText"
	}
}

function wWarning {
	<#
	.SYNOPSIS
		Muestra un texto de advertencia o resaltado.

	.DESCRIPTION
		Muestra un texto de color amarillo y opcionalmente con formato.
		Utiliza la función Reset-EndLine para aplicar el formato.

	.PARAMETER Text
		El texto que se mostrará como advertencia. Este parámetro es obligatorio.

	.PARAMETER wider
		Un interruptor (switch) opcional. Al especificarse, hará que el texto se vea al ancho de la consola.

	.EXAMPLE
		wWarning "Este es un mensaje de advertencia."
		Muestra el texto "Este es un mensaje de advertencia." con formato de advertencia.

	.EXAMPLE
		wWarning -Text "Texto de advertencia extenso..." -wider
		Esto hará que un texto ancho se divida en base al ancho de la consola.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-03-12
		Fecha de modificación: 2025-03-12
		Versión: 1.0.0

	.INPUTS
		System.String

	.OUTPUTS
		Ninguno (La función escribe directamente en la consola)

	#>
	param(
		[Parameter(Mandatory, Position = 0)]
		[string]
		$Text,
		[switch]
		$Wider = $false
	)
	process {
		# Formatear y mostrar el texto usando Reset-EndLine
		Write-Host (Reset-EndLine -Text "$($Text)" -custom "$($TerminalColor.txt.yellow)" -Wider:([bool]$wider))
	}
}
