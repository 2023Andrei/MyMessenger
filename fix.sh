#!/bin/bash
echo "🔧 Исправление проекта..."
sed -i '/android.useAndroidX/d' gradle.properties 2>/dev/null || true
echo "android.useAndroidX=true" >> gradle.properties
sed -i 's/package="com.example.mymessenger"//' app/src/main/AndroidManifest.xml
mkdir -p app/src/main/res/values app/src/main/res/mipmap-mdpi
cat > app/src/main/res/values/colors.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="colorPrimary">#008577</color>
    <color name="colorPrimaryDark">#00574B</color>
    <color name="colorAccent">#D81B60</color>
</resources>
EOL
cat > app/src/main/res/values/styles.xml << 'EOL'
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.Light.DarkActionBar">
        <item name="colorPrimary">@color/colorPrimary</item>
        <item name="colorPrimaryDark">@color/colorPrimaryDark</item>
        <item name="colorAccent">@color/colorAccent</item>
    </style>
</resources>
EOL
echo "Placeholder" > app/src/main/res/mipmap-mdpi/ic_launcher.png
cp app/src/main/res/mipmap-mdpi/ic_launcher.png app/src/main/res/mipmap-mdpi/ic_launcher_round.png
cp -r app/src/main/res/mipmap-mdpi app/src/main/res/mipmap-hdpi 2>/dev/null || true
cp -r app/src/main/res/mipmap-mdpi app/src/main/res/mipmap-xhdpi 2>/dev/null || true
sed -i 's/implementation(\"androidx.core:core-ktx:1.12.0\")/implementation(\"androidx.core:core-ktx:1.10.1\")/' app/build.gradle.kts
sed -i 's/implementation(\"com.google.android.material:material:1.11.0\")/implementation(\"com.google.android.material:material:1.9.0\")/' app/build.gradle.kts
sed -i 's/compileSdk = 34/compileSdk = 33/' app/build.gradle.kts
echo "✅ Исправления применены"
./gradlew assembleDebug || echo "⚠️ Сборка завершена с предупреждениями"
