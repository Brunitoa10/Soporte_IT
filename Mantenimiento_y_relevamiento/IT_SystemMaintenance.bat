@echo off



:: ==================================================
:: IT_SystemMaintenance.bat
:: Author   : Bruno A. Parisi
:: Role     : IT / Field Service / SysAdmin
:: Version  : 1.0.0
:: Purpose  : Windows system maintenance operations
::            - GPUpdate
::            - System File Checker
:: ==================================================

setlocal EnableExtensions

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
:: Llamado a procedimientos
:: ===============================
:run
call :showMessage
call :runGPUpdate
call :runSFC
call :waitClose
exit /b


:: ===============================
:: SHOW MESSAGE
:: ===============================
:showMessage

echo =====================================
echo Desarrollado por Bruno A. Parisi
echo.
echo Version  : 1.0.0
echo =====================================
echo.
exit /b


:: ===============================
:: INICIO LOGICA DEL PROGRAMA
:: ===============================

:: ===============================
:: RUN GPUPDATE
:: ===============================

:runGPUpdate
echo -------------------------------------
echo Ejecutando gpupdate /force
echo.
echo Puede tardar unos minutos...
echo -------------------------------------
echo.

gpupdate /force

if errorlevel 1 (
    echo.
    echo [ERROR] gpupdate finalizo con errores.
) else (
    echo.
    echo [OK] gpupdate ejecutado correctamente.
)

echo.

:: ===============================
:: RUN SFC /SCANNOW
:: ===============================

:runSFC
echo -------------------------------------
echo Ejecutando sfc \scannow
echo.
echo Puede tardar unos minutos...
echo -------------------------------------
echo.

sfc /scannow

if errorlevel 1 (
    echo.
    echo [ERROR] sfc detecto o no pudo reparar errores.
) else (
    echo.
    echo [OK] sfc finalizo correctamente.
)


:: ===============================
:: WAIT CONFIRMATION
:: ===============================
:waitClose
echo Presione una tecla para cerrar la consola...
pause >nul
exit /b
