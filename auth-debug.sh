#!/bin/bash
echo "🔍 Полная диагностика проблемы с аутентификацией..."

# 1. Проверка подключения устройства
echo "🔍 Проверка подключения устройства..."
adb devices
if [ "$(adb get-state)" != "device" ]; then
    echo "❌ Устройство не подключено или не в режиме отладки"
    echo "1. Включите режим разработчика на телефоне"
    echo "2. Включите отладку по USB"
    echo "3. Подтвердите доверие к компьютеру на телефоне"
    exit 1
fi
echo "✅ Устройство подключено"

# 2. Очистка логов
echo "🧹 Очистка логов..."
adb logcat -c

# 3. Запуск приложения и сбор логов
echo "📱 Запуск приложения и сбор логов (ожидайте вылета)..."
echo "❗ Внимание: после запуска приложения дождитесь его вылета!"
adb shell monkey -p com.example.mymessenger -c android.intent.category.LAUNCHER 1

# 4. Сохранение полных логов
echo "📝 Сохранение полных логов в файл..."
adb logcat -d > full_auth_log.txt

# 5. Проверка ключевых компонентов аутентификации
echo -e "\n🔧 Проверка ключевых компонентов аутентификации..."

# Проверка AndroidManifest.xml
echo -e "\n🔍 Проверка AndroidManifest.xml..."
if grep -q "AuthActivity" app/src/main/AndroidManifest.xml; then
    echo "✅ AuthActivity объявлена в манифесте"
    
    # Проверка корректности записи
    if ! grep -q "android:name=\".AuthActivity\"" app/src/main/AndroidManifest.xml; then
        echo "⚠️ Некорректная запись AuthActivity"
        echo "💡 Решение: замените на корректную запись:"
        echo '<activity android:name=".AuthActivity" android:exported="true" />'
    else
        echo "✅ Запись AuthActivity корректна"
    fi
else
    echo "❌ AuthActivity НЕ объявлена в манифесте"
    echo "💡 Решение: добавьте в AndroidManifest.xml:"
    echo '<activity android:name=".AuthActivity" android:exported="true" />'
fi

# Проверка наличия AuthActivity.kt
echo -e "\n🔍 Проверка AuthActivity.kt..."
if [ -f "app/src/main/java/com/example/mymessenger/AuthActivity.kt" ]; then
    echo "✅ Файл AuthActivity.kt найден"
    
    # Проверка на использование устаревших методов
    if grep -q "onActivityResult" app/src/main/java/com/example/mymessenger/AuthActivity.kt && 
       grep -q "startActivityForResult" app/src/main/java/com/example/mymessenger/AuthActivity.kt; then
        echo "⚠️ Используются устаревшие методы startActivityForResult и onActivityResult"
        echo "💡 Решение: замените на современный API registerForActivityResult"
    else
        echo "✅ Используется современный API для обработки результатов"
    fi
    
    # Проверка на наличие Web Client ID
    if ! grep -q "default_web_client_id" app/src/main/java/com/example/mymessenger/AuthActivity.kt; then
        echo "⚠️ Не найдено упоминание default_web_client_id"
        echo "💡 Решение: убедитесь, что используется getString(R.string.default_web_client_id)"
    fi
else
    echo "❌ Файл AuthActivity.kt отсутствует"
    echo "💡 Решение: создайте файл с правильной реализацией"
fi

# Проверка google-services.json
echo -e "\n🔍 Проверка google-services.json..."
if [ -f "app/google-services.json" ]; then
    echo "✅ Файл google-services.json найден"
    
    # Проверка package name
    packageName=$(cat app/google-services.json | grep -A 5 'client_info' | grep 'package_name' | cut -d '"' -f 4)
    echo "📦 Package name в google-services.json: $packageName"
    
    # Проверка на соответствие package name
    if [ "$packageName" != "com.example.mymessenger" ]; then
        echo "⚠️ Package name в google-services.json не совпадает с package name приложения"
        echo "💡 Решение: создайте новый google-services.json с правильным package name"
    else
        echo "✅ Package name совпадает"
    fi
    
    # Проверка наличия OAuth клиента
    if ! grep -q "oauth_client" app/google-services.json; then
        echo "⚠️ Не найден oauth_client в google-services.json"
        echo "💡 Решение: убедитесь, что Google-аутентификация включена в Firebase Console"
    else
        echo "✅ OAuth клиент присутствует"
    fi
else
    echo "❌ Файл google-services.json не найден"
    echo "💡 Решение: скачайте его из Firebase Console и поместите в папку app/"
fi

