function Clear-WindowsUpdateDownloads {
	Winfo "Verificando carpeta de descargas (Caché) de Windows Update..."
	$windowsUpdateDownloadPath = "$($env:SystemRoot)\SoftwareDistribution\Download"

	Stop-Service -Name "wuauserv", "bits" -Force -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 2

	$ProcedureName = "Caché de Windows Update"
	Clear-FolderContent -Path $windowsUpdateDownloadPath -LogPrefix $ProcedureName
	Set-Snapshot -Name $ProcedureName
}

function Clear-DeliveryOptimizationCache {
	Winfo "Verificando caché de Delivery Optimization..."
	$doPath = "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization"

	Stop-Service -Name "DoSvc" -Force -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 2

	$ProcedureName = "WU Delivery Optimization"
	# Eliminar contenido de la carpeta (no la carpeta raíz)
	Clear-FolderContent -Path $doPath -LogPrefix $ProcedureName
	Set-Snapshot -Name $ProcedureName
}
