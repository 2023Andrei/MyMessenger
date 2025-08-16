package com.example.mymessenger

import android.Manifest
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.RecyclerView
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.ValueEventListener
import com.google.firebase.database.ktx.database
import com.google.firebase.ktx.Firebase
import android.content.pm.PackageManager

class MainActivity : AppCompatActivity() {

    private lateinit var auth: FirebaseAuth
    private lateinit var callManager: CallManager
    private lateinit var userAdapter: UserAdapter
    private lateinit var binding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Инициализация View Binding
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Инициализация Firebase
        auth = FirebaseAuth.getInstance()

        // Проверка аутентификации
        if (auth.currentUser == null) {
            startActivity(Intent(this, AuthActivity::class.java))
            finish()
            return
        }

        // Инициализация CallManager
        callManager = CallManager(this, auth.currentUser?.uid ?: "")
        callManager.initialize()

        // Проверка разрешений
        checkPermissions()

        // Настройка UI
        setupUI()
        setupUsersList()
    }

    private fun setupUI() {
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
            startActivity(Intent(this, AudioCallActivity::class.java))
        }
    }

    private fun checkPermissions() {
        val permissions = arrayOf(
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.CAMERA
        )

        if (permissions.any { checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }) {
            requestPermissions(permissions, 123)
        }
    }

    private fun setupUsersList() {
        val usersRef = Firebase.database.reference.child("users")
        usersRef.addValueEventListener(object : ValueEventListener {
            override fun onDataChange(snapshot: DataSnapshot) {
                val users = snapshot.children.mapNotNull { 
                    it.getValue(User::class.java)
                }.filter { it.uid != auth.currentUser?.uid }

                userAdapter = UserAdapter(users) { user ->
                    startCall(user)
                }
                binding.usersRecyclerView.adapter = userAdapter
            }

            override fun onCancelled(error: DatabaseError) {
                error.toException().printStackTrace()
            }
        })
    }

    private fun startCall(user: User) {
        callManager.startCall(user.uid)
        val intent = Intent(this, CallActivity::class.java).apply {
            putExtra("targetUser", user)
        }
        startActivity(intent)
    }
}
