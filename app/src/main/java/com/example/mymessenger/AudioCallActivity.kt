package com.example.mymessenger

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.example.mymessenger.databinding.ActivityAudioCallBinding

class AudioCallActivity : AppCompatActivity() {
    private lateinit var binding: ActivityAudioCallBinding

        super.onCreate(savedInstanceState)
        binding = ActivityAudioCallBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.endCallButton.setOnClickListener {
            finish()
        }
    }
}
