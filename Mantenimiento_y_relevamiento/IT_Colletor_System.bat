@echo off
chcp 65001 >nul
:: ==================================================
:: IT_SystemInfoCollector.bat
:: Author    : Bruno A. Parisi
:: Role      : IT / Field Service / SysAdmin
:: Version   : 1.1.0 (Optimized)
:: ==================================================

setlocal EnableExtensions EnableDelayedExpansion

set "NA=No corresponde"

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
powershell -NoProfile -Command ^

 "Start-Process powershell -Verb RunAs -ArgumentList '-NoExit -Command \"cmd /c \\\"%~f0 admin\\\"\"'"

exit /b

:: ===============================
:: MAIN FLOW
:: ===============================
:run
call :showMessage
call :getBaseInfo
call :getNetworkInfo
call :getSystemAndDiskInfo
call :getJavaInfo

call :getSAPInfo

call :waitClose
exit /b

:showMessage
echo =====================================
echo IT_SystemInfoCollector
echo Desarrollado por Bruno A. Parisi
echo Version : 1.0.0
echo =====================================
echo.
exit /b

:getBaseInfo
set "HOSTNAME=%COMPUTERNAME%"
set "EXEC_DATE=%DATE%"
set "EXEC_TIME=%TIME%"
set "FECHA=%DATE:~6,4%%DATE:~3,2%%DATE:~0,2%"
set "OUTPUT=%HOSTNAME%_%FECHA%.json"
echo [OK] Hostname: %HOSTNAME%
exit /b

:getNetworkInfo
echo [INFO] Obteniendo direccion IP...
set "IP=%NA%"
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    if "!IP!"=="%NA%" (
        set "temp_ip=%%i"
        set "IP=!temp_ip:~1!"
    )
)
echo [OK] IP: %IP%
echo.
exit /b

:: ==================================================
:: SYSTEM & DISK INFO (OPTIMIZED SINGLE CALL)
:: ==================================================
:getSystemAndDiskInfo
echo [INFO] Extrayendo Hardware, OS y Disco...

:: Usamos punto y coma (;) como delimitador para evitar conflictos con comas en nombres de fabricantes
for /f "tokens=1-9 delims=;" %%a in ('
    powershell -NoProfile -Command ^
    "$b = Get-WmiObject Win32_BIOS;" ^
    "$o = Get-WmiObject Win32_OperatingSystem;" ^
    "$c = Get-WmiObject Win32_ComputerSystem;" ^
    "$d = Get-WmiObject Win32_LogicalDisk -Filter \"DeviceID='C:'\";" ^
    "$bv = if($b.SMBIOSBIOSVersion){$b.SMBIOSBIOSVersion}else{$b.Version};" ^
    "$df = if($d){[math]::Round($d.FreeSpace/1GB,2)}else{0};" ^
    "$dt = if($d){[math]::Round($d.Size/1GB,2)}else{0};" ^
    "Write-Output ('{0};{1};{2};{3};{4};{5};{6};{7};{8}' -f $bv, $o.Caption, $o.Version, $o.InstallDate, $c.Manufacturer, $c.Model, $o.SerialNumber, $df, $dt)"
') do (
    set "BIOS_VERSION=%%a"
    set "OS_NAME=%%b"
    set "OS_VERSION=%%c"
    set "INSTALL_DATE=%%d"
    set "SYSTEM_VENDOR=%%e"
    set "SYSTEM_MODEL=%%f"
    set "PRODUCT_ID=%%g"
    set "DISK_FREE_GB=%%h"
    set "DISK_TOTAL_GB=%%i"
)

echo [OK] BIOS             : %BIOS_VERSION%
echo [OK] OS               : %OS_NAME%
echo [OK] Fabricante       : %SYSTEM_VENDOR%
echo [OK] Modelo           : %SYSTEM_MODEL%
echo [OK] Disco C: Libre   : %DISK_FREE_GB% GB
echo.
exit /b

:getJavaInfo
echo [INFO] Verificando Java...
set "JAVA_VERSION=%NA%"
java -version >nul 2>&1
if %errorlevel%==0 (
    for /f "tokens=3 delims= " %%i in ('java -version 2^>^&1 ^| find "version"') do set "JAVA_VERSION=%%i"
    set "JAVA_VERSION=!JAVA_VERSION:"=!"
    echo [OK] Java: !JAVA_VERSION!
) else (
    echo [WARN] Java no instalado
)
echo.
exit /b

:getEdgeInfo
echo [INFO] Verificando Microsoft Edge...
set "EDGE_VERSION=%NA%"
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
    for /f "tokens=3" %%i in ('"%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" --version') do set "EDGE_VERSION=%%i"
    echo [OK] Edge: %EDGE_VERSION%
) else (
    echo [WARN] Edge no encontrado
)
echo.
exit /b

:getSAPInfo
echo [INFO] Verificando SAP GUI...
set "SAP_VERSION=%NA%"
if exist "C:\Program Files (x86)\SAP\FrontEnd\SAPgui\saplogon.exe" (
    for /f "tokens=2" %%i in ('"%ProgramFiles(x86)%\SAP\FrontEnd\SAPgui\saplogon.exe" -v 2^>^&1') do set "SAP_VERSION=%%i"
    echo [OK] SAP: %SAP_VERSION%
) else (
    echo [WARN] SAP GUI no instalado
)
echo.
exit /b

:generateJSON
echo [INFO] Generando archivo JSON...
(
echo {
echo    "hostname": "%HOSTNAME%",
echo    "execution_date": "%EXEC_DATE%",
echo    "execution_time": "%EXEC_TIME%",
echo    "ip_address": "%IP%",
echo    "bios_version": "%BIOS_VERSION%",
echo    "os_name": "%OS_NAME%",
echo    "os_version": "%OS_VERSION%",
echo    "system_vendor": "%SYSTEM_VENDOR%",
echo    "system_model": "%SYSTEM_MODEL%",
echo    "product_id": "%PRODUCT_ID%",
echo    "install_date": "%INSTALL_DATE:~0,8%",
echo    "disk_c_free_gb": "%DISK_FREE_GB%",
echo    "disk_c_total_gb": "%DISK_TOTAL_GB%",
echo    "java_version": "%JAVA_VERSION%",
echo    "edge_version": "%EDGE_VERSION%",
echo    "sap_version": "%SAP_VERSION%"
echo }
) > "%OUTPUT%"
echo [OK] Archivo generado: %OUTPUT%
echo.
exit /b

:waitClose
echo Proceso finalizado.
pause
exit /b