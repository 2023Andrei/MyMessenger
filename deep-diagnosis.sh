#!/bin/bash
echo "🔍 Глубокая диагностика вылетающего приложения..."

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

# 3. Запуск приложения и сбор ВСЕХ логов
echo "📱 Запуск приложения и сбор всех логов (ожидайте вылета)..."
echo "❗ Внимание: после запуска приложения дождитесь его вылета!"
adb shell monkey -p com.example.mymessenger -c android.intent.category.LAUNCHER 1

# 4. Сохранение ПОЛНЫХ логов
echo "📝 Сохранение ПОЛНЫХ логов в файл..."
adb logcat -d > full_crash_log.txt

# 5. Анализ всех возможных ошибок
echo "🔍 Анализ всех возможных ошибок..."
echo -e "\n📌 Основные типы ошибок в логах:"

# Проверка на ActivityNotFoundException
if grep -q "ActivityNotFoundException" full_crash_log.txt; then
    echo -e "\n❌ ActivityNotFoundException обнаружена:"
    grep -A 10 -B 5 "ActivityNotFoundException" full_crash_log.txt
    echo -e "\n💡 Вероятная причина: активность не объявлена в AndroidManifest.xml"
    echo "🛠️ Решение: добавьте недостающую активность в манифест"
fi

# Проверка на NullPointerException
if grep -q "NullPointerException" full_crash_log.txt; then
    echo -e "\n❌ NullPointerException обнаружена:"
    grep -A 10 -B 5 "NullPointerException" full_crash_log.txt
    echo -e "\n💡 Вероятная причина: обращение к null-объекту"
    echo "🛠️ Решение: проверьте инициализацию объектов в коде"
fi

# Проверка на Firebase инициализации
if grep -q "FirebaseApp" full_crash_log.txt; then
    echo -e "\n📌 Firebase инициализация:"
    grep -A 10 -B 5 "FirebaseApp" full_crash_log.txt
fi

# Проверка на Google Sign-In ошибки
if grep -q "GoogleSignIn" full_crash_log.txt; then
    echo -e "\n📌 Google Sign-In ошибки:"
    grep -A 10 -B 5 "GoogleSignIn" full_crash_log.txt
fi

# Проверка на ошибки WebRTC
if grep -q "WebRTC" full_crash_log.txt || grep -q "PeerConnection" full_crash_log.txt; then
    echo -e "\n📌 WebRTC ошибки:"
    grep -A 10 -B 5 -E "WebRTC|PeerConnection" full_crash_log.txt
fi

# 6. Проверка ключевых компонентов
echo -e "\n🔧 Проверка ключевых компонентов..."

# Проверка наличия google-services.json
echo -e "\n🔍 Проверка google-services.json..."
if [ -f "app/google-services.json" ]; then
    echo "✅ Файл google-services.json найден"
    echo "📌 Package name: $(cat app/google-services.json | grep -A 5 'client_info' | grep 'package_name')"
else
    echo "❌ Файл google-services.json не найден"
    echo "💡 Решение: скачайте его из Firebase Console и поместите в папку app/"
fi

# Проверка AndroidManifest.xml
echo -e "\n🔍 Проверка AndroidManifest.xml..."
if grep -q "AuthActivity" app/src/main/AndroidManifest.xml; then
    echo "✅ AuthActivity объявлена в манифесте"
else
    echo "❌ AuthActivity НЕ объявлена в манифесте"
    echo "💡 Решение: добавьте следующее в AndroidManifest.xml:"
    echo '<activity android:name=".AuthActivity" android:exported="true" />'
fi

# Проверка strings.xml
echo -e "\n🔍 Проверка strings.xml..."
if [ -f "app/src/main/res/values/strings.xml" ]; then
    if grep -q "default_web_client_id" app/src/main/res/values/strings.xml; then
        echo "✅ Web Client ID найден в strings.xml"
    else
        echo "❌ Web Client ID ОТСУТСТВУЕТ в strings.xml"
        echo "💡 Решение: добавьте в strings.xml:"
        echo '<string name="default_web_client_id">ВАШ_ИДЕНТИФИКАТОР.apps.googleusercontent.com</string>'
    fi
