#!/bin/bash
echo "🔥 ФИНАЛЬНОЕ И ТОЧНОЕ РЕШЕНИЕ ПРОБЛЕМЫ С WEBRTC..."

# 1. УДАЛЯЕМ ВСЕ УПОМИНАНИЯ JitPack для WebRTC
echo "🔧 Удаление всех упоминаний JitPack для WebRTC..."
sed -i '/com\.github\.webrtc/d' app/build.gradle.kts
sed -i '/org\.webrtc:webrtc/d' app/build.gradle.kts
sed -i '/google-webrtc/d' app/build.gradle.kts
sed -i '/io\.github\.webrtc/d' app/build.gradle.kts
echo "✅ Все упоминания JitPack для WebRTC удалены"

# 2. УДАЛЯЕМ JitPack из settings.gradle.kts (если он там есть для WebRTC)
echo "🔧 Удаление JitPack из settings.gradle.kts..."
sed -i '/jitpack.io/d' settings.gradle.kts
echo "✅ JitPack удален из settings.gradle.kts"

# 3. ИСПОЛЬЗУЕМ ОФИЦИАЛЬНУЮ ЗАВИСИМОСТЬ WEBRTC ИЗ MAVEN CENTRAL
echo "🔧 Использование официальной зависимости WebRTC из Maven Central..."
if ! grep -q "org.webrtc:google-webrtc" app/build.gradle.kts; then
    sed -i '/implementation("com.google.firebase:firebase-messaging")/a \    implementation("org.webrtc:google-webrtc:1.0.35530")' app/build.gradle.kts
    echo "✅ Добавлена официальная зависимость WebRTC (org.webrtc:google-webrtc:1.0.35530)"
else
    echo "✅ Официальная зависимость WebRTC уже добавлена"
fi

# 4. УВЕЛИЧИВАЕМ ПАМЯТЬ ДЛЯ GRADLE
echo "🔧 Увеличение памяти для Gradle..."
if [ -f "gradle.properties" ]; then
    sed -i '/org.gradle.jvmargs/d' gradle.properties
    echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" >> gradle.properties
else
    echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" > gradle.properties
fi
echo "✅ Память для Gradle увеличена до 4GB"

# 5. ОЧИЩАЕМ КЭШ GRADLE
echo "🔧 Очистка кэша Gradle..."
rm -rf ~/.gradle/caches/modules-2/files-2.1/com.github.webrtc 2>/dev/null || true
rm -rf ~/.gradle/caches/modules-2/files-2.1/org.webrtc 2>/dev/null || true
rm -rf ~/.gradle/caches/journal-1 2>/dev/null || true
rm -rf ~/.gradle/caches/8.4 2>/dev/null || true
echo "✅ Кэш Gradle очищен"

# 6. ПЕРЕСОБИРАЕМ ПРОЕКТ
echo "🔧 Пересборка проекта с официальной зависимостью WebRTC..."
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

# 7. ИНСТРУКЦИЯ ПО ИСПОЛЬЗОВАНИЮ АУДИО ЗВОНКОВ
echo -e "\n📌 Как совершать аудио звонки:"
echo "1. Запустите приложение и войдите в систему"
echo "2. На главном экране нажмите кнопку 'Позвонить'"
echo "3. Дождитесь установки соединения"
echo "4. Для включения/отключения микрофона нажмите серую кнопку"
echo "5. Для завершения звонка нажмите красную кнопку по центру"

# 8. ДОБАВЛЯЕМ ЗАДЕРЖКУ, ЧТОБЫ ТЕРМИНАЛ НЕ ЗАКРЫВАЛСЯ
read -p "Нажмите Enter для завершения..."
