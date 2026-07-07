<#
.SYNOPSIS
  Lista de procesos a cerrar durante la limpieza (Core).

.DESCRIPTION
  Cada elemento es un hashtable con las siguientes propiedades:

  | Propiedad            | Tipo   | Obligatoria  | Descripción                                            |
  |----------------------|--------|--------------|--------------------------------------------------------|
  | Name                 | string | Sí           | Nombre del proceso (sin .exe).                         |
  | DisplayName          | string | No           | Nombre legible para el usuario.                        |
  | CloseGracefully      | bool   | No           | Si $true, intenta cierre suave antes de forzar.        |
  | ConfirmationMessage  | string | No           | Mensaje personalizado para la confirmación.            |
  | CloseFunction        | string | No           | Nombre de función que se ejecuta para el proceso       |
  | PathCondition        | string | No           | Patrón wildcard de la ruta del ejecutable.             |
  | ReopenAfterClean     | bool   | No           | Si $true, Abre el proceso al terminar la limpiza.      |
  | RequireConfirmation  | bool   | No           | Si es $true, pregunta al usuario antes de cerrar.      |
  | Scope                | string | No           | 'Initial' (solo al inicio) o 'Always' (siempre).       |
  | TreatAsSingleProcess | bool   | No           | Indica que sus procesos deben tratarse como uno solo.  |

#>

@{
	Processes = @(
		@{
			Name                 = 'chrome'
			DisplayName          = 'Google Chrome'
			ConfirmationMessage  = "Google Chrome está abierto, verifiquelo (Se cerrará forzadamente). Entendido [s/n]"
			ReopenAfterClean     = $true
			RequireConfirmation  = $false
			Scope                = 'Always'
			WaitAfterClose       = $false
			TreatAsSingleProcess = $true
		},
		@{
			Name                = 'bleachbit'
			DisplayName         = 'BleachBit (portable del proyecto)'
			PathCondition       = '*\BleachBit-Portable\bleachbit.exe'
			RequireConfirmation = $false
			Scope               = 'Always'
		},
		@{
			Name                = 'explorer'
			DisplayName         = 'Explorador de Windows'
			CloseFunction       = 'Stop-ShellProcess'
			CloseGracefully     = $false   # Explorer se cierra de forma especial
			RequireConfirmation = $false
			Scope               = 'Initial'
		}
	)
}
