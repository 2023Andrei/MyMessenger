#!/bin/bash
echo "🔧 Переход с Google Sign-In на Email/Password аутентификацию..."

# 1. Проверка и обновление AndroidManifest.xml
echo "🔧 Проверка AndroidManifest.xml..."
if ! grep -q "AuthActivity" app/src/main/AndroidManifest.xml; then
    echo "⚠️ AuthActivity не найдена в манифесте, добавляем..."
    
    # Добавляем AuthActivity в манифест
    sed -i '/<activity android:name=".MainActivity"/a \        <activity\n            android:name=".AuthActivity"\n            android:exported="true"\/>' app/src/main/AndroidManifest.xml
    
    echo "✅ AuthActivity добавлена в AndroidManifest.xml"
else
    echo "✅ AuthActivity уже объявлена в манифесте"
fi

# 2. Проверка необходимых разрешений
echo "🔧 Проверка необходимых разрешений..."
if ! grep -q "INTERNET" app/src/main/AndroidManifest.xml; then
    sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.INTERNET" />' app/src/main/AndroidManifest.xml
    echo "✅ Добавлено разрешение INTERNET"
fi

# 3. Обновление layout для AuthActivity
echo "🔧 Создание layout для AuthActivity с email/password..."
mkdir -p app/src/main/res/layout
cat > app/src/main/res/layout/activity_auth.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical"
    android:padding="16dp">

    <TextView
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="16dp"
        android:text="Вход в Мой Мессенджер"
        android:textAlignment="center"
        android:textSize="24sp"
        android:textStyle="bold" />

    <EditText
        android:id="@+id/editTextEmail"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="8dp"
        android:hint="Email"
        android:inputType="textEmailAddress" />

    <EditText
        android:id="@+id/editTextPassword"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="16dp"
        android:hint="Пароль"
        android:inputType="textPassword" />

    <Button
        android:id="@+id/buttonLogin"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:layout_marginBottom="8dp"
        android:text="Войти" />

    <Button
        android:id="@+id/buttonRegister"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:text="Зарегистрироваться" />

</LinearLayout>
