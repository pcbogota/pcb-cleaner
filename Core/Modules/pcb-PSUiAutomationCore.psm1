<#
Tabla de Categorías de Funciones
-------------------------------------------------------------------------------
| Función                       | SYNOPSIS                                    |
-------------------------------------------------------------------------------
| Find-UIElementByName          | Busca un elemento de interfaz de usuario    |
|                               | por nombre, con opciones de retorno y       |
|                               | manejo de interacciones específicas.        |
|                               |                                             |
| Get-FocusedUIElement          | Obtiene el AutomationElement que tenga el   |
|                               | foco o información asociada.                |
|                               |                                             |
| Invoke-MouseAction            | Ejecuta una acción de mouse en una          |
|                               | posición específica con desplazamientos     |
|                               | opcionales.                                 |
|                               |                                             |
| Save-FocusedElementScreenshot | Captura una imagen del elemento de interfaz |
|                               | de usuario actualmente enfocado y la guarda |
|                               | como archivo PNG.                           |
|                               |                                             |
| Select-ComboBoxItem           | Selecciona un ítem de un ComboBox en una    |
|                               | aplicación GUI mediante UIAutomation.       |
|                               |                                             |
| Select-StartMenuProgram       | Busca y selecciona un programa o acceso     |
|                               | directo en el menú inicio de Windows,       |
|                               | expandiendo carpetas si es necesario.       |
|                               |                                             |
| Set-CollapseExpand            | Cambia el estado expandido o colapsado de   |
|                               | un control enfocado en la interfaz de       |
|                               | usuario.                                    |
|                               |                                             |
| Set-UIElementToggle           | Cambia el estado On/Off de un control       |
|                               | Toggle ya enfocado en la interfaz Windows.  |
|                               |                                             |
| Show-App                      | Inicia o enfoca una aplicación o URI        |
|                               | especificado, con la opción de cerrar       |
|                               | instancias existentes primero.              |
|                               |                                             |
| Show-WindowUIElements         | Muestra los nombres, clases y tipos de      |
|                               | control de todos los elementos de la        |
|                               | ventana activa.                             |
|                               |                                             |
| Test-NextFocus                | Detecta y muestra el siguiente elemento     |
|                               | enfocado en la interfaz después de enviar   |
|                               | teclas, permitiendo saltar cambios          |
|                               | intermedios de foco.                        |
|                               |                                             |
| Test-UILanguage               | Comprueba si la referencia cultural de la   |
|                               | interfaz de usuario actual coincide con un  |
|                               | idioma especificado.                        |
|                               |                                             |
| Wait-UIFocusMatch             | Espera hasta que el elemento actualmente    |
|                               | enfocado coincida con un Name y/o un        |
|                               | ControlType específico.                     |
|                               |                                             |
| Wait-UIFocusChange            | Espera hasta que el elemento enfocado deje  |
|                               | de coincidir con un Name y/o un ControlType |
|                               | especificado.                               |
|                               |                                             |
-------------------------------------------------------------------------------

Total de funciones: 15

#>

# Carga la librería UIAutomationClient para trabajar con UI Automation en .NET
Add-Type -AssemblyName UIAutomationClient

function Find-UIElementByName {
	<#
	.SYNOPSIS
	Busca un elemento de interfaz de usuario por nombre, con opciones de retorno y manejo de interacciones específicas.

	.DESCRIPTION
	La función `Find-UIElementByName` permite localizar un elemento de UI que tenga el foco mediante su nombre (y opcionalmente su tipo). Está diseñada para recorrer secuencialmente los controles de la ventana activa usando teclas de navegación (TAB, flechas, etc.) definidas por tipo de control. Soporta dos modos de operación: búsqueda (Search) y exploración informativa (Info). Incluye manejo automático de expansores, carpetas contraídas del menú inicio y prevención de ciclos infinitos.

	.PARAMETER Target
	[string] Nombre del elemento a buscar. Obligatorio en el modo Search.

	.PARAMETER AsBoolean
	[switch] Si se especifica, la función devuelve $true o $false en lugar de un objeto o salida nula.

	.PARAMETER AsElement
	[switch] Si se especifica, la función devuelve el objeto AutomationElement encontrado.

	.PARAMETER Type
	[string] Opcional. Tipo de elemento (ClassName) a coincidir. Si no se especifica, se acepta cualquier tipo. Debe pertenecer a la lista de tipos permitidos.

	.PARAMETER Info
	[switch] Activa el modo información: recorre la interfaz mostrando nombre, clase y tipo de control de cada elemento, sin buscar un objetivo concreto.

	.PARAMETER MaxIterations
	[int] Número máximo de iteraciones permitidas antes de detenerse. Valor por defecto: 100.

	.PARAMETER TabDelayMs
	[int] Tiempo de espera entre pulsaciones de tecla en milisegundos. Valor por defecto: 20.

	.PARAMETER KeyMappings
	[hashtable] Mapeo de nombres de clase a teclas de navegación de navegación específicas.

	.EXAMPLE
	Find-UIElementByName -Target "Aceptar" -AsElement
	Busca el elemento con nombre exacto "Aceptar" y devuelve el objeto AutomationElement del elemento.

	.EXAMPLE
	Find-UIElementByName "Configuración" -Type "ListViewItem" -AsBoolean
	Busca un elemento de tipo ListViewItem llamado "Configuración" y devuelve $true si lo encuentra, $false en caso contrario.

	.EXAMPLE
	Find-UIElementByName -Info
	Recorre la ventana activa mostrando los detalles de cada control.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-04-07
		Fecha de modificación: 2026-04-26
		Versión de la función: 1.0.3

		Posibles tipos que se pueden utilizar en el parámetro type:
		Button:        Botón
		CheckBox:      Casilla de verificación
		ComboBox:      Lista desplegable
		Edit:          Campo de texto
		GridViewItem:  Elemento de contenedor
		Group:         Grupo
		HeaderItem:    Elemento de encabezado
		Hyperlink:     Enlace hipertexto
		List:          Lista
		ListItem:      Elemento de lista
		Menu:          Menú
		MenuItem:      Opción de menú
		ProgressBar:   Barra de progreso
		RadioButton:   Botón de opción
		ScrollBar:     Barra de desplazamiento
		Slider:        Control deslizante
		StatusBar:     Barra de estado
		Tab:           Pestaña
		TabPage:       Página de pestaña
		TextBox:       Cuadro de texto
		ToolBar:       Barra de herramientas
		ToolTip:       Información rápida
		Tree:          Árbol
		TreeNode:      Nodo de árbol
		Window:        Ventana

	.INPUTS
	Esta función no acepta entradas desde la tubería.

	.OUTPUTS
	En modo Search:
		Sin AsBoolean ni AsElement: no devuelve nada (solo efecto de navegación).
		Con AsBoolean: devuelve [bool].
		Con AsElement: devuelve System.Windows.Automation.AutomationElement.
		En modo Info: muestra información en pantalla y no devuelve ningún objeto.

	.LINK
	https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
	https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/send-keys?view=powershell-5.1
	https://docs.microsoft.com/en-us/dotnet/api/system.windows.automation.automationelement?view=netframework-4.8
	#>


	[CmdletBinding(DefaultParameterSetName = 'Search')]
	param(
		[Parameter(Mandatory, ParameterSetName = 'Search', Position = 0)]
		[string]$Target,

		[Parameter(ParameterSetName = 'Search')]
		[switch]$AsBoolean,

		[Parameter(ParameterSetName = 'Search')]
		[switch]$AsElement,

		[Parameter(ParameterSetName = 'Search')]
		[ValidateScript({
				# Definimos una sola vez el listado de tipos permitidos
				$allowed = @(
					'Button', 'CheckBox', 'ComboBox', 'Edit', 'ExpanderToggleButton', 'Group', 'HeaderItem', 'Hyperlink',
					'List', 'ListItem', 'ListViewItem', 'Menu', 'MenuItem', 'Microsoft.UI.Xaml.Controls.NavigationViewItem', 'ProgressBar', 'RadioButton',
					'ScrollBar', 'Slider', 'StatusBar', 'Tab', 'TabPage', 'TextBox',
					'ToggleSwitch', 'ToolBar', 'ToolTip', 'Tree', 'TreeNode', 'Window', 'GridViewItem'
				)
				if ($_ -in $allowed) {
					$true
				} else {
					throw "Tipo inválido: '$_'. Tipos válidos: $($allowed -join ', ')"
				}
			})]
		[string]$Type,

		[Parameter(Mandatory, ParameterSetName = 'Info')]
		[switch]$Info,

		[int]$MaxIterations = 100,
		[int]$TabDelayMs = 40,
		[hashtable]$KeyMappings = @{
			"ListViewHeaderItem"                            = '{TAB}'
			"ListViewItem"                                  = '{DOWN}'
			"GridViewItem"                                  = '{RIGHT}'
			"Microsoft.UI.Xaml.Controls.NavigationViewItem" = '{DOWN}'
			"ExpanderToggleButton"                          = '{TAB}'  # Se manejará programáticamente
			"Taskbar.TaskListButtonAutomationPeer"          = '{RIGHT}'
			"MenuFlyoutItem"                                = '{DOWN}'
			"MenuFlyoutSubItem"                             = '{DOWN}'
		}
	)

	# Guarda el elemento con foco al iniciar, para detectar ciclo completo.
	$firstElement = [System.Windows.Automation.AutomationElement]::FocusedElement
	if (-not $firstElement) {
		Write-Warning "No hay elemento enfocado inicial."
		return
	}
	# 2. Inicializa variables para controlar el ciclo de navegación
	$lastElement = $null
	$sameElementCount = 0

	# Bucle principal que recorre elementos enfocados usando teclas de navegación.
	for ($count = 0; $count -lt $MaxIterations; $count++) {

		$currentElement = [System.Windows.Automation.AutomationElement]::FocusedElement

		# Modo Info: Si no es la primera iteración, muestra una vista rápida del elemento actual.
		if ($PSCmdlet.ParameterSetName -eq 'Info' -and $count -ne 0) {
			Get-FocusedUIElement -QuickInfo
		}

		# Modo Search: Evalúa si el elemento actual coincide con "Target" y, opcionalmente, el "Type"; si coincide, retorna información según los switches.
		else {
			$name = $currentElement.Current.Name
			$className = $currentElement.Current.ClassName
			if ($name -eq $Target -and ([string]::IsNullOrEmpty($Type) -or $className -eq $Type) -or ($Target -match "\*" -and $name -match ($Target -replace "\*", ''))) {
				if ($AsBoolean) { return $true }
				if ($AsElement) { return $currentElement }
				return
			}
		}

		# Si el elemento es un Expander colapsado, lo expande para continuar la navegación
		if ($currentElement.Current.ClassName -eq "ExpanderToggleButton" -or $currentElement.Current.ClassName -eq "Microsoft.UI.Xaml.Controls.Expander") {
			try {
				$pattern = $currentElement.GetCurrentPattern(
					[System.Windows.Automation.ExpandCollapsePattern]::Pattern
				)

				if ($pattern.Current.ExpandCollapseState -eq "Collapsed") {
					$pattern.Expand()
					Start-Sleep -Milliseconds 400  # Esperar a que se actualice la UI
				}
			} catch {}
		}
		# Expande carpetas contraídas en el menú inicio enviando {SPACE}
		if ($currentElement.Current.ClassName -eq "ListViewItem" -and $currentElement.Current.Name -imatch "Carpeta.*, contraída") {
			try {
				Send-Keys "{SPACE}"
			} catch {}
		}

		# Si el elemento actual vuelve a ser el inicial después de avanzar, se ha completado un ciclo completo y debe terminar.
		if ($currentElement -eq $firstElement -and $count -gt 1) {
			if ($PSCmdlet.ParameterSetName -ne 'Info') {
				Write-Host "Ciclo completo detectado sin encontrar '$Target'. " -ForegroundColor Yellow
			}
			Write-Host "Elementos recorridos: " -NoNewline
			Write-Host " $count" -ForegroundColor Cyan
			break
		}

		# Selecciona la tecla para avanzar según la clase del elemento; por defecto, TAB.
		$key = if ($KeyMappings.ContainsKey($currentElement.Current.ClassName)) {
			$KeyMappings[$currentElement.Current.ClassName]
		} else {
			'{TAB}'
		}

		# Si el elemento se repite varias veces seguidas, fuerza TAB para romper el estancamiento.
		# En ListViewItem, si se repite más de 3 veces, cambia a TAB para evitar bloqueo.
		if ($sameElementCount -gt 3 -and $currentElement.Current.ClassName -eq "ListViewItem") {
			$key = '{TAB}'
		} elseif ($currentElement -eq $lastElement) {
			$sameElementCount++
			if ($sameElementCount -ge 3) {
				# Usar TAB como alternativa si hay elementos repetidos
				$key = '{TAB}'
				$sameElementCount = 0
			}
		} else {
			$sameElementCount = 0
		}
		# Envía la tecla de navegación y espera el retardo configurado para la secuencia.
		Send-Keys $key 1 $TabDelayMs
		$lastElement = $currentElement
	}

	if ($PSCmdlet.ParameterSetName -eq 'Info') {
		Write-Warning "Los elementos de información mostrados solo son para referencia, de necesitar datos adicionales ejecutar los dos siquientes comandos:`nFind-UIElementByName -Target `"Elemento_objetivo`"`nGet-FocusedUIElement -Info`n`n"
	}

	# Si se supera el límite máximo de iteraciones, se advierte.
	if ($count -ge $MaxIterations) {
		Write-Warning "Límite de iteraciones alcanzado ($MaxIterations)."
	}

	# En modo Search con AsBoolean, devuelve $false si no se encontró.
	if ($PSCmdlet.ParameterSetName -eq 'Search' -and $AsBoolean) { return $false }
}

