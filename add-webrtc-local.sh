#!/bin/bash
echo "🔧 Добавление WebRTC через локальный AAR файл..."

# 1. Создаем каталог libs в проекте
echo "🔧 Создание каталога libs..."
mkdir -p app/libs

# 2. Скачиваем WebRTC AAR из надежного источника
echo "🔧 Скачивание WebRTC AAR..."
cd app/libs

# Попробуем скачать из нескольких источников
if ! wget -q https://github.com/webrtc-sdk/webrtc/releases/download/1.0.35530/libwebrtc-release.aar -O libwebrtc-release.aar; then
    if ! wget -q https://github.com/webrtc/webrtc/releases/download/1.0.35530/libwebrtc-release.aar -O libwebrtc-release.aar; then
        echo "❌ Не удалось скачать WebRTC AAR автоматически"
        echo "Скачайте файл вручную:"
        echo "1. Откройте в браузере: https://github.com/webrtc/webrtc/releases"
        echo "2. Найдите версию 1.0.35530"
        echo "3. Скачайте libwebrtc-release.aar"
        echo "4. Поместите в папку app/libs проекта"
        exit 1
    fi
fi
echo "✅ WebRTC AAR успешно скачан"

# 3. Проверяем, скачался ли файл
if [ ! -f "libwebrtc-release.aar" ] || [ ! -s "libwebrtc-release.aar" ]; then
    echo "❌ Файл libwebrtc-release.aar не скачан или пустой"
    exit 1
fi

# 4. Добавляем локальную зависимость
echo "🔧 Добавление локальной зависимости..."
cd ../../

# Удаляем старые зависимости WebRTC
sed -i '/google-webrtc/d' app/build.gradle.kts
sed -i '/webrtc/d' app/build.gradle.kts

# Добавляем правильную локальную зависимость
if ! grep -q "implementation(files(\"libs/libwebrtc-release.aar\"))" app/build.gradle.kts; then
    sed -i '/implementation("androidx.constraintlayout:constraintlayout:2.1.4")/a \    implementation(files("libs/libwebrtc-release.aar"))' app/build.gradle.kts
    echo "✅ Локальная зависимость добавлена"
else
    echo "ℹ️ Локальная зависимость уже добавлена"
fi

# 5. Собираем проект
echo "🔧 Сборка проекта с поддержкой звонков..."
if [ -f "./gradlew" ]; then
    ./gradlew clean assembleDebug
elif [ -f "gradlew" ]; then
    ./gradlew clean assembleDebug
else
    echo "❌ Не найден файл gradlew. Проверьте, что вы находитесь в корне проекта."
    exit 1
fi

if [ $? -eq 0 ]; then
    echo -e "\n✅ Звонки успешно добавлены!"
    echo "---------------------------------------------------"
    echo "Готовый APK: app/build/outputs/apk/debug/app-debug.apk"
    echo "1. Установите новый APK на телефон"
    echo "2. Откройте приложение и нажмите 'Позвонить'"
    echo "3. Для полноценной работы звонков:"
    echo "   - Настройте Firebase для чата"
    echo "   - Разверните сигнальный сервер (можно бесплатно на Render.com)"
else
    echo -e "\n❌ Ошибка при сборке проекта"
    echo "---------------------------------------------------"
    echo "Если проблема сохраняется:"
    echo "1. Проверьте, что файл libwebrtc-release.aar существует:"
    echo "   ls app/libs/libwebrtc-release.aar"
    echo "2. Убедитесь, что в build.gradle.kts правильно добавлена зависимость:"
    echo "   grep 'libs/libwebrtc-release.aar' app/build.gradle.kts"
    echo "3. Запустите сборку с подробным выводом:"
    echo "   ./gradlew assembleDebug --info"
fi
