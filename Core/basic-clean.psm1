
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

function Show-Notification {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Title,
		[Parameter(Mandatory = $true)]
		[string]$Text,
		[ValidateSet("long", "short")]
		[string] $Duration = "short",
		[ValidateSet("alert", "info", "error")]
		[string] $Type = "info",
		[switch] $Silent
	)
	if ($text.Length -gt 147) {
		Write-Error "La notificación se verá truncada ya que el tamaño es mayor a 147 caracteres, debería mejorarse el texto"
	}
	# 1. Variables de Identidad de tu Aplicación Local
	$app_id_custom = "PCB_Cleaner.LocalAlerts.v1"
	$app_display_name = "PCB Cleaner Basic"
	$registry_path = "HKCU:\Software\Classes\AppUserModelId\$app_id_custom"
	$iconUri = "$CleanerRootPath\Assets\Common\Icon\PCBCleaner.ico"

	# 2. Registrar el AppID de manera local en el Registro de Windows
	if (-not (Test-Path $registry_path)) {
		New-Item -Path $registry_path -Force | Out-Null
		New-ItemProperty -Path $registry_path -Name "DisplayName" -Value $app_display_name -PropertyType String -Force | Out-Null
		New-ItemProperty -Path $registry_path -Name "IconUri" -Value $iconUri -PropertyType String -Force | Out-Null
		# Nota: Windows asume el ícono por defecto del sistema si no se le asocia una ruta (.ico)
	}

	# 3. Cargar las clases de Windows Runtime para la notificación
	[void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
	[void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

	# 4. Diseñar la estructura XML de la Notificación
	# https://learn.microsoft.com/en-us/uwp/schemas/tiles/toastschema/schema-root

	$TitleXml = [System.Security.SecurityElement]::Escape($Title)
	$TextXml = [System.Security.SecurityElement]::Escape($Text)

	# personalización por tipo de notificación
	$audioTone = "ms-winsoundevent:Notification.Default"
	$audioSilent = ([string]$Silent).tolower()

	$imagePath = "$CleanerRootPath\Assets\Common\Icon\PCBNotifyInfoImage.png"
	$cropImage = 'Circle'

	if ($type -eq "error") {
		$audioTone = "ms-winsoundevent:Notification.Looping.Alarm10"
		$imagePath = "$CleanerRootPath\Assets\Common\Icon\PCBNotifyErrorImage.png"
	} elseif ($type -eq "alert") {
		$audioTone = "ms-winsoundevent:Notification.Looping.Alarm3"
		$imagePath = "$CleanerRootPath\Assets\Common\Icon\PCBNotifyAlertImages.png"
	}

	if (-not (Test-Path $imagePath)) {
		$imagePath = $iconUri
		$cropImage = 'Default'
	}
	$xml_string = @"
<toast duration="$duration" scenario="reminder">
    <visual lang="es-CO">
        <binding template="ToastGeneric">
            <text id="1" lang="es-CO">$TitleXml</text>
            <text id="0" lang="es-CO">$TextXml</text>
            <image placement="appLogoOverride" hint-crop="$cropImage" src="file:///$imagePath"/>
        </binding>
    </visual>
	<audio src="$audioTone" silent="$audioSilent"/>
	</toast>
"@

	# 5. Cargar el XML en el DOM de Windows
	$toast_xml = New-Object Windows.Data.Xml.Dom.XmlDocument
	$toast_xml.LoadXml($xml_string)

	# 6. Construir y desplegar el Toast usando tu nuevo AppID legítimo
	$toast_notification = New-Object Windows.UI.Notifications.ToastNotification $toast_xml
	[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app_id_custom).Show($toast_notification)
}