function Get-FocusedUIElement {
	<#
	.SYNOPSIS
		Obtiene el AutomationElement que tenga el foco o información asociada.

	.DESCRIPTION
		La función Get-FocusedUIElement captura el elemento de UI Automation que actualmente tiene
		el foco en el sistema. Dependiendo de los switches suministrados, puede devolver:
		- Booleano comparando el nombre actual con un nombre esperado.
		- Un objeto de propiedades detalladas del elemento.
		- Una salida rápida en texto con los campos básicos.
		También muestra en consola información detallada de patrones soportados y, si es un ComboBox,
		sus ítems.

	.PARAMETER ExpectedName
		[string]  Opcional.
		Nombre exacto esperado del elemento para la comparación en modo booleano.

	.PARAMETER AsBoolean
		[switch]  Opcional.
		Si se incluye, la función devuelve $true/$false comparando
		`$elem.Current.Name -eq $ExpectedName`.

	.PARAMETER Info
		[switch]  Opcional.
		Si se incluye, construye y devuelve un PSCustomObject con todas las propiedades relevantes del elemento.

	.PARAMETER QuickInfo
		[switch]  Opcional.
		Si se incluye, emite por consola una versión resumida de Name, ClassName y ControlType.

	.EXAMPLE
		# Comparar nombre y devolver booleano
		Get-FocusedUIElement -ExpectedName "Editor" -AsBoolean

	.EXAMPLE
		# Mostrar información completa del elemento
		Get-FocusedUIElement -Info

	.INPUTS
		Ninguno. No acepta entrada por la tubería.

	.OUTPUTS
		Dependiendo de switches:
		- Booleano ($true/$false)
		- PSCustomObject con propiedades del elemento
		- BoundingRectangle u otros objetos .Current
		- Si no hay switches, devuelve `$elem.Current`

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-05-20
		Fecha de modificación: 2025-12-10
		Versión: 1.0.1

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
		https://docs.microsoft.com/en-us/dotnet/api/system.windows.automation.automationelement?view=windowsdesktop-5.0
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-warning?view=powershell-5.1
	#>

	[CmdletBinding()]
	param(
		[string]  $ExpectedName,
		[switch]  $AsBoolean, # Si se pasa, devuelve $true/$false comparando con $ExpectedName
		[switch]  $Info, # Si se pasa, devuelve un objeto de propiedades del elemento
		[switch]  $QuickInfo   # Si se pasa, devuelve un texto con elos elementos básicos
	)

	try {
		# Obtiene el AutomationElement actualmente con foco
		$elem = [System.Windows.Automation.AutomationElement]::FocusedElement
		if (-not $elem) {
			Write-Verbose "No hay elemento enfocado"
			if ($AsBoolean) { return $false }
			return $null
		}

		# Agrupa la lógica de presentación de detalles cuando se usa -Info o -QuickInfo
		if ($Info -or $QuickInfo) {
			# Obtiene la propiedad BoundingRectangle del elemento
			$r = $elem.Current.BoundingRectangle
			# Muestra Name, ClassName y ControlType siempre
			Write-Host "Name                 : $($elem.Current.Name)"
			Write-Host "ClassName            : $($elem.Current.ClassName)"
			Write-Host "ControlType          : $($elem.Current.ControlType.ProgrammaticName)"
			if (-not $QuickInfo) {
				# En modo Info completo, muestra AutomationId, LocalizedControlType, estado y BoundingRectangle
				Write-Host "AutomationId         : $($elem.Current.AutomationId)"
				Write-Host "LocalizedControlType : $($elem.Current.LocalizedControlType)"
				Write-Host "IsEnabled            : $($elem.Current.IsEnabled)"
				Write-Host "`nBoundingRectangle:"
				Write-Host "    X      : $($r.X)"
				Write-Host "    Y      : $($r.Y)"
				Write-Host "    Width  : $($r.Width)"
				Write-Host "    Height : $($r.Height)"
				Write-Host "`nPatterns & States    :"

				# Recorre cada PatternIdentifier soportado e intenta volcar sus propiedades .Current
				foreach ($patId in $elem.GetSupportedPatterns()) {
					# Determina nombre amigable del patrón
					$fullName = $patId.ProgrammaticName
					if ($fullName -match '(\w+)PatternIdentifiers') { $patName = $matches[1] }
					else { $patName = $fullName.Split('.')[ - 1] }

					Write-Host ">>> Pattern: $patName" -ForegroundColor Yellow
					try {
						$patternObj = $elem.GetCurrentPattern($patId)
						# Muestra todas las propiedades actuales del objeto de patrón
						$patternObj.Current.psobject.Properties | ForEach-Object {
							$name = if ([string]::IsNullOrEmpty($_.Name)) { "No name" } else { $_.Name }
							$value = if ([string]::IsNullOrEmpty($_.Value)) { "n/a" } else { $_.Value }
							Write-Host ("    {0,-20}: {1}" -f $name, $value)
						}
					} catch {
						Write-Warning "    ❌ No se pudo instanciar patrón $($patName): $_"
					}
					Write-Host ""
				}
			} else {
				Write-Host "-------"
			}

			# Si el elemento es un ComboBox y no estamos en QuickInfo, lista sus ítems
			if ($elem.Current.ClassName -eq "ComboBox" -and (-not $QuickInfo)) {
				Write-Host ">>> ComboBox Items:" -ForegroundColor Green

				try {
					# Expande el ComboBox para exponer los ListItems
					$exp = $elem.GetCurrentPattern(
						[System.Windows.Automation.ExpandCollapsePattern]::Pattern
					)
					$exp.Expand()
					Start-Sleep -Milliseconds 50
				} catch { }

				# Busca y enumera ListItems bajo el subtree
				$items = $elem.FindAll(
					[System.Windows.Automation.TreeScope]::Subtree,
					[System.Windows.Automation.Condition]::TrueCondition
				) | Where-Object {
					$_.Current.ControlType -eq [System.Windows.Automation.ControlType]::ListItem
				}

				if ($items.Count -eq 0) {
					Write-Host "    (no se encontraron ítems)"
				} else {
					$i = 0
					foreach ($it in $items) {
						$i++
						Write-Host ("  {0,3}. {1}" -f $i, $it.Current.Name)
					}
				}

				# Colapsa de nuevo el ComboBox
				try {
					$exp.Collapse()
				} catch { }
				Write-Host ""
			}

			return

			# Agrupa la lógica de retorno según switches: Info/QuickInfo, AsBoolean o Current
		} elseif ($AsBoolean) {
			# Devuelve true si el nombre actual coincide exactamente con ExpectedName
			return ($elem.Current.Name -eq $ExpectedName)
		} else {
			# Devuelve el objeto Current del elemento enfocado
			return $elem.Current
		}
	} catch {
		# Captura y reporta errores de UI Automation; respeta el switch -AsBoolean
		Write-Warning "Error UIA: $_"
		if ($AsBoolean) { return $false }
		return $null
	}
}

