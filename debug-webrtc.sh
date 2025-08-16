#!/bin/bash
echo "🔧 Запуск диагностики и отладки WebRTC для аудио звонков..."

# 1. Сбор информации о текущей конфигурации
echo "🔍 Сбор информации о текущей конфигурации..."
echo "---------------------------------------------------"
echo "1.1 Проверка settings.gradle.kts:"
cat settings.gradle.kts | grep -A 3 'repositories {'
echo "---------------------------------------------------"
echo "1.2 Проверка build.gradle.kts:"
cat app/build.gradle.kts | grep -A 5 'dependencies {'
echo "---------------------------------------------------"
echo "1.3 Проверка gradle.properties:"
cat gradle.properties
echo "---------------------------------------------------"
echo "1.4 Проверка кэша Gradle для WebRTC:"
ls -la /home/and/.gradle/caches/modules-2/files-2.1/org.webrtc 2>/dev/null || echo "Кэш WebRTC не найден"
echo "---------------------------------------------------"

# 2. Проверка на распространенные ошибки
echo "⚠️ Проверка на распространенные ошибки..."
# Проверка на пробелы в URL
if grep -q 'maven { url = uri("https://jitpack.io ") }' settings.gradle.kts; then
    echo "❌ ОШИБКА: Найден пробел в URL JitPack в settings.gradle.kts"
    echo "   Исправьте строку: maven { url = uri(\"https://jitpack.io \") } -> maven { url = uri(\"https://jitpack.io\") }"
else
    echo "✅ URL JitPack в settings.gradle.kts выглядит корректно"
fi

# Проверка на правильную зависимость WebRTC
if grep -q 'org.webrtc:google-webrtc' app/build.gradle.kts; then
    echo "✅ Найдена официальная зависимость WebRTC: org.webrtc:google-webrtc"
else
    echo "❌ ОШИБКА: Не найдена официальная зависимость WebRTC"
    echo "   Добавьте в build.gradle.kts: implementation(\"org.webrtc:google-webrtc:1.0.+\")"
fi

# Проверка на дублирующиеся зависимости
if grep -c 'webrtc' app/build.gradle.kts | grep -q '2\|3\|4'; then
    echo "❌ ОШИБКА: Найдены дублирующиеся зависимости WebRTC"
    echo "   Удалите дубликаты из build.gradle.kts"
else
    echo "✅ Зависимости WebRTC не дублируются"
fi

# Проверка памяти Gradle
if [ -f "gradle.properties" ] && grep -q 'Xmx' gradle.properties; then
    MEMORY=$(grep 'Xmx' gradle.properties | grep -o '[0-9]\+m')
    if [ "${MEMORY%?}" -lt 2048 ]; then
        echo "⚠️ ПРЕДУПРЕЖДЕНИЕ: Выделено недостаточно памяти для Gradle (${MEMORY})"
        echo "   Рекомендуется: org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m"
    else
        echo "✅ Достаточно памяти выделено для Gradle (${MEMORY})"
    fi
else
    echo "⚠️ ПРЕДУПРЕЖДЕНИЕ: Не настроена память для Gradle"
    echo "   Добавьте в gradle.properties: org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m"
fi
echo "---------------------------------------------------"

# 3. Предложение решения
echo "💡 Предложение решения проблем с WebRTC..."
echo "---------------------------------------------------"
echo "3.1 Рекомендуемые исправления:"
echo "   a) Удалите все упоминания JitPack из settings.gradle.kts, если вы используете официальную зависимость"
echo "   b) Используйте официальную зависимость WebRTC:"
echo "      implementation(\"org.webrtc:google-webrtc:1.0.+\")"
echo "   c) Убедитесь, что в settings.gradle.kts нет пробелов в URL репозиториев"
echo "   d) Добавьте в gradle.properties:"
echo "      org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m"
echo "---------------------------------------------------"

