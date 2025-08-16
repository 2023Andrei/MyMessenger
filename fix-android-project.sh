#!/bin/bash

echo "🔧 Автоматическое исправление проекта Android..."
echo "---------------------------------------------------"

# Проверка, существует ли проект
PROJECT_DIR="/home/and/AndroidStudioProjects/MyMessenger"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Проект не найден в $PROJECT_DIR"
    echo "Пожалуйста, сначала создайте проект с помощью create-android-messenger.sh"
    exit 1
fi

cd "$PROJECT_DIR" || exit
echo "✅ Найден проект: $PROJECT_DIR"

# 1. Добавляем android.useAndroidX в gradle.properties
echo "🔧 Исправление gradle.properties..."
if [ ! -f "gradle.properties" ]; then
    touch gradle.properties
fi

# Удаляем старые настройки, если они есть
sed -i '/android.useAndroidX/d' gradle.properties 2>/dev/null
sed -i '/android.suppressUnsupportedCompileSdk/d' gradle.properties 2>/dev/null

# Добавляем необходимые настройки
echo "android.useAndroidX=true" >> gradle.properties
echo "android.suppressUnsupportedCompileSdk=34" >> gradle.properties
echo "✅ Добавлены настройки AndroidX и подавление предупреждения compileSdk"

# 2. Исправляем AndroidManifest.xml
echo "🔧 Исправление AndroidManifest.xml..."
MANIFEST_FILE="app/src/main/AndroidManifest.xml"

# Удаляем атрибут package из манифеста
if [ -f "$MANIFEST_FILE" ]; then
    sed -i 's/package="com.example.mymessenger"//' "$MANIFEST_FILE"
    sed -i 's/package=com.example.mymessenger //' "$MANIFEST_FILE"
    echo "✅ Удален атрибут package из AndroidManifest.xml"
else
    echo "❌ AndroidManifest.xml не найден!"
    exit 1
fi

# 3. Создаем недостающие ресурсы
echo "🔧 Создание недостающих ресурсов..."

# Создаем каталоги для ресурсов
mkdir -p app/src/main/res/values
mkdir -p app/src/main/res/mipmap-mdpi
mkdir -p app/src/main/res/mipmap-hdpi
mkdir -p app/src/main/res/mipmap-xhdpi
mkdir -p app/src/main/res/mipmap-xxhdpi
mkdir -p app/src/main/res/mipmap-xxxhdpi

# Создаем colors.xml
cat > app/src/main/res/values/colors.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="colorPrimary">#008577</color>
    <color name="colorPrimaryDark">#00574B</color>
    <color name="colorAccent">#D81B60</color>
</resources>
EOF
echo "✅ Создан colors.xml"

# Создаем styles.xml
cat > app/src/main/res/values/styles.xml << 'EOF'
<resources>
    <!-- Base application theme. -->
    <style name="AppTheme" parent="Theme.AppCompat.Light.DarkActionBar">
        <!-- Customize your theme here. -->
        <item name="colorPrimary">@color/colorPrimary</item>
        <item name="colorPrimaryDark">@color/colorPrimaryDark</item>
        <item name="colorAccent">@color/colorAccent</item>
    </style>
</resources>
EOF
echo "✅ Создан styles.xml"

# Создаем простые иконки-заглушки
echo "Placeholder" > app/src/main/res/mipmap-mdpi/ic_launcher.png
echo "Placeholder" > app/src/main/res/mipmap-mdpi/ic_launcher_round.png
cp app/src/main/res/mipmap-mdpi/*.png app/src/main/res/mipmap-hdpi/ 2>/dev/null
cp app/src/main/res/mipmap-mdpi/*.png app/src/main/res/mipmap-xhdpi/ 2>/dev/null
cp app/src/main/res/mipmap-mdpi/*.png app/src/main/res/mipmap-xxhdpi/ 2>/dev/null
cp app/src/main/res/mipmap-mdpi/*.png app/src/main/res/mipmap-xxxhdpi/ 2>/dev/null
echo "✅ Созданы иконки приложения"

# 4. Исправляем build.gradle.kts
echo "🔧 Исправление build.gradle.kts..."

# Исправляем app/build.gradle.kts
BUILD_GRADLE="app/build.gradle.kts"
if [ -f "$BUILD_GRADLE" ]; then
    # Устанавливаем правильные версии плагинов
    sed -i 's/id("com.android.application")/id("com.android.application") version "8.1.0"/' "$BUILD_GRADLE"
    sed -i 's/id("org.jetbrains.kotlin.android")/id("org.jetbrains.kotlin.android") version "1.8.0"/' "$BUILD_GRADLE"
    
    # Добавляем namespace, если его нет
    if ! grep -q "namespace = \"com.example.mymessenger\"" "$BUILD_GRADLE"; then
        sed -i '/android {/a \    namespace = "com.example.mymessenger"' "$BUILD_GRADLE"
    fi
    
    # Понижаем compileSdk до 33
    sed -i 's/compileSdk = 34/compileSdk = 33/' "$BUILD_GRADLE"
    
    echo "✅ Исправлен app/build.gradle.kts"
else
    echo "❌ app/build.gradle.kts не найден!"
    exit 1
fi

# 5. Проверяем settings.gradle.kts
echo "🔧 Проверка settings.gradle.kts..."
SETTINGS_GRADLE="settings.gradle.kts"
if [ -f "$SETTINGS_GRADLE" ]; then
    # Добавляем pluginManagement, если его нет
    if ! grep -q "pluginManagement" "$SETTINGS_GRADLE"; then
        cat > "$SETTINGS_GRADLE" << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "Мой Мессенджер"
include(":app")
EOF
        echo "✅ Пересоздан settings.gradle.kts"
    fi
else
    echo "❌ settings.gradle.kts не найден, создаем новый..."
    cat > "$SETTINGS_GRADLE" << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "Мой Мессенджер"
include(":app")
EOF
fi

# 6. Создаем Gradle Wrapper, если его нет
echo "🔧 Проверка Gradle Wrapper..."
if [ ! -f "gradlew" ]; then
    echo "⚠️ Gradle Wrapper отсутствует, создаем..."
    ./gradle/wrapper/gradle-wrapper.jar --gradle-version 8.4
    echo "✅ Gradle Wrapper создан"
fi

echo -e "\n✅ Все исправления выполнены успешно!"
echo "---------------------------------------------------"
echo "Теперь вы можете собрать проект:"
echo "1. Через терминал: ./gradlew assembleDebug"
echo "2. Или через Android Studio:"
echo "   - Откройте проект в Android Studio"
echo "   - Нажмите 'Sync Now'"
echo "   - Соберите APK: Build → Build Bundle(s) / APK → Build APK"
echo -e "\nГотовый APK будет в: app/build/outputs/apk/debug/app-debug.apk"
