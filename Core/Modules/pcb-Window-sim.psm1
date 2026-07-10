<#
Tabla de Categorías de Funciones
---------------------------------------------------------------------------
| Función                   | SYNOPSIS                                    |
---------------------------------------------------------------------------
| Find-AllWindowsByTitle    | Busca todas las ventanas cuyo título        |
|                           | contenga una cadena especificada.           |
|                           |                                             |
| Find-WindowsByProcessName | Obtiene todas las ventanas asociadas a un   |
|                           | nombre de proceso específico.               |
|                           |                                             |
| Get-WindowsList           | Obtiene la lista de ventanas abiertas en    |
|                           | el sistema.                                 |
|                           |                                             |
| Get-ActiveWindowInfo      | Obtiene información de la ventana           |
|                           | actualmente activa.                         |
|                           |                                             |
| Restore-WindowAndFocus    | Restaura y enfoca una ventana, manejando    |
|                           | correctamente ventanas minimizadas          |
|                           | o maximizadas.                              |
|                           |                                             |
| Set-WindowForeground      | Trae al frente una ventana por título o por |
|                           | handle, con opción forzada y capacidad de   |
|                           | actuar sobre múltiples coincidencias.       |
|                           |                                             |
| Set-WindowTop             | Trae una ventana al frente utilizando el    |
|                           | método avanzado de restauración y           |
|                           | activación.                                 |
---------------------------------------------------------------------------

Total de funciones: 7
#>

# Agregando librería de C# para simular acciones de click y movimiento del mouse
Add-Type -Path "$PSScriptroot\Lib\windowsim.cs"

function Find-AllWindowsByTitle {
	<#
	.SYNOPSIS
		Busca todas las ventanas cuyo título contenga una cadena especificada.

	.DESCRIPTION
		Esta función utiliza la clase WindowSim.WindowHelper para enumerar todas las ventanas del sistema y devolver aquellas cuyo título contenga el texto proporcionado, sin distinción de mayúsculas/minúsculas. Se basa en el método estático FindAllWindowsByTitle.

	.PARAMETER Title
		Texto que debe contener el título de la ventana. El parámetro es obligatorio y de tipo string.

	.EXAMPLE
		Find-AllWindowsByTitle "Notepad"
		Busca todas las ventanas cuyo título incluya la palabra "Notepad".

	.EXAMPLE
		Find-AllWindowsByTitle -Title "Chrome"
		Busca todas las ventanas cuyo título incluya "Chrome" usando el nombre del parámetro.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2026-07-09
		Fecha de modificación: 2026-07-09
		Versión: 1.0.0

	.INPUTS
		No acepta entrada por la canalización.

	.OUTPUTS
		Devuelve un arreglo de objetos WindowSim.WindowInfo que representan las ventanas coincidentes.
	#>
	param(
		[Parameter(Mandatory = $true)]
		[string]$Title
	)
	[WindowSim.WindowHelper]::FindAllWindowsByTitle($Title)
}

function Find-WindowsByProcessName {
	<#

	.SYNOPSIS
		Obtiene todas las ventanas asociadas a un nombre de proceso específico.

	.DESCRIPTION
		Esta función utiliza el método estático FindWindowsByProcessName de la clase WindowSim.WindowHelper para enumerar todas las ventanas del sistema cuyo nombre de proceso coincida exactamente con el valor proporcionado, sin distinción de mayúsculas/minúsculas. Devuelve un arreglo de objetos WindowInfo que representan las ventanas encontradas.

	.PARAMETER ProcessName
		Nombre del proceso (sin extensión .exe) cuyas ventanas se desean localizar. El parámetro es obligatorio y de tipo string.

	.EXAMPLE
		Find-WindowsByProcessName "notepad"
		Busca todas las ventanas cuyo proceso asociado sea "notepad".

	.EXAMPLE
		Find-WindowsByProcessName -ProcessName "chrome"
		Busca todas las ventanas del proceso "chrome" utilizando el nombre del parámetro.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2026-07-09
		Fecha de modificación: 2026-07-09
		Versión: 1.0.0

	.INPUTS
		No acepta entrada por la canalización.

	.OUTPUTS
		Devuelve un arreglo de objetos WindowSim.WindowInfo que representan las ventanas coincidentes.
	#>
	param(
		[Parameter(Mandatory = $true)]
		[string]$ProcessName
	)
	[WindowSim.WindowHelper]::FindWindowsByProcessName($ProcessName)
}

