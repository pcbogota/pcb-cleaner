function Remove-FlexisignTemps {
	$tempFolder = Get-FlexisignTempFolder
}

function Remove-FlexisignJobs {
	$JobsFolder = Get-FlexisignJobsFolder
}

function Get-FlexisignTempFolder {
	# obtener desde HKEY_CURRENT_USER\SOFTWARE\Amiable\Production-3684 el atributo 'TempFolderPath'
	$folder = "Carpeta desde registro. Si no existe, usar como fallback la carpeta en psd1"
	$sessionsToKepp = "Dato desde psd1 de carpetas a borrar."

}

function Get-FlexisignJobsFolder {
	# obtener desde HKEY_CURRENT_USER\SOFTWARE\Amiable\Production-3684 el atributo 'JobFolderPath'
	$folder = "Carpeta desde registro. Si no existe, usar como fallback la carpeta en psd1"
	$sessionsToKepp = "Dato desde psd1 de carpetas a borrar"
}
