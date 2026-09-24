package br.org.digitavox.digitavox_criancas

import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.UUID

class MainActivity : FlutterActivity() {
    private var ttsHandler: NativeTextToSpeechHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ttsHandler = NativeTextToSpeechHandler(this).also { handler ->
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                "br.org.digitavox/audio_guidance_tts",
            ).setMethodCallHandler(handler)
        }
    }

    override fun onDestroy() {
        ttsHandler?.dispose()
        ttsHandler = null
        super.onDestroy()
    }
}

private class NativeTextToSpeechHandler(
    private val activity: MainActivity,
) : MethodChannel.MethodCallHandler, TextToSpeech.OnInitListener {
    private var tts: TextToSpeech? = null
    private var initialized = false
    private var initializationResult: MethodChannel.Result? = null
    private var activeSpeechResult: MethodChannel.Result? = null
    private var configuration: SpeechConfiguration? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "speak" -> speak(call, result)
            "stop" -> {
                stop()
                result.success(null)
            }
            "dispose" -> {
                dispose()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun initialize(call: MethodCall, result: MethodChannel.Result) {
        configuration = SpeechConfiguration(
            locale = call.argument<String>("locale") ?: "pt-BR",
            rate = (call.argument<Double>("rate") ?: 0.85).toFloat(),
            pitch = (call.argument<Double>("pitch") ?: 1.0).toFloat(),
            volume = (call.argument<Double>("volume") ?: 1.0).toFloat(),
            voice = call.argument<String>("voice"),
        )
        if (initialized) {
            applyConfiguration()
            result.success(null)
            return
        }
        if (initializationResult != null) {
            result.error("tts_initializing", "TTS initialization already pending", null)
            return
        }
        initializationResult = result
        tts = TextToSpeech(activity, this)
    }

    override fun onInit(status: Int) {
        activity.runOnUiThread {
            val result = initializationResult
            initializationResult = null
            if (status != TextToSpeech.SUCCESS) {
                result?.error("tts_unavailable", "System TTS initialization failed", status)
                return@runOnUiThread
            }
            initialized = true
            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) = Unit

                override fun onDone(utteranceId: String?) = completeSpeech()

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) = failSpeech("tts_error")

                override fun onError(utteranceId: String?, errorCode: Int) =
                    failSpeech("tts_error_$errorCode")

                override fun onStop(utteranceId: String?, interrupted: Boolean) =
                    completeSpeech()
            })
            applyConfiguration()
            result?.success(null)
        }
    }

    private fun applyConfiguration() {
        val config = configuration ?: return
        val engine = tts ?: return
        val localeParts = config.locale.replace('_', '-').split('-')
        val locale = if (localeParts.size > 1) {
            Locale(localeParts[0], localeParts[1])
        } else {
            Locale.forLanguageTag(config.locale)
        }
        engine.language = locale
        engine.setSpeechRate(config.rate.coerceIn(0.1f, 2.0f))
        engine.setPitch(config.pitch.coerceIn(0.5f, 2.0f))
        config.voice?.let { requested ->
            engine.voices?.firstOrNull { it.name == requested }?.let { engine.voice = it }
        }
    }

    private fun speak(call: MethodCall, result: MethodChannel.Result) {
        val engine = tts
        if (!initialized || engine == null) {
            result.error("tts_unavailable", "System TTS is not initialized", null)
            return
        }
        val text = call.argument<String>("text")?.trim().orEmpty()
        if (text.isEmpty()) {
            result.error("tts_invalid_text", "Speech text is empty", null)
            return
        }
        stop()
        activeSpeechResult = result
        val params = Bundle().apply {
            putFloat(TextToSpeech.Engine.KEY_PARAM_VOLUME, configuration?.volume ?: 1.0f)
        }
        val status = engine.speak(text, TextToSpeech.QUEUE_FLUSH, params, UUID.randomUUID().toString())
        if (status == TextToSpeech.ERROR) failSpeech("tts_start_failed")
    }

    private fun stop() {
        tts?.stop()
        completeSpeech()
    }

    fun dispose() {
        stop()
        initializationResult?.error("tts_disposed", "TTS disposed during initialization", null)
        initializationResult = null
        tts?.shutdown()
        tts = null
        initialized = false
    }

    private fun completeSpeech() {
        activity.runOnUiThread {
            val result = activeSpeechResult
            activeSpeechResult = null
            result?.success(null)
        }
    }

    private fun failSpeech(code: String) {
        activity.runOnUiThread {
            val result = activeSpeechResult
            activeSpeechResult = null
            result?.error(code, "System TTS playback failed", null)
        }
    }
}

private data class SpeechConfiguration(
    val locale: String,
    val rate: Float,
    val pitch: Float,
    val volume: Float,
    val voice: String?,
)
