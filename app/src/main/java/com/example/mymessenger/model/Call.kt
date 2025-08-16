package com.example.mymessenger.model

data class Call(
    val callerId: String = "",
    val callerName: String = "",
    val type: String = "audio" // или "video"
)
