#!/bin/bash
echo "🔧 Финальное исправление WebRTC для аудио звонков..."

# 1. Проверка и исправление JitPack репозитория в settings.gradle.kts
echo "🔧 Проверка JitPack репозитория в settings.gradle.kts..."
if ! grep -q "maven { url = uri(\"https://jitpack.io\") }" settings.gradle.kts; then
    # Удаляем старую запись с возможным пробелом
    sed -i '/maven { url = uri("https:\/\/jitpack.io") }/d' settings.gradle.kts
    
    # Добавляем правильный JitPack репозиторий БЕЗ ПРОБЕЛА
    sed -i '/dependencyResolutionManagement {/a \    repositories {\n        maven { url = uri("https://jitpack.io") }\n    }' settings.gradle.kts
    echo "✅ Добавлен правильный JitPack репозиторий в settings.gradle.kts"
else
    echo "✅ JitPack репозиторий уже правильно настроен в settings.gradle.kts"
fi

# 2. Исправление зависимости WebRTC
echo "🔧 Исправление зависимости WebRTC..."
# Удаляем ВСЕ старые зависимости WebRTC
sed -i '/com\.github\.\(google\|webrtc\):webrtc/d' app/build.gradle.kts
sed -i '/org\.webrtc:google-webrtc/d' app/build.gradle.kts
sed -i '/org\.webrtc:webrtc/d' app/build.gradle.kts

# Добавляем правильную зависимость WebRTC (БЕЗ ПРОБЕЛА В ВЕРСИИ)
if ! grep -q "com.github.webrtc:webrtc:master-SNAPSHOT" app/build.gradle.kts; then
    # Используем правильный формат БЕЗ ПРОБЕЛА В ВЕРСИИ
    sed -i '/implementation("com.google.firebase:firebase-messaging")/a \    implementation("com.github.webrtc:webrtc:master-SNAPSHOT")' app/build.gradle.kts
    echo "✅ Добавлена правильная зависимость WebRTC (com.github.webrtc:webrtc:master-SNAPSHOT)"
else
    echo "✅ Зависимость WebRTC уже правильно настроена"
fi

# 3. Перезагрузка Gradle кэша (важно!)
echo "🔧 Очистка Gradle кэша..."
rm -rf /home/and/.gradle/caches/modules-2/files-2.1/com.github.webrtc
rm -rf /home/and/.gradle/caches/journal-1
rm -rf /home/and/.gradle/caches/7.4.2

# 4. Пересборка проекта
echo "🔧 Пересборка проекта..."
./gradlew clean assembleDebug

if [ $? -eq 0 ]; then
    echo -e "\n✅ Проект успешно собран!"
    echo "---------------------------------------------------"
    echo "Готовый APK: app/build/outputs/apk/debug/app-debug.apk"
    
    # Установка на устройство
    echo -e "\n📱 Установка приложения на устройство..."
    adb install -r app/build/outputs/apk/debug/app-debug.apk
    
    echo -e "\n✅ Установка завершена!"
    echo "1. Теперь вы можете совершать аудио звонки"
    echo "2. Нажмите кнопку 'Позвонить' на главном экране"
    echo "3. Для завершения звонка нажмите красную кнопку"
else
    echo -e "\n❌ Ошибка при сборке проекта"
    echo "---------------------------------------------------"
    echo "Если проблема сохраняется:"
    echo "1. Проверьте settings.gradle.kts:"
    echo "   cat settings.gradle.kts | grep 'jitpack'"
    echo "2. Проверьте build.gradle.kts:"
    echo "   cat app/build.gradle.kts | grep 'webrtc'"
    echo "3. Запустите сборку с подробным выводом:"
    echo "   ./gradlew assembleDebug --info"
fi

# 5. Инструкция по использованию аудио звонков
echo -e "\n📌 Как совершать аудио звонки:"
echo "1. Запустите приложение и войдите в систему"
echo "2. На главном экране нажмите кнопку 'Позвонить'"
echo "3. Дождитесь установки соединения"
echo "4. Для включения/отключения микрофона нажмите серую кнопку"
echo "5. Для завершения звонка нажмите красную кнопку по центру"

# 6. Добавляем задержку, чтобы терминал не закрывался
read -p "Нажмите Enter для завершения..."
