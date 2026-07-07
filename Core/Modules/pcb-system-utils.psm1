function Test-IsLaptop {
	<#
	.SYNOPSIS
		Determina si el computador es un portátil (laptop) o similar.

	.DESCRIPTION
		Devuelve $true si el computador es un portátil, notebook, sub-notebook o similar, basado en el tipo de chasis.
		Esta función utiliza la clase WMI `win32_systemenclosure` para obtener el tipo de chasis del sistema.

	.PARAMETER
		No se requieren parámetros para esta función.

	.EXAMPLE
		PS C:\> Test-IsLaptop
		Devuelve $true si el equipo es un portátil, notebook, sub-notebook o similar.

	.NOTES
		Autor: Camilo Salazar
		Fecha de creación: 2025-02-25
		Fecha de modificación: 2025-02-25
		Versión: 1.0.0

		Valores posibles de la propiedad `ChassisTypes` de la clase `win32_systemenclosure`:
		- Other (1)
		- Unknown (2)
		- Desktop (3)
		- Low Profile Desktop (4)
		- Pizza Box (5)
		- Mini Tower (6)
		- Tower (7)
		- *Portable (8)        <- Detecta un portátil
		- *Laptop (9)          <- Detecta un portátil
		- *Notebook (10)       <- Detecta un portátil
		- *Hand Held (11)      <- Detecta un portátil
		- Docking Station (12)
		- All in One (13)
		- *Sub Notebook (14)   <- Detecta un portátil
		- Space-Saving (15)
		- Lunch Box (16)
		- Main System Chassis (17)
		- Expansion Chassis (18)
		- SubChassis (19)
		- Bus Expansion Chassis (20)
		- Peripheral Chassis (21)
		- Storage Chassis (22)
		- Rack Mount Chassis (23)
		- Sealed-Case PC (24)

	.INPUTS
		Ninguno

	.OUTPUTS
		System.Boolean
		Devuelve $true si el equipo es un portátil, notebook, sub-notebook o similar; de lo contrario, devuelve $false.

	.LINK
		https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-wmiobject?view=powershell-5.1
		https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-systemenclosure
	#>
	return ([string](Get-WmiObject -Class win32_systemenclosure).ChassisTypes).trim() -in @(8, 9, 10, 14)
}
