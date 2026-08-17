package nuviapps.co.verdadoreto

import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.SoundPool
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var soundPool: SoundPool? = null
    private val sounds = mutableMapOf<String, Int>()
    private var tickingPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        soundPool = SoundPool.Builder().setMaxStreams(3).setAudioAttributes(attributes).build()
        val soundAssets = mapOf(
            "tap" to "flutter_assets/assets/audio/ui/click1.wav",
            "select" to "flutter_assets/assets/audio/ui/click2.wav",
            "confirm" to "flutter_assets/assets/audio/ui/switch15.wav",
            "back" to "flutter_assets/assets/audio/ui/click3.wav",
            "toggle" to "flutter_assets/assets/audio/ui/switch2.wav",
            "reveal" to "flutter_assets/assets/audio/ui/switch6.wav",
            "timerEnd" to "flutter_assets/assets/audio/ui/switch15.wav",
            "bombExplosion" to "flutter_assets/assets/audio/ui/bomb_explosion.wav"
        )
        soundAssets.forEach { (name, path) ->
            assets.openFd(path).use { descriptor ->
                sounds[name] = soundPool!!.load(descriptor, 1)
            }
        }
        assets.openFd("flutter_assets/assets/audio/ui/bomb_ticking.wav").use { descriptor ->
            tickingPlayer = MediaPlayer().apply {
                setAudioAttributes(attributes)
                setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                isLooping = true
                setVolume(.55f, .55f)
                prepare()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "verdadoreto/ui_audio")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTicking" -> {
                        tickingPlayer?.seekTo(0)
                        tickingPlayer?.start()
                        result.success(null)
                    }
                    "pauseTicking" -> {
                        tickingPlayer?.pause()
                        result.success(null)
                    }
                    "resumeTicking" -> {
                        tickingPlayer?.start()
                        result.success(null)
                    }
                    "stopTicking" -> {
                        tickingPlayer?.pause()
                        tickingPlayer?.seekTo(0)
                        result.success(null)
                    }
                    "playExplosion" -> {
                        sounds["bombExplosion"]?.let { soundPool?.play(it, .9f, .9f, 3, 0, 1f) }
                        result.success(null)
                    }
                    "play" -> {
                        val name = call.argument<String>("sound")
                        val volume = (call.argument<Double>("volume") ?: .35).toFloat()
                        sounds[name]?.let { soundPool?.play(it, volume, volume, 1, 0, 1f) }
                        result.success(null)
                    }
                    "dispose" -> {
                        tickingPlayer?.release()
                        tickingPlayer = null
                        soundPool?.release()
                        soundPool = null
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        tickingPlayer?.release()
        tickingPlayer = null
        soundPool?.release()
        soundPool = null
        super.onDestroy()
    }
}