# Проверка strings.xml
echo -e "\n🔍 Проверка strings.xml..."
if [ -f "app/src/main/res/values/strings.xml" ]; then
    echo "✅ Файл strings.xml найден"
    
    # Проверка наличия Web Client ID
    if grep -q "default_web_client_id" app/src/main/res/values/strings.xml; then
        echo "✅ Web Client ID присутствует в strings.xml"
        
        # Проверка на пустое значение
        webClientId=$(grep "default_web_client_id" app/src/main/res/values/strings.xml | sed 's/.*<string name="default_web_client_id">//;s/<\/string>.*//')
        if [ "$webClientId" = "123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com" ]; then
            echo "⚠️ Web Client ID имеет значение по умолчанию"
            echo "💡 Решение: замените на реальный Web Client ID из google-services.json"
        else
            echo "✅ Web Client ID имеет реальное значение"
        fi
    else
        echo "❌ Web Client ID отсутствует в strings.xml"
        echo "💡 Решение: добавьте в strings.xml:"
        echo '<string name="default_web_client_id">ВАШ_ИДЕНТИФИКАТОР.apps.googleusercontent.com</string>'
    fi
else
    echo "❌ Файл strings.xml не найден"
    echo "💡 Решение: создайте файл strings.xml с необходимыми строками"
fi

# Проверка настроек Firebase Console
echo -e "\n🌐 Проверка настроек Firebase Console..."
echo "❗ Проверьте следующее в Firebase Console:"
echo "1. Google-аутентификация ВКЛЮЧЕНА в разделе Authentication → Sign-in method"
echo "2. SHA-1 сертификат добавлен в Project settings → Your apps"
echo "3. Package name совпадает с тем, что в приложении (com.example.mymessenger)"

# 6. Анализ логов на наличие ошибок аутентификации
echo -e "\n🔍 Анализ логов на наличие ошибок аутентификации..."
if grep -q "ActivityNotFoundException" full_auth_log.txt; then
    echo -e "\n❌ ActivityNotFoundException обнаружена:"
    grep -A 10 -B 5 "ActivityNotFoundException" full_auth_log.txt
    echo -e "\n💡 Вероятная причина: активность не объявлена в AndroidManifest.xml"
    echo "🛠️ Решение: добавьте недостающую активность в манифест"
fi

if grep -q "NullPointerException" full_auth_log.txt; then
    echo -e "\n❌ NullPointerException обнаружена:"
    grep -A 10 -B 5 "NullPointerException" full_auth_log.txt
    echo -e "\n💡 Вероятная причина: обращение к null-объекту"
    echo "🛠️ Решение: проверьте инициализацию объектов в коде"
fi

if grep -q "GoogleSignIn" full_auth_log.txt; then
    echo -e "\n📌 Google Sign-In ошибки:"
    grep -A 10 -B 5 "GoogleSignIn" full_auth_log.txt
fi

if grep -q "FirebaseApp" full_auth_log.txt; then
    echo -e "\n📌 Firebase инициализация:"
    grep -A 10 -B 5 "FirebaseApp" full_auth_log.txt
fi

# 7. Проверка SHA-1 сертификата
echo -e "\n🔍 Проверка SHA-1 сертификата..."
echo "1. Получите SHA-1 для отладочной сборки:"
echo "   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
echo "2. Сравните с тем, что в Firebase Console"
echo "3. Если не совпадает, добавьте правильный SHA-1 в Firebase Console"

# 8. Тестирование аутентификации через ADB
echo -e "\n🧪 Тестирование аутентификации через ADB..."
echo "1. Запуск MainActivity:"
echo "   adb shell am start -n com.example.mymessenger/com.example.mymessenger.MainActivity"
echo "2. Запуск AuthActivity:"
echo "   adb shell am start -n com.example.mymessenger/com.example.mymessenger.AuthActivity"
echo "3. Просмотр логов в реальном времени:"
echo "   adb logcat | grep 'com.example.mymessenger'"

# 9. Рекомендуемые действия
echo -e "\n🛠️ Рекомендуемые действия для решения проблемы:"

# Проверка на использование современного API
if [ -f "app/src/main/java/com/example/mymessenger/AuthActivity.kt" ] && 
   grep -q "onActivityResult" app/src/main/java/com/example/mymessenger/AuthActivity.kt &&
   grep -q "startActivityForResult" app/src/main/java/com/example/mymessenger/AuthActivity.kt; then
    echo -e "\n🔧 Проблема: использование устаревших методов"
    echo "💡 Решение: замените устаревшие методы на современный API:"
    cat << 'EOF'
// Регистрация обработчика для результатов активности
private val signInResultLauncher = registerForActivityResult(
    ActivityResultContracts.StartActivityForResult()
) { result ->
    if (result.resultCode == RESULT_OK) {
        val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
        // Обработка результата
    }
}

private fun signInWithGoogle() {
    val signInIntent = googleSignInClient.signInIntent
    signInResultLauncher.launch(signInIntent)
}