function Invoke-MouseAction {
	<#
	.SYNOPSIS
		Ejecuta una acción de mouse en una posición específica con desplazamientos opcionales.

	.DESCRIPTION
		Esta función realiza una acción de mouse combinando lógica en PowerShell con una llamada directa a una clase definida en una librería C# externa previamente cargada mediante Add-Type. Calcula una posición final a partir de coordenadas base y desplazamientos opcionales, introduce una pausa breve para sincronización y ejecuta opcionalmente un clic izquierdo o derecho. Aunque utiliza una implementación nativa en C#, esta función agrega una capa mínima de lógica y control, actuando como un punto intermedio entre funciones de muy bajo nivel y automatización básica de interfaz gráfica.

	.PARAMETER X
		[int] Coordenada horizontal base en pantalla utilizada para calcular la posición final del cursor. Obligatorio.

	.PARAMETER Y
		[int] Coordenada vertical base en pantalla utilizada para calcular la posición final del cursor. Obligatorio.

	.PARAMETER OffsetX
		[int] Desplazamiento horizontal opcional aplicado a la coordenada X base. Opcional.

	.PARAMETER OffsetY
		[int] Desplazamiento vertical opcional aplicado a la coordenada Y base. Opcional.

	.PARAMETER Click
		[switch] Indica que se debe ejecutar un clic izquierdo del mouse en la posición calculada. Opcional.

	.PARAMETER RightClick
		[switch] Indica que se debe ejecutar un clic derecho del mouse en la posición calculada. Opcional.

	.EXAMPLE
		Invoke-MouseAction -X 500 -Y 300 -Click
		Mueve el cursor a la posición indicada y ejecuta un clic izquierdo.

	.EXAMPLE
		Invoke-MouseAction -X 800 -Y 600 -OffsetX 10 -OffsetY -5 -RightClick
		Mueve el cursor aplicando desplazamientos y ejecuta un clic derecho.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-12-16
		Fecha de modificación: 2025-12-16
		Versión: 1.0.0
		Requiere que la librería C# correspondiente (mousesim.cs) haya sido cargada previamente mediante Add-Type -Path "$PSScriptRoot\mousesim.cs". Esta función es de bajo nivel y actúa como puente directo entre PowerShell y la implementación nativa en C#.

	.INPUTS
		No acepta entrada desde la tubería.

	.OUTPUTS
		No devuelve ningún valor. Ejecuta una acción directa del mouse en la interfaz gráfica.

	.LINK
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/add-type?view=powershell-5.1
	#>

	# Define las coordenadas base y los desplazamientos opcionales para calcular la posición final del cursor.
	param(
		[int]$X,
		[int]$Y,
		[int]$OffsetX = 0,
		[int]$OffsetY = 0,
		[switch]$Click,
		[switch]$RightClick
	)

	# Cálculo de las coordenadas finales del cursor aplicando los desplazamientos definidos.
	$finalX = $X + $OffsetX
	$finalY = $Y + $OffsetY

	# Pausa breve antes de ejecutar la acción para sincronización básica con la interfaz gráfica.
	Start-Sleep -Milliseconds 400

	# Llamada directa a la implementación en C# para mover el cursor y ejecutar la acción de clic indicada.
	[InputSim.MouseSim]::ClickAt($finalX, $finalY, $Click.IsPresent, $RightClick.IsPresent)
}

