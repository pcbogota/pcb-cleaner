function Start-CleanGoogleChrome {
	param(
		[object[]]$ProcessData
	)
	$p = $ProcessData | Where-Object { $_.Name -eq "chrome" }
	if (-not $p) {
		$P = [PSCustomObject]@{
			Name        = "chrome"
			DisplayName = "Google Chrome"
		}
	}

	Stop-ProcessGracefully -Name ($p.Name) -KillProcess
	Start-Sleep -Seconds 3  # Pequeña pausa para que suelte los archivos

	$chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
	Clear-FolderContent -Path $chromeCache -LogPrefix $p.DisplayName
	Set-Snapshot -Name $p.DisplayName

}

function Start-CleanGoogleChromeDeep {
	param(
		[string]$ChromeUserData = "$env:LOCALAPPDATA\Google\Chrome\User Data",
		[switch]$PreserveSessions
	)

	Winfo "Limpiando datos profundos de Google Chrome..."

	# Carpetas seguras (no afectan sesiones ni cookies)
	$safeFolders = @(
		"Code Cache",
		"Service Worker",
		"File System",
		"Session Storage"
	)

	# Carpetas que pueden cerrar sesiones si se borran
	$riskyFolders = @(
		"Local Storage",
		"IndexedDB"
	)

	$foldersToClear = $safeFolders
	if (-not $PreserveSessions) {
		$foldersToClear += $riskyFolders
	}

	# Buscar todos los perfiles (Default, Profile 1, etc.)
	$userProfiles = Get-ChildItem -Path $ChromeUserData -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^(Default|Profile\s*\d+)$' }

	foreach ($up in $userProfiles) {
		foreach ($folder in $foldersToClear) {
			$folderPath = Join-Path $up.FullName $folder
			Clear-FolderContent -Path $folderPath -LogPrefix "Google Chrome (Usuario: $($up.Name)) - $folder"
		}
	}
	Set-Snapshot -Name "Limpieza profunda de Google Chrome"
}
