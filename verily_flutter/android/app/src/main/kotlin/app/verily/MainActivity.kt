package app.verily

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyInfo
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Hosts Flutter and the two device channels proof capture relies on.
 *
 * - `app.verily/device_integrity` asks Play Integrity's Standard API for a
 *   token bound to a server-supplied request hash.
 * - `app.verily/capture_provenance` signs a finished capture's manifest with a
 *   hardware-backed P-256 key that never leaves the device.
 */
class MainActivity : FlutterFragmentActivity() {
    private var integrityTokenProvider: StandardIntegrityManager.StandardIntegrityTokenProvider? = null

    // Key generation and signing can take hundreds of milliseconds on
    // StrongBox, so they run off the platform thread. One thread also
    // serialises first-use key generation.
    private val signingExecutor: ExecutorService = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_INTEGRITY_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestStandardToken" -> {
                    requestStandardIntegrityToken(
                        requestHash = call.argument<String>("requestHash"),
                        cloudProjectNumber = call.argument<Number>("cloudProjectNumber")?.toLong(),
                        result = result,
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CAPTURE_PROVENANCE_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "signManifest" -> {
                    signCaptureManifest(
                        manifest = call.argument<ByteArray>("manifest"),
                        result = result,
                    )
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        signingExecutor.shutdown()
        super.onDestroy()
    }

    private fun signCaptureManifest(
        manifest: ByteArray?,
        result: MethodChannel.Result,
    ) {
        if (manifest == null || manifest.isEmpty() || manifest.size > MAX_MANIFEST_BYTES) {
            result.error("invalid_capture_manifest", "The capture record is invalid.", null)
            return
        }
        signingExecutor.execute {
            val signed =
                runCatching {
                    val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }
                    if (!keyStore.containsAlias(CAPTURE_KEY_ALIAS)) {
                        generateCaptureKey(preferStrongBox = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                    }
                    val privateKey = keyStore.getKey(CAPTURE_KEY_ALIAS, null) as PrivateKey
                    val publicKey = keyStore.getCertificate(CAPTURE_KEY_ALIAS).publicKey as ECPublicKey
                    val signer =
                        Signature.getInstance("SHA256withECDSA").apply {
                            initSign(privateKey)
                            update(manifest)
                        }
                    mapOf(
                        "signature" to derSignatureToP1363(signer.sign()),
                        "publicKey" to uncompressedPublicKey(publicKey),
                        "keyStorage" to captureKeyStorage(privateKey),
                    )
                }
            runOnUiThread {
                signed
                    .onSuccess(result::success)
                    .onFailure { error ->
                        // The class name helps diagnosis without exposing key
                        // material or device detail to the person.
                        result.error(
                            "capture_signing_failed",
                            "Device signing is unavailable.",
                            error.javaClass.simpleName,
                        )
                    }
            }
        }
    }

    private fun generateCaptureKey(preferStrongBox: Boolean) {
        val generator =
            KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_EC,
                ANDROID_KEY_STORE,
            )
        val builder =
            KeyGenParameterSpec
                .Builder(
                    CAPTURE_KEY_ALIAS,
                    KeyProperties.PURPOSE_SIGN,
                ).setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                .setDigests(KeyProperties.DIGEST_SHA256)
        if (preferStrongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }
        try {
            generator.initialize(builder.build())
            generator.generateKeyPair()
        } catch (error: StrongBoxUnavailableException) {
            if (!preferStrongBox) throw error
            generateCaptureKey(preferStrongBox = false)
        }
    }

    /** Where the capture key lives, reported with every signature. */
    private fun captureKeyStorage(privateKey: PrivateKey): String =
        runCatching {
            val keyInfo =
                KeyFactory
                    .getInstance(
                        privateKey.algorithm,
                        ANDROID_KEY_STORE,
                    ).getKeySpec(privateKey, KeyInfo::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                when (keyInfo.securityLevel) {
                    KeyProperties.SECURITY_LEVEL_STRONGBOX -> "strongBox"
                    KeyProperties.SECURITY_LEVEL_TRUSTED_ENVIRONMENT -> "trustedEnvironment"
                    else -> "software"
                }
            } else if (keyInfo.isInsideSecureHardware) {
                "trustedEnvironment"
            } else {
                "software"
            }
        }.getOrDefault("unknown")

    /** The 65-byte uncompressed SEC1 point: `0x04 || X || Y`. */
    private fun uncompressedPublicKey(publicKey: ECPublicKey): ByteArray {
        val encoded = ByteArray(UNCOMPRESSED_POINT_BYTES)
        encoded[0] = 0x04
        copyUnsignedCoordinate(publicKey.w.affineX.toByteArray(), encoded, 1)
        copyUnsignedCoordinate(publicKey.w.affineY.toByteArray(), encoded, 1 + COORDINATE_BYTES)
        return encoded
    }

