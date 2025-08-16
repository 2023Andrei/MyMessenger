package com.example.mymessenger.call

import android.content.Context
import org.webrtc.*

class CallManager(
    private val context: Context,
    private val currentUserId: String
) {
    private var peerConnectionFactory: PeerConnectionFactory? = null
    private var peerConnection: PeerConnection? = null

    fun initialize() {
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .createInitializationOptions()
        )
        
        peerConnectionFactory = PeerConnectionFactory.builder()
            .createPeerConnectionFactory()
    }

        val iceServers = listOf(
            PeerConnection.IceServer.builder("stun:stun.l.google.com:19302")
                .createIceServer()
        )
        
        peerConnection = peerConnectionFactory?.createPeerConnection(
            iceServers,
            object : PeerConnection.Observer() {
                override fun onIceCandidate(candidate: IceCandidate) {
                    // Отправляем кандидата через Firebase
                }
                
                override fun onAddStream(stream: MediaStream) {
                    // Обработка добавления потока
                }
            }
        )
    }

    fun endCall() {
        peerConnection?.close()
        peerConnection = null
    }
}