function Save-FocusedElementScreenshot {
	<#
	.SYNOPSIS
		Captura una imagen del elemento de interfaz de usuario actualmente enfocado y la guarda como archivo PNG.

	.DESCRIPTION
		Esta función obtiene el elemento de interfaz de usuario que tiene el foco en el sistema, calcula su área visible en
		pantalla y realiza una captura de pantalla limitada a dicho rectángulo. La imagen capturada puede ser escalada a un
		factor específico y almacenada con una resolución DPI configurable. El resultado incluye tanto la ruta del archivo
		generado como metadatos detallados del área capturada, permitiendo su uso en escenarios de automatización, análisis
		visual u OCR. La función está diseñada para operar de forma defensiva en entornos multi-monitor y no acepta entrada
		desde la tubería.

	.PARAMETER OutputPath
		[string] Ruta opcional donde se guardará la imagen capturada. Si no se especifica, la imagen se guarda en el
		Escritorio del usuario con un nombre basado en la fecha y hora actual.

	.PARAMETER scaleFactor
		[double] Factor de escalado aplicado a la imagen capturada antes de guardarla. Debe ser mayor que cero. Valores
		mayores a 1 incrementan la resolución efectiva de la imagen.

	.PARAMETER dpi
		[int] Resolución DPI asignada a la imagen resultante. Este valor se establece como metadato de la imagen y debe ser
		mayor que cero.

	.PARAMETER Force
		[switch] Permite sobrescribir el archivo de salida si ya existe. Si no se especifica, se genera un nombre
		alternativo para evitar la sobrescritura.

	.EXAMPLE
		Save-FocusedElementScreenshot "C:\Temp\captura.png" 2 300

		Realiza una captura del elemento enfocado, la escala al doble de su tamaño original, asigna 300 DPI y guarda la
		imagen en la ruta especificada.

	.EXAMPLE
		Save-FocusedElementScreenshot -scaleFactor 1.5 -dpi 300 -Force

		Realiza una captura del elemento enfocado utilizando parámetros nombrados, aplica un escalado de 1.5, asigna 300
		DPI y permite sobrescribir el archivo de salida si existe.

	.NOTES
		Fecha de creación: 2025-02-01
		Fecha de modificación: 2025-02-01
		Versión: 1.0.0
		Autor: Camilo Salazar

	.INPUTS
		Ninguno. Esta función no acepta entrada desde la tubería.

	.OUTPUTS
		System.Collections.Hashtable. Devuelve un objeto que contiene la ruta de la imagen generada, las coordenadas del
		área capturada y el objeto de límites original del elemento enfocado.

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/add-type?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/test-path?view=powershell-5.1
		Función personalizada interna del módulo: Get-FocusedUIElement
	#>
	param(
		# Ruta opcional para guardar la imagen. Por defecto: Escritorio con nombre basado en fecha.
		[string]$OutputPath = "$([Environment]::GetFolderPath('Desktop'))\CoreInput_Captura_$(Get-Date -Format 'yyyyMMdd_HHmmss').png",
		[double]$scaleFactor = 1,
		[int]$dpi = 300,
		[switch]$Force
	)
	# Añadir ensamblados necesarios para captura de pantalla
	Add-Type -AssemblyName System.Drawing, System.Windows.Forms -ErrorAction Stop

	# Validaciones preventivas de parámetros de entrada para evitar estados inválidos durante la captura y el escalado.
	if ($ScaleFactor -le 0) {
		throw "El parámetro scaleFactor debe ser mayor a cero."
	}

	if ($Dpi -le 0) {
		throw "El parámetro dpi debe ser mayor a cero."
	}


	# Obtiene el elemento de interfaz actualmente enfocado utilizando una función personalizada interna del módulo.
	$focusedElement = Get-FocusedUIElement

	if (-not $focusedElement) {
		throw "No se encontró elemento con foco. No es posible realizar la captura."
	}

	# Obtiene el rectángulo de límites del elemento enfocado y valida que el área resultante sea apta para una captura de pantalla.
	$bounds = $focusedElement.BoundingRectangle
	if ($bounds.Width -le 0 -or $bounds.Height -le 0) {
		Write-Error "El área del elemento es demasiado pequeña o no es válida para capturar."
		return $null
	}

	# Ajustar a enteros y redondear para evitar truncamiento que pierda 1px en los bordes
	$x = [int][math]::Round($bounds.X)
	$y = [int][math]::Round($bounds.Y)
	$w = [int][math]::Round($bounds.Width)
	$h = [int][math]::Round($bounds.Height)

	# Ajusta el área de captura a los límites del escritorio virtual para soportar entornos multi-monitor y evitar coordenadas inválidas.
	$vs = [System.Windows.Forms.SystemInformation]::VirtualScreen
	$x = [math]::Max($vs.Left, $x)
	$y = [math]::Max($vs.Top, $y)
	if ($x + $w -gt $vs.Right) { $w = $vs.Right - $x }
	if ($y + $h -gt $vs.Bottom) { $h = $vs.Bottom - $y }
	if ($w -le 0 -or $h -le 0) {
		throw "El área de captura queda fuera de la pantalla."
	}

	# Previene la creación de bitmaps excesivamente grandes que puedan provocar consumo excesivo de memoria o errores de GDI+.
	$maxDim = 16000
	$scaledWidth = [int]([math]::Round($w * $ScaleFactor))
	$scaledHeight = [int]([math]::Round($h * $ScaleFactor))
	if ($scaledWidth -gt $maxDim -or $scaledHeight -gt $maxDim) {
		throw "Resultado escalado excede límites prácticos ($maxDim px). El paramétro scaleFactor debe reducirse."
	}

	# Evitar sobrescritura no deseada
	if ((Test-Path $OutputPath) -and -not $Force) {
		$base = [System.IO.Path]::GetFileNameWithoutExtension($OutputPath)
		$ext = [System.IO.Path]::GetExtension($OutputPath)
		$dir = [System.IO.Path]::GetDirectoryName($OutputPath)
		$i = 1
		do {
			$candidate = Join-Path $dir ("{0} ({1}){2}" -f $base, $i, $ext)
			$i++
		} while (Test-Path $candidate)
		$OutputPath = $candidate
	}

	# Captura y escalado con liberación segura
	$captureRect = [System.Drawing.Rectangle]::new($x, $y, $w, $h)
	$srcBitmap = $null
	$scaledBitmap = $null

	try {
		$srcBitmap = New-Object System.Drawing.Bitmap($captureRect.Width, $captureRect.Height)
		$srcGraphics = [System.Drawing.Graphics]::FromImage($srcBitmap)

		try {
			$srcGraphics.CopyFromScreen($captureRect.Location, [System.Drawing.Point]::Empty, $captureRect.Size)
		} finally {
			$srcGraphics.Dispose()
		}

		# Escalado
		$scaledBitmap = New-Object System.Drawing.Bitmap($scaledWidth, $scaledHeight)
		$scaledBitmap.SetResolution($Dpi, $Dpi)
		$scaledGraphics = [System.Drawing.Graphics]::FromImage($scaledBitmap)
		try {
			$scaledGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
			$scaledGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

			# Se utiliza SmoothingMode=None para preservar la nitidez del texto en interfaces gráficas.
			$scaledGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
			$scaledGraphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy

			$scaledGraphics.DrawImage($srcBitmap, 0, 0, $scaledWidth, $scaledHeight)
		} finally {
			$scaledGraphics.Dispose()
		}

		$scaledBitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
	} finally {
		if ($srcBitmap) {
			$srcBitmap.Dispose()
		}
		if ($scaledBitmap) {
			$scaledBitmap.Dispose()
		}
	}

	return @{
		ImagePath   = $OutputPath
		CaptureArea = @{
			X      = $x
			Y      = $y
			Width  = $w
			Height = $h
			Right  = $x + $w
			Bottom = $y + $h
		}
		Bounds      = $bounds
	}
}

function Select-ComboBoxItem {
	<#
	.SYNOPSIS
		Selecciona un ítem de un ComboBox en una aplicación GUI mediante UIAutomation.

	.DESCRIPTION
		La función Select-ComboBoxItem expande el ComboBox que tenga el foco, busca en todo su árbol de elementos
		un ListItem cuyo nombre coincida exactamente con el parámetro -desiredItem (sin acentos y sin diferenciar mayúsculas),
		y lo selecciona usando SelectionItemPattern o, en su lugar, escribiendo el valor con ValuePattern si está disponible.
		Finalmente, colapsa el ComboBox para restaurar su estado original.

	.PARAMETER desiredItem
		[string]  Obligatorio.
		Texto exacto del elemento que se desea seleccionar. La comparación se hace eliminando acentos y sin distinguir mayúsculas.

	.EXAMPLE
		# Uso con parámetro posicional:
		Select-ComboBoxItem "Opción Avanzada"

	.EXAMPLE
		# Uso con parámetro nombrado:
		Select-ComboBoxItem -desiredItem "Opción Básica"

	.INPUTS
		Ninguno. Esta función no acepta entrada por la tubería.

	.OUTPUTS
		Ninguno. Solo emite mensajes en consola (Write-Host, Write-Warning).

	.NOTES
		Autor: Camilo Salzar
		Fecha de creación: 2025-05-20
		Fecha de modificación: 2025-05-20
		Versión: 1.0.0

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-warning?view=powershell-5.1
		https://docs.microsoft.com/en-us/dotnet/api/system.windows.automation?view=windowsdesktop-5.0
	#>
	param(
		[string]$desiredItem   # texto exacto de la opción que quieres seleccionar
	)

	# Obtiene el AutomationElement que actualmente tiene el foco (debe ser un ComboBox)
	$combo = [System.Windows.Automation.AutomationElement]::FocusedElement

	# Si no se detecta un elemento con foco, muestra advertencia y sale
	if (-not $combo) {
		Write-Warning "No hay elemento enfocado."
		return
	}
	# Expansión del ComboBox
	$expPattern = $combo.GetCurrentPattern(
		[System.Windows.Automation.ExpandCollapsePattern]::Pattern
	)

	# Obtiene y usa el patrón ExpandCollapsePattern para abrir el ComboBox
	$expPattern.Expand()
	# Pausa breve para asegurar que la UI termine de renderizar los ítems
	Start-Sleep -Milliseconds 300

	# Encuentra todos los ListItem bajo el ComboBox usando TreeScope.Subtree
	$condition = [System.Windows.Automation.Condition]::TrueCondition
	$listItems = $combo.FindAll(
		[System.Windows.Automation.TreeScope]::Subtree,
		$condition
	) | Where-Object {
		$_.Current.ControlType -eq [System.Windows.Automation.ControlType]::ListItem
	}
	# Elimina acentos y pasa a minúsculas para comparación insensible
	$normalizedDesired = (Remove-Accents $desiredItem).ToLower()

	# Recorre cada ListItem, normaliza su nombre y compara con el deseado
	foreach ($item in $listItems) {
		$normalizedItem = (Remove-Accents ($item.Current.Name)).ToLower()
		if ($normalizedItem -eq $normalizedDesired) {
			#  Verifica y utiliza SelectionItemPattern para seleccionar el elemento
			if ($item.GetSupportedPatterns() |
				Where-Object { $_.ProgrammaticName -match 'SelectionItemPattern' }) {
				$selPattern = $item.GetCurrentPattern(
					[System.Windows.Automation.SelectionItemPattern]::Pattern
				)
				$selPattern.Select()
				Write-Host "Seleccionado '$desiredItem'"
			}
			# Si el elemento soporta ValuePattern (ComboBox editable), asigna el texto directamente
			elseif ($item.GetSupportedPatterns() |
				Where-Object { $_.ProgrammaticName -match 'ValuePattern' }) {
				$valPattern = $item.GetCurrentPattern(
					[System.Windows.Automation.ValuePattern]::Pattern
				)
				$valPattern.SetValue($desiredItem)
				Write-Host "Escrito y seleccionado '$desiredItem'"
			} else {
				Write-Warning "El ítem no tiene patrón de selección ni valor."
			}
			break
		}
	}

	# Cierra el ComboBox restaurando su estado con Collapse()
	$expPattern.Collapse()
	# ————————————————
	# Ejemplo de uso:
	#  1) Coloca foco en el ComboBox (con Tab o AppActivate + Send-Keys).
	#  2) Llama a la función con el texto exacto de la opción:
	#  Select-ComboBoxItem -desiredItem "Texto de opción"
	#  Select-ComboBoxItem "Otro Texto"  # posicional
}

