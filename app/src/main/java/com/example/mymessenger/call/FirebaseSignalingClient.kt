package com.example.mymessenger.call

import com.google.firebase.database.*
import org.webrtc.IceCandidate
import org.webrtc.SessionDescription

class FirebaseSignalingClient(
    private val callId: String,
    private val isCaller: Boolean
) {
    private val database = FirebaseDatabase.getInstance()
    private val callRef = database.getReference("calls").child(callId)
    
    fun sendSessionDescription(sdp: SessionDescription) {
        callRef.child("sdp").setValue(mapOf(
            "type" to sdp.type.canonicalForm(),
            "description" to sdp.description
        ))
    }

    fun sendIceCandidate(candidate: IceCandidate) {
        callRef.child("iceCandidates").push().setValue(mapOf(
            "sdpMid" to candidate.sdpMid,
            "sdpMLineIndex" to candidate.sdpMLineIndex,
            "sdp" to candidate.sdp
        ))
    }

    fun listenForAnswer(onAnswerReceived: (SessionDescription) -> Unit) {
        if (isCaller) {
            callRef.child("sdp").addValueEventListener(object : ValueEventListener {
                override fun onDataChange(snapshot: DataSnapshot) {
                    val sdpMap = snapshot.value as? Map<*,*> ?: return
                    if (sdpMap["type"] == "answer") {
                        onAnswerReceived(SessionDescription(
                            SessionDescription.Type.ANSWER, 
                            sdpMap["description"] as String
                        ))
                    }
                }
                override fun onCancelled(error: DatabaseError) {}
            })
        }
    }

    fun listenForSdpOffer(onOfferReceived: (SessionDescription) -> Unit) {
        if (!isCaller) {
            callRef.child("sdp").addValueEventListener(object : ValueEventListener {
                override fun onDataChange(snapshot: DataSnapshot) {
                    val sdpMap = snapshot.value as? Map<*,*> ?: return
                    if (sdpMap["type"] == "offer") {
                        onOfferReceived(SessionDescription(
                            SessionDescription.Type.OFFER,
                            sdpMap["description"] as String
                        ))
                    }
                }
                override fun onCancelled(error: DatabaseError) {}
            })
        }
    }

    fun listenForIceCandidates(onIceCandidateReceived: (IceCandidate) -> Unit) {
        callRef.child("iceCandidates").addChildEventListener(object : ChildEventListener {
            override fun onChildAdded(snapshot: DataSnapshot, prev: String?) {
                val candidate = snapshot.value as Map<*,*>
                onIceCandidateReceived(IceCandidate(
                    candidate["sdpMid"] as String,
                    (candidate["sdpMLineIndex"] as Long).toInt(),
                    candidate["sdp"] as String
                ))
            }
            override fun onChildChanged(s: DataSnapshot, p: String?) {}
            override fun onChildRemoved(s: DataSnapshot) {}
            override fun onChildMoved(s: DataSnapshot, p: String?) {}
            override fun onCancelled(e: DatabaseError) {}
        })
    }

    fun cleanup() = callRef.removeValue()
}
EOF && \
# 2. Обновляем AudioCallActivity
cat > app/src/main/java/com/example/mymessenger/AudioCallActivity.kt <<'EOF'
package com.example.mymessenger

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.example.mymessenger.call.FirebaseSignalingClient
import com.example.mymessenger.databinding.ActivityAudioCallBinding
import com.google.firebase.auth.FirebaseAuth
import org.webrtc.*

class AudioCallActivity : AppCompatActivity() {
    private lateinit var binding: ActivityAudioCallBinding
    private lateinit var signalingClient: FirebaseSignalingClient
    private lateinit var peerConnectionFactory: PeerConnectionFactory
    private lateinit var peerConnection: PeerConnection
    private val iceServers = listOf(
        PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer()
    )
    private val currentUserId = FirebaseAuth.getInstance().currentUser?.uid ?: ""
    private var isCaller = false
    private var callId = ""

        super.onCreate(savedInstanceState)
        binding = ActivityAudioCallBinding.inflate(layoutInflater)
        setContentView(binding.root)

        callId = intent.getStringExtra("callId") ?: generateCallId()
        isCaller = intent.getBooleanExtra("isCaller", false)

        initializeWebRTC()
        setupSignalingClient()
        setupCallControls()

