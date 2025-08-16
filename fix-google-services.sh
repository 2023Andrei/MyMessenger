#!/bin/bash
echo "🔧 Финальное исправление Google Services Plugin..."

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

# 2. Установка jq (если нужно)
echo "🔧 Установка jq..."
sudo apt update >/dev/null 2>&1
sudo apt install -y jq >/dev/null 2>&1
echo "✅ jq установлен"

# 3. Проверка package name
echo "🔍 Проверка package name в google-services.json..."
packageName=$(cat app/google-services.json | jq -r '.client[0].client_info.android_client_info.package_name')
echo "📦 Package name: $packageName"

# 4. Удаление старых упоминаний плагина
echo "🔧 Очистка build.gradle.kts от старых упоминаний плагина..."
sed -i '/com.google.gms.google-services/d' app/build.gradle.kts
echo "✅ Старые упоминания удалены"

# 5. Добавление плагина с указанием версии
echo "🔧 Добавление Google Services Plugin с версией..."
# Если есть блок plugins, добавляем внутрь
if grep -q "plugins {" app/build.gradle.kts; then
    # Удаляем старый плагин, если он есть
    sed -i '/id("com.google.gms.google-services")/d' app/build.gradle.kts
    # Добавляем плагин с версией
    sed -i '/plugins {/a \    id("com.google.gms.google-services") version "4.4.0"' app/build.gradle.kts
else
    # Создаем блок plugins с плагином
    cat > temp_build.gradle.kts << 'EOT'
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.0" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false
}
EOT
    cat temp_build.gradle.kts app/build.gradle.kts > temp_build.gradle.kts.new
    mv temp_build.gradle.kts.new app/build.gradle.kts
    rm temp_build.gradle.kts
fi
echo "✅ Google Services Plugin добавлен с версией 4.4.0"

# 6. Добавление репозитория Google в settings.gradle.kts
echo "🔧 Добавление репозитория Google в settings.gradle.kts..."
if ! grep -q "google()" settings.gradle.kts; then
    sed -i '/mavenCentral()/a \        google()' settings.gradle.kts
    echo "✅ Репозиторий Google добавлен"
else
    echo "ℹ️ Репозиторий Google уже добавлен"
fi

# 7. Добавление зависимостей Firebase
echo "🔧 Добавление зависимостей Firebase..."
if ! grep -q "firebase-auth" app/build.gradle.kts; then
    sed -i '/implementation("com.infobip:google-webrtc:1.0.35530")/a \    implementation("com.google.firebase:firebase-auth:22.3.0")\n    implementation("com.google.firebase:firebase-firestore:24.9.1")' app/build.gradle.kts
    echo "✅ Зависимости Firebase добавлены"
else
    echo "ℹ️ Зависимости Firebase уже добавлены"
fi

# 8. Очистка кэша Gradle
echo "🔧 Очистка кэша Gradle..."
rm -rf ~/.gradle/caches/modules-2/files-2.1/com.google.gms 2>/dev/null || true
echo "✅ Кэш Gradle очищен"

# 9. Пересборка проекта
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

# 10. Добавляем задержку, чтобы терминал не закрывался
read -p "Нажмите Enter для завершения..."
