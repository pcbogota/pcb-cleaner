
function Get-FreeSpaceGB {
	$drive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='$($env:SystemDrive)'"
	return [math]::Round($drive.FreeSpace / 1GB, 2)
}

function Set-SpaceMark {
	[CmdletBinding()]
	param (
		[string] $Name
	)
	$global:currentSpace = Get-FreeSpaceGB
	$global:results += "Limpieza de $($Name): $([math]::Round($global:currentSpace - $global:lastMark, 2)) GB"
	$global:lastMark = $global:currentSpace
}

function Get-SpaceMark {
	# --- FINAL LOG ---
	$global:currentSpace = Get-FreeSpaceGB
	$netGain = [math]::Round($global:currentSpace - $global:initialFreeSpace, 2)
	Write-Host "`n"
	Write-Host ("=" * 40) -ForegroundColor White
	Write-Host "RESUMEN DE LIMPIEZA" -ForegroundColor Green
	Write-Host ("=" * 40) -ForegroundColor White

	foreach ($line in $global:results) {
		Write-Host $line
	}
	Write-Host ("-" * 40) -ForegroundColor White

	$format = "{0,-25} | {1,7:N2} GB"
	Write-Host ($format -f "Espacio libre al iniciar", $global:initialFreeSpace) -ForegroundColor Cyan
	Write-Host ($format -f "Ganancia neta de espacio", $netGain) -ForegroundColor Yellow
	Write-Host ($format -f "Espacio libre actual", $global:currentSpace) -ForegroundColor Green
}
