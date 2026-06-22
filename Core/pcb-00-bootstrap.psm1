function Initialize-PcbConsoleUi {
	# Importación del modulo de funciones para visualización de consola
	$lib = "pcb-Write-to-user"
	try {
		Remove-Module $lib -Force -ErrorAction SilentlyContinue
		Import-Module "$PSScriptRoot\$lib.psm1" -DisableNameChecking -Global -Force
	} catch {
		throw "No se ha podido cargar la librería '$PSScriptRoot\$lib.psm1'"
	}
	Clear-Host
	Write-Logo
}

function Initialize-PcbEnvironmentVars {
	################################################
	#----------------------------------------------#
	#------------- Variables globales -------------#
	#----------------------------------------------#
	################################################

	################################################
	# ENTRADA DE USUARIO / INTERACCIÓN
	################################################

	# teclas que se ignoran en Pause y Get-UserAnswer
	$global:keyboardPressIgnores = (
		16, # Shift (left or right)
		17, # Ctrl (left or right)
		18, # Alt (left or right)
		20, # Caps lock
		91, # Windows key (left)
		92, # Windows key (right)
		93, # Menu key
		144, # Num lock
		145, # Scroll lock
		166, # Back
		167, # Forward
		168, # Refresh
		169, # Stop
		170, # Search
		171, # Favorites
		172, # Start/Home
		173, # Mute
		174, # Volume Down
		175, # Volume Up
		176, # Next Track
		177, # Previous Track
		178, # Stop Media
		179, # Play
		180, # Mail
		181, # Select Media
		182, # Application 1
		183  # Application 2
	)

	################################################
	# COLORES Y CONFIGURACIÓN DE TERMINAL
	################################################

	$global:TerminalColor = [PSCustomObject]@{
		bg    = [PSCustomObject]@{
			black = "$([char]0x1b)[48;5;0m" #fondo black/negro
			white = "$([char]0x1b)[48;5;255m" #Fondo blanco
			red   = "$([char]0x1b)[48;5;124m" #Fondo Rojo
			green = "$([char]0x1b)[48;5;22m" #Texto verde
			reset = "$([char]0x1b)[49m" # Resetear solo el fondo
		}
		txt   = [PSCustomObject]@{
			black       = "$([char]0x1b)[38;5;16m" #Texto en negro
			blue        = "$([char]0x1b)[38;5;39m" #texto en azul
			cyan        = "$([char]0x1b)[38;5;51m" #Texto Azul Claro
			green       = "$([char]0x1b)[38;5;154m" #Texto verde
			red         = "$([char]0x1b)[38;5;196m" #Texto rojo
			white       = "$([char]0x1b)[38;5;15m" #Texto Blanco
			yellow      = "$([char]0x1b)[38;5;228m" #Texto amarillo
			orange      = "$([char]0x1b)[38;5;214m" #Texto naranja P de PCBogota
			gray        = "$([char]0x1b)[38;5;245m" #Texto gris u opaco
			brightWhite = "$([char]0x1b)[37;1m" #Texto blanco brillante
			darkRed     = "$([char]0x1b)[38;5;9m" #Texto en rojo opaco

			blink       = "$([char]0x1b)[6m" # texto intermitente rápido
			bold        = "$([char]0x1b)[1m" #Texto en negrita
			invert      = "$([char]0x1b)[7m" #Colores invertidos
			italic      = "$([char]0x1b)[3m" #texto en cursiva
			opaque      = "$([char]0x1b)[2m" #Texto opaco
			underline   = "$([char]0x1b)[4m" #Colores invertidos

			reset       = "$([char]0x1b)[39m" # Resetear solo el texto
		}
		reset = "$([char]0x1b)[0m"
	}
}


function Initialize-PcbElevation {
	# Verifica si la sesión actual tiene privilegios de administrador.
	if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
			[Security.Principal.WindowsBuiltInRole]::Administrator
		)) {
		Write-Host "Elevando privilegios..."

		$invokerPath = (Get-PSCallStack | Where-Object { $_.ScriptName -and (Test-Path $_.ScriptName) } | Select-Object -Last 1).ScriptName
		Start-Process powershell.exe `
			-ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($invokerPath)`"" `
			-Verb RunAs
		exit
	}

	# Importación del modulo para tomar posesión del proceso
	$lib = "pcb-Take-own"
	try {
		Remove-Module $lib -Force -ErrorAction SilentlyContinue
		Import-Module "$PSScriptRoot\$lib.psm1" -DisableNameChecking -Global -Force
	} catch {
		throw "No se ha podido cargar la librería '$PSScriptRoot\$lib.psm1'"
	}
	do {} until (Get-ElevatedPrivileges SeTakeOwnershipPrivilege)
}

function Initialize-PcbLibraries {
	Write-Host ("$($global:TerminalColor.txt.cyan)CONFIGURANDO VARIABLES, ACCESO A CARPETAS Y MODULOS REQUERIDOS...$($global:TerminalColor.reset)")

	# Se requiere de cargla de librería de modulos para poder ejecutar la carga de las otras librerías
	$lib = "pcb-modules-functions"
	try {
		Remove-Module $lib -Force -ErrorAction SilentlyContinue
		Import-Module "$PSScriptRoot\$lib.psm1" -DisableNameChecking -Global -Force
	} catch {
		throw "No se ha podido cargar la librería '$PSScriptRoot\$lib.psm1'"
	}

	# Lista centralizada de librerías requeridas para la ejecución estándar.
	$loadLib = @(
		'basic-clean.psm1'

		# 'pcb-Take-own.psm1 # Cargado desde función 'Initialize-PcbElevation' en 'pcb-01-Bootstrap.psm1'
		# 'pcb-Write-to-user.psm1 # Cargado desde función 'Initialize-PcbConsoleUi' en 'pcb-01-Bootstrap.psm1'

	)

	# Registro y recarga controlada de módulos.
	Register-Libraries $loadLib
	Remove-Variable -Name loadLib -ErrorAction SilentlyContinue
	# Solicita privilegios adicionales necesarios para ciertas operaciones del sistema.
}

#region public functions
function Initialize-PcbExecution {
	Write-Host "Cargando módulo principal de PCBogota. Espera..."
	Initialize-PcbElevation			# Carga librería pcb-Take-own"
	Initialize-PcbEnvironmentVars	# Carga librería pcb-SystemTools
	Initialize-PcbConsoleUi			# Carga librería pcb-Write-to-user

	Initialize-PcbLibraries			# Carga librerias principales del proyecto
	wOk("Modulos correctamente cargados!")

}
#endregion public functions

Export-ModuleMember -Function Initialize-PcbExecution
