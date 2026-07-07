function Clear-ErrorReports {
	Winfo "Limpiando informes de errores de Windows (WER)..."

	# Ruta de informes a nivel de sistema
	$systemWerPath = "$env:SystemRoot\ProgramData\Microsoft\Windows\WER"
	# Ruta de informes a nivel de usuario actual
	$userWerPath = "$env:LOCALAPPDATA\Microsoft\Windows\WER"

	$ProcedureName = "Informes de errores de Windows"
	Clear-FolderContent -Path $systemWerPath -LogPrefix ("$ProcedureName [Sistema]")
	Clear-FolderContent -Path $userWerPath -LogPrefix ("$ProcedureName [Usuario]")

	Set-Snapshot -Name $ProcedureName
}
