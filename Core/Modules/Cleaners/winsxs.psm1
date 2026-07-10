function Clear-WinSxSComponents {
	<#
	.SYNOPSIS
		Limpia la carpeta WinSxS (componentes de Windows) para liberar espacio.
	.DESCRIPTION
		Utiliza DISM para limpiar y compactar el almacén de componentes.
		Es la operación más lenta del proceso de limpieza, pero la que más espacio recupera.
	#>
	$snapshotName = "WinSxS (DISM)"
	Set-Snapshot -Name $snapshotName
	winfo "Compactando almacén de componentes de Windows (DISM). Espera..."

	$dismArgs = "/online /Cleanup-Image /StartComponentCleanup /ResetBase"
	Invoke-ConsoleTool -FilePath "dism.exe" -ArgumentList $dismArgs -Wait
	Set-SnapshotFinishTime -Name $snapshotName
}
