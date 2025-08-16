#!/bin/bash
echo "🔧 Исправление конфликта версий Firebase..."

# 1. Проверка наличия google-services.json
echo "🔍 Проверка google-services.json..."
if [ ! -f "app/google-services.json" ]; then
    echo "⚠️ Файл google-services.json не найден"
    echo "Попробуем скопировать из Загрузок..."
    cp /home/and/Загрузки/google-services.json app/ 2>/dev/null || \
    cp ~/Downloads/google-services.json app/ 2>/dev/null
    
    if [ ! -f "app/google-services.json" ]; then
        echo "❌ Файл google-services.json не найден ни в одном месте"
        echo "Скачайте его из Firebase Console и поместите в папку app/"
        exit 1
    fi
fi
echo "✅ Файл google-services.json найден"

# 2. Использование Firebase BOM для согласования версий
echo "🔧 Использование Firebase BOM для согласования версий..."
# Удаляем старые зависимости Firebase
sed -i '/firebase-/d' app/build.gradle.kts

# Добавляем Firebase BOM и правильные зависимости
cat << 'EOT' > temp_deps.txt
    // Используем Firebase BOM для согласования версий
    implementation(platform("com.google.firebase:firebase-bom:33.1.1"))
    
    // Добавляем только нужные Firebase зависимости
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
EOT

# Вставляем зависимости перед WebRTC
sed -i '/implementation("com.infobip:google-webrtc:1.0.35530")/r temp_deps.txt' app/build.gradle.kts
rm temp_deps.txt
echo "✅ Firebase BOM добавлен для согласования версий"

# 3. Убедимся, что репозиторий Google добавлен в settings.gradle.kts
echo "🔧 Проверка репозитория Google в settings.gradle.kts..."
if ! grep -q "google()" settings.gradle.kts; then
    sed -i '/mavenCentral()/a \        google()' settings.gradle.kts
    echo "✅ Репозиторий Google добавлен в settings.gradle.kts"
else
    echo "ℹ️ Репозиторий Google уже добавлен"
fi

# 4. Очистка кэша Gradle
echo "🔧 Очистка кэша Gradle..."
rm -rf ~/.gradle/caches/modules-2/files-2.1/com.google.firebase 2>/dev/null || true
echo "✅ Кэш Gradle очищен"

# 5. Пересборка проекта
echo "🔧 Пересборка проекта..."
./gradlew --refresh-dependencies >/dev/null 2>&1
./gradlew clean assembleDebug

if [ $? -eq 0 ]; then
    echo -e "\n✅ Проект успешно собран с Firebase!"
    echo "---------------------------------------------------"
    echo "Готовый APK: app/build/outputs/apk/debug/app-debug.apk"
    echo "1. Установите новый APK на телефон"
    echo "2. Теперь ваш мессенджер подключен к Firebase"
    echo "3. Не забудьте включить Google-аутентификацию в Firebase Console:"
    echo "   - Перейдите в https://console.firebase.google.com/"
    echo "   - Выберите ваш проект"
    echo "   - Перейдите в Authentication → Sign-in method"
    echo "   - Включите провайдер Google"
else
    echo -e "\n❌ Ошибка при сборке проекта"
    echo "---------------------------------------------------"
    echo "Если проблема сохраняется:"
    echo "1. Убедитесь, что файл google-services.json корректный"
    echo "2. Проверьте package name в файле (должен быть com.example.mymessenger)"
    echo "3. Запустите сборку с подробным выводом:"
    echo "   ./gradlew assembleDebug --info"
fi

# 6. Добавляем задержку, чтобы терминал не закрывался
read -p "Нажмите Enter для завершения..."