function Set-CollapseExpand {
	<#
	.SYNOPSIS
		Cambia el estado expandido o colapsado de un control enfocado en la interfaz de usuario.

	.DESCRIPTION
		Esta función interactúa con el elemento actualmente enfocado en la interfaz gráfica mediante UIAutomation.
		Permite expandir o colapsar elementos que implementan el patrón ExpandCollapse de tipo Expander.
		La función asume que la búsqueda y el enfoque del elemento se han realizado previamente por una función externa.
		El cambio de estado se efectúa solo si el nombre del control coincide exactamente con el parámetro proporcionado.

	.PARAMETER Target
		[string] Nombre del control enfocado con el que se desea interactuar. Obligatorio.

	.PARAMETER State
		[string] Estado deseado del control. Puede ser 'Expand', 'Collapse', 'Open' o 'Close'. Obligatorio.

	.EXAMPLE
		Set-CollapseExpand -Target "Configuración avanzada" -State Expand
		Expande el control actualmente enfocado si se llama "Configuración avanzada".

	.EXAMPLE
		Set-CollapseExpand "Opciones ocultas" Close
		Colapsa el control enfocado si se llama "Opciones ocultas".

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-07-30
		Fecha de modificación: 2025-07-30
		Versión: 1.0.0

	.INPUTS
		No acepta entrada desde la tubería.

	.OUTPUTS
		No retorna ningún valor. Emite advertencias o mensajes Verbose según el flujo de ejecución.

	.LINK
		https://learn.microsoft.com/en-us/dotnet/api/system.windows.automation.expandcollapsepattern?view=windowsdesktop-5.1
		https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/adding-verbose-and-debug-messages?view=powershell-5.1
	#>
	param(
		[Parameter(Mandatory)]
		[string]$Target,
		[Parameter(Mandatory)]
		[ValidateSet('Expand', 'Collapse', 'Open', 'Close')]
		[string]$State
	)

	# Obtiene el elemento que tiene actualmente el foco del sistema
	$currentElement = [System.Windows.Automation.AutomationElement]::FocusedElement

	# Verifica si el elemento tiene una clase correspondiente a un control expandible
	if ($currentElement.TryGetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern, [ref]$null)) {

		# Intenta obtener el patrón ExpandCollapse desde el elemento enfocado
		try {
			$pattern = $currentElement.GetCurrentPattern(
				[System.Windows.Automation.ExpandCollapsePattern]::Pattern
			)

			# Compara el nombre del control enfocado con el parámetro especificado
			if ($currentElement.Current.Name -ne $Target) {
				Write-Warning "El elemento enfocado no coincide con '$Target'."
				return
			}

			# Determina si el estado requerido es expandido o colapsado
			$requiredOpen = ($State -eq "Expand" -or $State -eq "Open")
			$isCollapsed = ($pattern.Current.ExpandCollapseState -eq "Collapsed")


			# Ejecuta la acción correspondiente al estado deseado
			if ($isCollapsed -and $requiredOpen) {
				$pattern.Expand()
			} elseif (-not $isCollapsed -and -not $requiredOpen) {
				$pattern.Collapse()
			}

			# Esperar a que se actualice la UI
			Start-Sleep -Milliseconds 300
		} catch {
			# Si el patrón no es soportado, se muestra un mensaje en modo Verbose
			Write-Verbose "Este Expander no soporta el patrón Expand/Collapse"
		}
	}
}

function Select-StartMenuProgram {
	<#
	.SYNOPSIS
		Busca y selecciona un programa o acceso directo en el menú inicio de Windows, expandiendo carpetas si es necesario.

	.DESCRIPTION
		La función Select-StartMenuProgram abre el menú inicio, localiza la opción "Todos" y busca un elemento cuyo
		nombre coincida con el valor proporcionado. Si el elemento encontrado es una carpeta, la expande y continúa la
		búsqueda en su interior hasta localizar el acceso directo final o hasta agotar un número máximo de intentos.
		Está diseñada exclusivamente para sistemas con interfaz en español (México) y utiliza patrones de automatización de UI.

	.PARAMETER Name
		Tipo: System.String.
		Posición: 0.
		Obligatorio: Sí.
		Nombre o parte inicial del nombre del programa o acceso directo que se desea localizar. Es obligatorio y
		acepta comodines implícitos gracias al uso interno del patrón "$Name*".

	.EXAMPLE
		Select-StartMenuProgram "Bloc de notas"
		Busca y selecciona el acceso directo "Bloc de notas" en el menú inicio usando la posición 0 del parámetro.

	.EXAMPLE
		Select-StartMenuProgram -Name "Word"
		Busca y selecciona el programa "Word" especificando explícitamente el nombre del parámetro.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2026-05-06
		Fecha de modificación: 2026-05-06
		Versión: 1.0.0
		La función utiliza la función `Set-InputBlock` para bloquear que el usuario interfiera en la interfaz
		durante la ejecución. Al finalizar la ejecución deja el modo previo de bloqueo.

	.INPUTS
		None. La función no acepta entrada desde la tubería.

	.OUTPUTS
		None. La función no devuelve objetos; solo realiza acciones de automatización de interfaz de usuario y envía pulsaciones de teclas.

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
		https://docs.microsoft.com/en-us/dotnet/api/system.windows.automation.expandcollapsepattern?view=netframework-4.8
		(Nota: Send-Keys, Find-UIElementByName, Test-UILanguage y wError son funciones personalizadas no incluidas en el script provisto.)
	#>
	param (
		[Parameter(Position = 0, Mandatory = $true)]
		[string]$Name
	)
	begin {
		# Bloquear entradas de teclado si es necesario
		$InitialblockStatus = $global:InputBlocked
		if (-not ($global:InputBlocked)) {
			Set-InputBlock $true
		}
	}
	process {
		if (-not (Test-UILanguage "es-mx")) {
			wError "La función 'Select-StartMenuProgram' no puede usarse en un idioma distinto a español (México)"
			return
		}

		# Abre el menú inicio, busca y selecciona la opción 'Todos' para desplegar todas las aplicaciones
		Send-keys "{WIN}"
		Start-Sleep -Milliseconds 400
		Find-UIElementByName -Target "Todos"
		Send-keys "{ENTER}"

		# Commented line for debuggin using keys down press
		#Send-keys "{DOWN}" -Count 8

		# Busca el primer elemento de interfaz cuyo nombre coincida; puede ser una carpeta o un acceso directo
		$element = Find-UIElementByName -Target "$Name*" -Type 'ListViewItem' -MaxIterations 300 -AsElement

		# Límite de intentos para evitar un bucle infinito al expandir carpetas anidadas
		$maxAttempts = 10

		# Itera expandiendo carpetas hasta encontrar el acceso directo o agotar los intentos
		for ($i = 0; $i -lt $maxAttempts -and $null -ne $element; $i++) {
			$expand = $null
			if ($element.TryGetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern, [ref] $expand)) {
				# El elemento es una carpeta, se puede expandir
				if ($expand.Current.ExpandCollapseState -eq 'Collapsed') {
					$expand.Expand()
					Start-Sleep -Milliseconds 300
				}

				# Navega hacia el primer elemento dentro de la carpeta recién expandida
				Send-Keys "{DOWN}"
				Start-Sleep -Milliseconds 400

				# Reinicia la búsqueda del elemento deseado desde la nueva posición
				$element = Find-UIElementByName -Target "$Name*" -Type 'ListViewItem' -MaxIterations 300 -AsElement
			} else {
				# El elemento no es una carpeta, es el acceso directo buscado; finaliza el bucle
				break
			}
		}
	}
	end {
		if (-not $InitialblockStatus) {
			Set-InputBlock $false
		}
	}
}

