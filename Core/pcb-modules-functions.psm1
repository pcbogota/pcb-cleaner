function Register-Libraries {
	<#
	.SYNOPSIS
		Registra módulos de PowerShell para su uso en scripts.

	.DESCRIPTION
		Esta función importa uno o varios módulos de PowerShell ubicados en el mismo directorio que el script que la ejecuta.
		Si un módulo ya está cargado como Script, lo descarga antes de volver a importarlo.

	.PARAMETER Libs
		[string[]] Un array de nombres de archivos (con extensión .ps1 o .psm1) o rutas completas a los módulos que se van a registrar.

	.EXAMPLE
		# Registra los módulos 'MiModulo.ps1' y 'OtroModulo.psm1' ubicados en el mismo directorio que el script.
		Register-Libraries -Libs @("MiModulo.ps1", "OtroModulo.psm1")

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-08
		Fecha de modificación: 2025-08-02
		Versión: 1.0.1

	.LINK
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-module?view=powershell-5.1
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-module?view=powershell-5.1
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/test-path?view=powershell-5.1
	#>
	param(
		[Parameter(Mandatory, Position = 0)]
		[string[]]  # Se especifica que el parámetro Libs debe ser un array de strings.
		$Libs
	)
	process {
		foreach ($lib in $Libs) {
			$libName = [io.path]::GetFileNameWithoutExtension($lib)

			# Se verifica si el módulo ya está cargado como Script para descargarlo.
			if ((Get-Module -Name $libName).ModuleType -eq "Script") {
				Unregister-Libraries(@($lib))
			}
			# Se usa Join-Path para construir la ruta al módulo.
			$modulePath = Join-Path -Path $PSScriptRoot -ChildPath $lib
			if (Test-Path -Path $modulePath -PathType Leaf -ErrorAction SilentlyContinue) {
				Import-Module -DisableNameChecking -Name $modulePath -Global -Force
				Write-Host "$($TerminalColor.txt.blue)Módulo $($lib) cargado"
			} else {
				Write-Error "$($TerminalColor.txt.red)No se encontró el módulo '$($lib)'."
				Pause
				exit
			}
		}
	}
}

function Unregister-Libraries {
	<#
	.SYNOPSIS
		Descarga módulos de PowerShell de la memoria.

	.DESCRIPTION
		Esta función elimina uno o varios módulos de PowerShell de la memoria.
		Es útil para liberar recursos y asegurar que los módulos se carguen correctamente en ejecuciones posteriores.

	.PARAMETER Libs
		[string[]] Un array de nombres de módulos (sin extensión) o rutas completas a los módulos que se van a descargar.

	.EXAMPLE
		# Descarga los módulos 'MiModulo' y 'OtroModulo'.
		Unregister-Libraries -Libs @("MiModulo", "OtroModulo")

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-07
		Fecha de modificación: 2025-02-09
		Versión: 1.0.0
		Es importante destacar que esta función solo descarga los módulos de la memoria, no los elimina del sistema.

	.LINK
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/remove-module?view=powershell-5.1
		https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/get-module?view=powershell-5.1
	#>
	param(
		[Parameter(Mandatory, Position = 0)]
		[string[]]
		$Libs
	)
	process {
		foreach ($lib in $Libs) {
			# Obtiene el nombre del módulo sin extensión.
			$libName = [io.path]::GetFileNameWithoutExtension($lib)

			# Se usa Get-Module para buscar el módulo en todos los ámbitos.
			$module = Get-Module -Name $libName
			if ($module) {
				# Se usa $module.Name para asegurar la descarga del módulo correcto.
				Remove-Module -Name $module.Name -Force -ErrorAction SilentlyContinue
				Write-Host "$($global:TerminalColor.txt.yellow)Módulo $($libName) liberado.$($global:TerminalColor.reset)"
			}
		}
	}
}
