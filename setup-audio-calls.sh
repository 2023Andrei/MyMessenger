#!/bin/bash
echo "🔧 Настройка аудио звонков в мессенджере..."

# 1. Проверка и добавление необходимых разрешений
echo "🔧 Проверка необходимых разрешений для аудио звонков..."
if ! grep -q "RECORD_AUDIO" app/src/main/AndroidManifest.xml; then
    sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.RECORD_AUDIO" />' app/src/main/AndroidManifest.xml
    echo "✅ Добавлено разрешение RECORD_AUDIO"
fi

if ! grep -q "MODIFY_AUDIO_SETTINGS" app/src/main/AndroidManifest.xml; then
    sed -i '/<uses-permission/a \    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />' app/src/main/AndroidManifest.xml
    echo "✅ Добавлено разрешение MODIFY_AUDIO_SETTINGS"
fi

# 2. Проверка и добавление AudioCallActivity в манифест
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

# 3. Создание layout для AudioCallActivity
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
        android:src="@android:drawable/ic_mic_off"
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
