#!/bin/bash
echo "🔧 Исправление ошибок сборки WebRTC (точное решение)..."

# 1. Обновление Gradle Wrapper до версии 8.6
echo "🔧 Обновление Gradle Wrapper до версии 8.6..."
if [ -f "gradle/wrapper/gradle-wrapper.properties" ]; then
    sed -i 's|distributionUrl=.*|distributionUrl=https\\://services.gradle.org/distributions/gradle-8.6-all.zip|' gradle/wrapper/gradle-wrapper.properties
    echo "✅ Gradle Wrapper обновлен до версии 8.6"
else
    mkdir -p gradle/wrapper
    echo "distributionBase=GRADLE_USER_HOME" > gradle/wrapper/gradle-wrapper.properties
    echo "distributionPath=wrapper/dists" >> gradle/wrapper/gradle-wrapper.properties
    echo "distributionUrl=https\\://services.gradle.org/distributions/gradle-8.6-all.zip" >> gradle/wrapper/gradle-wrapper.properties
    echo "zipStoreBase=GRADLE_USER_HOME" >> gradle/wrapper/gradle-wrapper.properties
    echo "zipStorePath=wrapper/dists" >> gradle/wrapper/gradle-wrapper.properties
    echo "✅ Создан Gradle Wrapper версии 8.6"
fi

# 2. Включение AndroidX в gradle.properties (БЕЗ ПЕРЕЗАПИСИ!)
echo "🔧 Включение AndroidX в gradle.properties..."
if [ -f "gradle.properties" ]; then
    # Удаляем старые настройки AndroidX
    sed -i '/android.useAndroidX/d' gradle.properties
    sed -i '/android.enableJetifier/d' gradle.properties
    
    # Добавляем правильные настройки AndroidX В НАЧАЛО ФАЙЛА
    temp_file=$(mktemp)
    echo "android.useAndroidX=true" > "$temp_file"
    echo "android.enableJetifier=true" >> "$temp_file"
    cat gradle.properties >> "$temp_file"
    mv "$temp_file" gradle.properties
    echo "✅ AndroidX включен в gradle.properties"
else
    echo "android.useAndroidX=true" > gradle.properties
    echo "android.enableJetifier=true" >> gradle.properties
    echo "✅ Создан gradle.properties с настройками AndroidX"
fi

# 3. Добавление памяти для Gradle (БЕЗ ПЕРЕЗАПИСИ!)
echo "🔧 Добавление памяти для Gradle..."
if [ -f "gradle.properties" ]; then
    # Удаляем старые настройки памяти
    sed -i '/org.gradle.jvmargs/d' gradle.properties
    
    # Добавляем настройки памяти В КОНЕЦ ФАЙЛА
    echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" >> gradle.properties
    echo "✅ Настроена память для Gradle"
else
    echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" > gradle.properties
    echo "✅ Создан gradle.properties с настройками памяти"
fi

# 4. Проверка содержимого gradle.properties
echo "🔍 Проверка содержимого gradle.properties..."
cat gradle.properties
echo "✅ Содержимое gradle.properties проверено"

# 5. Исправление settings.gradle.kts - ДОБАВЛЕНИЕ JITPACK
echo "🔧 Исправление settings.gradle.kts (добавление JitPack)..."
cat > settings.gradle.kts << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("com.android.application") version "8.4.0"
        id("org.jetbrains.kotlin.android") version "1.9.0"
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") } // КРИТИЧЕСКИ ВАЖНО ДЛЯ WEBRTC
    }
}
include(":app")
