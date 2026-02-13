@echo off

:: ==========================================================
:: Bruno A Parisi - PORTAL TI LAUNCHER
:: Author    : Bruno A. Parisi
:: Role      : IT / Field Service
:: Name      : Portal_Launcher.bat
:: Version   : 1.0.0
:: ==========================================================

setlocal EnableExtensions

:: ==========================================================
:: CONFIGURACION
:: ==========================================================
:: Reemplaza la URL a continuacion con la direccion real de tu Portal TI
set "PORTAL_URL=https://www.youtube.com/"

:init
cls
echo.
echo  ==========================================================
echo    Acceso a Portal TI
echo  ==========================================================
echo.
echo  [i] Verificando conectividad con el servidor...

:: Verificacion rapida de ping para asegurar que el sitio esta online
ping -n 1 google.com >nul 2>&1
if %errorlevel% neq 0 (
    echo  [ERROR] No se detecta conexion a Internet/Red.
    echo          Verifique su cable o Wi-Fi antes de continuar.
    echo.
    pause
    exit /b
)

echo  [OK] Conexion establecida.
echo  [i] Abriendo Portal TI en el navegador predeterminado...
echo.

:: Lanzamiento del portal
start "" "%PORTAL_URL%"

echo  ==========================================================
echo    Acceso Gestionado por Bruno A Parisi
echo  ==========================================================
echo.
echo  Presione una tecla para cerrar esta ventana...
pause >nul
exit /b