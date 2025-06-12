@echo off
setlocal EnableDelayedExpansion

:: ========================================
:: CONFIGURATION
:: ========================================
set "INSTALL_ROOT=C:\Users\Rama"
set "PLANTUML_DIR=%INSTALL_ROOT%\plantuml-server"
set "JAVA_HOME=C:\Program Files\Java\jdk-24"
set "MAVEN_HOME=C:\Program Files\Apache\maven"
set "SERVICE_NAME=PlantUMLServer"
set "PORT=91"
set "LOG_FILE=%PLANTUML_DIR%\installation.log"
set "BACKUP_DIR=%PLANTUML_DIR%\backups"

:: ========================================
:: INITIALIZATION
:: ========================================
title PlantUML Server Installer v3.0
mode con cols=100 lines=50
color 0A

:: ========================================
:: DEPENDENCY CHECK
:: ========================================
echo Checking system dependencies...
echo --------------------------------

where java >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Java JDK not found!
    echo Download from: https://www.oracle.com/java/technologies/downloads/
    exit /b 1
)

where mvn >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Maven not found!
    echo Download from: https://maven.apache.org/download.cgi
    exit /b 1
)

where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Git not found!
    echo Download from: https://git-scm.com/downloads
    exit /b 1
)

echo ✅ All dependencies verified

:: ========================================
:: INSTALLATION SETUP
:: ========================================
if exist "%PLANTUML_DIR%" (
    echo Existing installation detected at %PLANTUML_DIR%
    set /p choice=Backup existing installation? (Y/N): 
    if /i "!choice!"=="Y" (
        if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
        set "timestamp=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%"
        xcopy "%PLANTUML_DIR%" "%BACKUP_DIR%\%timestamp%" /E /H /C /I /Y >nul
        echo ✅ Backup created: %BACKUP_DIR%\%timestamp%
    )
    rmdir /s /q "%PLANTUML_DIR%" 2>nul
)

:: ========================================
:: REPOSITORY SETUP
:: ========================================
echo Cloning PlantUML repository...
git clone https://github.com/Aditya469/plantuml-server.git "%PLANTUML_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Repository clone failed
    exit /b 1
)

:: ========================================
:: BUILD PROCESS
:: ========================================
echo Building PlantUML server...
cd /d "%PLANTUML_DIR%"
mvn clean install >> "%LOG_FILE%" 2>&1
if %errorlevel% neq 0 (
    echo ❌ Build failed. Check %LOG_FILE%
    exit /b 1
)

:: ========================================
:: SERVICE CONFIGURATION
:: ========================================
echo Configuring Windows service...
set "DAEMON_DIR=%PLANTUM_DIR%\service"
mkdir "%DAEMON_DIR%" 2>nul

:: Download Commons Daemon Windows binaries
curl -L -o "%DAEMON_DIR%\daemon.zip" https://downloads.apache.org/commons/daemon/binaries/windows/commons-daemon-1.4.1-bin-windows.zip
tar -xf "%DAEMON_DIR%\daemon.zip" -C "%DAEMON_DIR%"

:: Create service installation script
echo @echo off > "%DAEMON_DIR%\install_service.bat"
echo "%DAEMON_DIR%\prunsrv.exe" //IS//%SERVICE_NAME% ^
--DisplayName="PlantUML Server" ^
--Description="PlantUML Diagram Generation Service" ^
--Install="%DAEMON_DIR%\prunsrv.exe" ^
--Jvm="%JAVA_HOME%\bin\server\jvm.dll" ^
--StartMode=jvm ^
--StartClass=org.eclipse.jetty.start.Main ^
--StartParams=--port=%PORT% ^
--Classpath="%PLANTUML_DIR%\target\plantuml-server-*.war" ^
--LogPath="%PLANTUML_DIR%\logs" ^
--StdOutput=auto ^
--StdError=auto >> "%DAEMON_DIR%\install_service.bat"

:: Install service
call "%DAEMON_DIR%\install_service.bat"

:: ========================================
:: FIREWALL CONFIGURATION
:: ========================================
echo Configuring firewall...
netsh advfirewall firewall add rule name="PlantUML Server" dir=in action=allow protocol=TCP localport=%PORT% >> "%LOG_FILE%"

:: ========================================
:: START SERVICE
:: ========================================
echo Starting PlantUML service...
net start %SERVICE_NAME% >> "%LOG_FILE%"
if %errorlevel% neq 0 (
    echo ⚠️ Service start failed. Starting in console mode...
    start "PlantUML Server" cmd /k "mvn jetty:run -Djetty.http.port=%PORT%"
)

:: ========================================
:: VERIFICATION
:: ========================================
echo Verifying installation...
timeout /t 10 /nobreak >nul
curl -I http://localhost:%PORT%/plantuml 2>nul | find "200" >nul
if %errorlevel% equ 0 (
    echo ✅ Installation successful!
    echo Access at: http://localhost:%PORT%/plantuml
) else (
    echo ❌ Verification failed. Check %LOG_FILE%
)

:: ========================================
:: SHORTCUT CREATION
:: ========================================
echo Creating desktop shortcuts...
echo [InternetShortcut] > "%USERPROFILE%\Desktop\PlantUML Server.url"
echo URL=http://localhost:%PORT%/plantuml >> "%USERPROFILE%\Desktop\PlantUML Server.url"
echo IconFile=%SystemRoot%\system32\SHELL32.dll,13 >> "%USERPROFILE%\Desktop\PlantUML Server.url"

echo @echo off > "%USERPROFILE%\Desktop\PlantUML Control Panel.lnk"
echo echo Stopping service... >> "%USERPROFILE%\Desktop\PlantUML Control Panel.lnk"
echo net stop %SERVICE_NAME% >> "%USERPROFILE%\Desktop\PlantUML Control Panel.lnk"
echo echo Starting service... >> "%USERPROFILE%\Desktop\PlantUML Control Panel.lnk"
echo net start %SERVICE_NAME% >> "%USERPROFILE%\Desktop\PlantUML Control Panel.lnk"
echo pause >> "%USERPROFILE%\Desktop\PlantUML Control Panel.lnk"

:: ========================================
:: CLEANUP
:: ========================================
del /q "%DAEMON_DIR%\daemon.zip" >nul 2>&1

echo Installation complete! Press any key to exit...
pause >nul
