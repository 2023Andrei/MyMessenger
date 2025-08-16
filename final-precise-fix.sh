#!/bin/bash
echo "🔥 ТОЧНОЕ РЕШЕНИЕ ПРОБЛЕМЫ С WEBRTC (БЕЗ ОШИБКИ 401)..."

# 1. УДАЛЯЕМ ВСЕ УПОМИНАНИЯ WEBRTC
echo "🔧 Удаление всех упоминаний WebRTC..."
sed -i '/webrtc/d' app/build.gradle.kts
echo "✅ Все упоминания WebRTC удалены из build.gradle.kts"

# 2. УДАЛЯЕМ JitPack ИЗ settings.gradle.kts
echo "🔧 Удаление JitPack из settings.gradle.kts..."
sed -i '/jitpack.io/d' settings.gradle.kts
echo "✅ JitPack удален из settings.gradle.kts"

# 3. ДОБАВЛЯЕМ ПРАВИЛЬНЫЙ РЕПОЗИТОРИЙ JITPACK БЕЗ ПРОБЕЛОВ
echo "🔧 Добавление правильного репозитория JitPack..."
if ! grep -q "maven { url = uri(\"https://jitpack.io\") }" settings.gradle.kts; then
    # Добавляем репозиторий в правильном формате
    if grep -q "repositories {" settings.gradle.kts; then
        sed -i '/repositories {/a \        maven { url = uri("https://jitpack.io") }' settings.gradle.kts
    else
        echo "dependencyResolutionManagement {" >> settings.gradle.kts
        echo "    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)" >> settings.gradle.kts
        echo "    repositories {" >> settings.gradle.kts
        echo "        google()" >> settings.gradle.kts
        echo "        mavenCentral()" >> settings.gradle.kts
        echo "        maven { url = uri(\"https://jitpack.io\") }" >> settings.gradle.kts
        echo "    }" >> settings.gradle.kts
        echo "}" >> settings.gradle.kts
    fi
    echo "✅ Правильный репозиторий JitPack добавлен"
else
    echo "✅ Репозиторий JitPack уже добавлен"
fi

# 4. ДОБАВЛЯЕМ ПРАВИЛЬНУЮ ЗАВИСИМОСТЬ WEBRTC
echo "🔧 Добавление правильной зависимости WebRTC..."
if ! grep -q "com.github.webrtc:google-webrtc:1.0.35530" app/build.gradle.kts; then
    # Добавляем зависимость после firebase-messaging
    sed -i '/implementation("com.google.firebase:firebase-messaging")/a \    implementation("com.github.webrtc:google-webrtc:1.0.35530")' app/build.gradle.kts
    echo "✅ Добавлена правильная зависимость WebRTC"
else
    echo "✅ Зависимость WebRTC уже добавлена"
fi

# 5. ИСПРАВЛЯЕМ ВСЕ ПРОБЕЛЫ В URL JitPack
echo "🔧 Исправление всех пробелов в URL JitPack..."
# Удаляем все строки с пробелами в URL Jitpack
sed -i 's|https://jitpack.io[ ]*\"|https://jitpack.io"|g' settings.gradle.kts
sed -i 's|https://jitpack.io[ ]*")|https://jitpack.io")|g' settings.gradle.kts
sed -i 's|https://jitpack.io[ ]*"|https://jitpack.io"|g' settings.gradle.kts
sed -i 's|https://jitpack.io[ ]*\\\"|https://jitpack.io"|g' settings.gradle.kts
echo "✅ Все пробелы в URL JitPack удалены"

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
echo "🔧 Пересборка проекта с исправленной зависимостью WebRTC..."
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

# 9. ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ АУДИО ЗВОНКОВ
echo -e "\n📌 Как совершать аудио звонки:"
echo "1. Запустите приложение и войдите в систему"
echo "2. На главном экране нажмите кнопку 'Позвонить'"
echo "3. Дождитесь установки соединения"
echo "4. Для включения/отключения микрофона нажмите серую кнопку"
echo "5. Для завершения звонка нажмите красную кнопку по центру"

# 10. ДОБАВЛЯЕМ ЗАДЕРЖКУ, ЧТОБЫ ТЕРМИНАЛ НЕ ЗАКРЫВАЛСЯ
read -p "Нажмите Enter для завершения..."
