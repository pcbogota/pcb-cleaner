function Set-CompactOS {
	$DriveStatus = Get-CriticalDrivesLetter -Drives (Measure-AllDrives)
	$isSystemCritical = $env:SystemDrive -in $DriveStatus
	$compactStatus = compact /compactos:query
	$TextCompact = "El sistema se encuentra en el estado compacto"
	if ($isSystemCritical -and -not ($compactStatus -imatch $TextCompact)) {
		wwarning "Compactación no está activo. Comprimiendo sistema para ganar espacio..." -Wider
		compact /compactos:always
		wok "Compactación completada." -Wider
	}
	schtasks /run /tn "\Microsoft\Windows\Servicing\StartComponentCleanup" | Out-Null
	Set-Snapshot -Name "Compactación de Sistema Operativo"
}