function Set-UIElementToggle {
	<#
	.SYNOPSIS
		Cambia el estado On/Off de un control Toggle ya enfocado en la interfaz Windows.

	.DESCRIPTION
		Set-UIElementToggle recibe el nombre exacto de un control UI (Target) que debe estar previamente enfocado.
		Convierte el parámetro State al enum ToggleState correspondiente, valida que el elemento enfocado coincida
		con Target y, si el estado actual difiere del deseado, aplica el cambio utilizando el patrón TogglePattern.
		Incluye manejo de errores para fallos al obtener o aplicar el patrón.

	.PARAMETER Target
		[string] Nombre exacto (Current.Name) del control UI que ya debe estar enfocado. Obligatorio.

	.PARAMETER State
		[ValidateSet('Enable','Disable','On','Off')][string]
		Estado deseado para el toggle. "Enable"/"On" se interpretan como On; "Disable"/"Off" como Off. Obligatorio.

	.EXAMPLE
		# Activa el toggle "Wi-Fi" que ya está enfocado
		Set-UIElementToggle "Wi-Fi" On

	.EXAMPLE
		# Desactiva el toggle "Bluetooth" que ya está enfocado
		Set-UIElementToggle -Target "Bluetooth" -State Disable

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-05-21
		Fecha de modificación: 2025-05-21
		Versión: 1.0.0

	.INPUTS
		Ninguna. No recibe objetos de la tubería.

	.OUTPUTS
		Salidas en consola (Write-Host) y advertencias (Write-Warning). No devuelve objetos.

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/add-type?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdletbindingattribute?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/scripting/developer/paramattribute?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/scripting/developer/validatesetattribute?view=powershell-5.1
		https://docs.microsoft.com/en-us/dotnet/api/system.windows.automation.automationelement?view=windowsdesktop-6.0
		https://docs.microsoft.com/en-us/dotnet/api/system.windows.automation.togglepattern?view=windowsdesktop-6.0
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/start-sleep?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally?view=powershell-5.1
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory)]
		[string]$Target,

		[Parameter(Mandatory)]
		[ValidateSet('Enable', 'Disable', 'On', 'Off')]
		[string]$State
	)

	# Convierte el parámetro State ('Enable'/'On' → ToggleState.On; 'Disable'/'Off' → ToggleState.Off)
	$desired = if ($State -in 'Enable', 'On') {
		[System.Windows.Automation.ToggleState]::On
	} else {
		[System.Windows.Automation.ToggleState]::Off
	}

	# Obtiene el elemento UI actualmente enfocado y valida que coincida con Target
	$current = [System.Windows.Automation.AutomationElement]::FocusedElement
	if ($current.Current.Name -ne $Target) {
		Write-Warning "El elemento enfocado no coincide con '$Target'."
		return
	}

	# Intenta obtener el patrón TogglePattern y cambiar el estado si difiere del deseado
	$txtState = ""
	try {
		# Obtiene el patrón TogglePattern del elemento enfocado
		$pattern = $current.GetCurrentPattern(
			[System.Windows.Automation.TogglePattern]::Pattern
		)

		# Lee el estado actual del toggle
		$currentState = $pattern.Current.ToggleState
		$txtState = "'$Target'. Estado actual: $currentState. "

		# Si el estado no coincide, realiza el toggle y espera a que se aplique
		if ($currentState -ne $desired) {
			$pattern.Toggle()
			Start-Sleep -Milliseconds 200
			$newState = $pattern.Current.ToggleState
			$txtState += " Nuevo estado: $newState"
		}
		Write-Verbose $txtState
	} catch {
		# Manejo de errores al leer o aplicar TogglePattern
		Write-Warning "No se pudo leer o cambiar el TogglePattern: $_"
	}
}

function Show-App {
	<#
	.SYNOPSIS
		Inicia o enfoca una aplicación o URI especificado, con la opción de cerrar instancias existentes primero.

	.DESCRIPTION
		La función Show-App se encarga de iniciar un proceso (ejecutable o URI) y asegurarse de que tenga el foco.
		Utiliza un ejecutable externo 'StartAndFocusApp.exe' (que debe estar en la misma carpeta que el script) para realizar la acción de inicio y enfoque.
		Si no se proporciona el parámetro -NoClose, la función intentará cerrar las instancias existentes del proceso antes de iniciar una nueva.

		El método de cierre varía según el tipo de '$Process':
		- Para URIs 'ms-settings:*', utiliza la función 'Stop-SystemSettings'.
		- Para archivos '.exe', intenta detener el proceso por su nombre (sin extensión) repetidamente.
		- Para otros URIs o cadenas, busca procesos cuya ventana principal contenga la cadena '$Process' en el título y los detiene por PID.

		Si se proporciona el parámetro -Title, la función intentará activar explícitamente la ventana con ese título después de iniciar el proceso.

		El parámetro -Test pasa un argumento '-debug' al ejecutable externo.

	.PARAMETER Process
		La ruta completa a un archivo ejecutable (.exe), un URI (p. ej., 'ms-settings:display', 'mailto:test@example.com') o una cadena que pueda identificar parcialmente el título de la ventana de la aplicación a cerrar.
		Este parámetro es obligatorio.
		Tipo: String
		Obligatorio: True

	.PARAMETER Title
		El título exacto de la ventana de la aplicación que se espera activar después de iniciar el proceso.
		Si se omite o es una cadena vacía, no se intentará la activación explícita de la ventana mediante AppActivate.
		Tipo: String
		Obligatorio: False

	.PARAMETER NoClose
		Si se especifica este modificador, la función no intentará cerrar ninguna instancia existente del proceso antes de iniciarlo.
		Tipo: Switch
		Obligatorio: False

	.PARAMETER Test
		Si se especifica este modificador, se pasa el argumento '-debug' al ejecutable externo 'StartAndFocusApp.exe'.
		Tipo: Switch
		Obligatorio: False

	.EXAMPLE
		# Ejemplo 1: Inicia Notepad, cierra instancias previas e intenta activar la ventana "Untitled - Notepad"
		Show-App "C:\Windows\System32\notepad.exe" "Untitled - Notepad"

	.EXAMPLE
		# Ejemplo 2: Abre la configuración de WiFi sin cerrar instancias previas, usando parámetros nombrados.
		Show-App -Process "ms-settings:network-wifi" -NoClose

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-05-03
		Fecha de modificación: 2026-04-26
		Versión: 1.0.2
		Dependencias: Requiere el archivo 'StartAndFocusApp.exe' en el mismo directorio que el script ($PSScriptRoot). Puede requerir una función personalizada 'Stop-SystemSettings' para manejar URIs 'ms-settings:'.

	.INPUTS
	Ninguno. Esta función no acepta entrada desde la canalización (pipeline).

	.OUTPUTS
	Ninguno explícitamente devuelto. Muestra mensajes en la consola del host sobre las acciones realizadas (cierres de procesos, errores, intentos).

	.LINK
		Test-Path: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/test-path?view=powershell-5.1
		Join-Path: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/join-path?view=powershell-5.1
		Write-Host: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/write-host?view=powershell-5.1
		Stop-Process: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/stop-process?view=powershell-5.1
		Start-Sleep: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/start-sleep?view=powershell-5.1
		Get-Process: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-process?view=powershell-5.1
		Where-Object: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/where-object?view=powershell-5.1
		New-Object: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/new-object?view=powershell-5.1
		about_Operators: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-5.1 (-like, -match, -not)
		about_If: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_if?view=powershell-5.1
		about_While: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_while?view=powershell-5.1
		about_Foreach: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_foreach?view=powershell-5.1
	#>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true)]
		[string]$Process,
		[string]$Title,
		[switch]$NoClose,
		[switch]$Test
	)

	$debugTxt = $null

	# Verifica la existencia del ejecutable auxiliar necesario (StartAndFocusApp.exe).
	$starter = Join-Path $PSScriptRoot "StartAndFocusApp.exe"
	if (-not (Test-Path $starter)) {
		Write-Host "No existe StartAndFocusApp.exe. Por favor verifica la ruta."
		Pause
		exit 1
	}

	# Lógica para intentar cerrar instancias existentes si no se especifica -NoClose.
	if (-not ($NoClose)) {
		# Manejo específico para cerrar la aplicación de Configuración de Windows (ms-settings).
		if ($Process -match '\.exe$') {
			# Manejo para cerrar procesos basados en un archivo .exe.
			# Obtiene el nombre del proceso sin la extensión .exe.
			$exeName = [IO.Path]::GetFileNameWithoutExtension($Process)
			$attempt = 0
			# Intenta cerrar el proceso por nombre hasta 100 veces.
			while ($attempt -lt 100 -and (Get-Process -Name $exeName -ErrorAction SilentlyContinue)) {
				Write-Host "Intentando cerrar '$exeName' (intento $([int]($attempt + 1)) de 100)..."
				Stop-Process -Name $exeName -Force -ErrorAction SilentlyContinue
				Start-Sleep -Milliseconds 100
				$attempt++
			}
			# Advierte si no se pudo cerrar el proceso después de los intentos.
			if ($attempt -ge 100) {
				Write-Warning "No se pudo cerrar '$exeName' después de 100 intentos."
			}
		} elseif ($Process -notlike 'ms-settings:*') {
			# Manejo para cerrar otros tipos de procesos (URIs, etc.) buscando por título de ventana.
			Write-Host "Intentando cerrar instancias de '$Process' por ventana..."
			$attempt = 0
			while ($attempt -lt 100) {
				# busca ventanas cuyo título contenga la cadena
				$hWnds = @(Get-Process | Where-Object { $_.MainWindowTitle -like "*$Process*" } )
				if ($hWnds.Count -eq 0) {
					$attempt = 101
					break
				}
				foreach ($p in $hWnds) {
					Write-Host " - Matando PID $($p.Id) \"$($p.MainWindowTitle)\"..."
					Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
				}
				Start-Sleep -Milliseconds 100
				$attempt++
			}
		}
	}
	if ($Process -match "ms-settings:.+") {
		Start-Process "ms-settings:" -WindowStyle Minimized
	}

	# Prepara el argumento de depuración para el ejecutable externo si se especifica -Test.
	if ($Test) {
		$debugTxt = "-debug"
	}

	# Ejecuta la aplicación externa para iniciar o enfocar la aplicación/proceso deseado.
	& $starter $Process $Title $debugTxt


	Start-Sleep -Milliseconds 300
	# Si se proporcionó un título, intenta activar (poner en foco) la ventana correspondiente.
	if (-not([string]::IsNullOrEmpty($Title))) {
		(New-Object -ComObject wscript.shell).AppActivate($Title) | Out-Null
	}
	Start-Sleep -Milliseconds 200 # Pausa breve después de activar.
}

