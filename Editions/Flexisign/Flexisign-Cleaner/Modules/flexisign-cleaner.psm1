function Remove-TempFolderSet {
	param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[hashtable]$Folder
	)

	process {
		# Crear una copia para no modificar el objeto original
		$workingFolder = $Folder.Clone()

		# Actualizar la ruta desde el registro si aplica
		$workingFolder = Get-ExistingFolder -Folder $workingFolder

		Write-Host "Limpiando $($workingFolder.Name)..."

		# Determinar el valor de retención según el modo
		$retention = if ($global:AggressiveMode) {
			$workingFolder.RetentionValueAggressive
		} else {
			$workingFolder.RetentionValueNormal
		}

		# Ejecutar la limpieza de elementos temporales
		Remove-TempElements -Path $workingFolder.Path `
			-RetentionUnit $workingFolder.RetentionUnit `
			-RetentionValue $retention `
			-Force:$workingFolder.Force


		# Eliminar carpetas vacías resultantes
		Clear-EmptyFolders -TargetFolder $workingFolder.Path
	}
}

function Get-ExistingFolder {
	param(
		# Acepta un único objeto folder (hashtable) o un array por si acaso
		[hashtable]$Folder
	)
	# Verificar que existen las claves necesarias y no están vacías
	$hasRegPath = $Folder.ContainsKey('RegeditPath') -and -not [string]::IsNullOrWhiteSpace($Folder['RegeditPath'])
	$hasRegAttr = $Folder.ContainsKey('RegeditAttribute') -and -not [string]::IsNullOrWhiteSpace($Folder['RegeditAttribute'])

	if ($hasRegPath -and $hasRegAttr) {
		# Leer el valor del registro usando el método estático de .NET
		$regValue = [Microsoft.Win32.Registry]::GetValue(
			(ConvertTo-NativeRegistryPath -Path $Folder.RegeditPath),
			$Folder.RegeditAttribute,
			$null   # valor por defecto si no existe
		)

		# Si se obtuvo un valor, no es nulo/vacío y la ruta existe como carpeta
		if ($regValue -and (Test-Path -Path $regValue -PathType Container)) {
			# Sobrescribir la propiedad Path
			$Folder.Path = $regValue
		}
	}
	return $Folder
}
