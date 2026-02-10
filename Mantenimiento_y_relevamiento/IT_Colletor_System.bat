@echo off
chcp 65001 >nul
:: ==================================================
:: IT_SystemInfoCollector.bat
:: Author   : Bruno A. Parisi
:: Role     : IT / Field Service / SysAdmin
:: Version  : 1.0.0
:: Purpose  : Windows system information collection
::            - System Info (systeminfo filtered)
::            - Network / Disk
::            - SAP / Java / Edge
:: ==================================================

setlocal EnableExtensions EnableDelayedExpansion

set NA=No corresponde al dia de la fecha

:: ===============================
:: ENTRY POINT
:: ===============================
if "%1"=="admin" goto run

call :elevate
exit /b


:: ===============================
:: ELEVATE TO ADMIN
:: ===============================
:elevate
powershell -Command ^
 "Start-Process cmd -Verb RunAs -ArgumentList '/k \"%~f0 admin\"'"
exit /b


:: ===============================
:: MAIN FLOW
:: ===============================
:run
call :showMessage
call :getBaseInfo
call :getNetworkInfo
call :getSystemInfo
call :getDiskInfo
call :getJavaInfo
call :getEdgeInfo
call :getSAPInfo
call :generateJSON
call :waitClose
exit /b


:: ===============================
:: HEADER
:: ===============================
:showMessage
echo =====================================
echo IT_SystemInfoCollector
echo Desarrollado por Bruno A. Parisi
echo Version : 1.0.0
echo =====================================
echo.
exit /b


:: ===============================
:: BASE INFO
:: ===============================
:getBaseInfo
echo [INFO] Obteniendo hostname y fecha de ejecucion...

set HOSTNAME=%COMPUTERNAME%
set EXEC_DATE=%DATE%
set EXEC_TIME=%TIME%

set FECHA=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%
set OUTPUT=%HOSTNAME%_%FECHA%.json

echo [OK] Hostname: %HOSTNAME%
echo.
exit /b


:: ===============================
:: SYSTEM INFO (POWERSHELL SAFE)
:: ===============================
:getSystemInfo
echo [INFO] Obteniendo informacion del sistema (PowerShell)...

set BIOS_VERSION=%NA%
set OS_NAME=%NA%
set OS_VERSION=%NA%
set INSTALL_DATE=%NA%
set SYSTEM_VENDOR=%NA%
set SYSTEM_MODEL=%NA%
set PRODUCT_ID=%NA%

