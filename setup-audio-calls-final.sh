#!/bin/bash
echo "🔧 Настройка аудио звонков в мессенджере (финальная версия)..."

# 1. Проверка и добавление необходимых разрешений (без дублирования)
echo "🔧 Проверка необходимых разрешений для аудио звонков..."

# Удаляем дублирующиеся разрешения
if [ -f "app/src/main/AndroidManifest.xml" ]; then
    # Удаляем все повторяющиеся разрешения
    sed -i '/<uses-permission.*ACCESS_NETWORK_STATE/d' app/src/main/AndroidManifest.xml
    sed -i '/<uses-permission.*INTERNET/d' app/src/main/AndroidManifest.xml
    sed -i '/<uses-permission.*CAMERA/d' app/src/main/AndroidManifest.xml
    sed -i '/<uses-permission.*RECORD_AUDIO/d' app/src/main/AndroidManifest.xml
    sed -i '/<uses-permission.*MODIFY_AUDIO_SETTINGS/d' app/src/main/AndroidManifest.xml
    
    # Добавляем необходимые разрешения один раз
    if ! grep -q "INTERNET" app/src/main/AndroidManifest.xml; then
        sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.INTERNET" />' app/src/main/AndroidManifest.xml
        echo "✅ Добавлено разрешение INTERNET"
    fi
    
    if ! grep -q "RECORD_AUDIO" app/src/main/AndroidManifest.xml; then
        sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.RECORD_AUDIO" />' app/src/main/AndroidManifest.xml
        echo "✅ Добавлено разрешение RECORD_AUDIO"
    fi

    if ! grep -q "MODIFY_AUDIO_SETTINGS" app/src/main/AndroidManifest.xml; then
        sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />' app/src/main/AndroidManifest.xml
        echo "✅ Добавлено разрешение MODIFY_AUDIO_SETTINGS"
    fi
    
    if ! grep -q "ACCESS_NETWORK_STATE" app/src/main/AndroidManifest.xml; then
        sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />' app/src/main/AndroidManifest.xml
        echo "✅ Добавлено разрешение ACCESS_NETWORK_STATE"
    fi
else
    echo "❌ Файл AndroidManifest.xml не найден"
    exit 1
fi

# 2. Добавление JitPack репозитория в settings.gradle.kts
echo "🔧 Добавление JitPack репозитория в settings.gradle.kts..."
if ! grep -q "maven { url = uri(\"https://jitpack.io\") }" settings.gradle.kts; then
    # Удаляем старый JitPack репозиторий из build.gradle.kts, если он есть
    sed -i '/maven { url = uri(\"https://jitpack.io\") }/d' app/build.gradle.kts
    
    # Добавляем JitPack репозиторий в settings.gradle.kts
    sed -i '/dependencyResolutionManagement {/a \    repositories {\n        maven { url = uri(\"https://jitpack.io\") }\n    }' settings.gradle.kts
    echo "✅ Добавлен JitPack репозиторий в settings.gradle.kts"
else
    echo "✅ JitPack репозиторий уже добавлен в settings.gradle.kts"
fi

# 3. Добавление правильной зависимости WebRTC
echo "🔧 Добавление правильной зависимости WebRTC..."
# Удаляем старую зависимость WebRTC
sed -i '/com.github.webrtc:webrtc/d' app/build.gradle.kts
sed -i '/org.webrtc:google-webrtc/d' app/build.gradle.kts
sed -i '/org.webrtc:webrtc/d' app/build.gradle.kts

# Добавляем правильную зависимость WebRTC
if ! grep -q "com.github.webrtc:webrtc" app/build.gradle.kts; then
    # Используем master-SNAPSHOT вместо m85
    sed -i '/implementation("com.google.firebase:firebase-messaging")/a \    implementation("com.github.webrtc:webrtc:master-SNAPSHOT")' app/build.gradle.kts
    echo "✅ Добавлена правильная зависимость WebRTC (com.github.webrtc:webrtc:master-SNAPSHOT)"
else
    echo "✅ Зависимость WebRTC уже добавлена"
fi

# 4. Проверка и добавление AudioCallActivity в манифест
echo "🔧 Проверка AudioCallActivity в AndroidManifest.xml..."
if ! grep -q "AudioCallActivity" app/src/main/AndroidManifest.xml; then
    echo "⚠️ AudioCallActivity не найдена в манифесте, добавляем..."
    
    # Заменяем CallActivity на AudioCallActivity
    sed -i '/<activity android:name=".CallActivity"/d' app/src/main/AndroidManifest.xml
    sed -i '/<activity android:name=".AuthActivity"/a \        <activity\n            android:name=".AudioCallActivity"\n            android:exported="false"\/>' app/src/main/AndroidManifest.xml
    
    echo "✅ AudioCallActivity добавлена в AndroidManifest.xml"
else
    echo "✅ AudioCallActivity уже объявлена в манифесте"
    
    # Проверяем, что запись корректна
    if ! grep -q "android:name=\".AudioCallActivity\"" app/src/main/AndroidManifest.xml; then
        echo "⚠️ Некорректная запись AudioCallActivity, исправляем..."
        sed -i 's|CallActivity.*>|AudioCallActivity" android:exported="false"\/>|' app/src/main/AndroidManifest.xml
    fi
fi

# 5. Создание layout для AudioCallActivity
echo "🔧 Создание layout для AudioCallActivity..."
mkdir -p app/src/main/res/layout
cat > app/src/main/res/layout/activity_audio_call.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="#2C3E50">

    <TextView
        android:id="@+id/textViewCallStatus"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_centerHorizontal="true"
        android:layout_marginTop="40dp"
        android:text="Установка соединения..."
        android:textColor="#FFFFFF"
        android:textSize="20sp"
        android:textStyle="bold" />

    <TextView
        android:id="@+id/textViewCallerName"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_below="@id/textViewCallStatus"
        android:layout_centerHorizontal="true"
        android:layout_marginTop="10dp"
        android:text="Имя пользователя"
        android:textColor="#ECF0F1"
        android:textSize="16sp" />

    <ImageButton
        android:id="@+id/buttonToggleMute"
        android:layout_width="70dp"
        android:layout_height="70dp"
        android:layout_above="@id/hangup_button"
        android:layout_centerHorizontal="true"
        android:layout_marginBottom="20dp"
        android:background="@drawable/circle_gray"
        android:src="@drawable/ic_mic"
        android:tint="#FFFFFF"
        android:contentDescription="Включить/выключить микрофон" />

    <ImageButton
        android:id="@+id/hangup_button"
        android:layout_width="90dp"
        android:layout_height="90dp"
        android:layout_alignParentBottom="true"
        android:layout_centerHorizontal="true"
        android:layout_marginBottom="40dp"
        android:background="@drawable/circle_red"
        android:src="@android:drawable/ic_menu_close_clear_cancel"
        android:tint="#FFFFFF"
        android:contentDescription="Завершить вызов" />

</RelativeLayout>
