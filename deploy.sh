#!/bin/bash
# ============================
# Script de déploiement Project1
# ============================

# === Variables communes ===
TOMCAT_WEBAPPS="/home/anita/apache-tomcat-10.1.28/webapps"

# === Variables Project1 (application) ===
PROJECT_DIR="Project1"
APP_NAME="project1"
PROJECT_SRC="$PROJECT_DIR/src/main/java"
PROJECT_WEB="$PROJECT_DIR/src/main/webapp"
PROJECT_BUILD="$PROJECT_DIR/build"
PROJECT_LIB="$PROJECT_DIR/lib"

# === Vérification de l'existence du framework ===
if [ ! -f "$PROJECT_LIB/fw.jar" ]; then
    echo "❌ ERREUR : Le fichier $PROJECT_LIB/fw.jar n'existe pas !"
    echo "Veuillez placer fw.jar dans $PROJECT_LIB/"
    exit 1
fi

echo "=== Étape 1 : Vérification du Framework ==="
echo "✓ Framework trouvé : $PROJECT_LIB/fw.jar"

# Construire le classpath pour Project1 (tous les jars dans lib)
CLASSPATH=$(echo $PROJECT_LIB/*.jar | tr ' ' ':')

echo "=== Étape 2 : Compilation du projet Project1 ==="
rm -rf "$PROJECT_BUILD"
mkdir -p "$PROJECT_BUILD/WEB-INF/classes"

if [ -d "$PROJECT_SRC" ]; then
    find "$PROJECT_SRC" -name "*.java" > sources.txt
    if [ -s sources.txt ]; then
        javac -parameters -cp "$CLASSPATH" -d "$PROJECT_BUILD/WEB-INF/classes" @sources.txt
        if [ $? -ne 0 ]; then
            echo "❌ Erreur de compilation de l'application Project1"
            rm sources.txt
            exit 1
        fi
        echo "✓ Application Project1 compilée"
    else
        echo "ℹ Aucun fichier Java à compiler dans Project1"
    fi
    rm sources.txt
else
    echo "❌ ERREUR : Le dossier $PROJECT_SRC n'existe pas !"
    exit 1
fi

# Copie des ressources web
if [ -d "$PROJECT_WEB" ]; then
    cp -r "$PROJECT_WEB"/* "$PROJECT_BUILD/"
    echo "✓ Ressources web copiées"
else
    echo "❌ ERREUR : Le dossier $PROJECT_WEB n'existe pas !"
    exit 1
fi

# Copie des librairies
mkdir -p "$PROJECT_BUILD/WEB-INF/lib"
cp "$PROJECT_LIB"/*.jar "$PROJECT_BUILD/WEB-INF/lib/"
echo "✓ Librairies copiées"

echo "=== Étape 3 : Génération du WAR et déploiement ==="
cd "$PROJECT_BUILD" || exit
jar -cvf "$APP_NAME.war" *
cd ../..

cp -f "$PROJECT_BUILD/$APP_NAME.war" "$TOMCAT_WEBAPPS/"
echo "✓ WAR déployé"

# === Création automatique du dossier uploads ===
echo "=== Étape 4 : Création du dossier uploads ==="
UPLOAD_DIR="$TOMCAT_WEBAPPS/$APP_NAME/uploads"
mkdir -p "$UPLOAD_DIR"
echo "✓ Dossier uploads créé : $UPLOAD_DIR"

echo ""
echo "========================================="
echo "✓ Déploiement terminé avec succès !"
echo "========================================="
echo "WAR déployé : $TOMCAT_WEBAPPS/$APP_NAME.war"
echo "Accédez à : http://localhost:8080/$APP_NAME/"
echo ""