package com.example.mymessenger

import android.os.Bundle
import android.util.Log
import android.view.SurfaceView
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import org.webrtc.*
import org.webrtc.PeerConnection.IceServer
import java.util.*

class CallActivity : AppCompatActivity() {

    private var peerConnection: PeerConnection? = null
    private var localVideoView: SurfaceViewRenderer? = null
    private var remoteVideoView: SurfaceViewRenderer? = null
    private var localVideoTrack: VideoTrack? = null
    private var localAudioTrack: AudioTrack? = null
    private var peerConnectionFactory: PeerConnectionFactory? = null

        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_call)

        // Инициализация WebRTC
        initializeWebRTC()

        // Настройка интерфейса
        setupUI()
    }

    private fun initializeWebRTC() {
        // Инициализация PeerConnectionFactory
        val initializationOptions = PeerConnectionFactory.InitializationOptions.builder(this)
            .createInitializationOptions()
        PeerConnectionFactory.initialize(initializationOptions)

        // Создание PeerConnectionFactory
        peerConnectionFactory = PeerConnectionFactory.builder().createPeerConnectionFactory()

        // Создание аудио и видео источников
        val videoSource = peerConnectionFactory?.createVideoSource(false)
        val audioSource = peerConnectionFactory?.createAudioSource(MediaConstraints())
        localVideoTrack = peerConnectionFactory?.createVideoTrack("video", videoSource)
        localAudioTrack = peerConnectionFactory?.createAudioTrack("audio", audioSource)

        // Настройка SurfaceView для локального и удаленного видео
        localVideoView = findViewById<SurfaceViewRenderer>(R.id.local_video_view).apply {
            init(EglBase.create().eglBaseContext, null)
            setEnableHardwareScaler(true)
            setMirror(true)
        }

        remoteVideoView = findViewById<SurfaceViewRenderer>(R.id.remote_video_view).apply {
            init(EglBase.create().eglBaseContext, null)
            setEnableHardwareScaler(true)
        }

        // Отображение локального видео
        localVideoTrack?.addSink(localVideoView)

        // Создание и настройка PeerConnection
        peerConnection = createPeerConnection()
    }

    private fun setupUI() {
        findViewById<View>(R.id.hangup_button).setOnClickListener {
            finish()
        }
    }

    private fun createPeerConnection(): PeerConnection? {
        val iceServers = listOf(
            IceServer.builder("stun:stun.l.google.com:19302").createIceServer()
        )

        val rtcConfig = PeerConnection.RTCConfiguration(iceServers)
        rtcConfig.tcpCandidatePolicy = PeerConnection.TcpCandidatePolicy.DISABLED
        rtcConfig.bundlePolicy = PeerConnection.BundlePolicy.MAXBUNDLE
        rtcConfig.rtcpMuxPolicy = PeerConnection.RtcpMuxPolicy.REQUIRE
        rtcConfig.continualGatheringPolicy = PeerConnection.ContinualGatheringPolicy.GATHER_CONTINUALLY
        rtcConfig.keyType = PeerConnection.KeyType.ECDSA

        return peerConnectionFactory?.createPeerConnection(
            rtcConfig,
            object : PeerConnection.Observer {
                override fun onIceCandidate(candidate: IceCandidate) {
                    Log.d("CallActivity", "ICE кандидат: ${candidate.sdp}")
                }
                override fun onAddStream(stream: MediaStream) {
                    // Отображаем удаленный видеопоток
                    if (stream.videoTracks.size > 0) {
                        stream.videoTracks[0].addSink(remoteVideoView)
                    }
                }
                // Другие методы Observer...
                override fun onSignalingChange(state: PeerConnection.SignalingState) {}
                override fun onIceConnectionChange(state: PeerConnection.IceConnectionState) {}
                override fun onIceConnectionReceivingChange(receiving: Boolean) {}
                override fun onIceGatheringChange(state: PeerConnection.IceGatheringState) {}
                override fun onIceCandidatesRemoved(candidates: Array<out IceCandidate>) {}
                override fun onRemoveStream(stream: MediaStream) {}
                override fun onDataChannel(channel: DataChannel) {}
                override fun onRenegotiationNeeded() {}
                override fun onAddTrack(receiver: RtpReceiver, mediaStreams: Array<out MediaStream>) {}
            })
    }

    override fun onDestroy() {
        peerConnection?.close()
        peerConnection = null
        super.onDestroy()
    }
}
