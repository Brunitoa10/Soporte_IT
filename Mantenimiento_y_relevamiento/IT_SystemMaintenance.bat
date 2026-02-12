@echo off

:: ==========================================================
:: TECHNOLOGY ADVANCE SOLUTION
:: Author    : Bruno A. Parisi
:: Role      : IT / Field Service / SysAdmin
:: Version   : 1.2.1
:: ==========================================================

setlocal EnableExtensions

:: ==========================================================
:: CONTROL DE PRIVILEGIOS
:: ==========================================================
:init
cls
echo.
echo  ==========================================================
echo    Mantenimiento de Sistema
echo  ==========================================================
echo.
echo  [1] Ejecutar con Privilegios de Administrador (MODO ROOT)
echo  [2] Ejecutar con Privilegios Limitados (MODO ESTANDAR)
echo.
set /p opt=" SELECCIONE UNA OPCION [1-2]: "

if "%opt%"=="1" goto check_admin
if "%opt%"=="2" (set "MODE=USUARIO ESTANDAR" & goto run)
goto init

:check_admin
net session >nul 2>&1
if %errorlevel% == 0 (
    set "MODE=ROOT (ADMINISTRADOR)"
    goto run
) else (
    goto elevate
)

:elevate
echo.
echo  [!] Elevando privilegios... Por favor, acepte el prompt de UAC.
powershell -NoProfile -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"%~f0\" admin_mode'"
exit /b

:: ==========================================================
:: LOGICA PRINCIPAL
:: ==========================================================
:run
if "%1"=="admin_mode" set "MODE=ROOT (ADMINISTRADOR)"
cls
call :showMessage

:: Ejecucion de Tareas
call :runGPUpdate
call :runSFC

call :waitClose
exit /b

:: ==========================================================
:: PROCEDIMIENTOS (UI)
:: ==========================================================
:showMessage
echo  ==========================================================
echo    Autor - Bruno A. Parisi
echo    ESTADO DE SESION: %MODE%
echo  ==========================================================
echo.
exit /b

:runGPUpdate
echo  [i] Iniciando: Actualizacion de Politicas de Grupo...
echo  ----------------------------------------------------------
gpupdate /force
if %errorlevel% equ 0 (
    echo.
    echo  [OK] gpupdate completado exitosamente.
) else (
    echo.
    echo  [ERROR] Hubo un problema al actualizar las politicas.
)
echo.
exit /b

:runSFC
echo  [i] Iniciando: System File Checker (SFC)...
echo  ----------------------------------------------------------
if "%MODE%"=="USUARIO ESTANDAR" (
    echo  [AVISO] SFC requiere privilegios ROOT para ejecutarse.
    echo  Operacion omitida por falta de permisos.
) else (
    sfc /scannow
    if %errorlevel% equ 0 (
        echo.
        echo  [OK] SFC finalizo sin encontrar errores de integridad.
    ) else (
        echo.
        echo  [!] SFC encontro problemas o no pudo completar la tarea.
    )
)
echo.
exit /b

:waitClose
echo.
echo  ==========================================================
echo    Proceso Finalizado
echo  ==========================================================
echo  Presione una tecla para salir...
pause >nul
exit /b