else
    echo "❌ Файл strings.xml не найден"
    echo "💡 Решение: создайте файл strings.xml с необходимыми строками"
fi

# 7. Проверка Firebase Console
echo -e "\n🌐 Проверка настроек Firebase Console..."
echo "❗ Проверьте следующее в Firebase Console:"
echo "1. Google-аутентификация ВКЛЮЧЕНА в разделе Authentication → Sign-in method"
echo "2. SHA-1 сертификат добавлен в Project settings → Your apps"
echo "3. Package name совпадает с тем, что в приложении (com.example.mymessenger)"

# 8. Рекомендуемые действия
echo -e "\n🛠️ Рекомендуемые действия для решения проблемы:"

# Проверка SHA-1 сертификата
echo -e "\n🔍 Проверка SHA-1 сертификата:"
echo "1. Получите SHA-1 для отладочной сборки:"
echo "   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android"
echo "2. Сравните с тем, что в Firebase Console"
echo "3. Если не совпадает, добавьте правильный SHA-1 в Firebase Console"

# Проверка Web Client ID
echo -e "\n🔍 Проверка Web Client ID:"
echo "1. Откройте google-services.json из папки app/"
echo "2. Найдите значение в разделе oauth_client -> client_id"
echo "3. Убедитесь, что это значение точно совпадает со строкой default_web_client_id в strings.xml"

# Проверка разрешений
echo -e "\n🔍 Проверка разрешений:"
if grep -q "INTERNET" app/src/main/AndroidManifest.xml; then
    echo "✅ Разрешение INTERNET найдено"
else
    echo "❌ Разрешение INTERNET ОТСУТСТВУЕТ"
    echo "💡 Решение: добавьте в AndroidManifest.xml:"
    echo '<uses-permission android:name="android.permission.INTERNET" />'
fi

if grep -q "CAMERA" app/src/main/AndroidManifest.xml; then
    echo "✅ Разрешение CAMERA найдено"
else
    echo "❌ Разрешение CAMERA ОТСУТСТВУЕТ"
    echo "💡 Решение: добавьте в AndroidManifest.xml:"
    echo '<uses-permission android:name="android.permission.CAMERA" />'
fi

if grep -q "RECORD_AUDIO" app/src/main/AndroidManifest.xml; then
    echo "✅ Разрешение RECORD_AUDIO найдено"
else
    echo "❌ Разрешение RECORD_AUDIO ОТСУТСТВУЕТ"
    echo "💡 Решение: добавьте в AndroidManifest.xml:"
    echo '<uses-permission android:name="android.permission.RECORD_AUDIO" />'
fi

# 9. Дополнительные команды для отладки
echo -e "\n🔧 Дополнительные команды для отладки:"
echo "1. Просмотр ВСЕХ логов приложения в реальном времени:"
echo "   adb logcat | grep 'com.example.mymessenger'"
echo ""
echo "2. Запуск конкретной активности для тестирования:"
echo "   adb shell am start -n com.example.mymessenger/com.example.mymessenger.AuthActivity"
echo ""
echo "3. Просмотр информации о приложении:"
echo "   adb shell dumpsys package com.example.mymessenger"
echo ""
echo "4. Проверка установленных разрешений:"
echo "   adb shell dumpsys package com.example.mymessenger | grep permission"
echo ""
echo "5. Проверка состояния Firebase:"
echo "   adb logcat | grep -E 'Firebase|FIS|FA'"

# 10. Создание тестового MainActivity
echo -e "\n🔧 Создание упрощенного MainActivity для тестирования..."
cat > app/src/main/java/com/example/mymessenger/MainActivity.kt << 'EOF'
package com.example.mymessenger

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Просто выводим сообщение, чтобы убедиться, что активность запускается
        println("MainActivity запущен!")
    }
}
