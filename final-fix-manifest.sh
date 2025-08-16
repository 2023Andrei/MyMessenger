#!/bin/bash
echo "🔧 Финальное исправление AndroidManifest.xml..."

# 1. Проверка и восстановление AndroidManifest.xml
echo "🔧 Проверка AndroidManifest.xml..."
if [ ! -f "app/src/main/AndroidManifest.xml" ]; then
    echo "❌ Файл AndroidManifest.xml не найден, создаем заново..."
    
    # Создаем директорию, если не существует
    mkdir -p app/src/main
    
    cat > app/src/main/AndroidManifest.xml << 'EOF'
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