    private fun copyUnsignedCoordinate(
        source: ByteArray,
        target: ByteArray,
        offset: Int,
    ) {
        val start = if (source.size > COORDINATE_BYTES) source.size - COORDINATE_BYTES else 0
        val length = source.size - start
        source.copyInto(target, offset + COORDINATE_BYTES - length, start, source.size)
    }

    /** Converts an ASN.1 DER ECDSA signature to the 64-byte IEEE P1363 `r || s`. */
    private fun derSignatureToP1363(der: ByteArray): ByteArray {
        var index = 0
        require(der[index++].toInt() and 0xff == 0x30)
        val sequenceLength = readDerLength(der, index)
        index += sequenceLength.second
        require(sequenceLength.first == der.size - index)
        val output = ByteArray(2 * COORDINATE_BYTES)
        index = copyDerInteger(der, index, output, 0)
        index = copyDerInteger(der, index, output, COORDINATE_BYTES)
        require(index == der.size)
        return output
    }

    private fun copyDerInteger(
        der: ByteArray,
        initialIndex: Int,
        output: ByteArray,
        outputOffset: Int,
    ): Int {
        var index = initialIndex
        require(der[index++].toInt() and 0xff == 0x02)
        val integerLength = readDerLength(der, index)
        index += integerLength.second
        var valueOffset = index
        var valueLength = integerLength.first
        while (valueLength > COORDINATE_BYTES && der[valueOffset] == 0.toByte()) {
            valueOffset += 1
            valueLength -= 1
        }
        require(valueLength in 1..COORDINATE_BYTES)
        der.copyInto(
            output,
            outputOffset + COORDINATE_BYTES - valueLength,
            valueOffset,
            valueOffset + valueLength,
        )
        return index + integerLength.first
    }

    private fun readDerLength(
        der: ByteArray,
        index: Int,
    ): Pair<Int, Int> {
        val first = der[index].toInt() and 0xff
        if (first < 0x80) return first to 1
        val byteCount = first and 0x7f
        require(byteCount in 1..2 && index + byteCount < der.size)
        var length = 0
        repeat(byteCount) { offset ->
            length = (length shl 8) or (der[index + 1 + offset].toInt() and 0xff)
        }
        return length to (1 + byteCount)
    }

    private fun requestStandardIntegrityToken(
        requestHash: String?,
        cloudProjectNumber: Long?,
        result: MethodChannel.Result,
    ) {
        if (requestHash.isNullOrBlank() || cloudProjectNumber == null || cloudProjectNumber <= 0) {
            result.error("invalid_integrity_request", "Play Integrity is not configured.", null)
            return
        }
        val provider = integrityTokenProvider
        if (provider != null) {
            requestFromProvider(provider, requestHash, result)
            return
        }
        val manager = IntegrityManagerFactory.createStandard(applicationContext)
        manager
            .prepareIntegrityToken(
                StandardIntegrityManager.PrepareIntegrityTokenRequest
                    .builder()
                    .setCloudProjectNumber(cloudProjectNumber)
                    .build(),
            ).addOnSuccessListener { prepared ->
                integrityTokenProvider = prepared
                requestFromProvider(prepared, requestHash, result)
            }.addOnFailureListener { error ->
                result.error(
                    "integrity_prepare_failed",
                    "Device verification is unavailable.",
                    error.javaClass.simpleName,
                )
            }
    }

    private fun requestFromProvider(
        provider: StandardIntegrityManager.StandardIntegrityTokenProvider,
        requestHash: String,
        result: MethodChannel.Result,
    ) {
        provider
            .request(
                StandardIntegrityManager.StandardIntegrityTokenRequest
                    .builder()
                    .setRequestHash(requestHash)
                    .build(),
            ).addOnSuccessListener { response ->
                result.success(response.token())
            }.addOnFailureListener { error ->
                // A provider can expire; the next request prepares a new one.
                integrityTokenProvider = null
                result.error(
                    "integrity_request_failed",
                    "Device verification is unavailable.",
                    error.javaClass.simpleName,
                )
            }
    }

    private companion object {
        const val DEVICE_INTEGRITY_CHANNEL = "app.verily/device_integrity"
        const val CAPTURE_PROVENANCE_CHANNEL = "app.verily/capture_provenance"
        const val CAPTURE_KEY_ALIAS = "verily_capture_provenance_v1"
        const val ANDROID_KEY_STORE = "AndroidKeyStore"
        const val MAX_MANIFEST_BYTES = 4096
        const val COORDINATE_BYTES = 32
        const val UNCOMPRESSED_POINT_BYTES = 1 + 2 * COORDINATE_BYTES
    }
}
