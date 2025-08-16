#!/bin/bash
echo "🔧 Финальное исправление ошибки с AuthActivity..."

# 1. Создание AuthActivity.kt (если отсутствует)
echo "🔧 Создание AuthActivity.kt..."
mkdir -p app/src/main/java/com/example/mymessenger
cat > app/src/main/java/com/example/mymessenger/AuthActivity.kt << 'EOF'
package com.example.mymessenger

import android.content.Intent
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
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

    // Регистрация обработчика для результатов активности
    private val signInResultLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
            try {
                // Успешный вход Google
                val account = task.getResult(ApiException::class.java)
                firebaseAuthWithGoogle(account)
            } catch (e: ApiException) {
                // Ошибка входа
                finish()
            }
        }
    }

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
        signInResultLauncher.launch(signInIntent)
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
                    finish()
                }
            }
    }
}