for /f "delims=" %%i in ('
    powershell -NoProfile -Command ^
    "(systeminfo | Select-String '^Versión del BIOS').ToString().Split(':',2)[1].Trim()"
') do set BIOS_VERSION=%%i

for /f "delims=" %%i in ('
    powershell -NoProfile -Command ^
    "(systeminfo | Select-String '^Nombre del sistema operativo').ToString().Split(':',2)[1].Trim()"
') do set OS_NAME=%%i

for /f "delims=" %%i in ('
    powershell -NoProfile -Command ^
    "(systeminfo | Select-String '^Versión del sistema operativo').ToString().Split(':',2)[1].Trim()"
') do set OS_VERSION=%%i

for /f "delims=" %%i in ('
    powershell -NoProfile -Command ^
    "(systeminfo | Select-String '^Fecha de instalación original').ToString().Split(':',2)[1].Trim()"
') do set INSTALL_DATE=%%i

for /f "delims=" %%i in ('
    powershell -NoProfile -Command ^
    "(systeminfo | Select-String '^Fabricante del sistema').ToString().Split(':',2)[1].Trim()"
') do set SYSTEM_VENDOR=%%i

for /f "delims=" %%i in ('
    powershell -NoProfile -Command ^
    "(systeminfo | Select-String '^Modelo del sistema').ToString().Split(':',2)[1].Trim()"
') do set SYSTEM_MODEL=%%i

for /f "delims=" %%i in ('
    powershell -NoProfile -Command ^
    "(systeminfo | Select-String '^Id. del producto').ToString().Split(':',2)[1].Trim()"
') do set PRODUCT_ID=%%i

echo [OK] BIOS              : %BIOS_VERSION%
echo [OK] OS                : %OS_NAME%
echo [OK] OS Version        : %OS_VERSION%
echo [OK] Fecha instalacion : %INSTALL_DATE%
echo [OK] Fabricante        : %SYSTEM_VENDOR%
echo [OK] Modelo            : %SYSTEM_MODEL%
echo [OK] Product ID        : %PRODUCT_ID%
echo.

exit /b



:: ===============================
:: NETWORK INFO
:: ===============================
:getNetworkInfo
echo [INFO] Obteniendo direccion IP...

set IP=%NA%
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    if "%IP%"=="%NA%" set IP=%%i
)

set IP=%IP:~1%

echo [OK] IP: %IP%
echo.
exit /b


:: ===============================
:: DISK INFO
:: ===============================
:getDiskInfo
echo [INFO] Obteniendo espacio en disco C:...

for /f "tokens=1,2 delims==" %%A in ('powershell -NoProfile -Command ^
    "Get-CimInstance -ClassName Win32_LogicalDisk -Filter \"DeviceID='C:'\" ^|
     Select-Object -ExpandProperty FreeSpace,Size ^|
     ForEach-Object -Begin { $i=0 } -Process {
         if ($i -eq 0) { \$freeGB = [math]::Round($_ / 1GB, 2); } else { \$totalGB = [math]::Round($_ / 1GB, 2); }
         \$i++
     }
     Write-Output (\"DISK_FREE_GB={0}\" -f \$freeGB);
     Write-Output (\"DISK_TOTAL_GB={0}\" -f \$totalGB)
    "') do (
    set "%%A=%%B"
)

echo [OK] Disco C: libre = %DISK_FREE_GB% GB
echo [OK] Disco C: total = %DISK_TOTAL_GB% GB
echo.
exit /b



:: ===============================
:: JAVA INFO
:: ===============================
:getJavaInfo
echo [INFO] Verificando Java...

set JAVA_VERSION=%NA%
java -version >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=3 delims= " %%i in ('java -version 2^>^&1 ^| find "version"') do set JAVA_VERSION=%%i
    set JAVA_VERSION=%JAVA_VERSION:"=%
    echo [OK] Java: %JAVA_VERSION%
) else (
    echo [WARN] Java no instalado
)
echo.
exit /b


:: ===============================
:: EDGE INFO
:: ===============================
:getEdgeInfo
echo [INFO] Verificando Microsoft Edge...

set EDGE_VERSION=%NA%
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    for /f "tokens=3" %%i in (
        '"%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --version'
    ) do set EDGE_VERSION=%%i
    echo [OK] Edge: %EDGE_VERSION%
) else (
    echo [WARN] Edge no encontrado
)
echo.
exit /b


:: ===============================
:: SAP INFO
:: ===============================
:getSAPInfo
echo [INFO] Verificando SAP GUI...

set SAP_VERSION=%NA%
if exist "C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe" (
    for /f "tokens=2" %%i in (
        '"C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe" -v 2^>^&1'
    ) do set SAP_VERSION=%%i
    echo [OK] SAP: %SAP_VERSION%
) else (
    echo [WARN] SAP GUI no instalado
)
echo.
exit /b


:: ===============================
:: GENERATE JSON
:: ===============================
:generateJSON
echo [INFO] Generando archivo JSON...

(
echo {
echo   "hostname": "%HOSTNAME%",
echo   "execution_date": "%EXEC_DATE%",
echo   "execution_time": "%EXEC_TIME%",
echo   "ip_address": "%IP%",
echo   "bios_version": "%BIOS_VERSION%",
echo   "os_name": "%OS_NAME%",
echo   "os_version": "%OS_VERSION%",
echo   "system_vendor": "%SYSTEM_VENDOR%",
echo   "system_model": "%SYSTEM_MODEL%",
echo   "product_id": "%PRODUCT_ID%",
echo   "install_date": "%INSTALL_DATE%",
echo   "disk_c_free_bytes": "%DISK_FREE%",
echo   "disk_c_total_bytes": "%DISK_TOTAL%",
echo   "java_version": "%JAVA_VERSION%",
echo   "edge_version": "%EDGE_VERSION%",
echo   "sap_version": "%SAP_VERSION%"
echo }
) > "%OUTPUT%"

echo [OK] Archivo generado: %OUTPUT%
echo.
exit /b


:: ===============================
:: WAIT
:: ===============================
:waitClose
echo Presione una tecla para cerrar la consola...
pause >nul
exit /b
