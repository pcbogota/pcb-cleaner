function Clear-WinSxSComponents {
	<#
	.SYNOPSIS
		Limpia la carpeta WinSxS (componentes de Windows) para liberar espacio.
	.DESCRIPTION
		Utiliza DISM para limpiar y compactar el almacén de componentes.
		Es la operación más lenta del proceso de limpieza, pero la que más espacio recupera.
	#>
	winfo "Compactando almacén de componentes de Windows (DISM). Espera..."

	#$dismArgs = "/online /Cleanup-Image /StartComponentCleanup /ResetBase"
	#Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -WindowStyle Normal -Wait
	Invoke-ConsoleTool -FilePath "dism.exe" -ArgumentList $dismArgs -Wait
	Set-Snapshot -Name "WinSxS (DISM)"
}