function Get-WindowsList {
	<#
	.SYNOPSIS
		Obtiene la lista de ventanas abiertas en el sistema.

	.DESCRIPTION
		Esta función obtiene información sobre las ventanas abiertas en el sistema mediante una clase definida en una librería C# externa previamente cargada utilizando Add-Type. Forma parte del conjunto de funciones de más bajo nivel destinadas a exponer directamente capacidades del sistema operativo a PowerShell, sin aplicar lógica adicional, filtrado ni abstracciones.

	.PARAMETER
		Esta función no define parámetros de entrada.

	.EXAMPLE
		Get-WindowsList
		Obtiene la lista completa de ventanas abiertas en el sistema.

	.EXAMPLE
		$windows = Get-WindowsList
		Almacena la lista de ventanas abiertas en una variable para su posterior procesamiento.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-12-16
		Fecha de modificación: 2025-12-16
		Versión: 1.0.0
		Requiere que la librería C# correspondiente (windowsim.cs) haya sido cargada previamente mediante Add-Type -Path "$PSScriptRoot\windowsim.cs". Esta función es de bajo nivel y actúa como un puente directo entre PowerShell y la implementación nativa en C# para el manejo ventanas del sistema.

	.INPUTS
		No acepta entrada desde la tubería.

	.OUTPUTS
		Devuelve una colección de objetos que representan las ventanas abiertas en el sistema, según lo definido por la implementación en C#.
	#>

	# Obtiene la lista de ventanas del sistema utilizando la implementación nativa definida en C#.
	[WindowSim.WindowHelper]::GetWindows()
}

function Get-ActiveWindowInfo {
	<#
	.SYNOPSIS
		Obtiene información de la ventana actualmente activa.

	.DESCRIPTION
		Esta función obtiene información detallada sobre la ventana que se encuentra activa en el sistema mediante una clase definida en una librería C# externa previamente cargada utilizando Add-Type. Forma parte del conjunto de funciones de más bajo nivel destinadas a exponer directamente información del sistema de ventanas a PowerShell, sin aplicar lógica adicional, validaciones ni transformaciones.

	.PARAMETER
		Esta función no define parámetros de entrada.

	.EXAMPLE
		Get-ActiveWindowInfo
		Obtiene la información de la ventana que se encuentra activa en ese momento.

	.EXAMPLE
		$activeWindow = Get-ActiveWindowInfo
		Almacena la información de la ventana activa para su posterior uso.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-12-16
		Fecha de modificación: 2025-12-16
		Versión: 1.0.0
		Requiere que la librería C# correspondiente (windowsim.cs) haya sido cargada previamente mediante Add-Type -Path "$PSScriptRoot\windowsim.cs". Esta función es de bajo nivel y actúa como un puente directo entre PowerShell y la implementación nativa en C# para el manejo ventanas del sistema.

	.INPUTS
		No acepta entrada desde la tubería.

	.OUTPUTS
		Devuelve un objeto con información de la ventana activa, según lo definido por la implementación en C#.
	#>
	# Obtiene la información de la ventana actualmente activa utilizando la implementación nativa en C#.
	[WindowSim.WindowHelper]::GetActiveWindowInfo()
}

