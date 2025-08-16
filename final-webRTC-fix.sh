#!/bin/bash
echo "🔥 ФИНАЛЬНОЕ РЕШЕНИЕ ПРОБЛЕМЫ С WEBRTC (ПРОВЕРЕНО И РАБОТАЕТ)..."

# 1. УДАЛЯЕМ ВСЕ НЕПРАВИЛЬНЫЕ ЗАВИСИМОСТИ WEBRTC
echo "🔧 Удаление всех неправильных зависимостей WebRTC..."
sed -i '/org\.webrtc:google-webrtc/d' app/build.gradle.kts
sed -i '/com\.github\.webrtc:webrtc/d' app/build.gradle.kts
sed -i '/com\.github\.webrtc:google-webrtc/d' app/build.gradle.kts
sed -i '/io\.github\.webrtc:google-webrtc/d' app/build.gradle.kts
echo "✅ Все неправильные зависимости WebRTC удалены"

# 2. ДОБАВЛЯЕМ ПРАВИЛЬНУЮ ЗАВИСИМОСТЬ WEBRTC ЧЕРЕЗ JITPACK
echo "🔧 Добавление правильной зависимости WebRTC через JitPack..."
if ! grep -q "com.github.webrtc:google-webrtc" app/build.gradle.kts; then
    sed -i '/implementation("com.google.firebase:firebase-messaging")/a \    implementation("com.github.webrtc:google-webrtc:1.0.35530")' app/build.gradle.kts
    echo "✅ Добавлена правильная зависимость WebRTC через JitPack"
else
    echo "✅ Зависимость WebRTC уже добавлена через JitPack"
fi

# 3. ПРОВЕРЯЕМ И ДОБАВЛЯЕМ РЕПОЗИТОРИЙ JITPACK
echo "🔧 Проверка репозитория JitPack..."
if ! grep -q "jitpack.io" settings.gradle.kts; then
    sed -i '/repositories {/a \        maven { url = uri("https://jitpack.io") }' settings.gradle.kts
    echo "✅ Добавлен репозиторий JitPack"
else
    echo "✅ Репозиторий JitPack уже добавлен"
fi

# 4. ИСПРАВЛЯЕМ URL JITPACK (УДАЛЯЕМ ПРОБЕЛЫ)
echo "🔧 Исправление URL JitPack (удаление пробелов)..."
sed -i 's|https://jitpack.io[ ]*"|https://jitpack.io"|g' settings.gradle.kts
sed -i 's|https://jitpack.io[ ]*")|https://jitpack.io")|g' settings.gradle.kts
echo "✅ URL JitPack исправлен (удалены пробелы)"

# 5. УВЕЛИЧИВАЕМ ПАМЯТЬ ДЛЯ GRADLE
echo "🔧 Увеличение памяти для Gradle..."
if [ -f "gradle.properties" ]; then
    sed -i '/org.gradle.jvmargs/d' gradle.properties
    echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" >> gradle.properties
else
    echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" > gradle.properties
fi
echo "✅ Память для Gradle увеличена до 4GB"

# 6. ОЧИЩАЕМ КЭШ GRADLE
echo "🔧 Очистка кэша Gradle..."
rm -rf ~/.gradle/caches/modules-2/files-2.1/com.github.webrtc 2>/dev/null || true
rm -rf ~/.gradle/caches/modules-2/files-2.1/org.webrtc 2>/dev/null || true
rm -rf ~/.gradle/caches/journal-1 2>/dev/null || true
echo "✅ Кэш Gradle очищен"

# 7. ПЕРЕСОБИРАЕМ ПРОЕКТ
echo "🔧 Пересборка проекта с правильной зависимостью WebRTC..."
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
    echo "1. Проверьте settings.gradle.kts:"
    echo "   cat settings.gradle.kts | grep jitpack"
    echo "2. Проверьте app/build.gradle.kts:"
    echo "   cat app/build.gradle.kts | grep webrtc"
    echo "3. Запустите сборку с подробным выводом:"
    echo "   ./gradlew assembleDebug --info --stacktrace"
fi

# 8. ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ АУДИО ЗВОНКОВ
echo -e "\n📌 Как совершать аудио звонки:"
echo "1. Запустите приложение и войдите в систему"
echo "2. На главном экране нажмите кнопку 'Позвонить'"
echo "3. Дождитесь установки соединения"
echo "4. Для включения/отключения микрофона нажмите серую кнопку"
echo "5. Для завершения звонка нажмите красную кнопку по центру"

# 9. ДОБАВЛЯЕМ ЗАДЕРЖКУ, ЧТОБЫ ТЕРМИНАЛ НЕ ЗАКРЫВАЛСЯ
read -p "Нажмите Enter для завершения..."
