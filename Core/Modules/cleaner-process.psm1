# ============================================================
# Módulo: cleaner-processes.psm1
# Propósito: Gestión de procesos durante la limpieza.
#            Cierre controlado según políticas y reapertura posterior.
# ============================================================

# --- Estado interno (cola de procesos a reabrir) ---
# Solo las funciones del módulo pueden acceder a esta variable.
$script:_reopenQueue = [System.Collections.Generic.List[PSObject]]::new()

# ============================================================
# Funciónes auxiliares privadas
# ============================================================

function Add-UniqueProcessQueue {
	param(
		[string]$Name,
		[string]$CommandLine,
		[string]$Path
	)

	# Comprobar si ya existe un proceso con el mismo Path (puedes elegir la propiedad que defina la unicidad)
	$exists = $script:_reopenQueue | Where-Object { $_.Path -eq $Path -and $_.CommandLine -eq $CommandLine }
	if (-not $exists) {
		$script:_reopenQueue.Add([PSCustomObject]@{
				Name        = $Name
				CommandLine = $CommandLine
				Path        = $Path
			})
	}
}

function Get-ProcessCommandLine {
	<#
    .SYNOPSIS
        Obtiene la línea de comandos exacta con la que se inició un proceso.
    .PARAMETER Process
        Objeto de proceso obtenido con Get-Process.
    #>
	param(
		[System.Diagnostics.Process]$Process
	)

	try {
		$wmi = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($Process.Id)" -ErrorAction Stop
		if ($wmi -and $wmi.CommandLine) {
			return $wmi.CommandLine
		}
	} catch {
		# Si falla (permisos, proceso ya terminado), devolvemos solo la ruta
	}

	# Fallback: solo la ruta del ejecutable
	if ($Process.Path) {
		return $Process.Path
	}
	return $Process.Name
}

function Stop-ShellProcess {
	<#
	.SYNOPSIS
		Detiene el proceso explorer.exe evitando que se reinicie automáticamente.
	.DESCRIPTION
		Desactiva temporalmente el reinicio automático del shell mediante el registro,
		fuerza el cierre con taskkill, y reactiva la clave al finalizar.
	#>
	param(
		[object]$ProcessDef
	)

	$regPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
	$regName = 'AutoRestartShell'
	$originalValue = $null

	try {
		# 1. Guardar el valor original de la clave (si existe)
		$originalValue = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue |
		Select-Object -ExpandProperty $regName

		# 2. Desactivar el reinicio automático del shell
		Set-ItemProperty -Path $regPath -Name $regName -Value 0 -Force

		# 3. Forzar el cierre con taskkill (más efectivo que Stop-Process)
		& taskkill /F /IM explorer.exe >$null
		Start-Sleep -Seconds 1

		# Registrar para reabrir al final
		Add-UniqueProcessQueue -Path 'explorer.exe' -Name ($ProcessDef.DisplayName) -CommandLine ( 'explorer.exe')

		wok "$($ProcessDef.DisplayName) se cerró correctamente." -oneLine

	} catch {
		wError "Error al detener Explorer: $_" -Wider
		wWarning $_ -Wider
	} finally {
		# 4. Restaurar el valor original
		if ($null -ne $originalValue) {
			Set-ItemProperty -Path $regPath -Name $regName -Value $originalValue -Force
		} else {
			Remove-ItemProperty -Path $regPath -Name $regName -ErrorAction SilentlyContinue
		}
	}
}

function show-reopenProcess {
	$script:_reopenQueue | select *
}

# ============================================================
# Funciones públicas
# ============================================================

function Stop-ProcessGracefully {
	<#
	.SYNOPSIS
		Detiene todos los procesos con un nombre dado, primero con cierre suave y luego forzado si se solicita.

	.DESCRIPTION
		Intenta cerrar cada proceso llamando a CloseMainWindow() y esperando 5 segundos.
		si se usa el switch -KillProcess,fuerza el cierre de los procesos que sigan vivos.

	.PARAMETER Name
		Nombre del proceso (sin .exe). Ej: 'chrome'

	.PARAMETER KillProcess
		si se especifica, fuerza el cierre de los procesos que no respondieron al cierre suave.

	.PARAMETER WindowProcess
		si se especifica, se usará el objeto de proceso enviado para intentar cerrar el proceso con un cierre suave
	#>
	param(
		[Parameter(Mandatory)]
		[string]$Name,
		[switch]$KillProcess,
		[object]$WindowProcess
	)

	if ($WindowProcess) {
		$procs = $WindowProcess
	}
	if (-not $procs) { return }

	foreach ($p in $procs) {
		if ($closeGracefully) {
			# Intentar cierre suave
			$p.CloseMainWindow() | Out-Null
			$p.WaitForExit(5000) | Out-Null
		}
		if (-not $p.HasExited -and $KillProcess) {
			$p.Kill() | Out-Null
		}
	}
}

