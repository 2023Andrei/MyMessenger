#!/bin/bash
echo "🔑 Включение Google-аутентификации в Firebase..."

# 1. Проверка авторизации в Firebase CLI
echo "🔍 Проверка авторизации в Firebase CLI..."
if ! firebase login:list | grep -q "logged in"; then
    echo "⚠️ Вы не авторизованы в Firebase CLI. Выполняем вход..."
    firebase login --no-localhost
    if [ $? -ne 0 ]; then
        echo "❌ Ошибка авторизации в Firebase CLI"
        echo "Пожалуйста, следуйте инструкциям:"
        echo "1. Скопируйте session ID из терминала"
        echo "2. Перейдите по ссылке в браузере"
        echo "3. Введите session ID на странице авторизации"
        echo "4. Скопируйте код аутентификации и введите его в терминал"
        echo "Попробуйте снова выполнить: firebase login --no-localhost"
        exit 1
    fi
fi
echo "✅ Вы авторизованы в Firebase CLI"

# 2. Выбор проекта Firebase
echo "🔧 Выбор проекта Firebase..."
if [ -z "$(firebase projects:list --json | jq -r '.projects[].projectId')" ]; then
    echo "❌ Не найдено ни одного проекта Firebase"
    echo "1. Перейдите в https://console.firebase.google.com/"
    echo "2. Создайте новый проект"
    echo "3. Возвращайтесь к этому скрипту"
    exit 1
fi

# Отображаем список проектов
firebase projects:list

# Запрашиваем выбор проекта
read -p "Введите ID проекта Firebase, в котором нужно включить Google-аутентификацию: " projectId

# Сохраняем выбор проекта
firebase use $projectId --add
echo "✅ Выбран проект: $projectId"

# 3. Проверка существования проекта
echo "🔍 Проверка существования проекта..."
if ! firebase projects:list | grep -q "$projectId"; then
    echo "❌ Проект $projectId не найден"
    echo "Проверьте правильность введенного ID"
    exit 1
fi

# 4. Включение Google-аутентификации через REST API (без закрытия терминала)
echo "🔧 Включение Google-аутентификации через REST API..."
echo "ℹ️ Этот метод безопасен и не требует оставлять терминал открытым"

# Получаем токен доступа
accessToken=$(firebase login:ci --no-localhost 2>/dev/null | grep -v "https://")

# Проверяем, получен ли токен
if [ -z "$accessToken" ]; then
    echo "⚠️ Не удалось получить токен доступа автоматически"
    echo "Выполняем ручной процесс:"
    echo "1. Выполните в новом терминале: firebase login:ci"
    echo "2. Следуйте инструкциям для получения токена"
    echo "3. Скопируйте токен и вставьте его ниже"
    read -sp "Введите токен Firebase: " accessToken
    echo
fi

# Включаем Google-аутентификацию
echo "🔄 Включение Google-аутентификации для проекта $projectId..."
curl -s -o /dev/null -w "%{http_code}" -X PATCH \
  -H "Authorization: Bearer $accessToken" \
  -H "Content-Type: application/json" \
  -d '{
    "config": {
      "signIn": {
        "allowDuplicateEmails": false,
        "email": {
          "enabled": true,
          "passwordRequired": true
        },
        "phoneNumber": {
          "enabled": false
        },
        "anonymous": {
          "enabled": false
        },
        "apple": {
          "enabled": false
        },
        "facebook": {
          "enabled": false
        },
        "github": {
          "enabled": false
        },
        "google": {
          "enabled": true
        },
        "microsoft": {
          "enabled": false
        },
        "playGames": {
          "enabled": false
        },
        "twitter": {
          "enabled": false
        },
        "yahoo": {
          "enabled": false
        }
      }
    }
  }' "https://identitytoolkit.googleapis.com/admin/v2/projects/$projectId/config" > /tmp/firebase_auth_status.txt

# Проверяем результат
authStatus=$(cat /tmp/firebase_auth_status.txt)
rm /tmp/firebase_auth_status.txt

