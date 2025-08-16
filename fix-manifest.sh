#!/bin/bash
echo "🔧 Исправление AndroidManifest.xml..."

# 1. Создаем резервную копию поврежденного манифеста
echo "🔧 Создание резервной копии манифеста..."
cp app/src/main/AndroidManifest.xml app/src/main/AndroidManifest.xml.bak
echo "✅ Резервная копия сохранена"

# 2. Создаем новый, корректный AndroidManifest.xml
echo "🔧 Создание нового AndroidManifest.xml..."
cat > app/src/main/AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

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
            android:name=".CallActivity"
            android:exported="false">
        </activity>
    </application>

</manifest>
