function Start-WindowsDiskCleanup {
	[CmdletBinding()]
	param(
		[int]$ProfileNumber = 999
	)
	$snapshotName = "Liberador de espacio de Windows"
	Set-Snapshot -Name $snapshotName
	$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
	$keys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue


	# Si no existen las claves retorna de la función sin modificar claves de registro ni usar el liberador de espacio
	if (-not $keys) {
		Set-SnapshotFinishTime -Name $snapshotName
		return
	}

	wInfo "Ejecutando el Liberador de espacio de Windows. Espera..." -Wider
	$stateFlag = "StateFlags{0:D4}" -f $ProfileNumber  # Formato de 4 dígitos

	# Establecer la bandera para limpiar todas las categorías
	foreach ($key in $keys) {
		Set-ItemProperty -Path $key.PSPath -Name $stateFlag -Value 2 -Type DWord -ErrorAction SilentlyContinue
	}

	# Ejecutar el limpiador con ese perfil
	#Start-Process -FilePath "cleanmgr" -ArgumentList "/sagerun:$ProfileNumber" -Wait -NoNewWindow

	Start-Process -FilePath "cleanmgr" -ArgumentList "/sagerun:$ProfileNumber" -NoNewWindow
	while (Get-Process "cleanmgr" -ErrorAction SilentlyContinue) {
		Start-Sleep -Milliseconds 500
		$title = (Get-Process "cleanmgr" -ErrorAction SilentlyContinue).MainWindowTitle
		# Busca todas las ventanas que contengan "Liberador de espacio en disco"
		if ($title) {
			Set-WindowForeground -Title $title -All -Force | Out-Null
			Start-Sleep -Milliseconds 400
		}
	}

	# Limpiar el registro: eliminar las propiedades que creamos
	foreach ($key in $keys) {
		Remove-ItemProperty -Path $key.PSPath -Name $stateFlag -ErrorAction SilentlyContinue
	}
	Set-SnapshotFinishTime -Name $snapshotName
}
