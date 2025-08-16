#!/bin/bash
echo "🔧 Исправление проблемы с аутентификацией..."

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

# 2. Проверка strings.xml
echo "🔧 Проверка strings.xml..."
mkdir -p app/src/main/res/values
if [ ! -f "app/src/main/res/values/strings.xml" ]; then
    echo "⚠️ Файл strings.xml отсутствует, создаем..."
    cat > app/src/main/res/values/strings.xml << 'EOF'
<resources>
    <string name="app_name">Мой Мессенджер</string>
    <string name="default_web_client_id">123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com</string>
    
    <!-- Добавляем недостающие строковые ресурсы -->
    <string name="call">Позвонить</string>
    <string name="chat">Чат</string>
    <string name="email">Email</string>
    <string name="enter_message">Введите сообщение</string>
    <string name="login">Вход</string>
    <string name="login_button">Войти</string>
    <string name="logout">Выйти</string>
    <string name="password">Пароль</string>
    <string name="register">Регистрация</string>
    <string name="register_button">Зарегистрироваться</string>
    <string name="send">Отправить</string>
</resources>
