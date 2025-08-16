#!/bin/bash
echo "🔧 Исправление ошибки с compileSdk и Android Gradle Plugin..."

# 1. Обновление Android Gradle Plugin до версии, поддерживающей compileSdk 34
echo "🔧 Обновление Android Gradle Plugin..."
# Обновляем версию AGP в build.gradle.kts (корневой)
sed -i 's|id("com.android.application") version "8.1.0"|id("com.android.application") version "8.2.2"|' build.gradle.kts
sed -i 's|id("com.android.library") version "8.1.0"|id("com.android.library") version "8.2.2"|' build.gradle.kts
echo "✅ Android Gradle Plugin обновлен до версии 8.2.2"

# 2. Обновление compileSdk до версии 34
echo "🔧 Обновление compileSdk до версии 34..."
# Обновляем compileSdk в app/build.gradle.kts
sed -i 's|compileSdk = 33|compileSdk = 34|' app/build.gradle.kts
sed -i 's|targetSdk = 33|targetSdk = 34|' app/build.gradle.kts
echo "✅ compileSdk и targetSdk обновлены до версии 34"

# 3. Убедимся, что установлены необходимые компоненты Android SDK
echo "🔧 Проверка установленных компонентов Android SDK..."
if ! sdkmanager --list | grep -q "build-tools;34.0.0"; then
    echo "🔧 Установка Android SDK Build-Tools 34.0.0..."
    sdkmanager "build-tools;34.0.0"
fi

if ! sdkmanager --list | grep -q "platforms;android-34"; then
    echo "🔧 Установка Android SDK Platform 34..."
    sdkmanager "platforms;android-34"
fi
echo "✅ Необходимые компоненты Android SDK установлены"

# 4. Использование Firebase BOM для согласования версий
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

# 5. Убеждаемся, что репозиторий Google добавлен в settings.gradle.kts
echo "🔧 Проверка репозитория Google в settings.gradle.kts..."
if ! grep -q "google()" settings.gradle.kts; then
    sed -i '/mavenCentral()/a \        google()' settings.gradle.kts
    echo "✅ Репозиторий Google добавлен в settings.gradle.kts"
else
    echo "ℹ️ Репозиторий Google уже добавлен"
fi

# 6. Очистка кэша Gradle
echo "🔧 Очистка кэша Gradle..."
rm -rf ~/.gradle/caches/modules-2/files-2.1/com.google.firebase 2>/dev/null || true
echo "✅ Кэш Gradle очищен"

# 7. Пересборка проекта
echo "🔧 Пересборка проекта..."
./gradlew --refresh-dependencies >/dev/null 2>&1
./gradlew clean assembleDebug

if [ $? -eq 0 ]; then
    echo -e "\n✅ Проект успешно собран!"
    echo "---------------------------------------------------"
    echo "Готовый APK: app/build/outputs/apk/debug/app-debug.apk"
    echo "1. Установите новый APK на телефон"
    echo "2. Теперь ваш мессенджер работает с Firebase"
    echo "3. Не забудьте включить Google-аутентификацию в Firebase Console"
else
    echo -e "\n❌ Ошибка при сборке проекта"
    echo "---------------------------------------------------"
    echo "Если проблема сохраняется:"
    echo "1. Убедитесь, что установлен Android SDK Platform 34"
    echo "2. Проверьте, что файл google-services.json корректный"
    echo "3. Запустите сборку с подробным выводом:"
    echo "   ./gradlew assembleDebug --info"
fi

# 8. Добавляем задержку, чтобы терминал не закрывался
read -p "Нажмите Enter для завершения..."
