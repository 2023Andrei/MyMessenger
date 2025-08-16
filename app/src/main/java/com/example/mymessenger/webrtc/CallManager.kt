package com.example.mymessenger.webrtc

import android.content.Context
import org.webrtc.*
import com.google.firebase.database.FirebaseDatabase
import java.util.*

class CallManager(
    private val context: Context,
    private val currentUserId: String
) : PeerConnection.Observer {

    private val TAG = "CallManager"
    private var peerConnectionFactory: PeerConnectionFactory? = null
    private var peerConnection: PeerConnection? = null
    private val iceCandidates = mutableListOf<IceCandidate>()
    private val firebaseRef = FirebaseDatabase.getInstance().reference

    fun initialize() {
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .createInitializationOptions()
        )

        val options = PeerConnectionFactory.Options()
        peerConnectionFactory = PeerConnectionFactory.builder()
            .setOptions(options)
            .createPeerConnectionFactory()

        // Можно добавить аудио/видео источники при необходимости
    }

    fun startCall(targetUserId: String) {
        val configuration = PeerConnection.RTCConfiguration(emptyList<PeerConnection.IceServer>().apply {
            add(PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer())
            // Добавьте TURN сервер при необходимости
            // add(PeerConnection.IceServer.builder("turn:your.turn.server").setUsername("u").setPassword("p").createIceServer())
        })

        peerConnection = peerConnectionFactory?.createPeerConnection(configuration, this)

        if (peerConnection == null) {
            return
        }

        peerConnection?.createOffer(object : SdpObserver {
            override fun onOfferSuccess(desc: SessionDescription) {
                peerConnection?.setLocalDescription(object : SdpObserver {
                    override fun onSetSuccess() {
                        sendCallOffer(targetUserId, desc.description)
                    }

                    override fun onSetFailure(error: String?) {
                        // Обработка ошибки
                    }
                }, desc)
            }

            override fun onOfferFailure(error: String?) {
                // Обработка ошибки
            }
        }, MediaConstraints())
    }

    private fun sendCallOffer(targetUserId: String, offer: String) {
        val callData = hashMapOf(
            "callerId" to currentUserId,
            "recipientId" to targetUserId,
            "offer" to offer,
            "timestamp" to Date().time
        )
        firebaseRef.child("calls").child(targetUserId).setValue(callData)
    }

    override fun onSignalingChange(state: PeerConnection.SignalingState?) {}
    override fun onIceConnectionChange(state: PeerConnection.IceConnectionState?) {}
    override fun onIceConnectionReceivingChange(receiving: Boolean) {}
    override fun onIceGatheringChange(state: PeerConnection.IceGatheringState?) {}
    override fun onAddStream(stream: MediaStream?) {}
    override fun onRemoveStream(stream: MediaStream?) {}
    override fun onDataChannel(channel: DataChannel?) {}
    override fun onRenegotiationNeeded() {}
    override fun onAddTrack(receiver: RtpReceiver?, streams: Array<out MediaStream>?) {}

    override fun onIceCandidate(candidate: IceCandidate) {
        iceCandidates.add(candidate)
        firebaseRef.child("calls").child(currentUserId).child("iceCandidates")
            .push().setValue(candidate.sdp)
    }

    fun endCall() {
        firebaseRef.child("calls").child(currentUserId).removeValue()
        peerConnection?.close()
        peerConnection = null
    }
}
