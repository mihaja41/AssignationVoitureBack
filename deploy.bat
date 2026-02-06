@echo off
setlocal enabledelayedexpansion

REM ============================
REM Script de deploiement Project1
REM ============================

REM === Variables communes ===
set TOMCAT_WEBAPPS=F:\tomcat10\webapps

REM === Variables Project1 ===
set PROJECT_DIR=Project1
set APP_NAME=project1
set PROJECT_SRC=%PROJECT_DIR%\src\main\java
set PROJECT_WEB=%PROJECT_DIR%\src\main\webapp
set PROJECT_BUILD=%PROJECT_DIR%\build
set PROJECT_LIB=%PROJECT_DIR%\lib

echo.

REM === Verification du framework ===
if not exist "%PROJECT_LIB%\fw.jar" (
    echo ERREUR : fw.jar introuvable dans %PROJECT_LIB%
    exit /b 1
)

echo === Etape 1 : Verification du Framework ===
echo Framework trouve : %PROJECT_LIB%\fw.jar

REM === Construction du CLASSPATH ===
set CLASSPATH=.
for %%f in ("%PROJECT_LIB%\*.jar") do (
    set CLASSPATH=!CLASSPATH!;%%f
)

echo CLASSPATH = !CLASSPATH!

echo === Etape 2 : Compilation du projet Project1 ===

if exist "%PROJECT_BUILD%" rmdir /s /q "%PROJECT_BUILD%"
mkdir "%PROJECT_BUILD%\WEB-INF\classes"

dir /s /b "%PROJECT_SRC%\*.java" > sources.txt

javac -parameters ^
 -cp "!CLASSPATH!" ^
 -d "%PROJECT_BUILD%\WEB-INF\classes" ^
 @sources.txt

if errorlevel 1 (
    echo ❌ ERREUR DE COMPILATION
    del sources.txt
    exit /b 1
)

del sources.txt
echo ✅ Application Project1 compilee

REM === Copie des ressources web ===
xcopy "%PROJECT_WEB%\*" "%PROJECT_BUILD%\" /E /I /Y >nul
echo Ressources web copiees

REM === Copie des librairies ===
mkdir "%PROJECT_BUILD%\WEB-INF\lib"
copy "%PROJECT_LIB%\*.jar" "%PROJECT_BUILD%\WEB-INF\lib\" >nul
echo Librairies copiees

echo === Etape 3 : Generation du WAR et deploiement ===
cd "%PROJECT_BUILD%"
jar -cvf "%APP_NAME%.war" *
cd ..\..

copy /Y "%PROJECT_BUILD%\%APP_NAME%.war" "%TOMCAT_WEBAPPS%\"
echo WAR deploye

echo === Etape 4 : Creation du dossier uploads ===
mkdir "%TOMCAT_WEBAPPS%\%APP_NAME%\uploads"

echo =========================================
echo ✅ Deploiement termine avec succes
echo =========================================
echo http://localhost:8080/%APP_NAME%/
pause
