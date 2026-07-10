function Clear-WindowsUpdateDownloads {
	$snapshotName = "Descargas de Windows Update"
	Set-Snapshot -Name $snapshotName
	Winfo "Verificando carpeta de descargas (Caché) de Windows Update..."
	$windowsUpdateDownloadPath = "$($env:SystemRoot)\SoftwareDistribution\Download"

	Stop-Service -Name "wuauserv", "bits" -Force -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 2

	Clear-FolderContent -Path $windowsUpdateDownloadPath -LogPrefix $snapshotName
	Set-SnapshotFinishTime -Name $snapshotName
}

function Clear-DeliveryOptimizationCache {
	$snapshotName = "WU Delivery Optimization"
	Set-Snapshot -Name $snapshotName
	Winfo "Verificando caché de Delivery Optimization..."
	$doPath = "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization"

	Stop-Service -Name "DoSvc" -Force -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 2

	# Eliminar contenido de la carpeta (no la carpeta raíz)
	Clear-FolderContent -Path $doPath -LogPrefix $snapshotName
	Set-SnapshotFinishTime -Name $snapshotName
}