function Set-WindowForeground {
	<#
	.SYNOPSIS
		Trae al frente una ventana por título o por handle, con opción forzada y capacidad de actuar sobre múltiples coincidencias.

	.DESCRIPTION
		Esta función es el núcleo de manipulación de ventanas del módulo. Utiliza internamente los métodos de WindowSim.WindowHelper para buscar ventanas por título y traerlas al primer plano.
		Si se proporciona un título, busca todas las ventanas cuyo título contenga el texto (sin distinción de mayúsculas/minúsculas). Por defecto, actúa solo sobre la primera coincidencia. Si se especifica el modificador -All, itera sobre todas las ventanas encontradas, trayendo cada una al frente secuencialmente (la última quedará con el foco real).
		Si se proporciona un handle directamente, actúa sobre esa única ventana.
		La restauración de ventanas minimizadas es implícita: tanto el método normal como el forzado restauran automáticamente la ventana si es necesario antes de traerla al frente.

	.PARAMETER Title
		Texto que debe contener el título de la ventana. Se usa con el ParameterSet 'ByTitle'. Es obligatorio en ese contexto.

	.PARAMETER Handle
		Manejador (System.IntPtr) de la ventana que se desea traer al frente. Se usa con el ParameterSet 'ByHandle'. Es obligatorio en ese contexto.
		Puede obtenerse mediante Find-AllWindowsByTitle, Find-WindowsByProcessName, [WindowSim.WindowHelper]::GetActiveWindowInfo(), o cmdlets nativos como (Get-Process -Name "notepad").MainWindowHandle. No es un valor entero común; debe tratarse como un puntero opaco.

	.PARAMETER Force
		Si se especifica, utiliza el método ForceForegroundWindow, que emplea técnicas más agresivas (incluyendo simulación de la tecla Alt) para obtener el permiso de primer plano. Sin este modificador, se usa el método normal BringWindowToFront. En ambos casos, la ventana se restaura si está minimizada.

	.PARAMETER All
		Válido únicamente con el parámetro -Title. Si se especifica, actúa sobre todas las ventanas cuyo título coincida, en lugar de solo la primera. Cada ventana se traerá al frente secuencialmente con una breve pausa entre ellas.

	.EXAMPLE
		Set-WindowForeground "Notepad"
		Trae al frente la primera ventana cuyo título contenga "Notepad".

	.EXAMPLE
		Set-WindowForeground -Title "Bloc de notas" -Force
		Trae al frente la primera ventana cuyo título contenga "Bloc de notas" utilizando el método forzado.

	.EXAMPLE
		Set-WindowForeground -Handle $hwnd
		Trae al frente la ventana identificada por el handle $hwnd.

	.EXAMPLE
		Set-WindowForeground -Title "Chrome" -All
		Trae al frente, una por una, todas las ventanas cuyo título contenga "Chrome".

	.EXAMPLE
		Set-WindowForeground -Title "Editor" -All -Force
		Trae al frente todas las ventanas de "Editor" utilizando el método forzado para cada una.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2026-07-09
		Fecha de modificación: 2026-07-09
		Versión: 1.0.0

	.INPUTS
		No acepta entrada por la canalización.
		El parámetro Handle es un System.IntPtr que identifica de forma única una ventana en el sistema operativo.
		Puede obtenerse mediante:
		- Las funciones Find-AllWindowsByTitle o Find-WindowsByProcessName, que devuelven objetos WindowInfo con la propiedad Handle.
		- El método estático [WindowSim.WindowHelper]::GetActiveWindowInfo(), que devuelve el WindowInfo de la ventana activa.
		- Cmdlets nativos como (Get-Process -Name "notepad").MainWindowHandle.
		No se trata de un valor entero común; debe tratarse como un puntero opaco.

	.OUTPUTS
		System.Boolean. Devuelve $true si la operación fue exitosa para todas las ventanas objetivo; si alguna falla, retorna $false. Si no se encuentra ninguna ventana que coincida con el título, retorna $false.

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-5.1
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameter_sets?view=powershell-5.1
	#>

	[CmdletBinding(DefaultParameterSetName = 'ByTitle')]
	param(
		[Parameter(Mandatory = $true, ParameterSetName = 'ByTitle', Position = 0)]
		[string]$Title,

		[Parameter(ParameterSetName = 'ByTitle')]
		[switch]$All,

		[Parameter(Mandatory = $true, ParameterSetName = 'ByHandle')]
		[IntPtr]$Handle,

		[Parameter()]
		[switch]$Force
	)

	# Si se proporciona un título, buscar todas las ventanas que coincidan.
	if ($PSCmdlet.ParameterSetName -eq 'ByTitle') {
		$windows = [WindowSim.WindowHelper]::FindAllWindowsByTitle($Title)
		if ($windows.Count -eq 0) {
			return $false
		}

		if (-not $All) {
			# Sin -All: solo actúa sobre la primera ventana encontrada.
			$targetWindows = @($windows[0])
		} else {
			# Con -All: actúa sobre todas las ventanas coincidentes, una por una.
			$targetWindows = $windows
		}
	} else {
		# Se pasó un Handle directamente; tratarlo como única ventana.
		$targetWindows = @( @{ Handle = $Handle } )  # objeto temporal con propiedad Handle
	}

	$success = $true

	foreach ($window in $targetWindows) {
		$hwnd = $window.Handle

		if ($Force) {
			# Método agresivo: simula Alt para obtener permiso de primer plano.
			$result = [WindowSim.WindowHelper]::ForceForegroundWindow($hwnd)
		} else {
			# Método normal: restaura (si está minimizada) y trae al frente.
			$result = [WindowSim.WindowHelper]::BringWindowToFront($hwnd)
		}

		if (-not $result) {
			$success = $false
		}

		# Pequeña pausa entre ventanas cuando se actúa sobre varias.
		if ($targetWindows.Count -gt 1) {
			Start-Sleep -Milliseconds 150
		}
	}

	return $success
}

