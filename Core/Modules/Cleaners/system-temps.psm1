function Clear-SystemTemp {
	wInfo "Limpiando archivos temporales del sistema..."

	# 1. Temporales del usuario
	$userTemp = $env:TEMP
	if (Test-Path $userTemp) {
		Remove-Item -Path "$userTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
	}

	# 2. Temporales del sistema
	$systemTemp = "$env:SystemRoot\Temp"
	if (Test-Path $systemTemp) {
		Remove-Item -Path "$systemTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
	}

	# 3. Caché de miniaturas (thumbcache) del usuario actual
	$thumbCache = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
	if (Test-Path $thumbCache) {
		Remove-Item -Path "$thumbCache\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
		Remove-Item -Path "$thumbCache\iconcache_*.db" -Force -ErrorAction SilentlyContinue
	}

	Set-Snapshot -Name "Limpieza de careptas temporales"
}

function Clear-SystemLogs {
	wInfo "Limpiando logs de eventos..."

	try {
		$logs = wevtutil el 2>$null
		foreach ($log in $logs) {
			wevtutil cl $log 2>$null
		}
	} catch {
		# Silencioso
	}
}
