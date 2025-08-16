#!/bin/bash
echo "🔥 ФИНАЛЬНОЕ РЕШЕНИЕ ПРОБЛЕМЫ С WEBRTC (ПРАВИЛЬНЫЙ СПОСОБ)..."

# 1. СОЗДАЕМ ПАПКУ LIBS, ЕСЛИ ЕЕ НЕТ
echo "🔧 Создание папки libs..."
mkdir -p app/libs
echo "✅ Папка libs создана"

# 2. СКАЧИВАЕМ WEBRTC AAR ФАЙЛ
echo "🔧 Скачивание WebRTC AAR файла..."
if [ ! -f "app/libs/webrtc.aar" ]; then
    # Скачиваем WebRTC AAR напрямую из репозитория WebRTC
    curl -L -o app/libs/webrtc.aar "https://github.com/webrtc-sdk/webrtc-android/releases/download/1.0.35530/google-webrtc-1.0.35530.aar"
    
    if [ $? -ne 0 ]; then
        echo "❌ Не удалось скачать WebRTC AAR через GitHub. Попробуем альтернативный источник..."
        # Альтернативный источник
        curl -L -o app/libs/webrtc.aar "https://jitpack.io/com/github/webrtc/google-webrtc/1.0.35530/google-webrtc-1.0.35530.aar"
    fi
    
    if [ $? -ne 0 ]; then
        echo "❌ Не удалось скачать WebRTC AAR. Проверьте подключение к интернету."
        exit 1
    fi
    echo "✅ WebRTC AAR файл успешно скачан"
else
    echo "✅ WebRTC AAR файл уже существует"
fi

# 3. ПРОВЕРЯЕМ РАЗМЕР ФАЙЛА (ДОЛЖЕН БЫТЬ БОЛЬШЕ 50MB)
FILE_SIZE=$(stat -c%s "app/libs/webrtc.aar" 2>/dev/null || stat -f%z "app/libs/webrtc.aar" 2>/dev/null)
if [ "$FILE_SIZE" -lt 50000000 ]; then
    echo "❌ Файл WebRTC AAR слишком маленький. Возможно, скачан не полностью."
    echo "Попробуем перезагрузить файл..."
    rm -f app/libs/webrtc.aar
    curl -L -o app/libs/webrtc.aar "https://github.com/webrtc-sdk/webrtc-android/releases/download/1.0.35530/google-webrtc-1.0.35530.aar"
    if [ $? -ne 0 ]; then
        echo "❌ Не удалось перезагрузить WebRTC AAR."
        exit 1
    fi
    echo "✅ WebRTC AAR файл успешно перезагружен"
fi
echo "✅ Проверка размера WebRTC AAR завершена (размер: ${FILE_SIZE} байт)"

# 4. УДАЛЯЕМ ВСЕ УПОМИНАНИЯ JitPack ДЛЯ WEBRTC
echo "🔧 Удаление всех упоминаний JitPack для WebRTC..."
sed -i '/com\.github\.webrtc/d' app/build.gradle.kts
sed -i '/org\.webrtc:webrtc/d' app/build.gradle.kts
sed -i '/google-webrtc/d' app/build.gradle.kts
sed -i '/io\.github\.webrtc/d' app/build.gradle.kts
sed -i '/jitpack.io/d' settings.gradle.kts
echo "✅ Все упоминания JitPack для WebRTC удалены"

# 5. УБЕЖДАЕМСЯ, ЧТО ЗАВИСИМОСТЬ УКАЗЫВАЕТ НА ЛОКАЛЬНЫЙ ФАЙЛ
echo "🔧 Проверка зависимости WebRTC..."
if ! grep -q "implementation(files(\"libs/webrtc.aar\"))" app/build.gradle.kts; then
    # Удаляем все предыдущие упоминания WebRTC
    sed -i '/implementation.*webrtc/d' app/build.gradle.kts
    
    # Добавляем правильную зависимость
    echo "    implementation(files(\"libs/webrtc.aar\"))" >> app/build.gradle.kts
    echo "✅ Добавлена зависимость на локальный файл WebRTC AAR"
else
    echo "✅ Зависимость на локальный файл WebRTC AAR уже добавлена"
fi

# 6. УВЕЛИЧИВАЕМ ПАМЯТЬ ДЛЯ GRADLE
echo "🔧 Увеличение памяти для Gradle..."
if [ -f "gradle.properties" ]; then
    sed -i '/org.gradle.jvmargs/d' gradle.properties
    echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" >> gradle.properties
else
    echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" > gradle.properties
fi
echo "✅ Память для Gradle увеличена до 4GB"

# 7. ОЧИЩАЕМ КЭШ GRADLE
echo "🔧 Очистка кэша Gradle..."
rm -rf ~/.gradle/caches/modules-2/files-2.1/com.github.webrtc 2>/dev/null || true
rm -rf ~/.gradle/caches/modules-2/files-2.1/org.webrtc 2>/dev/null || true
rm -rf ~/.gradle/caches/journal-1 2>/dev/null || true
rm -rf ~/.gradle/caches/8.4 2>/dev/null || true
echo "✅ Кэш Gradle очищен"

# 8. ПЕРЕСОБИРАЕМ ПРОЕКТ
echo "🔧 Пересборка проекта с локальным WebRTC AAR..."
./gradlew clean assembleDebug --stacktrace

if [ $? -eq 0 ]; then
    echo -e "\n✅ Проект успешно собран!"
    echo "---------------------------------------------------"
    echo "Готовый APK: app/build/outputs/apk/debug/app-debug.apk"
    
    # УСТАНОВКА НА УСТРОЙСТВО
    echo -e "\n📱 Установка приложения на устройство..."
    adb install -r app/build/outputs/apk/debug/app-debug.apk
    
    echo -e "\n✅ Установка завершена!"
    echo "1. Теперь вы можете совершать аудио звонки"
    echo "2. Нажмите кнопку 'Позвонить' на главном экране"
    echo "3. Для завершения звонка нажмите красную кнопку по центру"
else
    echo -e "\n❌ Ошибка при сборке проекта"
    echo "---------------------------------------------------"
    echo "Если проблема сохраняется:"
    echo "1. Проверьте наличие файла WebRTC AAR:"
    echo "   ls -lh app/libs/webrtc.aar"
    echo "2. Проверьте build.gradle.kts:"
    echo "   cat app/build.gradle.kts | grep webrtc"
    echo "3. Запустите сборку с подробным выводом:"
    echo "   ./gradlew assembleDebug --info --stacktrace"
fi

# 9. ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ АУДИО ЗВОНКОВ
echo -e "\n📌 Как совершать аудио звонки:"
echo "1. Запустите приложение и войдите в систему"
echo "2. На главном экране нажмите кнопку 'Позвонить'"
echo "3. Дождитесь установки соединения"
echo "4. Для включения/отключения микрофона нажмите серую кнопку"
echo "5. Для завершения звонка нажмите красную кнопку по центру"

# 10. ДОБАВЛЯЕМ ЗАДЕРЖКУ, ЧТОБЫ ТЕРМИНАЛ НЕ ЗАКРЫВАЛСЯ
read -p "Нажмите Enter для завершения..."