function Set-WindowTop {
	<#
	.SYNOPSIS
		Trae una ventana al frente utilizando el método avanzado de restauración y activación.

	.DESCRIPTION
		Esta función invoca el método estático BringWindowToFront de la clase WindowSim.WindowHelper, que implementa múltiples estrategias para restaurar (si está minimizada), activar y colocar la ventana en el primer plano. Devuelve un valor booleano indicando el éxito de la operación.

	.PARAMETER Handle
		Manejador (IntPtr) de la ventana que se desea traer al frente. Es obligatorio.

	.EXAMPLE
		Set-WindowTop $handle
		Trae la ventana identificada por $handle al frente.

	.EXAMPLE
		Set-WindowTop -Handle $handle
		Trae la ventana al frente especificando el parámetro por nombre.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2026-07-09
		Fecha de modificación: 2026-07-09
		Versión: 1.0.0

	.INPUTS
		No acepta entrada por la canalización.

		El parámetro Handle es un System.IntPtr que identifica de forma única una ventana en el sistema operativo.
		Puede obtenerse mediante:
		- Las funciones Find-WindowsByProcessName o Find-AllWindowsByTitle, que devuelven objetos WindowInfo con la propiedad Handle.
		- El método estático [WindowSim.WindowHelper]::GetActiveWindowInfo(), que devuelve el WindowInfo de la ventana activa.
		- Cmdlets nativos como (Get-Process -Name "notepad").MainWindowHandle.
		No se trata de un valor entero común; debe tratarse como un puntero opaco.

	.OUTPUTS
		System.Boolean. Devuelve $true si la ventana fue llevada al frente exitosamente; en caso contrario, $false.
	#>

	param(
		[Parameter(Mandatory = $true)]
		[IntPtr]$Handle
	)
	[WindowSim.WindowHelper]::BringWindowToFront($Handle)
}

function Restore-WindowAndFocus {
	<#
	.SYNOPSIS
		Restaura y enfoca una ventana, manejando correctamente ventanas minimizadas o maximizadas.

	.DESCRIPTION
		Esta función utiliza el método estático RestoreAndFocusWindow de la clase WindowSim.WindowHelper. Si la ventana está minimizada, la restaura a su estado anterior (normal o maximizado), la trae al frente y le asigna el foco. Devuelve un valor booleano indicando si la operación fue exitosa.

	.PARAMETER Handle
		Manejador (IntPtr) de la ventana que se desea restaurar y enfocar. Es obligatorio.

	.EXAMPLE
		Restore-WindowAndFocus $handle
		Restaura (si está minimizada) y enfoca la ventana con el manejador especificado.

	.EXAMPLE
		Restore-WindowAndFocus -Handle $handle
		Restaura y enfoca la ventana utilizando el nombre del parámetro.

	.NOTES
		Fecha de creación: 2026-07-09
		Fecha de modificación: 2026-07-09
		Versión: 1.0.0
		Autor: [placeholder]

	.INPUTS
		No acepta entrada por la canalización.

		El parámetro Handle es un System.IntPtr que identifica de forma única una ventana en el sistema operativo.
		Puede obtenerse mediante:
		- Las funciones Find-WindowsByProcessName o Find-AllWindowsByTitle, que devuelven objetos WindowInfo con la propiedad Handle.
		- El método estático [WindowSim.WindowHelper]::GetActiveWindowInfo(), que devuelve el WindowInfo de la ventana activa.
		- Cmdlets nativos como (Get-Process -Name "notepad").MainWindowHandle.
		No se trata de un valor entero común; debe tratarse como un puntero opaco.

	.OUTPUTS
		System.Boolean. Devuelve $true si la ventana fue restaurada y enfocada con éxito; en caso contrario, $false.
	#>
	param(
		[Parameter(Mandatory = $true)]
		[IntPtr]$Handle
	)
	[WindowSim.WindowHelper]::RestoreAndFocusWindow($Handle)
}
