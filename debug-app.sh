#!/bin/bash
echo "🔧 Запуск отладки приложения через ADB..."

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

# 2. Проверка установленного приложения
echo "🔍 Проверка установленного приложения..."
if adb shell pm list packages | grep -q "com.example.mymessenger"; then
    echo "✅ Приложение установлено"
else
    echo "⚠️ Приложение не установлено, устанавливаем..."
    adb install -r app/build/outputs/apk/debug/app-debug.apk
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка установки приложения"
        exit 1
    fi
fi

# 3. Очистка логов
echo "🧹 Очистка логов..."
adb logcat -c

# 4. Запуск приложения и сбор логов
echo "📱 Запуск приложения и сбор логов (ожидайте вылета)..."
echo "❗ Внимание: после запуска приложения дождитесь его вылета!"
adb shell monkey -p com.example.mymessenger -c android.intent.category.LAUNCHER 1

# 5. Сохранение логов
echo "📝 Сохранение логов в файл..."
adb logcat -d > crash_log.txt
grep -A 30 -B 10 "AndroidRuntime.*FATAL" crash_log.txt > error_log.txt

# 6. Анализ ошибки
echo "🔍 Анализ ошибки..."
if [ -s error_log.txt ]; then
    echo -e "\n❌ Обнаружена критическая ошибка:"
    cat error_log.txt
    
    # Определение типа ошибки
    if grep -q "ActivityNotFoundException" error_log.txt; then
        echo -e "\n💡 Возможная причина: активность не объявлена в AndroidManifest.xml"
        echo "Проверьте файл AndroidManifest.xml на наличие недостающих активностей"
    elif grep -q "NullPointerException" error_log.txt; then
        echo -e "\n💡 Возможная причина: обращение к null-объекту"
        echo "Проверьте инициализацию объектов в коде"
    elif grep -q "ClassNotFoundException" error_log.txt; then
        echo -e "\n💡 Возможная причина: отсутствует класс или зависимость"
        echo "Проверьте зависимости в build.gradle.kts"
    fi
    
    # Предложение решения
    echo -e "\n🛠️ Рекомендуемые действия:"
    echo "1. Проверьте AndroidManifest.xml:"
    echo "   cat app/src/main/AndroidManifest.xml | grep -A 5 -B 5 'AuthActivity'"
    
    echo -e "\n2. Проверьте MainActivity.kt:"
    echo "   cat app/src/main/java/com/example/mymessenger/MainActivity.kt | grep 'AuthActivity'"
    
    echo -e "\n3. Проверьте наличие AuthActivity.kt:"
    echo "   ls -la app/src/main/java/com/example/mymessenger/AuthActivity.kt"
else
    echo -e "\n✅ Критических ошибок не обнаружено"
fi

# 7. Дополнительные команды для отладки
echo -e "\n🔧 Дополнительные команды для отладки:"
echo "1. Просмотр всех логов приложения:"
echo "   adb logcat | grep 'com.example.mymessenger'"
echo ""
echo "2. Перезапуск приложения после очистки данных:"
echo "   adb shell am force-stop com.example.mymessenger"
echo "   adb shell pm clear com.example.mymessenger"
echo "   adb shell monkey -p com.example.mymessenger -c android.intent.category.LAUNCHER 1"
echo ""
echo "3. Запуск конкретной активности для тестирования:"
echo "   adb shell am start -n com.example.mymessenger/com.example.mymessenger.AuthActivity"
echo ""
echo "4. Просмотр информации о приложении:"
echo "   adb shell dumpsys package com.example.mymessenger"

# 8. Предложение исправления для текущей ошибки
echo -e "\n🛠️ Конкретное исправление для текущей ошибки:"
echo "Похоже, что AuthActivity не объявлена в AndroidManifest.xml. Выполните:"
echo ""
echo "sed -i '/<activity android:name=\".MainActivity\"/a \        <activity\n            android:name=\".AuthActivity\"\n            android:exported=\"true\" />' app/src/main/AndroidManifest.xml"
echo ""
echo "Или полностью замените AndroidManifest.xml:"
cat << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.mymessenger">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/AppTheme">
        
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
        <activity
            android:name=".AuthActivity"
            android:exported="true" />
            
        <activity
            android:name=".CallActivity"
            android:exported="false" />
            
    </application>

</manifest>