function Show-WindowUIElements {
	<#
	.SYNOPSIS
		Muestra los nombres, clases y tipos de control de todos los elementos de la ventana activa.

	.DESCRIPTION
		La función `Show-WindowUIElements` es un envoltorio cómodo para `Find-UIElementByName -Info`.
		Recorre secuencialmente los controles de la ventana que tiene el foco, utilizando las teclas de navegación configuradas, y presenta en pantalla la información de cada elemento (nombre, clase y tipo de control).
		Utiliza los valores predeterminados de iteraciones máximas y retardos definidos en la función `Find-UIElementByName`.
		Está pensada para explorar la interfaz de forma informativa sin buscar un elemento concreto.

	.EXAMPLE
		Show-WindowUIElements
		Recorre la ventana activa e imprime en consola los detalles de cada control encontrado.

	.NOTES
		Esta función es un simple atajo para no tener que recordar el parámetro -Info.
		de necesitar moderar el número máximo de iteraciones, el retardo entre teclas o el mapeo de teclas predeterminadas, se debe usar directamente
		Find-UIElementByName -Info -MaxIterations <valor> -TabDelayMs <valor> -KeyMapping <objeto>.
	#>
	Find-UIElementByName -Info
}

function Test-NextFocus {
	<#
	.SYNOPSIS
		Detecta y muestra el siguiente elemento enfocado en la interfaz después de enviar teclas, permitiendo saltar cambios intermedios de foco.

	.DESCRIPTION
		La función Test-NextFocus envía una secuencia de teclas opcional y luego monitorea los cambios reales de foco en la interfaz de usuario
		utilizando Get-FocusedUIElement. El parámetro Skip permite omitir una cantidad específica de transiciones intermedias antes de capturar el
		elemento enfocado final. Esta función es útil en escenarios donde aplicaciones como instaladores generan múltiples pantallas o mensajes
		temporales antes de llegar al foco relevante. De manera opcional, puede devolverse el objeto completo mediante -PassThru.

	.PARAMETER Keys
		Tipo: [string]
		Opcional.
		Secuencia de teclas que se enviará utilizando Send-Keys antes de iniciar la detección de cambios de foco. Si se omite o está vacío, no se envían teclas.

	.PARAMETER Skip
		Tipo: [int]
		Opcional.
		Cantidad de cambios reales de foco que deben ignorarse antes de capturar el elemento final. Valor predeterminado: 1. Cada vez que el foco cambie, el contador disminuye.

	.PARAMETER PassThru
		Tipo: [switch]
		Opcional.
		Si se incluye, la función devuelve el objeto final detectado ($prev). Si no se usa, solamente se imprimen sus propiedades sin retornarlo.

	.EXAMPLE
		Test-NextFocus -Keys "{ALT}+S" -Skip 2
		Envía ALT+S y omite dos cambios de foco antes de mostrar la información del tercer elemento enfocado.

	.EXAMPLE
		Test-NextFocus " " 1 -PassThru
		Llama a la función enviando un espacio como tecla, omitiendo un cambio de foco y devolviendo el objeto final.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-12-10
		Fecha de modificación: 2025-12-10
		Versión: 1.0.0
		Funciones utilizadas: Get-FocusedUIElement, Send-Keys, wInfo
		Advertencias: Los cambios de foco dependen del comportamiento de la aplicación bajo prueba y pueden ocurrir con distintas velocidades.

	.INPUTS
		Ninguna. Los parámetros no aceptan entrada por la tubería.

	.OUTPUTS
		Devuelve un objeto de UIA únicamente cuando se usa -PassThru. Sin -PassThru, la salida consiste en texto impreso en la consola.

	.LINK
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_Functions?view=powershell-5.1
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_Comment_Based_Help?view=powershell-5.1
	#>

	param(
		[string]$Keys,
		[int]$Skip = 1,
		[switch]$PassThru
	)

	# Obtiene el foco actual antes de enviar las teclas
	$prev = Get-FocusedUIElement

	# Envía las teclas indicadas si se pasaron (evita enviar cadena vacía)
	if (-not ([string]::IsNullOrEmpty($Keys))) {
		Send-Keys "$Keys"
	}

	# Bucle principal para detectar cambios reales de foco
	while ($Skip -gt 0) {

		# Pequeña espera para no saturar el loop
		Start-Sleep -Milliseconds 50

		# Captura el elemento actualmente enfocado
		$curr = Get-FocusedUIElement

		# Si el objeto o su ControlType es nulo, ignorar esta iteración
		if ($null -eq $curr -or $null -eq $curr.ControlType) {
			continue
		}

		# Detecta cambio real de foco comparando Name y ControlType.ProgrammaticName
		$focusChanged = $curr.Name -ne $prev.Name -or $curr.ControlType.ProgrammaticName -ne $prev.ControlType.ProgrammaticName

		if ($focusChanged) {
			# Actualiza el "prev" con el nuevo foco detectado
			$prev = $curr

			# Reduce el contador de pantallas intermedias (Skip)
			$Skip--
		}
	}

	# Cuando Skip llega a 0: mostrar información del foco final
	Write-Host "Name = $($prev.Name)"
	Write-Host "ControlType = $($prev.ControlType.ProgrammaticName)"

	# Aviso si el elemento no tiene nombre útil
	if ([string]::IsNullOrEmpty($prev.Name)) {
		wInfo "Es altamente probable que no pueda utilizarse el elemento debido a que no tiene un nombre específico."
	}

	# Si se solicitó PassThru, devolver el objeto completo; antes muestra una separación informativa
	if ($PassThru) {
		wInfo "`n`n-- Elemento obtenido:"
		return $prev
	}
}

