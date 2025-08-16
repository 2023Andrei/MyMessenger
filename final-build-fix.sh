#!/bin/bash
echo "🔧 Финальное исправление сборки проекта..."

# 1. Увеличение лимита памяти для Gradle
echo "🔧 Увеличение лимита памяти для Gradle..."
if [ ! -f "gradle.properties" ]; then
    touch gradle.properties
fi

# Удаляем старые настройки памяти
sed -i '/org.gradle.jvmargs/d' gradle.properties

# Добавляем новые настройки с увеличенным лимитом памяти
echo "org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8" >> gradle.properties
echo "✅ Лимит памяти для Gradle увеличен до 4 ГБ"

# 2. Проверка наличия google-services.json
echo "🔍 Проверка google-services.json..."
if [ ! -f "app/google-services.json" ]; then
    echo "⚠️ Файл google-services.json не найден"
    echo "Попробуем скопировать из Загрузок..."
    cp /home/and/Загрузки/google-services.json app/ 2>/dev/null || \
    cp ~/Downloads/google-services.json app/ 2>/dev/null
    
    if [ ! -f "app/google-services.json" ]; then
        echo "❌ Файл google-services.json не найден ни в одном месте"
        echo "Скачайте его из Firebase Console и поместите в папку app/"
        exit 1
    fi
fi
echo "✅ Файл google-services.json найден"

# 3. Обновление Android Gradle Plugin и SDK
echo "🔧 Обновление Android Gradle Plugin и SDK..."
sed -i 's|id("com.android.application") version "8.1.0"|id("com.android.application") version "8.2.2"|' build.gradle.kts
sed -i 's|compileSdk = 33|compileSdk = 34|' app/build.gradle.kts
sed -i 's|targetSdk = 33|targetSdk = 34|' app/build.gradle.kts
echo "✅ Android Gradle Plugin и SDK обновлены"

# 4. Установка необходимых компонентов Android SDK
echo "🔧 Установка необходимых компонентов Android SDK..."
if ! sdkmanager --list | grep -q "build-tools;34.0.0"; then
    echo "🔧 Установка Android SDK Build-Tools 34.0.0..."
    sdkmanager "build-tools;34.0.0"
fi

if ! sdkmanager --list | grep -q "platforms;android-34"; then
    echo "🔧 Установка Android SDK Platform 34..."
    sdkmanager "platforms;android-34"
fi
echo "✅ Необходимые компоненты Android SDK установлены"

# 5. Использование Firebase BOM для согласования версий
echo "🔧 Использование Firebase BOM для согласования версий..."
sed -i '/firebase-/d' app/build.gradle.kts
sed -i '/com.google.gms.google-services/d' app/build.gradle.kts

# Добавляем плагин Google Services
if ! grep -q "com.google.gms.google-services" app/build.gradle.kts; then
    if grep -q "plugins {" app/build.gradle.kts; then
        sed -i '/plugins {/a \    id("com.google.gms.google-services") version "4.4.0"' app/build.gradle.kts
    else
        sed -i '1i plugins {\n    id("com.google.gms.google-services") version "4.4.0"\n}' app/build.gradle.kts
    fi
    echo "✅ Плагин Google Services добавлен"
fi

# Добавляем Firebase BOM и необходимые зависимости
cat << 'EOT' > temp_deps.txt
    // Используем Firebase BOM для согласования версий
    implementation(platform("com.google.firebase:firebase-bom:33.1.1"))
    
    // Добавляем только нужные Firebase зависимости
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
    
    // Добавляем Google Play Services Auth для Google Sign In
    implementation("com.google.android.gms:play-services-auth:20.7.0")
EOT
sed -i '/implementation("com.infobip:google-webrtc:1.0.35530")/r temp_deps.txt' app/build.gradle.kts
rm temp_deps.txt
echo "✅ Firebase BOM и зависимости добавлены"

# 6. Исправление MainActivity.kt
echo "🔧 Исправление MainActivity.kt..."
cat > app/src/main/java/com/example/mymessenger/MainActivity.kt << 'EOF'
package com.example.mymessenger

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.auth.FirebaseAuth

class MainActivity : AppCompatActivity() {
    
    private lateinit var auth: FirebaseAuth

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Инициализация Firebase
        auth = FirebaseAuth.getInstance()
        
        // Проверка аутентификации
        if (auth.currentUser == null) {
            startActivity(Intent(this, AuthActivity::class.java))
            finish()
            return
        }

        val editTextMessage = findViewById<EditText>(R.id.editTextMessage)
        val buttonSend = findViewById<Button>(R.id.buttonSend)
        val buttonCall = findViewById<Button>(R.id.buttonCall)
        val textViewMessages = findViewById<TextView>(R.id.textViewMessages)

        val messages = mutableListOf<String>()

        buttonSend.setOnClickListener {
            val text = editTextMessage.text.toString().trim()
            if (text.isNotEmpty()) {
                messages.add("Вы: $text")
                textViewMessages.text = messages.joinToString("\n")
                editTextMessage.text.clear()
            }
        }

        buttonCall.setOnClickListener {
            val intent = Intent(this, CallActivity::class.java)
            startActivity(intent)
        }
    }
}
