package dev.verily.capture

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationManager
import android.media.MediaMetadataRetriever
import android.media.MediaRecorder
import android.os.Build
import android.os.SystemClock
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.FileOutputOptions
import androidx.camera.video.Quality
import androidx.camera.video.QualitySelector
import androidx.camera.video.Recorder
import androidx.camera.video.Recording
import androidx.camera.video.VideoCapture
import androidx.camera.video.VideoRecordEvent
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage
import dev.leptoskit.bridge.NativePlugin
import dev.leptoskit.bridge.PluginException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.net.HttpURLConnection
import java.net.URL
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Verily live capture plugin for Android (`"verily-capture"`).
 *
 * Captures live photos, video (while forwarding camera frames to
 * `dev.leptoskit.mediapipe.MediaPipePlugin.analyzeFrame`), microphone audio,
 * QR venue codes (ML Kit), bounded gyroscope+accelerometer traces, and GPS
 * fixes, then streams exact hashed files directly to server-issued upload URLs.
 * Never opens a gallery or file picker.
 */
class VerilyCapturePlugin(
    context: Context,
) : NativePlugin {
    override val name: String = "verily-capture"
    override val methods: IntArray = intArrayOf(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)

    private val hostContext = context
    private val appContext = context.applicationContext
    private val captureDir = File(appContext.cacheDir, "verily_captures").apply { mkdirs() }
    private val capturedFiles = ConcurrentHashMap<String, StoredCapture>()
    private val analysisExecutor = Executors.newSingleThreadExecutor()

    private var activeVideoRecording: Recording? = null
    private var activeVideoFile: File? = null
    private var activeVideoFinalized: CompletableDeferred<File>? = null
    private var activeAudioRecorder: MediaRecorder? = null
    private var activeAudioFile: File? = null
    @Volatile
    private var closed = false

    private data class StoredCapture(
        val file: File,
        val sha256Hex: String,
        val mimeType: String,
    )

    override suspend fun invoke(method: Int, payload: ByteArray): ByteArray {
        if (closed) throw PluginException.cancelled()
        return when (method) {
            0 -> handleCapturePhoto(payload)
            1 -> handleStartVideo(payload)
            2 -> handleStopVideo(payload)
            3 -> handleStartAudio(payload)
            4 -> handleStopAudio(payload)
            5 -> handleScanQr(payload)
            6 -> handleCaptureMotion(payload)
            7 -> handleCaptureLocation(payload)
            8 -> handleUploadCapturedFile(payload)
            9 -> handleDiscardCapturedFile(payload)
            else -> throw PluginException.unavailable()
        }
    }

    override fun close() {
        closed = true
        runCatching { activeVideoRecording?.stop() }
        runCatching { activeAudioRecorder?.stop() }
        runCatching { activeAudioRecorder?.release() }
        analysisExecutor.shutdown()
        for (entry in capturedFiles.values) {
            runCatching { entry.file.delete() }
        }
        capturedFiles.clear()
    }

    private suspend fun handleCapturePhoto(payload: ByteArray): ByteArray {
        val reader = WireReader(payload)
        val facing = reader.readU32()
        reader.finish()
        requirePermission(Manifest.permission.CAMERA)
        val owner = hostContext as? LifecycleOwner ?: throw PluginException.unavailable()
        val provider = cameraProvider()
        val outputFile = File(captureDir, "photo_${UUID.randomUUID()}.jpg")
        val imageCapture = ImageCapture.Builder()
            .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
            .build()
        val selector = if (facing == 1) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
        withContext(Dispatchers.Main) {
            provider.unbindAll()
            provider.bindToLifecycle(owner, selector, imageCapture)
        }
        suspendCancellableCoroutine<Unit> { cont ->
            val opts = ImageCapture.OutputFileOptions.Builder(outputFile).build()
            imageCapture.takePicture(
                opts,
                ContextCompat.getMainExecutor(appContext),
                object : ImageCapture.OnImageSavedCallback {
                    override fun onImageSaved(outputFileResults: ImageCapture.OutputFileResults) {
                        cont.resume(Unit)
                    }

                    override fun onError(exception: ImageCaptureException) {
                        cont.resumeWithException(PluginException.nativeError())
                    }
                },
            )
        }
        return registerCapturedMedia(outputFile, "image/jpeg", durationMs = 0)
    }

    private suspend fun handleStartVideo(payload: ByteArray): ByteArray {
        val reader = WireReader(payload)
        val facing = reader.readU32()
        val _maxDurationSeconds = reader.readU32()
        val cameraSessionId = reader.readU32()
        val recordAudio = reader.readU32() == 1
        reader.finish()
        requirePermission(Manifest.permission.CAMERA)
        if (recordAudio) requirePermission(Manifest.permission.RECORD_AUDIO)
        val owner = hostContext as? LifecycleOwner ?: throw PluginException.unavailable()
        val provider = cameraProvider()
        val recorder = Recorder.Builder()
            .setQualitySelector(QualitySelector.from(Quality.HD))
            .build()
        val videoCapture = VideoCapture.withOutput(recorder)
        val analysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()
        analysis.setAnalyzer(analysisExecutor) { proxy ->
            try {
                val bitmap = proxy.toBitmap()
                val rotation = proxy.imageInfo.rotationDegrees
                val ts = SystemClock.elapsedRealtime()
                forwardToMediaPipe(cameraSessionId, bitmap, rotation, facing == 1, ts)
            } catch (_: Throwable) {
                // MediaPipe plugin optional when tracking is not active.
            } finally {
                proxy.close()
            }
        }
        val selector = if (facing == 1) CameraSelector.DEFAULT_FRONT_CAMERA else CameraSelector.DEFAULT_BACK_CAMERA
        val file = File(captureDir, "video_${UUID.randomUUID()}.mp4")
        val finalized = CompletableDeferred<File>()
        activeVideoFile = file
        activeVideoFinalized = finalized
        withContext(Dispatchers.Main) {
            provider.unbindAll()
            provider.bindToLifecycle(owner, selector, videoCapture, analysis)
            var pending = videoCapture.output.prepareRecording(appContext, FileOutputOptions.Builder(file).build())
            if (recordAudio) {
                pending = pending.withAudioEnabled()
            }
            activeVideoRecording = pending.start(ContextCompat.getMainExecutor(appContext)) { event ->
                if (event is VideoRecordEvent.Finalize) {
                    if (event.hasError()) {
                        finalized.completeExceptionally(PluginException.nativeError())
                    } else {
                        finalized.complete(file)
                    }
                }
            }
        }
        return ByteArray(0)
    }

    private suspend fun handleStopVideo(payload: ByteArray): ByteArray {
        if (payload.isNotEmpty()) throw PluginException.invalidArgument()
        val recording = activeVideoRecording ?: throw PluginException.invalidArgument()
        val finalized = activeVideoFinalized ?: throw PluginException.invalidArgument()
        activeVideoRecording = null
        activeVideoFinalized = null
        activeVideoFile = null
        withContext(Dispatchers.Main) { recording.stop() }
        val file = finalized.await()
        val durationMs = probeDurationMs(file)
        return registerCapturedMedia(file, "video/mp4", durationMs)
    }

    private suspend fun handleStartAudio(payload: ByteArray): ByteArray {
        val reader = WireReader(payload)
        val maxDurationSeconds = reader.readU32()
        reader.finish()
        requirePermission(Manifest.permission.RECORD_AUDIO)
        val file = File(captureDir, "audio_${UUID.randomUUID()}.m4a")
        val recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MediaRecorder(appContext)
        } else {
            @Suppress("DEPRECATION")
            MediaRecorder()
        }
        recorder.apply {
            setAudioSource(MediaRecorder.AudioSource.MIC)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setAudioSamplingRate(44100)
            setAudioEncodingBitRate(128000)
            if (maxDurationSeconds > 0) setMaxDuration(maxDurationSeconds * 1000)
            setOutputFile(file.absolutePath)
            prepare()
            start()
        }
        activeAudioRecorder = recorder
        activeAudioFile = file
        return ByteArray(0)
    }

    private suspend fun handleStopAudio(payload: ByteArray): ByteArray {
        if (payload.isNotEmpty()) throw PluginException.invalidArgument()
        val recorder = activeAudioRecorder ?: throw PluginException.invalidArgument()
        val file = activeAudioFile ?: throw PluginException.invalidArgument()
        activeAudioRecorder = null
        activeAudioFile = null
        withContext(Dispatchers.IO) {
            runCatching { recorder.stop() }
            recorder.release()
        }
        val durationMs = probeDurationMs(file)
        return registerCapturedMedia(file, "audio/mp4", durationMs)
    }

    private suspend fun handleScanQr(payload: ByteArray): ByteArray {
        if (payload.isNotEmpty()) throw PluginException.invalidArgument()
        requirePermission(Manifest.permission.CAMERA)
        val owner = hostContext as? LifecycleOwner ?: throw PluginException.unavailable()
        val provider = cameraProvider()
        val scanner = BarcodeScanning.getClient()
        val deferred = CompletableDeferred<String>()
        val analysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .build()
        analysis.setAnalyzer(analysisExecutor) { proxy ->
            val mediaImage = proxy.image
            if (mediaImage == null || deferred.isCompleted) {
                proxy.close()
                return@setAnalyzer
            }
            val input = InputImage.fromMediaImage(mediaImage, proxy.imageInfo.rotationDegrees)
            scanner.process(input)
                .addOnSuccessListener { barcodes ->
                    val raw = barcodes.firstOrNull { !it.rawValue.isNullOrBlank() }?.rawValue
                    if (raw != null && !deferred.isCompleted) {
                        deferred.complete(raw)
                    }
                }
                .addOnCompleteListener { proxy.close() }
        }
        withContext(Dispatchers.Main) {
            provider.unbindAll()
            provider.bindToLifecycle(owner, CameraSelector.DEFAULT_BACK_CAMERA, analysis)
        }
        val code = deferred.await()
        withContext(Dispatchers.Main) { provider.unbindAll() }
        val out = WireWriter()
        out.writeBytes(code.toByteArray(Charsets.UTF_8))
        return out.toByteArray()
    }

    private suspend fun handleCaptureMotion(payload: ByteArray): ByteArray {
        val reader = WireReader(payload)
        val durationMs = reader.readU32().coerceIn(500, 30_000)
        reader.finish()
        val manager = appContext.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            ?: throw PluginException.unavailable()
        val gyro = manager.getDefaultSensor(Sensor.TYPE_GYROSCOPE) ?: throw PluginException.unavailable()
        val accel = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER) ?: throw PluginException.unavailable()

        val samples = ArrayList<LongArray>(256)
        var lastGyro = floatArrayOf(0f, 0f, 0f)
        var lastAccel = floatArrayOf(0f, 0f, 9.81f)
        var startNanos = -1L
        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (event.sensor.type == Sensor.TYPE_GYROSCOPE) {
                    lastGyro = event.values.copyOf()
                } else if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
                    lastAccel = event.values.copyOf()
                } else {
                    return
                }
                if (startNanos < 0L) startNanos = event.timestamp
                val elapsedUs = ((event.timestamp - startNanos) / 1000L).coerceAtLeast(0L)
                synchronized(samples) {
                    if (samples.size < 1000 && (samples.isEmpty() || elapsedUs > samples.last()[0])) {
                        samples.add(
                            longArrayOf(
                                elapsedUs,
                                Math.round(lastGyro[0].toDouble() * 1_000_000.0),
                                Math.round(lastGyro[1].toDouble() * 1_000_000.0),
                                Math.round(lastGyro[2].toDouble() * 1_000_000.0),
                                Math.round(lastAccel[0].toDouble() * 1_000_000.0),
                                Math.round(lastAccel[1].toDouble() * 1_000_000.0),
                                Math.round(lastAccel[2].toDouble() * 1_000_000.0),
                            ),
                        )
                    }
                }
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
        }
        manager.registerListener(listener, gyro, SensorManager.SENSOR_DELAY_GAME)
        manager.registerListener(listener, accel, SensorManager.SENSOR_DELAY_GAME)
        try {
            delay(durationMs.toLong())
        } finally {
            manager.unregisterListener(listener)
        }
        val json = buildString {
            append("{\"version\":1,\"samples\":[")
            synchronized(samples) {
                samples.forEachIndexed { idx, row ->
                    if (idx > 0) append(',')
                    append('[')
                    row.forEachIndexed { c, v ->
                        if (c > 0) append(',')
                        append(v)
                    }
                    append(']')
                }
            }
            append("]}")
        }
        val out = WireWriter()
        out.writeBytes(json.toByteArray(Charsets.UTF_8))
        return out.toByteArray()
    }

    private suspend fun handleCaptureLocation(payload: ByteArray): ByteArray {
        if (payload.isNotEmpty()) throw PluginException.invalidArgument()
        requirePermission(Manifest.permission.ACCESS_FINE_LOCATION)
        val manager = appContext.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
            ?: throw PluginException.unavailable()
        @Suppress("MissingPermission")
        val loc: Location = manager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            ?: manager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            ?: throw PluginException.unavailable()
        val isMock = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            loc.isMock
        } else {
            @Suppress("DEPRECATION")
            loc.isFromMockProvider
        }
        val out = WireWriter()
        out.writeF64(loc.latitude)
        out.writeF64(loc.longitude)
        out.writeF64(loc.accuracy.toDouble())
        out.writeI64(loc.time)
        out.writeU32(if (isMock) 1 else 0)
        return out.toByteArray()
    }

    private suspend fun handleUploadCapturedFile(payload: ByteArray): ByteArray {
        val reader = WireReader(payload)
        val fileId = reader.readString()
        val uploadUrl = reader.readString()
        val mimeType = reader.readString()
        val expectedSha256 = reader.readString()
        reader.finish()

        val stored = capturedFiles[fileId] ?: throw PluginException.invalidArgument()
        if (stored.sha256Hex != expectedSha256) throw PluginException.invalidArgument()
        val versionId = withContext(Dispatchers.IO) {
            val actualSha = sha256File(stored.file)
            if (actualSha != expectedSha256) throw PluginException.nativeError()
            val conn = (URL(uploadUrl).openConnection() as HttpURLConnection).apply {
                requestMethod = "PUT"
                doOutput = true
                setRequestProperty("Content-Type", mimeType)
                setFixedLengthStreamingMode(stored.file.length())
                connectTimeout = 15_000
                readTimeout = 60_000
            }
            try {
                FileInputStream(stored.file).use { input ->
                    conn.outputStream.use { output -> input.copyTo(output) }
                }
                val code = conn.responseCode
                if (code !in 200..299) throw PluginException.nativeError()
                conn.getHeaderField("x-amz-version-id")
                    ?: conn.getHeaderField("x-bz-file-id")
                    ?: ""
            } finally {
                conn.disconnect()
            }
        }
        val out = WireWriter()
        out.writeBytes(versionId.toByteArray(Charsets.UTF_8))
        return out.toByteArray()
    }

    private fun handleDiscardCapturedFile(payload: ByteArray): ByteArray {
        val reader = WireReader(payload)
        val fileId = reader.readString()
        reader.finish()
        capturedFiles.remove(fileId)?.file?.delete()
        return ByteArray(0)
    }

    private suspend fun registerCapturedMedia(
        file: File,
        mimeType: String,
        durationMs: Int,
    ): ByteArray {
        val sha = withContext(Dispatchers.IO) { sha256File(file) }
        val fileId = UUID.randomUUID().toString()
        capturedFiles[fileId] = StoredCapture(file, sha, mimeType)
        val out = WireWriter()
        out.writeBytes(fileId.toByteArray(Charsets.UTF_8))
        out.writeBytes(sha.toByteArray(Charsets.UTF_8))
        out.writeI64(file.length())
        out.writeBytes(mimeType.toByteArray(Charsets.UTF_8))
        out.writeU32(durationMs)
        return out.toByteArray()
    }

    private fun forwardToMediaPipe(
        cameraSessionId: Int,
        bitmap: android.graphics.Bitmap,
        rotationDegrees: Int,
        mirrored: Boolean,
        timestampMs: Long,
    ) {
        val cls = Class.forName("dev.leptoskit.mediapipe.MediaPipePlugin")
        val method = cls.getMethod(
            "analyzeFrame",
            Int::class.javaPrimitiveType,
            android.graphics.Bitmap::class.java,
            Int::class.javaPrimitiveType,
            Boolean::class.javaPrimitiveType,
            Long::class.javaPrimitiveType,
        )
        method.invoke(null, cameraSessionId, bitmap, rotationDegrees, mirrored, timestampMs)
    }

    private suspend fun cameraProvider(): ProcessCameraProvider =
        suspendCancellableCoroutine { cont ->
            val future = ProcessCameraProvider.getInstance(appContext)
            future.addListener(
                {
                    runCatching { future.get() }
                        .onSuccess { cont.resume(it) }
                        .onFailure { cont.resumeWithException(PluginException.nativeError()) }
                },
                ContextCompat.getMainExecutor(appContext),
            )
        }

    private fun requirePermission(permission: String) {
        if (ContextCompat.checkSelfPermission(appContext, permission) != PackageManager.PERMISSION_GRANTED) {
            throw PluginException.permissionDenied()
        }
    }

    private fun probeDurationMs(file: File): Int {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(file.absolutePath)
            retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toIntOrNull() ?: 0
        } catch (_: Throwable) {
            0
        } finally {
            runCatching { retriever.release() }
        }
    }

    private fun sha256File(file: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val buffer = ByteArray(16 * 1024)
        FileInputStream(file).use { input ->
            while (true) {
                val read = input.read(buffer)
                if (read <= 0) break
                digest.update(buffer, 0, read)
            }
        }
        return digest.digest().joinToString("") { "%02x".format(it) }
    }

    private class WireReader(private val bytes: ByteArray) {
        private var pos = 0

        fun readU32(): Int {
            if (pos + 4 > bytes.size) throw PluginException.invalidArgument()
            val v = ByteBuffer.wrap(bytes, pos, 4).order(ByteOrder.LITTLE_ENDIAN).int
            pos += 4
            return v
        }

        fun readString(): String {
            val len = readU32()
            if (len < 0 || pos + len > bytes.size) throw PluginException.invalidArgument()
            val s = String(bytes, pos, len, Charsets.UTF_8)
            pos += len
            return s
        }

        fun finish() {
            if (pos != bytes.size) throw PluginException.invalidArgument()
        }
    }

    private class WireWriter {
        private val stream = ByteArrayOutputStream(256)

        fun writeU32(value: Int) {
            stream.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(value).array())
        }

        fun writeI64(value: Long) {
            stream.write(ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN).putLong(value).array())
        }

        fun writeF64(value: Double) {
            stream.write(ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN).putDouble(value).array())
        }

        fun writeBytes(value: ByteArray) {
            writeU32(value.size)
            stream.write(value)
        }

        fun toByteArray(): ByteArray = stream.toByteArray()
    }
}