if [ "$authStatus" = "200" ]; then
    echo "✅ Google-аутентификация успешно включена для проекта $projectId!"
    echo "---------------------------------------------------"
    echo "Теперь вы можете:"
    echo "1. Добавить Google-аутентификацию в ваш мессенджер"
    echo "2. Проверить настройки в Firebase Console:"
    echo "   https://console.firebase.google.com/project/$projectId/authentication/providers"
    echo "3. Протестировать вход через Google в вашем приложении"
else
    echo "❌ Ошибка при включении Google-аутентификации (HTTP статус: $authStatus)"
    echo "Попробуйте выполнить следующие действия:"
    echo "1. Убедитесь, что у вас есть права администратора для проекта"
    echo "2. Проверьте правильность ID проекта"
    echo "3. Вручную включите Google-аутентификацию в Firebase Console:"
    echo "   a) Перейдите в https://console.firebase.google.com/"
    echo "   b) Выберите проект $projectId"
    echo "   c) Перейдите в раздел Authentication → Sign-in method"
    echo "   d) Найдите Google в списке провайдеров и нажмите 'Включить'"
fi

# 5. Добавление кода для Google-аутентификации в приложение
echo -e "\n🔧 Добавление кода Google-аутентификации в приложение..."
if ! grep -q "implementation(\"com.google.firebase:firebase-auth" app/build.gradle.kts; then
    sed -i '/implementation("com.infobip:google-webrtc:1.0.35530")/a \    implementation("com.google.firebase:firebase-auth:22.3.0")' app/build.gradle.kts
    echo "✅ Зависимость Firebase Auth добавлена"
fi

cat > app/src/main/java/com/example/mymessenger/AuthActivity.kt << 'EOF'
package com.example.mymessenger

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase

class AuthActivity : AppCompatActivity() {

    private lateinit var auth: FirebaseAuth
    private lateinit var googleSignInClient: GoogleSignInClient
    private val RC_SIGN_IN = 9001

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Инициализация Firebase
        auth = FirebaseAuth.getInstance()
        
        // Проверка текущего состояния аутентификации
        if (auth.currentUser != null) {
            // Пользователь уже вошел, перейти к основному экрану
            startActivity(Intent(this, MainActivity::class.java))
            finish()
            return
        }
        
        // Настройка Google Sign In
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(getString(R.string.default_web_client_id))
            .requestEmail()
            .build()
            
        googleSignInClient = GoogleSignIn.getClient(this, gso)
        
        // Запуск процесса входа
        signInWithGoogle()
    }

    private fun signInWithGoogle() {
        val signInIntent = googleSignInClient.signInIntent
        startActivityForResult(signInIntent, RC_SIGN_IN)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        // Результат, возвращенный из Intent signIn
        if (requestCode == RC_SIGN_IN) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(data)
            try {
                // Успешный вход Google
                val account = task.getResult(ApiException::class.java)
                firebaseAuthWithGoogle(account)
            } catch (e: ApiException) {
                // Ошибка входа
                Toast.makeText(this, "Ошибка входа: ${e.statusCode}", Toast.LENGTH_SHORT).show()
                finish()
            }
        }
    }

    private fun firebaseAuthWithGoogle(acct: GoogleSignInAccount) {
        val credential = GoogleAuthProvider.getCredential(acct.idToken, null)
        auth.signInWithCredential(credential)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    // Аутентификация успешна
                    saveUserToFirestore(acct)
                    startActivity(Intent(this, MainActivity::class.java))
                    finish()
                } else {
                    // Ошибка аутентификации
                    Toast.makeText(this, "Ошибка аутентификации", Toast.LENGTH_SHORT).show()
                    finish()
                }
            }
    }

    private fun saveUserToFirestore(acct: GoogleSignInAccount) {
        val user = hashMapOf(
            "uid" to auth.currentUser?.uid,
            "email" to acct.email,
            "displayName" to acct.displayName,
            "photoUrl" to acct.photoUrl?.toString()
        )

        Firebase.firestore.collection("users")
            .document(auth.currentUser?.uid ?: "")
            .set(user)
    }
}
