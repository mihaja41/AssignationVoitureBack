#!/bin/bash
# ============================
# Script de déploiement Project1
# ============================

set -e  # Stoppe le script à la moindre erreur

# === Variables communes ===
TOMCAT_WEBAPPS="/home/etu003240/Documents/apache-tomcat-10.1.52/webapps"
# === Variables Project1 ===
PROJECT_DIR="Project1"
APP_NAME="project1"
PROJECT_SRC="$PROJECT_DIR/src/main/java"
PROJECT_WEB="$PROJECT_DIR/src/main/webapp"
PROJECT_BUILD="$PROJECT_DIR/build"
PROJECT_LIB="$PROJECT_DIR/lib"

echo "========================================="
echo "Déploiement de $APP_NAME"
echo "========================================="

# === Vérification du framework ===
if [ ! -f "$PROJECT_LIB/fw.jar" ]; then
    echo "❌ ERREUR : fw.jar introuvable dans $PROJECT_LIB"
    exit 1
fi

echo "✓ Framework détecté : fw.jar"

# === Construction du CLASSPATH ===
CLASSPATH="."
for jar in "$PROJECT_LIB"/*.jar; do
    CLASSPATH="$CLASSPATH:$jar"
done

echo "CLASSPATH = $CLASSPATH"

# === Compilation ===
echo "=== Étape 1 : Compilation ==="

rm -rf "$PROJECT_BUILD"
mkdir -p "$PROJECT_BUILD/WEB-INF/classes"

if [ ! -d "$PROJECT_SRC" ]; then
    echo "❌ ERREUR : $PROJECT_SRC n'existe pas"
    exit 1
fi

find "$PROJECT_SRC" -name "*.java" > sources.txt

if [ ! -s sources.txt ]; then
    echo "⚠ Aucun fichier Java trouvé"
else
    javac \
        -parameters \
        -classpath "$CLASSPATH" \
        -d "$PROJECT_BUILD/WEB-INF/classes" \
        @sources.txt
    echo "✓ Compilation réussie"
fi

rm -f sources.txt

# === Copie des ressources web ===
echo "=== Étape 2 : Copie des ressources web ==="

if [ ! -d "$PROJECT_WEB" ]; then
    echo "❌ ERREUR : $PROJECT_WEB n'existe pas"
    exit 1
fi

cp -r "$PROJECT_WEB"/* "$PROJECT_BUILD/"
echo "✓ Ressources web copiées"

# === Copie des librairies ===
echo "=== Étape 3 : Copie des librairies ==="

mkdir -p "$PROJECT_BUILD/WEB-INF/lib"
cp "$PROJECT_LIB"/*.jar "$PROJECT_BUILD/WEB-INF/lib/"
echo "✓ Librairies copiées"

# === Génération du WAR ===
echo "=== Étape 4 : Génération du WAR ==="

cd "$PROJECT_BUILD"
jar -cf "$APP_NAME.war" .
cd - > /dev/null

echo "✓ WAR généré : $APP_NAME.war"

# === Déploiement Tomcat ===
echo "=== Étape 5 : Déploiement Tomcat ==="

rm -rf "$TOMCAT_WEBAPPS/$APP_NAME"
rm -f "$TOMCAT_WEBAPPS/$APP_NAME.war"

cp "$PROJECT_BUILD/$APP_NAME.war" "$TOMCAT_WEBAPPS/"
echo "✓ WAR copié dans Tomcat"

# === Attendre que Tomcat extraie le WAR ===
echo "Attente de l'extraction du WAR par Tomcat..."
WAIT_COUNT=0
while [ ! -d "$TOMCAT_WEBAPPS/$APP_NAME/WEB-INF" ] && [ $WAIT_COUNT -lt 30 ]; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ -d "$TOMCAT_WEBAPPS/$APP_NAME/WEB-INF" ]; then
    echo "✓ WAR extrait par Tomcat"
else
    echo "⚠ Timeout : le WAR n'a pas été extrait après 30s"
fi

# === Création dossier uploads ===
UPLOAD_DIR="$TOMCAT_WEBAPPS/$APP_NAME/uploads"
mkdir -p "$UPLOAD_DIR"
chmod 777 "$UPLOAD_DIR"

echo "✓ Dossier uploads prêt : $UPLOAD_DIR"

echo ""
echo "========================================="
echo "🎉 Déploiement terminé avec succès !"
echo "========================================="
echo "URL : http://localhost:8080/$APP_NAME/"
echo ""
