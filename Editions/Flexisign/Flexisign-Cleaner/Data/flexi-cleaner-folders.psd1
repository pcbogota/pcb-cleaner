<#
| Propiedad                | Tipo   | Obligatoria  | Descripción                                                |
| ------------------------ | ------ | -------------- | ---------------------------------------------------------|
| Name                     | string | Sí           | Nombre legible para logs.                                  |
| Path                     | string | Si           | Ruta absoluta de la carpeta raíz a limpiar.                |
| RetentionUnit            | string | Si           | Unidad de retención: 'Sessions', 'Days' 'Months'           |
| RetentionValueNormal     | int    | Si           | Valor para modo normal                                     |
| RetentionValueAggressive | int    | Si           | Valor para modo agresivo                                   |
| RegeditPath              | string | No           | Ruta del registro que puede contener la ruta de temporales |
| RegeditAttribute         | string | No           | Valor del registro con la ruta de temporales               |
| Force                    | bool   | No           | si se pasa `-Force` a `Remove-Item`                        |
| ExecutionFunction        | string | No           | Nombre de una función personalizada para la limpieza       |
#>

@{
	Folders = @(
		@{
			Name                     = 'Temporales FlexiSIGN'
			Path                     = 'C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Temp'
			Force                    = $true
			RetentionUnit            = 'Sessions'
			RetentionValueNormal     = 3
			RetentionValueAggressive = 1
			RegeditPath              = "HKEY_CURRENT_USER\SOFTWARE\Amiable\Production-3684"
			RegeditAttribute         = "TempFolderPath"
		},
		@{
			Name                     = 'Trabajos (Jobs) FlexiSIGN'
			Path                     = 'C:\Program Files\SAi\FlexiPRINT 21 RIPControl Edition\Jobs and Settings\Temp'
			Force                    = $true
			RetentionUnit            = 'Sessions'
			RetentionValueNormal     = 8
			RetentionValueAggressive = 3
		},
		@{
			Name                     = 'Spool PrintExpert'
			Path                     = 'D:\Temp_Rip'
			Force                    = $true
			RetentionUnit            = 'Sessions'
			RetentionValueNormal     = 4
			RetentionValueAggressive = 1
		},
		@{
			Name                     = 'Trabajos de clientes'
			Path                     = 'D:\TrabajosClientes'
			Force                    = $false
			RetentionUnit            = 'Days'
			RetentionValueNormal     = 180   # 6 meses
			RetentionValueAggressive = 150   # 5 meses
		}
	)
}