function Stop-CleanerProcesses {
	<#
	.SYNOPSIS
		Detiene los procesos especificados según las reglas definidas en una lista de configuración.
	.DESCRIPTION
		Recibe un array de hashtables con la configuración de cada proceso.
		Cierra los procesos según su configuración (confirmación, condición de ruta, cierre suave/forzado).
		Si un proceso tiene ReopenAfterClean = $true, registra su información para reabrirlo al final.
	.PARAMETER Processes
		Array de hashtables con la definición de cada proceso (Name, DisplayName, etc.).
	.PARAMETER Ask
		Switch que para permitor o no preguntar al usuario sobre el cierre forzado
	#>
	param(
		[Parameter(Mandatory = $true)]
		[object[]]$Processes,
		[switch]$ask
	)

	foreach ($procDef in $Processes) {
		# --- 1. Resolver valores por defecto ---
		$name = $procDef.Name
		$displayName = if ($procDef.DisplayName) { $procDef.DisplayName } else { $name }
		$closeGracefully = if ($null -ne $procDef.CloseGracefully) { $procDef.CloseGracefully } else { $true }
		$confirmationMessage = if ($procDef.ConfirmationMessage) { $procDef.ConfirmationMessage } else { "Es necesario cerrar $displayName. ¿Forzar cierre? [S/N]" }
		$pathCondition = $procDef.PathCondition
		$reopenAfterClean = if ($null -ne $procDef.ReopenAfterClean) { $procDef.ReopenAfterClean } else { $false }
		$requireConfirmation = if ($null -ne $procDef.RequireConfirmation) { $procDef.RequireConfirmation } else { $false }
		$singleProcess = if ($null -ne $procDef.TreatAsSingleProcess) { $procDef.TreatAsSingleProcess } else { $false }

		# --- 2. Obtener los procesos que coinciden con el nombre ---
		$runningProcs = Get-Process -Name $name -ErrorAction SilentlyContinue

		# Filtrar por condición de ruta si se especificó
		if ($pathCondition -and $runningProcs) {
			$runningProcs = $runningProcs | Where-Object { $_.Path -like $pathCondition }
		}

		if (-not $runningProcs) {
			continue
		}
		wWarning "[$(Format-CustomDate -Date (Get-Date) -OnlyTime -LongTime)] Proceso detectado: $displayName" -Wider

		# --- 3. Solicitar confirmación si es necesario ---
		if ($requireConfirmation -and $ask) {
			$confirmationMessage = Write-ColoredText -Text $confirmationMessage -AnsiColor $global:TerminalColor.txt.orange -Return
			$confirmation = Read-Host -Prompt "  $confirmationMessage"
			if ($confirmation -notmatch '^(s|si|sí|y|yes)$') {
				Write-Host "Omitiendo cierre de $displayName." -ForegroundColor Gray
				continue
			}
		}

		# --- 4. Registrar para reabrir si corresponde ---
		# Identificar el proceso principal (el que tiene ventana)
		$mainProc = if ($singleProcess -and $runningProcs) {
			$runningProcs | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
		} else { $null }

		if ($reopenAfterClean) {
			if ($singleProcess -and $mainProc) {
				Add-UniqueProcessQueue -Path $mainProc.Path -Name $displayName -CommandLine $mainProc.Path
			} else {
				foreach ($p in $runningProcs) {
					Add-UniqueProcessQueue -Path $p.Path -Name $displayName -CommandLine $cmdLine
				}
			}
		}

		# --- 5. Cerrar los procesos ---
		# Verificación y ejecución de función de cierre expecífica
		if ($procDef.ContainsKey('CloseFunction')) {
			$specialFunction = $procDef.CloseFunction
			if (Get-Command $specialFunction -ErrorAction SilentlyContinue) {
				& $specialFunction $procDef
				continue # Pasamos al siguiente proceso de la lista
			} else {
				Write-Host "[!] Función de cierre '$specialFunction' no encontrada." -ForegroundColor Red
			}
		}

		if (-not $mainProc) { $mainProc = $runningProcs[0] }

		if ($closeGracefully -and $ask) {
			Stop-ProcessGracefully -WindowProcess $mainProc -Name $name
			Start-Sleep 2
		}

		if (-not $mainProc.HasExited) {
			$mainProc.Kill() | Out-Null
			wWarning "$displayName fue cerrado forzosamente."
		} else {
			wOk "$displayName se cerró correctamente." -oneLine

		}

		$runningProcs | Where-Object { -not $_.HasExited } | Stop-Process -Force
	}
}

function Start-ReopenedProcesses {
	<#
    .SYNOPSIS
        Reabre los procesos que fueron cerrados durante la limpieza.
    .DESCRIPTION
        Utiliza la información registrada (línea de comandos o ruta) para reabrir los procesos
        que tenían la propiedad ReopenAfterClean = $true al ser cerrados.
    #>

	$processNum = $script:_reopenQueue.Count
	if ($processNum -eq 0) {
		return
	}
	wrun "REAPERTURA DE PROGRMAS Y PROCESOS"

	$txt = "[$(Format-CustomDate -Date (Get-Date) -OnlyTime -LongTime)] Reabriendo $processNum "
	$txt += "$(Get-pluralize -Number $processNum -Singular "proceso") "
	$txt += "$(Get-pluralize -Number $processNum -Singular "cerrado")..."

	winfo $txt

	foreach ($proc in $script:_reopenQueue) {
		try {
			# Si tenemos línea de comandos completa (con argumentos), la usamos directamente
			if ($proc.CommandLine -and $proc.CommandLine -ne $proc.Path -and $proc.CommandLine -notlike "$($proc.Path)*") {
				# La línea de comandos es diferente del path (tiene argumentos propios)
				$exePath = $proc.Path
				$arguments = $proc.CommandLine.Substring($exePath.Length).Trim()
				Start-Process -FilePath $exePath -ArgumentList $arguments
			} elseif ($proc.Path) {
				# Solo tenemos ruta, la abrimos sin argumentos
				Start-Process -FilePath $proc.Path
			}
			wok "Reabierto: $($proc.Name)" -oneLine
		} catch {
			wError "  No se pudo reabrir $($proc.Name): $_"
		}
	}
	# Limpiar la cola
	$script:_reopenQueue.Clear()
}

# Exportar solo las funciones públicas
#Export-ModuleMember -Function 'Stop-CleanerProcesses', 'Start-ReopenedProcesses', 'Stop-ProcessGracefully'
