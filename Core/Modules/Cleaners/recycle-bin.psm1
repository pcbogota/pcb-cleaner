function Clear-AllRecycleBins {
	<#
    .SYNOPSIS
        Vacía la papelera de reciclaje de todas las unidades disponibles.
    .DESCRIPTION
        Recorre cada unidad detectada en el sistema y ejecuta Clear-RecycleBin.
        Usa la información previamente recopilada en $initialShot.Drives.
    .PARAMETER Drives
        Array de objetos que contienen la propiedad 'Letter' (ej: 'C:').
        Si no se proporciona, no realiza ninguna acción.
    #>
	param(
		[Parameter(Mandatory = $true)]
		[object[]]$Drives
	)

	foreach ($drive in $Drives) {
		# La propiedad 'Letter' viene con dos puntos (C:), la quitamos porque el cmdlet espera solo la letra
		$driveLetter = $drive.Letter -replace ':$', ''
		if (-not $driveLetter) { continue }
		Winfo "Vaciando papelera de la unidad ${driveLetter}:"
		Clear-RecycleBin -DriveLetter $driveLetter -Force -ErrorAction SilentlyContinue
	}
	Set-Snapshot -Name "Papelera de reciclaje"
}
