function Start-BleachBitClean {
	param(
		[object[]]$ProcessData
	)
	$bleachbitExec = "$global:bleachbitPath\bleachbit_console.exe"
	if (Test-Path $bleachbitExec) {
		Winfo "Ejecutando limpieza programada en BleachBit. Espera..."
		# --clean ejecuta la limpieza.
		# --preset carga las casillas marcadas.
		# Start-Process -FilePath $bleachbitExec -ArgumentList "--clean", "--preset" -Wait
		Invoke-ConsoleTool -FilePath $bleachbitExec -ArgumentList "--clean --preset" -Wait
		Set-Snapshot -Name "BleachBit"
	}
	Stop-CleanerProcesses $ProcessData
}