function Test-UILanguage {
	<#
	.SYNOPSIS
		Comprueba si la referencia cultural de la interfaz de usuario actual coincide con un idioma especificado.

	.DESCRIPTION
		La función Test-UILanguage obtiene la referencia cultural actual de la interfaz de usuario (CurrentUICulture) mediante
		la clase .NET System.Globalization.CultureInfo y la compara con el código de idioma proporcionado.
		Devuelve $true si los nombres de cultura coinciden al compararlos sin distinción de
		mayúsculas y minúsculas, o $false en caso contrario.

	.PARAMETER Language
		Código de idioma (por ejemplo, 'es-MX', 'en-US') contra el que se evaluará la cultura actual. Es un parámetro opcional con posición 0 y valor predeterminado 'es-MX'.

	.EXAMPLE
		PS C:> Test-UILanguage 'es-MX'
		Comprueba si la interfaz de usuario actual usa 'es-MX' pasando el idioma de forma posicional.

	.EXAMPLE
		PS C:> Test-UILanguage -Language 'en-US'
		Comprueba si la interfaz de usuario actual usa 'en-US' usando el nombre del parámetro.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2026-05-06
		Fecha de modificación: 2026-05-06
		Versión: 1.0.0

	.INPUTS
		Ninguno. La función no acepta entrada desde la canalización.

	.OUTPUTS
		System.Boolean.
		Devuelve $true si la cultura actual coincide con el idioma especificado, $false en caso contrario.

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_culture?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
#>

	param(
		[Parameter(Position = 0)]
		[string]$Language = 'es-MX'
	)

	$currentUI = [System.Globalization.CultureInfo]::CurrentUICulture
	return ($currentUI.Name).ToLower() -like ($Language).ToLower()
}

function Wait-UIFocusMatch {
	<#
	.SYNOPSIS
		Espera hasta que el elemento actualmente enfocado coincida con un Name y/o un ControlType específico.

	.DESCRIPTION
		La función monitorea continuamente el elemento que posee el foco de interfaz mediante Get-FocusedUIElement y
		evalúa si coincide con los parámetros proporcionados. El usuario debe especificar al menos uno de los dos
		criterios: Name o ControlType. La función se detiene únicamente cuando ambos criterios proporcionados coinciden
		simultáneamente con el elemento actualmente enfocado. Si ninguno de los parámetros es proporcionado, la función
		detiene su ejecución inmediatamente con un error. La función no devuelve datos y solo finaliza cuando el
		foco cumple la condición solicitada.

	.PARAMETER Name
		Tipo: String
		Descripción: Nombre exacto del elemento esperado.
		Obligatorio: No. Debe especificarse junto a ControlType o como único criterio.

	.PARAMETER ControlType
		Tipo: String
		Descripción: Nombre programático del tipo de control esperado.
		Obligatorio: No. Debe especificarse junto a Name o como único criterio.

	.EXAMPLE
		Wait-UIFocusMatch -Name "Aceptar" -ControlType "ControlType.Button"

	.EXAMPLE
		Wait-UIFocusMatch
		No solicita el ingreso de los elementos, pero al no pasarse ambos genera una terminación abrupta de la función

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-12-10
		Fecha de modificación: 2025-12-10
		Versión: 1.0.0

	.INPUTS
		No recibe datos mediante la tubería.

	.OUTPUTS
		No devuelve objetos. Finaliza silenciosamente cuando el foco coincide con los criterios especificados.

	.LINK
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_throw?view=powershell-5.1
	#>

	param(
		[string]$Name,
		[string]$ControlType,
		[string]$Keys
	)

	# Valida que los parámetros hayan sido especificados; de lo contrario detiene la ejecución
	if ([string]::IsNullOrEmpty($Name) -or [string]::IsNullOrEmpty($ControlType)) {
		throw "Wait-UIFocusMatch requiere de Name y ControlType."
		Pause
	}

	# Bucle principal que evalúa continuamente el elemento con foco
	while ($true) {
		# Obtiene el elemento actualmente enfocado
		if (-not ([string]::IsNullOrEmpty($keys))) {
			Send-Keys $keys
			Start-Sleep -Milliseconds 300
		}
		$current = Get-FocusedUIElement

		# Inicializa indicador para Name
		$nameMatch = $current.Name -eq $Name

		# Inicializa indicador para ControlType
		$typeMatch = ($current.ControlType -and $current.ControlType.ProgrammaticName -eq $ControlType)

		# Si ambos criterios proporcionados coinciden, se cumple la condición y finaliza la función
		if ($nameMatch -and $typeMatch) {
			return
		}

		# Pequeña pausa para evitar iteraciones excesivas del bucle
		Start-Sleep -Milliseconds 50
	}
}

function Wait-UIFocusChange {
	<#
	.SYNOPSIS
		Espera hasta que el elemento enfocado deje de coincidir con un Name y/o un ControlType especificado.

	.DESCRIPTION
		La función monitorea continuamente el elemento que tiene el foco mediante Get-FocusedUIElement y compara sus
		propiedades Name y ControlType con los valores proporcionados. La función se mantiene en espera mientras
		ambos criterios coincidan y finaliza únicamente cuando ocurre un cambio real de foco. Si el usuario no
		especifica parámetros, la función captura automáticamente el elemento actualmente enfocado y lo usa como
		referencia, mostrando una advertencia salvo que se indique -Silent. Esta función no devuelve valores
		y finaliza cuando se detecta un cambio de foco válido.

	.PARAMETER Name
		Tipo: String
		Descripción: Nombre del elemento que debe mantenerse como referencia hasta que ocurra un cambio de foco.
		Obligatorio: No. Puede usarse solo o junto con ControlType. Si se omite junto a ControlType, se usará el elemento actual como referencia.

	.PARAMETER ControlType
		Tipo: String
		Descripción: Tipo de control (ProgrammaticName) que debe compararse para detectar cambios de foco.
		Obligatorio: No. Puede usarse solo o junto con Name. Si se omite junto a Name, se usará el elemento actual como referencia.

	.PARAMETER Silent
		Tipo: Switch
		Descripción: Suprime la advertencia que aparece cuando se invoca la función sin parámetros explícitos.
		Obligatorio: No.

	.EXAMPLE
		Wait-UIFocusChange -Name "Cancelar"

	.EXAMPLE
		Wait-UIFocusChange -ControlType "ControlType.Window" -Silent

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-12-10
		Fecha de modificación: 2025-12-10
		Versión: 1.0.0

	.INPUTS
		No acepta entradas desde la tubería.

	.OUTPUTS
		No devuelve objetos. Finaliza silenciosamente cuando ocurre un cambio de foco.

	.LINK
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators?view=powershell-5.1
	#>

	param(
		[string]$Name,
		[string]$ControlType,
		[switch]$Silent
	)

	# Si no se proporcionan criterios, se usa el elemento actualmente enfocado como referencia inicial
	if ([string]::IsNullOrEmpty($Name) -and [string]::IsNullOrEmpty($ControlType)) {
		$initial = Get-FocusedUIElement

		# Guarda temporalmente las propiedades del elemento inicial para comparaciones posteriores
		$Name = $initial.Name
		$ControlType = $initial.ControlType.ProgrammaticName

		# Muestra advertencia si el usuario no especificó parámetros y no activó el modo silencioso
		if (-not $silent) {
			wWarning "Sin parámetros Wait-UIFocusChange puede fallar si el foco cambia antes de que PowerShell capture el estado inicial."
		}
	}

	# Bucle principal que verifica continuamente si el foco sigue coincidiendo con los criterios establecidos
	while ($true) {
		# Obtiene el elemento actualmente enfocado
		$current = Get-FocusedUIElement

		# Compara el Name solo si se proporcionó este parámetro
		$nameMatch = $true
		if ($Name) {
			$nameMatch = ($current.Name -eq $Name)
		}

		# Compara el ControlType solo si se proporcionó este parámetro
		$typeMatch = $true
		if ($ControlType) {
			# Valida que ControlType no sea nulo antes de comparar ProgrammaticName
			$typeMatch = ($current.ControlType -and	$current.ControlType.ProgrammaticName -eq $ControlType)
		}

		# Cuando alguno de los criterios deja de coincidir, se detecta un cambio de foco y la función finaliza
		if (-not ($nameMatch -and $typeMatch)) {
			return
		}

		Start-Sleep -Milliseconds 100
	}
}
