function Clear-SystemRestorePoints {
	param(
		[int]$KeepLatest = 2
	)
	$snapshotName = "Puntos de restauración del sistema"
	Set-Snapshot -Name $snapshotName
	Winfo "Verificando puntos de restauración del sistema..."

	# Obtener la lista de sombras (puntos de restauración)
	$shadows = vssadmin list shadows | Select-String -Pattern "Id. de instantáneas: {(.*?)}" | ForEach-Object { $_.Matches.Groups[1].Value }

	if ($shadows.Count -le $KeepLatest) {
		Set-SnapshotFinishTime -Name $snapshotName
		return
	}

	$shadowsToDelete = $shadows[0..($shadows.Count - $KeepLatest - 1)]

	wWarning "Eliminando puntos de restauración manteniendo los $KeepLatest más recientes..." -wider
	foreach ($shadowId in $shadowsToDelete) {
		$txtId = "{$shadowId}"
		vssadmin delete shadows /shadow=$txtId /quiet >$null
	}
	Set-SnapshotFinishTime -Name $snapshotName
}
