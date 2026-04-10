# Slimming BleachBit: Destructive Dependency Testing
######
#####
####
##
# Not really slimed, only ~9MB removed. Good for testing, but not really slim!
##
####
#####
######


$bleachbitFolder = "$PSScriptRoot\BleachBit-5.0.2-portable"
$movedFolder = "$PSScriptRoot\BleachBit_Trash"
$consoleExe = "$bleachbitFolder\bleachbit_console.exe"

# 1. Crear carpeta de destino para archivos "no esenciales"
if (-not (Test-Path $movedFolder)) { New-Item -ItemType Directory -Path $movedFolder | Out-Null }

# Obtener lista de todos los archivos excepto el ejecutable de consola y archivos de configuración críticos
$filesToTest = Get-ChildItem -Path $bleachbitFolder -Recurse -File | Where-Object {
	$_.Name -notmatch "bleachbit_console.exe|bleachbit.ini|winapp2.ini" -and
	$_.Extension -ne ".xml" # No tocar los archivos de instrucciones de limpieza
}

Write-Host "Iniciando proceso de adelgazamiento destructivo..." -ForegroundColor Yellow
Write-Host "Archivos a probar: $($filesToTest.Count)"

$filesRemoved = 0

foreach ($file in $filesToTest) {
	$relativeName = $file.FullName.Replace($bleachbitFolder, "")
	$destinationPath = Join-Path $movedFolder $relativeName
	$destinationDir = Split-Path $destinationPath

	# 2. Crear estructura de carpetas en 'moved' para poder revertir si falla
	if (-not (Test-Path $destinationDir)) { New-Item -ItemType Directory -Path $destinationDir | Out-Null }

	# 3. Mover el archivo temporalmente
	Write-Host "Probando remover: $relativeName" -NoNewline
	Move-Item -Path $file.FullName -Destination $destinationPath -Force

	# 4. Ejecutar BleachBit para ver si sigue vivo
	# Usamos un comando simple que no cierre Explorer pero que fuerce la carga del motor
	$process = Start-Process -FilePath $consoleExe -ArgumentList "--clean", "--preset" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
	if ($process.ExitCode -eq 0) {
		# El programa funcionó sin ese archivo
		Write-Host " -> [OK] (Eliminado)" -ForegroundColor Green
		$filesRemoved++
	} else {
		# El programa falló, lo devolvemos a su sitio
		Write-Host " -> [FALLO] (Restaurando...)" -ForegroundColor Red
		Move-Item -Path $destinationPath -Destination $file.FullName -Force
	}
}

Write-Host "`nProceso terminado." -ForegroundColor Yellow
Write-Host "Archivos eliminados exitosamente: $filesRemoved"
Write-Host "La carpeta Slim de BleachBit está lista." -ForegroundColor Green
