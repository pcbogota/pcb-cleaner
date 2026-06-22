# Design Colors RIP temporales


<#

##Obtener espacio en disco actual

## para inspección
	- No realizar ninguna eliminación
	- Guardar información de los archivos para eliminar

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

🔴 FASE 0 — EVALUACIÓN INICIAL (SIEMPRE)
	- leer del registro en HKLM:\SOFTWARE\PCBogota
		- Ultima limpieza normal (fecha)
		- Ultima limpieza agresiva (fecha)
	- Mostrar en pantalla ultima vez que se ejecutó la limpieza normal y agresiva
	- Medir espacio total, usado y libre por cada disco (C:, D:, etc.).
	- Calcular % de uso.
	- Guardar estas cifras para el informe final.
	- Decidir modo de ejecución:
		- Normal: todas las unidades de almacenamiento con uso menor a umbral de porcentaje de uso.
		- Modo Agresivo: si algún disco ≥ umbral → activa automáticamente limpiezas extra y reducción de sesiones a 1.

🔴 FASE 1 — CIERRE CONTROLADO DE PROGRAMAS (SIEMPRE)
	-Verificar si flexiprint.exe o printexp.exe están corriendo.
	- Si están activos → preguntar al usuario:
		- [S] Saltar (no cerrar)
		- [F] Forzar cierre

	- Si elige forzar:
		- Intentar cierre normal y esperar 10s.
		- Si siguen activos → Stop-Process -Force.

	Nota: Si están imprimiendo, advertir que se pueden perder trabajos.

🔴 FASE 2 — LIMPIEZA BASE DE TEMPORALES DEL RIP (SIEMPRE)
	Carpetas objetivo (deben ser variables configurables):
	- C:\...FlexiSIGN\...\Temp, Spool, Jobs, Logs
	- D:\...PrintExpert\...\Temp, Spool, Jobs, Logs
	- Criterio: conservar últimas 4 sesiones (archivos agrupados por fecha de modificación).
	- Borrar todo lo que no pertenezca a esas sesiones.
	- Eliminar carpetas vacías resultantes.
	- Si el disco está en Modo Agresivo → reducir a 1 sesión (solo dejar archivos de hoy).

🔴 FASE 3 — ELIMINAR CARPETAS DE TRABAJOS DE CLIENTES (OPCIONAL)
	- Condición: Solo si existe la carpeta raíz de trabajos (su existencia es variable por máquina).
	- Antigüedad: Calcular $MesesLimite a partir de un parámetro (ej. 5 meses → 150 días).
	- Criterio: Eliminar carpetas cuyo CreationTime sea anterior a la fecha límite.
	- Eliminar carpetas vacías después del borrado.

🔴 FASE 4 — LIMPIEZA ADICIONAL DEL SISTEMA (SIEMPRE, PERO CON INTENSIDAD VARIABLE)
	- 🔵 Spooler de impresión (detener servicio, borrar C:\Windows\System32\spool\PRINTERS\*, reiniciar).
	- 🔵 Papelera de reciclaje de todos los discos.
	- 🔵 Temporales del sistema (Windows y usuario):
		- C:\Windows\Temp\*
		- %AppData%\Local\Temp\*
	- 🔵 Caché de actualizaciones (Delivery Optimization):
		- C:\Windows\SoftwareDistribution\Download\*
		- C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*
	- 🔵 Caché MSI: C:\Config.Msi\* (solo si no hay instalaciones en curso).
	- 🔵 BleachBit (línea de comandos): ejecutar con lista blanca (sin navegadores).
	- 🔵 Caché de navegadores (Opera, Firefox, Chrome, Edge): borrar solo caché, no cookies.
	- 🔵 Liberador de espacio (cleanmgr): con /sagerun:1 y archivo .reg preimportado.
	- 🔵 CompactOS: si no está activado, aplicar Compact /CompactOS:always.

	🟡 En Modo Agresivo (≥70%):
	- 🟡 Restauraciones del sistema: vssadmin delete shadows /all /quiet (deja solo la última sombra con vssadmin resize shadowstorage).
	- 🟡 Cachés de Adobe/Corel: buscar patrones temporales en %Temp% y %AppData% aunque su uso sea esporádico.
	- 🟡 DISM: /StartComponentCleanup /ResetBase (sin reinicio).
	- 🟡 Reducción de sesiones a 1: aplicar de nuevo Fase 2 con criterio mínimo.

🔴 FASE 5 — ESTADÍSTICAS E INFORME (SIEMPRE)
	- Medir espacio final por disco.
	- Calcular y mostrar:
		- Espacio inicial vs final.
		- MB/GB liberados en cada fase:
			- Temporales RIP
			- Trabajos de clientes
			- Sistema (spooler, papelera, temp, delivery, etc.)
			- BleachBit + navegadores
			- Componentes DISM + CompactOS
		- Tiempo total de ejecución.
	- Guardar en registro (MKLM:\SOFTWARE\PCBogota) ultima ejecución agresiva y ultima ejecución normal
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