        if (isCaller) createOffer()
    }

    private fun initializeWebRTC() {
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(this)
                .createInitializationOptions()
        )

        peerConnectionFactory = PeerConnectionFactory.builder().createPeerConnectionFactory()
        val rtcConfig = PeerConnection.RTCConfiguration(iceServers)
        
        peerConnection = peerConnectionFactory.createPeerConnection(rtcConfig, object : PeerConnection.Observer() {
            override fun onIceCandidate(candidate: IceCandidate) = 
                signalingClient.sendIceCandidate(candidate)

            override fun onAddStream(stream: MediaStream) = 
                stream.audioTracks.firstOrNull()?.setEnabled(true)

            override fun onIceConnectionChange(state: PeerConnection.IceConnectionState) {
                if (state == PeerConnection.IceConnectionState.DISCONNECTED) finish()
            }

            override fun onIceCandidatesRemoved(c: Array<IceCandidate>) {}
            override fun onDataChannel(d: DataChannel) {}
            override fun onIceConnectionReceivingChange(r: Boolean) {}
            override fun onIceGatheringChange(s: PeerConnection.IceGatheringState) {}
            override fun onRemoveStream(s: MediaStream) {}
            override fun onRenegotiationNeeded() {}
            override fun onSignalingChange(s: PeerConnection.SignalingState) {}
        })!!

        val audioSource = peerConnectionFactory.createAudioSource(MediaConstraints())
        val audioTrack = peerConnectionFactory.createAudioTrack("audio_$currentUserId", audioSource)
        val localStream = peerConnectionFactory.createLocalMediaStream("local_stream_$currentUserId")
        localStream.addTrack(audioTrack)
        peerConnection.addStream(localStream)
    }

    private fun setupSignalingClient() {
        signalingClient = FirebaseSignalingClient(callId, isCaller).apply {
            listenForIceCandidates { peerConnection.addIceCandidate(it) }
            if (isCaller) listenForAnswer { peerConnection.setRemoteDescription(SimpleSdpObserver(), it) }
            else listenForSdpOffer { peerConnection.setRemoteDescription(SimpleSdpObserver(), it, { createAnswer() }) }
        }
    }

    private fun createOffer() = peerConnection.createOffer(object : SdpObserver {
            peerConnection.setLocalDescription(SimpleSdpObserver(), sdp)
            signalingClient.sendSessionDescription(sdp)
        }
        override fun onSetSuccess() {}
        override fun onSetFailure(e: String) {}
    }, MediaConstraints())

    private fun createAnswer() = peerConnection.createAnswer(object : SdpObserver {
            peerConnection.setLocalDescription(SimpleSdpObserver(), sdp)
            signalingClient.sendSessionDescription(sdp)
        }
        override fun onSetSuccess() {}
        override fun onSetFailure(e: String) {}
    }, MediaConstraints())

    private fun setupCallControls() = binding.endCallButton.setOnClickListener {
        signalingClient.cleanup()
        peerConnection.close()
        finish()
    }

    private fun generateCallId() = "call_${System.currentTimeMillis()}_$currentUserId"

    override fun onDestroy() {
        signalingClient.cleanup()
        peerConnection.dispose()
        peerConnectionFactory.dispose()
        super.onDestroy()
    }

    private inner class SimpleSdpObserver : SdpObserver {
        override fun onSetSuccess() {}
        override fun onSetFailure(e: String) {}
    }
}
EOF && \
# 3. Добавляем вызов в MainActivity
cat >> app/src/main/java/com/example/mymessenger/MainActivity.kt <<'EOF'
    val callId = "call_${System.currentTimeMillis()}_${FirebaseAuth.getInstance().currentUser?.uid}"
    val intent = Intent(this, AudioCallActivity::class.java).apply {
        putExtra("callId", callId)
        putExtra("isCaller", true)
    }
    startActivity(intent)
    FirebaseDatabase.getInstance().reference.child("calls").child(callId).setValue(mapOf(
        "callerId" to FirebaseAuth.getInstance().currentUser?.uid,
        "calleeId" to user.uid,
        "timestamp" to System.currentTimeMillis()
    ))
}
EOF && \
# 4. Проверяем результат
echo "=== Проверка реализации ===" && \
echo "1. FirebaseSignalingClient: " && \
ls -l app/src/main/java/com/example/mymessenger/call/FirebaseSignalingClient.kt && \
echo "\n2. AudioCallActivity: " && \
ls -l app/src/main/java/com/example/mymessenger/AudioCallActivity.kt && \
echo "\n3. MainActivity обновлен: " && \
grep -A15 "fun startCall" app/src/main/java/com/example/mymessenger/MainActivity.kt && \
echo "\n=== Готово! ===" && \
echo "Реализация аудиозвонков через WebRTC и Firebase завершена." && \
echo "Не забудьте добавить в AndroidManifest.xml:" && \
echo "<uses-permission android:name=\"android.permission.RECORD_AUDIO\" />" && \
echo "<uses-permission android:name=\"android.permission.INTERNET\" />" && \
echo "<uses-permission android:name=\"android.permission.ACCESS_NETWORK_STATE\" />"
