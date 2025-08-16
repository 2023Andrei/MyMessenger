#!/bin/bash

# Улучшенный скрипт для настройки WebRTC в Android проекте

PROJECT_DIR="/home/and/AndroidStudioProjects/MyMessenger"
GRADLE_SETTINGS="$PROJECT_DIR/settings.gradle.kts"
APP_BUILD_GRADLE="$PROJECT_DIR/app/build.gradle.kts"
MANIFEST="$PROJECT_DIR/app/src/main/AndroidManifest.xml"
GRADLE_PROPERTIES="$PROJECT_DIR/gradle.properties"

# Функции для лучшей читаемости
error() {
    echo -e "\033[31m❌ $1\033[0m"
    exit 1
}

success() {
    echo -e "\033[32m✅ $1\033[0m"
}

info() {
    echo -e "\033[34m🔧 $1\033[0m"
}

check_files() {
    [ -d "$PROJECT_DIR" ] || error "Директория проекта не найдена: $PROJECT_DIR"
    [ -f "$GRADLE_SETTINGS" ] || error "Файл настроек не найден: $GRADLE_SETTINGS"
    [ -f "$APP_BUILD_GRADLE" ] || error "Файл сборки приложения не найден: $APP_BUILD_GRADLE"
    [ -f "$MANIFEST" ] || error "Файл манифеста не найден: $MANIFEST"
}

fix_jitpack() {
    info "Исправление JitPack в settings.gradle.kts..."
    
    # Проверяем наличие dependencyResolutionManagement
    if grep -q "dependencyResolutionManagement" "$GRADLE_SETTINGS"; then
        # Обновляем существующую конфигурацию
        if ! grep -q "jitpack.io" "$GRADLE_SETTINGS"; then
            sed -i '/repositories {/a \        maven { url = uri("https://jitpack.io") }' "$GRADLE_SETTINGS" || \
            error "Не удалось добавить JitPack в repositories"
            success "JitPack добавлен в repositories"
        else
            # Чистим URL от возможных проблем
            sed -i 's|https://jitpack.io[^"]*|https://jitpack.io|g' "$GRADLE_SETTINGS" && \
            success "URL JitPack исправлен"
        fi
    else
        # Добавляем полный блок dependencyResolutionManagement
        cat <<EOF >> "$GRADLE_SETTINGS"

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}
EOF
        success "Настроены настройки зависимостей для JitPack"
    fi
}

fix_webrtc_dependency() {
    info "Исправление зависимости WebRTC..."
    
    # Удаляем старые зависимости WebRTC
    sed -i '/org\.webrtc:/d' "$APP_BUILD_GRADLE" 2>/dev/null
    
    # Добавляем правильную зависимость
    if ! grep -q "com.github.webrtc:google-webrtc" "$APP_BUILD_GRADLE"; then
        # Ищем блок dependencies
        if grep -q "dependencies {" "$APP_BUILD_GRADLE"; then
            # Добавляем в существующий блок
            sed -i '/dependencies {/a \    implementation("com.github.webrtc:google-webrtc:1.0.+")' "$APP_BUILD_GRADLE" || \
            error "Не удалось добавить зависимость WebRTC"
        else
            # Создаем новый блок
            sed -i '/android {/a \ndependencies {\n    implementation("com.github.webrtc:google-webrtc:1.0.+")\n}' "$APP_BUILD_GRADLE" || \
            error "Не удалось создать блок dependencies"
        fi
        success "Зависимость WebRTC добавлена (используется последняя версия 1.0.x)"
    else
        success "Зависимость WebRTC уже присутствует"
    fi
}

fix_androidx() {
    info "Проверка настроек AndroidX..."
    
    touch "$GRADLE_PROPERTIES"
    
    if ! grep -q "android.useAndroidX=true" "$GRADLE_PROPERTIES"; then
        echo -e "\nandroid.useAndroidX=true" >> "$GRADLE_PROPERTIES"
        echo "android.enableJetifier=true" >> "$GRADLE_PROPERTIES"
        success "Настройки AndroidX добавлены"
    else
        success "Настройки AndroidX уже присутствуют"
    fi
}

fix_permissions() {
    info "Проверка разрешений в AndroidManifest.xml..."
    
    declare -A permissions=(
        ["INTERNET"]="android.permission.INTERNET"
        ["RECORD_AUDIO"]="android.permission.RECORD_AUDIO"
        ["MODIFY_AUDIO_SETTINGS"]="android.permission.MODIFY_AUDIO_SETTINGS"
        ["CAMERA"]="android.permission.CAMERA"
        ["ACCESS_NETWORK_STATE"]="android.permission.ACCESS_NETWORK_STATE"
        ["BLUETOOTH"]="android.permission.BLUETOOTH"
    )
    
    for perm in "${!permissions[@]}"; do
        if ! grep -q "${permissions[$perm]}" "$MANIFEST"; then
            sed -i "/<manifest/a \    <uses-permission android:name=\"${permissions[$perm]}\" />" "$MANIFEST" || \
            error "Не удалось добавить разрешение ${permissions[$perm]}"
            success "Добавлено разрешение: $perm"
        else
            success "Разрешение $perm уже присутствует"
        fi
    done
}

build_project() {
    info "Пересборка проекта..."
    
    cd "$PROJECT_DIR" || error "Не удалось перейти в директорию проекта"
    
    ./gradlew clean assembleDebug
    if [ $? -eq 0 ]; then
        success "Проект успешно собран!"
        
        info "Установка приложения на устройство..."
        if adb devices | grep -q "device$"; then
            adb install -r app/build/outputs/apk/debug/app-debug.apk && \
            success "Установка завершена!"
        else
            error "Устройство ADB не найдено"
        fi
    else
        error "Ошибка при сборке проекта"
        show_debug_info
    fi
}

show_debug_info() {
    echo -e "\n\033[33mℹ️ Если проблема сохраняется:\033[0m"
    echo "1. Проверьте settings.gradle.kts:"
    echo "   cat $GRADLE_SETTINGS | grep -A10 'repositories'"
    echo "2. Проверьте зависимости:"
    echo "   cat $APP_BUILD_GRADLE | grep -A10 'dependencies'"
    echo "3. Проверьте разрешения:"
    echo "   cat $MANIFEST | grep uses-permission"
    echo "4. Запустите сборку с подробным выводом:"
    echo "   ./gradlew assembleDebug --info --stacktrace"
    echo "5. Проверьте версию Gradle:"
    echo "   ./gradlew --version"
}

show_usage_tips() {
    echo -e "\n\033[36m📌 Как совершать звонки:\033[0m"
    echo "1. Запустите приложение и войдите в систему"
    echo "2. Выберите контакт из списка"
    echo "3. Нажмите кнопку 'Аудио звонок' или 'Видео звонок'"
    echo "4. Дождитесь ответа собеседника"
    echo -e "\n\033[36m🔍 Для отладки:\033[0m"
    echo "Логи WebRTC: adb logcat | grep -E 'PeerConnection|WebRTC'"
}

main() {
    check_files
    fix_jitpack
    fix_webrtc_dependency
    fix_androidx
    fix_permissions
    build_project
    show_usage_tips
}

main
