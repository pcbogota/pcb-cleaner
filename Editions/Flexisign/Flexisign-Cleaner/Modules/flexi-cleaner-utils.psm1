
function Clear-EmptyFolders {
	# 4. Limpieza de carpetas huérfanas (vacías)
	# Solo borramos si la carpeta está realmente vacía
	$EmptyFolder = Get-ChildItem -Path $targetFolder -Directory -Recurse | Where-Object { (Get-ChildItem -Path $_.FullName -Recurse).Count -eq 0 }

	foreach ($carpeta in $EmptyFolder) {
		# Validamos que no sea la carpeta raíz
		if ($Folder.FullName -ne $targetFolder) {
			# Remove-Item -Path $carpeta.FullName -Force -ErrorAction SilentlyContinue
			Write-Host "Eliminando carpeta huérfana: $($carpeta.FullName)"
		}
	}
}

function Get-FoldersBasedOnCalendar {}

function Get-FoldersBasedOnSesions {}
