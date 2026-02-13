@echo off

:: ==========================================================
:: 					TOTAL NETWORK DIAGNOSTIC
:: Author    : Bruno A. Parisi
:: Role      : IT / Field Service / SysAdmin
:: Version   : 1.6.0
:: ==========================================================

setlocal EnableExtensions

:: ==========================================================
:: CONTROL DE PRIVILEGIOS
:: ==========================================================
:init
cls
echo.
echo  ==========================================================
echo 					TOTAL NETWORK DIAGNOSTIC
echo Author    : Bruno A. Parisi
echo Role      : IT / Field Service
echo Version   : 1.0.0	
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
echo  [!] Elevando privilegios...
powershell -NoProfile -Command "Start-Process cmd -Verb RunAs -ArgumentList '/c \"%~f0\" admin_mode'"
exit /b

:: ==========================================================
:: LOGICA PRINCIPAL
:: ==========================================================
:run
if "%1"=="admin_mode" set "MODE=ROOT (ADMINISTRADOR)"
cls
echo  ==========================================================
echo    TOTAL NETWORK DIAGNOSTIC
echo    ESTADO DE SESION: %MODE%
echo  ==========================================================
echo.

:: --- IPCONFIG ---
echo  [1] COMANDO: ipconfig /all
echo  DESC: Configuracion IP, DNS y MAC de todos los adaptadores.
echo  ----------------------------------------------------------
ipconfig /all
echo.

:: --- ARP ---
echo  [2] COMANDO: arp -a
echo  DESC: Tabla de resolucion de direcciones fisicas (Capa 2).
echo  ----------------------------------------------------------
arp -a
echo.

:: --- NETSTAT ---
echo  [3] COMANDO: netstat -ano
echo  DESC: Conexiones activas y puertos abiertos vinculados a PID.
echo  ----------------------------------------------------------
netstat -ano
echo.

:: --- TRACERT ---
echo  [4] COMANDO: tracert -d 8.8.8.8
echo  DESC: Traza de saltos hacia DNS de Google (sin resolucion DNS para velocidad).
echo        Identifica en que "hop" se cae la conexion.
echo  ----------------------------------------------------------
tracert -d -h 10 8.8.8.8
echo.

:: --- DNS FLUSH (Solo ROOT) ---
if "%MODE%"=="ROOT (ADMINISTRADOR)" (
    echo  [5] COMANDO: ipconfig /flushdns
    echo  DESC: Limpieza de cache de resolucion DNS.
    echo  ----------------------------------------------------------
    ipconfig /flushdns
    echo  [OK] Cache liberada.
)

echo.
call :waitClose
exit /b

:: ==========================================================
:: PROCEDIMIENTOS (UI)
:: ==========================================================
:waitClose
echo.
echo  ==========================================================
echo    DIAGNOSTICO FINALIZADO 
echo  ==========================================================
echo  Presione una tecla para salir...
pause >nul
exit /b