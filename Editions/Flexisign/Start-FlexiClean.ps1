# Design Colors RIP temporales


<#

##Obtener espacio en disco actual

## obtener carpetas

Las conocidas
C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Temp\_PPS_tempAMJob
C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Temp\
E:\temp_rip

\HKEY_CURRENT_USER\SOFTWARE\Amiable\Production-3684


C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Temp

[HKEY_CURRENT_USER\SOFTWARE\Amiable\Production-3684]
"JobFolderPath"="C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Jobs"
"TempFolderPath"="C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Temp"

¿¿ carpetas de temporales para printexp???

¿¿ carpeta de trabajos de clientes ?? (Para eliminar la ultima fecha automáticamente)


### --- HOJA DE RUTA DEFINITIVA — LIMPIADOR RIP + SISTEMA --- ###

🔧 CONFIGURACIÓN PREVIA REQUERIDA (UNA SOLA VEZ)
	- Parametros para el script
		auto: define si se invoca desde tarea programada, omitirá preguntas interactivas (excepto cierre forzado de programas).
	- Variables configurables al inicio del script:
		- Ruta de elementos temporales para flexisign y printexpert (C: y D:).
		- Carpeta raiz de trabajos de clientes (opcional, puede no existir).
		- Meses hacia atrás para conservar trabajos de clientes (ej. 5)
		- Umbral para el porcenaje de uso de disco que activa modo de limpieza agresiva (por defecto 70).
		- Ruta de BleachBit.
		- Clave en el registro para guardar datos de ejecución (HKLM:\SOFTWARE\PCBogota)

--- 🛫 EJECUCION!

Hoja de ruta definitiva (implementación)
- Crear flexi-processes.psd1 con los procesos Flexisign/PrintExpert que quieras incluir de fábrica (aunque luego se editen).
Commit: 1	flexi-processes.psd1 (nuevo)	"Agrega configuración de procesos RIP para edición Flexisign"

- Crear flexi-folders.psd1 con las entradas de carpetas temporales del RIP y de trabajos de clientes (valores por defecto).
Commit: 2	flexi-folders.psd1 (nuevo)	"Añade definición de carpetas a limpiar (sesiones y antigüedad)"


Fase 1 – Cierre de procesos
- En clean-flexisign.ps1, cargar flexi-processes.psd1, filtrar por Scope='Initial' y llamar a Stop-ProcessGracefully por cada uno.
Commit: 3	clean-flexisign.ps1 (Fase 1)	"Implementa cierre controlado de procesos desde flexi-processes.psd1"

Fase 2 – Limpieza de temporales RIP (sesiones)
- Recorrer flexi-folders.psd1 donde RetentionUnit = 'Sessions'.
Commit: 4	clean-flexisign.ps1 (Fase 2, solo normal)	"Limpieza de temporales RIP por sesiones (4 en modo normal)"

- Crear función Clear-RIPSessionFolders que implemente el agrupamiento diario y borre según RetentionValueNormal o Aggressive.
Commit: 5	mismo script (Fase 2, agresivo)	"Soporte para modo agresivo en limpieza por sesiones (1 sesión)"

Fase 3 – Trabajos de clientes (días)
- Mismo bucle sobre las entradas con RetentionUnit = 'Days', llamar a una función que elimine carpetas/archivos antiguos (puede reutilizar Clear-FolderContent si conviene, o directamente Remove-Item filtrado).
Commit: 6	clean-flexisign.ps1 (Fase 3)	"Eliminación de trabajos de clientes por antigüedad configurable"

Fase 4 – Reintento agresivo
- Si el modo es agresivo, volver a ejecutar la limpieza de las entradas de sesiones pero forzando RetentionValueAggressive (1 sesión).
Commit: 7	clean-flexisign.ps1 (Fase 4)	"Reintento de limpieza de sesiones en modo agresivo"

Ajustes finales
- Integrar todo en clean-flexisign.ps1, probar, y verificar que Start-FlexiClean.ps1 apunte bien.
Commit: 8	Start-FlexiClean.ps1 / instalador	"Ajustes finales de integración y empaquetado"

<#
.SYNOPSIS
  Lista de procesos a cerrar durante la limpieza (Flexisign edition).

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

#

@{
	Processes = @(
		@{
			Name                = 'flexiprint'
			DisplayName         = 'FlexiPRINT (RIP)'
			CloseGracefully     = $true
			RequireConfirmation = $true    # Pregunta al usuario
			ConfirmationMessage = "FlexiPRINT está abierto. ¿Forzar cierre? (puede perder trabajos en curso)"
			Scope               = 'Initial'
			ReopenAfterClean    = $true
		},
		@{
			Name                = 'printexp'
			DisplayName         = 'PrintExpert'
			CloseGracefully     = $true
			RequireConfirmation = $true
			ConfirmationMessage = "PrintExpert está abierto. ¿Forzar cierre?"
			Scope               = 'Initial'
			ReopenAfterClean    = $true
		}
		# Aquí se podrán añadir más programas en el futuro
	)
}

2. Configuración de limpieza de carpetas: flexi-folders.psd1
Un solo archivo con un array de definiciones de carpetas a limpiar. Cada entrada será un hashtable con estas propiedades:


| Propiedad                | Tipo   | Obligatoria  | Descripción                                            |
| -------------------------- | -------- | -------------- | -------------------------------------------------------- |
| Name                     | string | Sí           | Nombre legible para logs.                              |
| Path                     | string | si           | Ruta absoluta de la carpeta raíz a limpiar.            |
| Force                    | bool   | No           | si se pasa `-Force` a `Remove-Item`                    |
| ExecutionFunction        | string | No           | Nombre de una función personalizada para la limpieza   |
| RetentionUnit            | string | si           | Unidad de retención: 'Sessions', 'Days' 'Months'       |
| RetentionValueNormal     | int    | si           | Valor para modo normal                                 |
| RetentionValueAggressive | int    | si           | Valor para modo agresivo                               |


powershell
@{
	Folders = @(
		@{
			Name                     = 'Temporales FlexiSIGN'
			Path                     = 'C:\Program Files\FlexiSIGN\Temp'
			Force                    = $true
			RetentionUnit            = 'Sessions'
			RetentionValueNormal     = 4
			RetentionValueAggressive = 1
		},
		@{
			Name                     = 'Spool PrintExpert'
			Path                     = 'D:\PrintExpert\Spool'
			Force                    = $true
			RetentionUnit            = 'Sessions'
			RetentionValueNormal     = 4
			RetentionValueAggressive = 1
		},
		@{
			Name                     = 'Trabajos de clientes'
			Path                     = 'E:\TrabajosClientes'
			Force                    = $false
			RetentionUnit            = 'Days'
			RetentionValueNormal     = 150   # 5 meses
			RetentionValueAggressive = 60
		}
	)
}
#>

$targetFolder = "e:\.MyBackup"
$ActivityDays = 3  # Hoy + 2 días de trabajo
$SecureSessions = 10  # Tu límite de 10 sesiones de uso

function Remove-TempElements {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path,
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateSet("File", "Directory")]
		[string]$type
	)
	# 1. Obtener todas las fechas de actividad disponibles en la carpeta

	$params = @{
		Path    = $Path
		Recurse = $true
	}
	if ($type.ToLower() -eq "file") {
		$params.File = $true
	} else {
		$params.Directory = $true
	}
	$elements = Get-ChildItem @params | Select-Object FullName, @{Name = "Fecha"; Expression = { $_.LastWriteTime.Date } }
	$ActivitySessions = $elements | Select-Object -ExpandProperty Fecha -Unique | Sort-Object -Descending

	# 2. Borrado de archivos basándose solo en sesiones
	if ($ActivitySessions.Count -gt $ActivityDays) {
		# Borramos archivos que pertenezcan a sesiones más antiguas que las 3 guardadas
		$RemoveFilesDates = $ActivitySessions | Select-Object -Skip $ActivityDays

		foreach ($Date in $RemoveFilesDates) {
			$elements | Where-Object { $_.Fecha -eq $Date } | ForEach-Object {
				Write-Host $_.FullName
				# Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
			}
		}
	}
}

Remove-TempElements -Path $targetFolder -Type "File"
exit

# 1. Obtener todas las fechas de actividad disponibles en la carpeta
$Files = Get-ChildItem -Path $targetFolder -File -Recurse |
Select-Object FullName, @{Name = "Fecha"; Expression = { $_.LastWriteTime.Date } }
$ActivitySessions = $Files | Select-Object -ExpandProperty Fecha -Unique | Sort-Object -Descending

# 2. Borrado de archivos basándose solo en sesiones
if ($ActivitySessions.Count -gt $ActivityDays) {
	# Borramos archivos que pertenezcan a sesiones más antiguas que las 3 guardadas
	$RemoveFilesDates = $ActivitySessions | Select-Object -Skip $ActivityDays

	foreach ($Date in $RemoveFilesDates) {
		$Files | Where-Object { $_.Fecha -eq $Date } | ForEach-Object {
			Write-Host $_.FullName
			# Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
		}
	}
}
#$RemoveFilesDates
exit

# 3. Borrado de carpetas basándose en sesiones (Sin calendario)
# Obtenemos todas las carpetas y sus fechas (usando el LastWriteTime de la carpeta)
$Folders = Get-ChildItem -Path $targetFolder -Directory -Recurse |
Select-Object FullName, @{Name = "Fecha"; Expression = { $_.LastWriteTime.Date } }

# Identificamos qué fechas de carpetas están más allá de la sesión 10
if ($ActivitySessions.Count -gt $SecureSessions) {
	# Saltamos las 10 sesiones más recientes, todo lo anterior es "pasto para el fuego"
	$RemoveFolderDates = $ActivitySessions | Select-Object -Skip $SecureSessions

	foreach ($Date in $RemoveFolderDates) {
		$Folders | Where-Object { $_.Fecha -eq $Date } | ForEach-Object {
			# Borrado recursivo y forzado
			# Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
			# Write-Host "Purgando carpeta de sesión antigua: $($_.FullName)"
		}
	}
}

# 4. Limpieza de carpetas huérfanas (vacías)
# Solo borramos si la carpeta está realmente vacía
$EmptyFolder = Get-ChildItem -Path $targetFolder -Directory -Recurse |
Where-Object { (Get-ChildItem -Path $_.FullName -Recurse).Count -eq 0 }

foreach ($carpeta in $EmptyFolder) {
	# Validamos que no sea la carpeta raíz
	if ($carpeta.FullName -ne $targetFolder) {
		# Remove-Item -Path $carpeta.FullName -Force -ErrorAction SilentlyContinue
		# Write-Host "Eliminando carpeta huérfana: $($carpeta.FullName)"
	}
}

exit
