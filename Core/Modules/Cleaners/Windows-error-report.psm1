function Clear-ErrorReports {
	$snapshotName = "Informes de error de Windows"
	Set-Snapshot -Name $snapshotName
	Winfo "Limpiando informes de errores de Windows (WER)..."

	# Ruta de informes a nivel de sistema
	$systemWerPath = "$env:SystemRoot\ProgramData\Microsoft\Windows\WER"
	# Ruta de informes a nivel de usuario actual
	$userWerPath = "$env:LOCALAPPDATA\Microsoft\Windows\WER"

	Clear-FolderContent -Path $systemWerPath -LogPrefix ("$snapshotName [Sistema]")
	Clear-FolderContent -Path $userWerPath -LogPrefix ("$snapshotName [Usuario]")
	Set-SnapshotFinishTime -Name $snapshotName
}