# 4. Автоматическое исправление (опционально)
read -p "Хотите автоматически исправить проблемы? [y/N] " FIX
if [[ "$FIX" =~ ^[Yy]$ ]]; then
    echo "🔧 Выполняю автоматическое исправление..."
    
    # Удаляем пробелы в URL JitPack
    sed -i 's|maven { url = uri("https://jitpack.io ") }|maven { url = uri("https://jitpack.io") }|g' settings.gradle.kts
    sed -i 's|maven { url = uri("https://jitpack.io") }|maven { url = uri("https://jitpack.io") }|g' settings.gradle.kts
    
    # Удаляем все зависимости WebRTC
    sed -i '/com\.infobip:google-webrtc/d' app/build.gradle.kts
    sed -i '/com\.github\.webrtc:webrtc/d' app/build.gradle.kts
    sed -i '/org\.webrtc:webrtc/d' app/build.gradle.kts
    
    # Добавляем официальную зависимость
    if ! grep -q "org.webrtc:google-webrtc" app/build.gradle.kts; then
        sed -i '/implementation("com.google.firebase:firebase-messaging")/a \    implementation("org.webrtc:google-webrtc:1.0.+")' app/build.gradle.kts
        echo "✅ Добавлена официальная зависимость WebRTC"
    fi
    
    # Настройка памяти Gradle
    if [ -f "gradle.properties" ]; then
        sed -i '/org.gradle.jvmargs/d' gradle.properties
        echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" >> gradle.properties
    else
        echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" > gradle.properties
    fi
    echo "✅ Настроена память для Gradle"
    
    # Очистка кэша Gradle
    echo "🔧 Очистка кэша Gradle..."
    rm -rf /home/and/.gradle/caches/modules-2/files-2.1/com.github.webrtc
    rm -rf /home/and/.gradle/caches/modules-2/files-2.1/org.webrtc
    rm -rf /home/and/.gradle/caches/journal-1
    echo "✅ Кэш Gradle очищен"
fi
echo "---------------------------------------------------"

# 5. Пересборка проекта
read -p "Хотите пересобрать проект? [y/N] " BUILD
if [[ "$BUILD" =~ ^[Yy]$ ]]; then
    echo "🔧 Пересборка проекта..."
    ./gradlew clean assembleDebug --stacktrace
    
    if [ $? -eq 0 ]; then
        echo "✅ Сборка прошла успешно!"
        
        # 6. Установка на устройство и отладка через adb
        read -p "Хотите установить приложение на устройство и начать отладку? [y/N] " DEBUG
        if [[ "$DEBUG" =~ ^[Yy]$ ]]; then
            echo "📱 Установка приложения на устройство..."
            adb install -r app/build/outputs/apk/debug/app-debug.apk
            
            if [ $? -eq 0 ]; then
                echo "✅ Приложение установлено успешно!"
                
                # 7. Запуск отладки через adb logcat
                echo "🔍 Запуск отладки через adb logcat (фильтр для WebRTC и вашего приложения)..."
                echo "💡 Совет: Для выхода из режима отладки нажмите Ctrl+C"
                echo "💡 Совет: Для поиска ошибок WebRTC ищите 'WebRTC', 'PeerConnection', 'AudioTrack'"
                
                # Запускаем logcat с фильтром для WebRTC и вашего приложения
                adb logcat -s "WebRTC" "PeerConnection" "AudioTrack" "org.webrtc" "com.example.mymessenger"
                
                # Дополнительные команды для отладки
                echo "---------------------------------------------------"
                echo "📌 Дополнительные команды для отладки:"
                echo "   1. Проверка установленного приложения:"
                echo "      adb shell pm list packages | grep 'com.example.mymessenger'"
                echo "   2. Проверка разрешений приложения:"
                echo "      adb shell dumpsys package com.example.mymessenger | grep permission"
                echo "   3. Проверка активности приложения:"
                echo "      adb shell dumpsys activity activities | grep 'com.example.mymessenger'"
                echo "   4. Проверка ошибок WebRTC в реальном времени:"
                echo "      adb logcat | grep -E 'WebRTC|PeerConnection|AudioTrack'"
                echo "---------------------------------------------------"
            else
                echo "❌ Ошибка установки приложения на устройство"
                echo "💡 Совет: Убедитесь, что устройство подключено и разрешена отладка по USB"
            fi
        fi
    else
        echo "❌ Ошибка при сборке проекта"
        echo "💡 Совет: Запустите сборку с подробным выводом:"
        echo "   ./gradlew assembleDebug --info --stacktrace"
        
        # 8. Дополнительная диагностика ошибок сборки
        echo "🔍 Дополнительная диагностика ошибок сборки..."
        echo "   1. Проверка settings.gradle.kts:"
        echo "      cat settings.gradle.kts | grep 'jitpack'"
        echo "   2. Проверка build.gradle.kts:"
        echo "      cat app/build.gradle.kts | grep 'webrtc'"
        echo "   3. Проверка gradle.properties:"
        echo "      cat gradle.properties | grep 'Xmx'"
        echo "   4. Проверка логов Gradle:"
        echo "      cat /home/and/.gradle/daemon/*/daemon-*.out.log | grep -i error"
    fi
fi

# 9. Инструкция по использованию аудио звонков
echo -e "\n📌 Как совершать аудио звонки:"
echo "1. Запустите приложение и войдите в систему"
echo "2. На главном экране нажмите кнопку 'Позвонить'"
echo "3. Дождитесь установки соединения"
echo "4. Для включения/отключения микрофона нажмите серую кнопку"
echo "5. Для завершения звонка нажмите красную кнопку по центру"

# 10. Добавляем задержку, чтобы терминал не закрывался
read -p "Нажмите Enter для завершения..."
