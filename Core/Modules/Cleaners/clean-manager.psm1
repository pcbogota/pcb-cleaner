function Start-WindowsDiskCleanup {
	[CmdletBinding()]
	param(
		[int]$ProfileNumber = 999
	)

	$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
	$keys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue


	# Si no existen las claves returna de la función sin modificar claves de registro ni usar el liberador de espacio
	if (-not $keys) {
		return
	}

	wInfo "Ejecutando el Liberador de espacio de Windows. Espera..." -Wider
	$stateFlag = "StateFlags{0:D4}" -f $ProfileNumber  # Formato de 4 dígitos

	# Establecer la bandera para limpiar todas las categorías
	foreach ($key in $keys) {
		Set-ItemProperty -Path $key.PSPath -Name $stateFlag -Value 2 -Type DWord -ErrorAction SilentlyContinue
	}

	# Ejecutar el limpiador con ese perfil
	Start-Process -FilePath "cleanmgr" -ArgumentList "/sagerun:$ProfileNumber" -Wait -NoNewWindow

	# Limpiar el registro: eliminar las propiedades que creamos
	foreach ($key in $keys) {
		Remove-ItemProperty -Path $key.PSPath -Name $stateFlag -ErrorAction SilentlyContinue
	}
	Set-Snapshot -Name "Liberador de espacio de Windows"
}
