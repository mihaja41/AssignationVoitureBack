@echo off
REM ============================
REM Script de deploiement Project1
REM ============================

REM === Activation delayed expansion (OBLIGATOIRE AVANT LES LOOPS) ===
setlocal EnableDelayedExpansion

REM === Variables communes ===
set TOMCAT_WEBAPPS=F:\tomcat10\webapps

REM === Variables Project1 ===
set PROJECT_DIR=Project1
set APP_NAME=project1
set PROJECT_SRC=%PROJECT_DIR%\src\main\java
set PROJECT_WEB=%PROJECT_DIR%\src\main\webapp
set PROJECT_BUILD=%PROJECT_DIR%\build
set PROJECT_LIB=%PROJECT_DIR%\lib

echo =========================================
echo Deploiement de %APP_NAME%
echo =========================================
echo.

REM === Verification du framework ===
if not exist "%PROJECT_LIB%\fw.jar" (
    echo ERREUR : Le fichier %PROJECT_LIB%\fw.jar n'existe pas !
    echo Veuillez placer fw.jar dans %PROJECT_LIB%
    exit /b 1
)

echo Framework trouve : %PROJECT_LIB%\fw.jar
echo.

REM === Construction du CLASSPATH ===
set CLASSPATH=.

for %%f in ("%PROJECT_LIB%\*.jar") do (
    set CLASSPATH=!CLASSPATH!;%%f
)

echo CLASSPATH = !CLASSPATH!
echo.

REM === Etape 1 : Compilation ===
if exist "%PROJECT_BUILD%" (
    rmdir /s /q "%PROJECT_BUILD%"
)

mkdir "%PROJECT_BUILD%\WEB-INF\classes"

if not exist "%PROJECT_SRC%" (
    echo ERREUR : Le dossier %PROJECT_SRC% n'existe pas !
    exit /b 1
)

dir /s /b "%PROJECT_SRC%\*.java" > sources.txt

if not exist sources.txt (
    echo Aucun fichier Java trouve
) else (
    javac -parameters -cp "!CLASSPATH!" -d "%PROJECT_BUILD%\WEB-INF\classes" @sources.txt
    if errorlevel 1 (
        echo ERREUR de compilation
        del sources.txt
        exit /b 1
    )
    echo Application compilee avec succes
)

del sources.txt
echo.

REM === Copie des ressources web ===
if not exist "%PROJECT_WEB%" (
    echo ERREUR : Le dossier %PROJECT_WEB% n'existe pas !
    exit /b 1
)

xcopy "%PROJECT_WEB%\*" "%PROJECT_BUILD%\" /E /I /Y >nul
echo Ressources web copiees
echo.

REM === Copie des librairies ===
mkdir "%PROJECT_BUILD%\WEB-INF\lib"
copy "%PROJECT_LIB%\*.jar" "%PROJECT_BUILD%\WEB-INF\lib\" >nul
echo Librairies copiees
echo.

REM === Generation du WAR ===
echo Generation du WAR...
cd /d "%PROJECT_BUILD%"
jar -cf "%APP_NAME%.war" .
cd /d "%~dp0"

echo WAR genere : %APP_NAME%.war
echo.

REM === Deploiement Tomcat ===
if exist "%TOMCAT_WEBAPPS%\%APP_NAME%" (
    rmdir /s /q "%TOMCAT_WEBAPPS%\%APP_NAME%"
)

if exist "%TOMCAT_WEBAPPS%\%APP_NAME%.war" (
    del "%TOMCAT_WEBAPPS%\%APP_NAME%.war"
)

copy /Y "%PROJECT_BUILD%\%APP_NAME%.war" "%TOMCAT_WEBAPPS%\" >nul
echo WAR deploye dans Tomcat
echo.

REM === Creation du dossier uploads ===
set UPLOAD_DIR=%TOMCAT_WEBAPPS%\%APP_NAME% 
mkdir "%UPLOAD_DIR%" >nul 2>&1
echo Dossier uploads cree : %UPLOAD_DIR%
echo.

echo =========================================
echo Deploiement termine avec succes !
echo =========================================
echo URL : http://localhost:8080/%APP_NAME%/
echo.

pause
