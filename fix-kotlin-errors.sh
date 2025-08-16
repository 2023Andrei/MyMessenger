#!/bin/bash
echo "🔧 Исправление ошибок компиляции Kotlin..."

# 1. Проверка наличия google-services.json
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

# 2. Обновление Android Gradle Plugin и SDK
echo "🔧 Обновление Android Gradle Plugin и SDK..."
sed -i 's|id("com.android.application") version "8.1.0"|id("com.android.application") version "8.2.2"|' build.gradle.kts
sed -i 's|compileSdk = 33|compileSdk = 34|' app/build.gradle.kts
sed -i 's|targetSdk = 33|targetSdk = 34|' app/build.gradle.kts
echo "✅ Android Gradle Plugin и SDK обновлены"

# 3. Использование Firebase BOM
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

# Добавляем Firebase BOM
cat << 'EOT' >> temp_deps.txt
    // Используем Firebase BOM для согласования версий
    implementation(platform("com.google.firebase:firebase-bom:33.1.1"))
    
    // Добавляем только нужные Firebase зависимости
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
EOT
sed -i '/implementation("com.infobip:google-webrtc:1.0.35530")/r temp_deps.txt' app/build.gradle.kts
rm temp_deps.txt
echo "✅ Firebase BOM добавлен"

# 4. Исправление MainActivity.kt
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
