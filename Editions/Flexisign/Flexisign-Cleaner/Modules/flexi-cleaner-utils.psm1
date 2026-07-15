
function Clear-EmptyFolders {
	param(
		[string]$TargetFolder
	)

	# Repetimos hasta que no queden carpetas vacías nuevas
	do {
		$deletedSomething = $false

		# Obtenemos todas las carpetas ordenadas por profundidad descendente (más profundas primero)
		$allFolders = Get-ChildItem -Path $TargetFolder -Directory -Recurse | Sort-Object { $_.FullName.Split('\').Count } -Descending

		foreach ($carpeta in $allFolders) {
			# Si la carpeta no es la raíz y está vacía (sin archivos ni subcarpetas)
			if ($carpeta.FullName -ne $TargetFolder) {
				# Comprobamos si está realmente vacía
				$contents = @(Get-ChildItem -Path $carpeta.FullName -Force)
				if ($contents.Count -eq 0) {
					# Eliminar (por ahora solo mostramos)
					Write-Host "[DUMMY]Eliminando carpeta vacía: $($carpeta.FullName)"
					# Remove-Item -Path $carpeta.FullName -Force -ErrorAction SilentlyContinue
					$deletedSomething = $true
				}
			}
		}
		# Si después de un recorrido se borró algo, repetimos por si aparecen nuevas vacías (padres ahora sin contenido)
	} while ($deletedSomething)
}

function ConvertTo-NativeRegistryPath {
	param([string]$Path)
	if ($Path -match '^HKEY_') { return $Path }
	$Path = $Path -replace '^HKCU:\\', 'HKEY_CURRENT_USER\'
	$Path = $Path -replace '^HKLM:\\', 'HKEY_LOCAL_MACHINE\'
	$Path = $Path -replace '^HKU:\\', 'HKEY_USERS\'
	$Path = $Path -replace '^HKCR:\\', 'HKEY_CLASSES_ROOT\'
	$Path = $Path -replace '^HKCC:\\', 'HKEY_CURRENT_CONFIG\'
	return $Path
}

function Remove-TempElements {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path,

		[Parameter(Mandatory = $true)]
		[ValidateSet("Sessions", "Days", "Months")]
		[string]$RetentionUnit,

		[Parameter(Mandatory = $true)]
		[int]$RetentionValue,

		[ValidateSet("File", "Directory")]
		[string]$Type = "File",      # Por defecto solo archivos

		[switch]$Force
	)

	# Determinar si buscamos archivos o directorios
	$getParams = @{
		Path    = $Path
		Recurse = $true
	}
	if ($Type -eq "File") {
		$getParams.File = $true
	} else {
		$getParams.Directory = $true
	}

	$allItems = Get-ChildItem @getParams

	# Filtro según la unidad de retención
	switch ($RetentionUnit) {
		"Days" {
			$cutoffDate = (Get-Date).AddDays(-$RetentionValue)
			$itemsToDelete = $allItems | Where-Object { $_.LastWriteTime -lt $cutoffDate }
		}
		"Months" {
			$cutoffDate = (Get-Date).AddMonths(-$RetentionValue)
			$itemsToDelete = $allItems | Where-Object { $_.LastWriteTime -lt $cutoffDate }
		}
		"Sessions" {
			# Agrupar por fecha única (día de modificación)
			$itemsWithDate = $allItems | Select-Object FullName, @{N = 'Date'; E = { $_.LastWriteTime.Date } }
			$allSessionDates = $itemsWithDate | Select-Object -ExpandProperty Date -Unique | Sort-Object -Descending

			if ($allSessionDates.Count -gt $RetentionValue) {
				$datesToRemove = $allSessionDates | Select-Object -Skip $RetentionValue
				$itemsToDelete = $itemsWithDate | Where-Object { $_.Date -in $datesToRemove }
			} else {
				$itemsToDelete = @()   # Conservar todos, no hay suficientes sesiones
			}
		}
	}

	# Mostrar lo que se eliminaría (modo seguro)
	foreach ($item in $itemsToDelete) {
		Write-Host " [DUMMY] $($item.FullName)"
		# Remove-Item -Path $item.FullName -Force:$Force -ErrorAction SilentlyContinue
	}
}
