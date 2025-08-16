#!/bin/bash
echo "📞 Добавление звонков в мессенджер..."

# 1. Убедимся, что репозиторий Google добавлен в settings.gradle.kts
echo "🔧 Проверка settings.gradle.kts..."
if ! grep -q "google()" settings.gradle.kts; then
    sed -i '/repositories {/a \        google()' settings.gradle.kts
fi

# 2. Добавляем зависимости WebRTC
echo "🔧 Обновление build.gradle.kts..."
sed -i '/implementation("androidx.constraintlayout:constraintlayout:2.1.4")/a \    implementation("org.webrtc:google-webrtc:1.0.+")' app/build.gradle.kts

# 3. Добавляем разрешения в AndroidManifest.xml
echo "🔧 Обновление AndroidManifest.xml..."
if ! grep -q "CAMERA" app/src/main/AndroidManifest.xml; then
    sed -i '/<uses-permission android:name="android.permission.RECORD_AUDIO" \/>/a \    <uses-permission android:name="android.permission.CAMERA" \/>' app/src/main/AndroidManifest.xml
fi
if ! grep -q "MODIFY_AUDIO_SETTINGS" app/src/main/AndroidManifest.xml; then
    sed -i '/<uses-permission android:name="android.permission.RECORD_AUDIO" \/>/a \    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" \/>' app/src/main/AndroidManifest.xml
fi

# 4. Создаем CallActivity.kt
echo "🔧 Создание CallActivity.kt..."
mkdir -p app/src/main/java/com/example/mymessenger/
cat > app/src/main/java/com/example/mymessenger/CallActivity.kt << 'EOL'
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

    override fun onCreate(savedInstanceState: Bundle?) {
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
        val peerConnectionFactory = PeerConnectionFactory.builder().createPeerConnectionFactory()

        // Создание аудио и видео источников
        val videoSource = peerConnectionFactory.createVideoSource(false)
        val audioSource = peerConnectionFactory.createAudioSource(MediaConstraints())
        localVideoTrack = peerConnectionFactory.createVideoTrack("video", videoSource)
        localAudioTrack = peerConnectionFactory.createAudioTrack("audio", audioSource)

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
        localVideoTrack?.addSink(object : VideoSink {
            override fun onFrame(frame: VideoFrame) {
                localVideoView?.onFrame(frame)
            }
        })

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

        return peerConnectionFactory.createPeerConnection(
            rtcConfig,
            object : PeerConnection.Observer {
                override fun onIceCandidate(candidate: IceCandidate) {
                    Log.d("CallActivity", "ICE кандидат: ${candidate.sdp}")
                }
                override fun onAddStream(stream: MediaStream) {
                    if (stream.videoTracks.size > 0) {
                        remoteVideoView?.onFrame(stream.videoTracks[0].frame)
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
EOL

# 5. Создаем layout для звонка
echo "🔧 Создание activity_call.xml..."
mkdir -p app/src/main/res/layout/
cat > app/src/main/res/layout/activity_call.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <org.webrtc.SurfaceViewRenderer
        android:id="@+id/remote_video_view"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />

    <org.webrtc.SurfaceViewRenderer
        android:id="@+id/local_video_view"
        android:layout_width="120dp"
        android:layout_height="160dp"
        android:layout_alignParentEnd="true"
        android:layout_alignParentTop="true"
        android:layout_margin="16dp" />

    <ImageButton
        android:id="@+id/hangup_button"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_centerInParent="true"
        android:background="@drawable/circle_red"
        android:src="@android:drawable/ic_menu_close_clear_cancel"
        android:tint="#FFFFFF"
        android:padding="16dp"
        android:contentDescription="Завершить вызов" />

</RelativeLayout>
EOL

# 6. Создаем drawable для кнопки
echo "🔧 Создание circle_red.xml..."
mkdir -p app/src/main/res/drawable/
cat > app/src/main/res/drawable/circle_red.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android"
    android:shape="oval">
    <solid android:color="#FF0000" />
</shape>
EOL

# 7. Обновляем MainActivity для запуска звонков
echo "🔧 Обновление MainActivity.kt..."
if ! grep -q "CallActivity" app/src/main/java/com/example/mymessenger/MainActivity.kt; then
    sed -i '/buttonCall.setOnClickListener {/a \            val intent = Intent(this, CallActivity::class.java)\n            startActivity(intent)' app/src/main/java/com/example/mymessenger/MainActivity.kt
fi

# 8. Добавляем активность в манифест
echo "🔧 Обновление AndroidManifest.xml..."
if ! grep -q "CallActivity" app/src/main/AndroidManifest.xml; then
    sed -i '/<application/a \        <activity\n            android:name=".CallActivity"\n            android:exported="false">\n        <\/activity>' app/src/main/AndroidManifest.xml
fi

# 9. Сборка проекта
echo "🔧 Сборка проекта с поддержкой звонков..."
./gradlew clean assembleDebug

if [ $? -eq 0 ]; then
    echo -e "\n✅ Звонки успешно добавлены!"
    echo "---------------------------------------------------"
    echo "Готовый APK: app/build/outputs/apk/debug/app-debug.apk"
    echo "1. Установите новый APK на телефон"
    echo "2. Откройте приложение и нажмите 'Позвонить'"
    echo "3. Для полноценной работы звонков:"
    echo "   - Настройте Firebase для чата"
    echo "   - Разверните сигнальный сервер (можно бесплатно на Render.com)"
else
    echo -e "\n❌ Ошибка при сборке проекта"
    echo "---------------------------------------------------"
    echo "Возможные причины:"
    echo "1. Нет подключения к интернету для загрузки зависимостей"
    echo "2. Проблемы с репозиторием Google для WebRTC"
    echo "3. Ошибки в коде"
    echo -e "\nРешение:"
    echo "1. Проверьте интернет-соединение"
    echo "2. Убедитесь, что в settings.gradle.kts есть 'google()'"
    echo "3. Запустите сборку с подробным выводом: ./gradlew assembleDebug --info"
fi
