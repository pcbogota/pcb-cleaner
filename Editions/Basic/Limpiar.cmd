@ECHO OFF
CLS
setlocal enabledelayedexpansion

:: Nombre de la aplicaci¢n y archivo .ps1 a ejecutar
set "title=Limpieza de Google Chrome y Windows"
set "ps1FilePath=Start-BasicClean.ps1"

:: Si argumentos a pasar al script. Si no lleva dejar vac°o
set "arguments="

:: Colocaci¢n del t°tulo
color 08 & title %title% & set len=0

set "title=  %title%"
:count_chars
if not "!title:~%len%,1!"=="" (set /a len+=1 & goto count_chars)
set /a total_len=len + 2
set iguales= & for /L %%i in (1,1,%total_len%) do set iguales=!iguales!=
ECHO. & ECHO !iguales! & ECHO  %title% & ECHO !iguales!

:: Inicializaci¢n de variables
set "tempScriptNamePrefix=%TEMP%\OEMgetPriv_PCB" & set "batchPath=%~dpnx0" & set "envVarPrefix=tmp_PCB_SS_" & set "shouldRecreatePolicyFile=false" & set "scopes=Process CurrentUser LocalMachine" & set "tempPolicyFile=%TEMP%\OE_OrigPolicies_PCB.tmp" & set "errorAdvert=false"

:: Verificaci¢n de privilegios
:checkPrivileges
NET SESSION 1>NUL 2>NUL
if '%errorlevel%' == '0' ( goto :runingasAdminPrivileges) else ( goto :getPrivileges)


:: Creaci¢n de un script para obtener privilegios
:getPrivileges
if /i '%1'=='ELEV' (shift /1 & goto :runingasAdminPrivileges)
ECHO. & ECHO ******************************************& ECHO Solicitando ejecuci¢n como administrador... & ECHO ******************************************

powershell.exe -NoProfile -Command "if ([int]$PSVersionTable.PSVersion.Major -ge 5) { exit 0 } else { exit 1 }" >NUL 2>&1
if %errorlevel% equ 0 ( goto :elevateWithPowerShell ) else ( goto :elevateWithVBScript )

:elevateWithPowerShell
set "currentBatchPath=%~dpnx0" & set "currentBatchArgs=%*" & set "tempScript=%tempScriptNamePrefix%.ps1"
(
echo if ^(-NOT ^([Security.Principal.WindowsPrincipal^]^[Security.Principal.WindowsIdentity^]::GetCurrent^(^)^).IsInRole^(^[Security.Principal.WindowsBuiltInRole^] 'Administrator'^)^)
echo { Start-Process powershell.exe -ArgumentList ^"-NoProfile -ExecutionPolicy Bypass -File `"$($PSCommandPath)`"" -Verb RunAs ; Exit }
echo $ScriptTempFilePath = $^(^(Get-Item -Path $MyInvocation.MyCommand.Path^).Name^)
echo ^& "%batchPath%" %currentBatchArgs%
echo If ^(Test-Path -Path ^"$PSScriptRoot\$ScriptTempFilePath^"^) {
echo     Remove-Item -LiteralPath ^"$PSScriptRoot\$ScriptTempFilePath^" -ErrorAction SilentlyContinue
echo }
) > "%tempScript%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%tempScript%"
goto :EOF

:elevateWithVBScript
set "tempScript=%tempScriptNamePrefix%.vbs"
ECHO Set UAC = CreateObject^("Shell.Application"^) > "%tempScript%"
ECHO args = "ELEV " >> "%tempScript%"
ECHO For Each strArg in WScript.Arguments >> "%tempScript%"
ECHO args = args ^& strArg ^& " "  >> "%tempScript%"
ECHO Next >> "%tempScript%"
ECHO UAC.ShellExecute "!batchPath!", args, "", "runas", 1 >> "%tempScript%"
"%SystemRoot%\System32\WScript.exe" "%tempScript%" %* & exit /B

:: Ejecuci¢n con privilegios de administrador
:runingasAdminPrivileges

icacls %TEMP% /grant Everyone:(OI)(CI)F /T >nul
pushd . & cd /d %~dp0
if /i '%1'=='ELEV' (del "%tempScriptNamePrefix%*.*" 1>nul 2>nul  &  shift /1)

:: Guardado de fecha de ejecuci¢n del script en registro (HKLM:\SOFTWARE\PCBogota)
for /f "tokens=1-2 delims=/ " %%a in ('time /t') do ( set "Time=%%a" & set "Merid=%%b")
for /f "tokens=1-3 delims=//" %%a in ('date /t') do ( set "Day=%%a" & set "Mon=%%b" & set "Year=%%c")
set "Day=%Day:~4,7%"
set "Mon=%Mon: =%"
set "Mon=%Mon:~0,2%"
set "Month="
set "Year=%Year:~0,4%"

for %%i in (
	"01=Enero" "02=Febrero" "03=Marzo" "04=Abril" "05=Mayo" "06=Junio"
	"07=Julio" "08=Agosto" "09=Septiembre" "10=Octubre" "11=Noviembre" "12=Diciembre"
) do (
	for /f "tokens=1,2 delims==" %%j in (%%i) do (
		if "%%j"=="%Mon%" set "Month=%%k"
	)
)

set "FechaTime=%Time%%Merid% - %Day% %Month% %Year%" & set "regPath=HKLM\Software\PCBogota\ExecBatchs"
reg add "%regPath%" /v "%title%" /d "%FechaTime%" /f >nul


:: EJECUCI‡N DEL SCRIPT DE POWERSHELL ::
ECHO. & ECHO No cierre esta ventana hasta que termine...!!
set /a exitcode = 1
if defined ps1FilePath (
	if exist "%ps1FilePath%" ( ECHO. & ECHO ^>^>^>    Ejecutando %ps1FilePath%... & ECHO. & powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%ps1FilePath%" %arguments%
	set "exitcode=!errorlevel!" ) else ( set "errorAdvert=true" )
) else ( set "errorAdvert=true" )
if "!errorAdvert!"=="true" ( ECHO. & echo oki & ECHO ^>^>^> NO SE HA DEFINIDO NIGÈN SCRIPT PARA EJECUTAR!!!^<^<^< & ECHO Este archivo requiere de muchas modificaciones! & ECHO. )

:END
echo.
echo.
echo --- Finalizado! ---
echo.
CALL :fn_pause
call :fn_countdown

color
goto :EOF


:: --- DEFINICIONES DE FUNCIONES/SUBRUTINAS ---
:fn_pause
echo Presiona una tecla para continuar...
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$ignore = @(16,17,18,20,91,92,93,144,145,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183); do { $k = $Host.UI.RawUI.ReadKey('NoEcho, IncludeKeyDown')} while ($ignore -contains $k.VirtualKeyCode)" >nul
goto :EOF

:fn_countdown
set /a "COUNTDOWN_SECONDS=5"
echo Cerrando ventana autom†ticamente...

:COUNTDOWN_LOOP
echo Tiempo restante: %COUNTDOWN_SECONDS% segundos
set /a "COUNTDOWN_SECONDS-=1"
ping 127.0.0.1 -n 2 > nul

if %COUNTDOWN_SECONDS% gtr 0 (
	goto COUNTDOWN_LOOP
)
goto :EOF
