package com.example.mymessenger

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.auth.FirebaseAuth

class AuthActivity : AppCompatActivity() {

    private lateinit var auth: FirebaseAuth
    private lateinit var editTextEmail: EditText
    private lateinit var editTextPassword: EditText
    private lateinit var buttonLogin: Button
    private lateinit var buttonRegister: Button

        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_auth)
        
        // Инициализация Firebase
        auth = FirebaseAuth.getInstance()
        
        // Проверка текущего состояния аутентификации
        if (auth.currentUser != null) {
            // Пользователь уже вошел, перейти к основному экрану
            startActivity(Intent(this, MainActivity::class.java))
            finish()
            return
        }
        
        // Инициализация UI элементов
        editTextEmail = findViewById(R.id.editTextEmail)
        editTextPassword = findViewById(R.id.editTextPassword)
        buttonLogin = findViewById(R.id.buttonLogin)
        buttonRegister = findViewById(R.id.buttonRegister)
        
        // Обработка входа
        buttonLogin.setOnClickListener {
            val email = editTextEmail.text.toString().trim()
            val password = editTextPassword.text.toString().trim()
            
            if (email.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, "Пожалуйста, заполните все поля", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            
            loginUser(email, password)
        }
        
        // Обработка регистрации
        buttonRegister.setOnClickListener {
            val email = editTextEmail.text.toString().trim()
            val password = editTextPassword.text.toString().trim()
            
            if (email.isEmpty() || password.isEmpty()) {
                Toast.makeText(this, "Пожалуйста, заполните все поля", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            
            registerUser(email, password)
        }
    }
    
    private fun loginUser(email: String, password: String) {
        auth.signInWithEmailAndPassword(email, password)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    // Аутентификация успешна
                    startActivity(Intent(this, MainActivity::class.java))
                    finish()
                } else {
                    // Ошибка аутентификации
                    Toast.makeText(this, "Ошибка входа: ${task.exception?.message}", Toast.LENGTH_SHORT).show()
                }
            }
    }
    
    private fun registerUser(email: String, password: String) {
        auth.createUserWithEmailAndPassword(email, password)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    // Регистрация успешна
                    Toast.makeText(this, "Регистрация успешна", Toast.LENGTH_SHORT).show()
                    startActivity(Intent(this, MainActivity::class.java))
                    finish()
                } else {
                    // Ошибка регистрации
                    Toast.makeText(this, "Ошибка регистрации: ${task.exception?.message}", Toast.LENGTH_SHORT).show()
                }
            }
    }
}
