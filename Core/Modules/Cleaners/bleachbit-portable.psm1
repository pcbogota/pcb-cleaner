function Start-BleachBitClean {
	param(
		[object[]]$ProcessData
	)
	$bleachbitExec = "$global:bleachbitPath\bleachbit_console.exe"
	if (Test-Path $bleachbitExec) {
		$snapshotName = "BleachBit"
		Set-Snapshot -Name $snapshotName
		Winfo "Ejecutando limpieza programada en BleachBit. Espera..."
		# --clean ejecuta la limpieza.
		# --preset carga las casillas marcadas.
		# Start-Process -FilePath $bleachbitExec -ArgumentList "--clean", "--preset" -Wait
		Invoke-ConsoleTool -FilePath $bleachbitExec -ArgumentList "--clean --preset" -Wait
		Stop-CleanerProcesses $ProcessData -NoPoint
		Set-SnapshotFinishTime -Name $snapshotName
	}
}
