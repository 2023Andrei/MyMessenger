#!/bin/bash
echo "🔧 Финальное исправление проблемы с AuthActivity..."

# 1. Проверка и восстановление AndroidManifest.xml
echo "🔧 Проверка AndroidManifest.xml..."
if ! grep -q "AuthActivity" app/src/main/AndroidManifest.xml; then
    echo "⚠️ AuthActivity не найдена в манифесте, добавляем..."
    
    # Добавляем AuthActivity в манифест
    sed -i '/<activity android:name=".MainActivity"/a \        <activity\n            android:name=".AuthActivity"\n            android:exported="true"\/>' app/src/main/AndroidManifest.xml
    
    echo "✅ AuthActivity добавлена в AndroidManifest.xml"
else
    echo "✅ AuthActivity уже объявлена в манифесте"
    
    # Проверяем, что запись корректна
    if ! grep -q "android:name=\".AuthActivity\"" app/src/main/AndroidManifest.xml; then
        echo "⚠️ Некорректная запись AuthActivity, исправляем..."
        sed -i 's|AuthActivity.*>|AuthActivity" android:exported="true"\/>|' app/src/main/AndroidManifest.xml
    fi
fi

# 2. Проверка необходимых разрешений
echo "🔧 Проверка необходимых разрешений..."
if ! grep -q "INTERNET" app/src/main/AndroidManifest.xml; then
    sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.INTERNET" />' app/src/main/AndroidManifest.xml
    echo "✅ Добавлено разрешение INTERNET"
fi

if ! grep -q "CAMERA" app/src/main/AndroidManifest.xml; then
    sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.CAMERA" />' app/src/main/AndroidManifest.xml
    echo "✅ Добавлено разрешение CAMERA"
fi

if ! grep -q "RECORD_AUDIO" app/src/main/AndroidManifest.xml; then
    sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.RECORD_AUDIO" />' app/src/main/AndroidManifest.xml
    echo "✅ Добавлено разрешение RECORD_AUDIO"
fi

if ! grep -q "ACCESS_NETWORK_STATE" app/src/main/AndroidManifest.xml; then
    sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />' app/src/main/AndroidManifest.xml
    echo "✅ Добавлено разрешение ACCESS_NETWORK_STATE"
fi

# 3. Проверка google-services.json
echo "🔍 Проверка google-services.json..."
if [ ! -f "app/google-services.json" ]; then
    echo "❌ Файл google-services.json не найден"
    echo "Скачайте его из Firebase Console и поместите в папку app/"
    exit 1
fi
echo "✅ Файл google-services.json найден"

# Проверка package name
packageName=$(cat app/google-services.json | grep -A 5 'client_info' | grep 'package_name' | cut -d '"' -f 4)
echo "📦 Package name в google-services.json: $packageName"

# Проверка на соответствие package name
if [ "$packageName" != "com.example.mymessenger" ]; then
    echo "⚠️ Package name в google-services.json не совпадает с package name приложения"
    echo "💡 Решение: создайте новый google-services.json с правильным package name"
fi

# Проверка наличия OAuth клиента
if ! grep -q "oauth_client" app/google-services.json; then
    echo "⚠️ Не найден oauth_client в google-services.json"
    echo "💡 Решение: убедитесь, что Google-аутентификация включена в Firebase Console"
else
    echo "✅ OAuth клиент присутствует"
    
    # Извлечение Web Client ID
    webClientId=$(cat app/google-services.json | grep -A 10 'oauth_client' | grep 'client_id' | cut -d '"' -f 4)
    echo "🔑 Web Client ID из google-services.json: $webClientId"
fi

# 4. Проверка и исправление strings.xml
echo "🔧 Проверка strings.xml..."
mkdir -p app/src/main/res/values
if [ ! -f "app/src/main/res/values/strings.xml" ]; then
    echo "⚠️ Файл strings.xml отсутствует, создаем..."
    cat > app/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">Мой Мессенджер</string>
    <string name="default_web_client_id">123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com</string>
</resources>
