#!/bin/bash
echo "🔧 Исправление ошибки с отсутствующей AuthActivity в манифесте..."

# 1. Проверка наличия AuthActivity.kt
echo "🔍 Проверка наличия AuthActivity.kt..."
if [ ! -f "app/src/main/java/com/example/mymessenger/AuthActivity.kt" ]; then
    echo "⚠️ Файл AuthActivity.kt не найден, создаем его..."
    
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
                    startActivity(Intent(this, MainActivity::class.java))
                    finish()
                } else {
                    // Ошибка аутентификации
                    Toast.makeText(this, "Ошибка аутентификации", Toast.LENGTH_SHORT).show()
                    finish()
                }
            }
    }
}
