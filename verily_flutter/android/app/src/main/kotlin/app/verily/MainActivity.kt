package app.verily

import android.content.pm.PackageManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.ProviderException
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Hosts Flutter and the two device channels proof capture relies on.
 *
 * - `app.verily/device_integrity` asks Play Integrity's Standard API for a
 *   token bound to a server-supplied request hash.
 * - `app.verily/capture_provenance` generates a fresh P-256 key for each
 *   capture window the server opens, before anything is recorded, with the
 *   window's Key Attestation challenge; then signs the finished capture's
 *   manifest with it and returns the key's attestation chain. The server
 *   learns where the key lives only from that chain.
 */
class MainActivity : FlutterFragmentActivity() {
    private var integrityTokenProvider: StandardIntegrityManager.StandardIntegrityTokenProvider? = null

    // Key generation and signing can take hundreds of milliseconds on
    // StrongBox, so they run off the platform thread. One thread also
    // serialises generation, signing, and cleanup.
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
                "prepareCaptureKey" -> {
                    prepareCaptureKey(
                        captureId = call.argument<String>("captureId"),
                        attestationChallenge = call.argument<ByteArray>("attestationChallenge"),
                        result = result,
                    )
                }

                "signCaptureManifest" -> {
                    signCaptureManifest(
                        captureId = call.argument<String>("captureId"),
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

    /**
     * Generates the key for one capture window, attesting
     * `attestationChallenge`. Keys left by earlier windows are deleted once
     * they are older than any window can live.
     */
    private fun prepareCaptureKey(
        captureId: String?,
        attestationChallenge: ByteArray?,
        result: MethodChannel.Result,
    ) {
        val alias = captureKeyAlias(captureId)
        if (alias == null ||
            attestationChallenge == null ||
            attestationChallenge.isEmpty() ||
            attestationChallenge.size > MAX_ATTESTATION_CHALLENGE_BYTES
        ) {
            result.error("invalid_capture_key_request", "The capture key request is invalid.", null)
            return
        }
        signingExecutor.execute {
            val prepared =
                runCatching {
                    val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }
                    deleteStaleCaptureKeys(keyStore, keep = alias)
                    if (!keyStore.containsAlias(alias)) {
                        generateCaptureKey(alias, attestationChallenge, preferStrongBox = hasStrongBox())
                    }
                }
            runOnUiThread {
                prepared
                    .onSuccess { result.success(null) }
                    .onFailure { error ->
                        // The class name helps diagnosis without exposing key
                        // material or device detail to the person.
                        result.error(
                            "capture_key_failed",
                            "Device signing is unavailable.",
                            error.javaClass.simpleName,
                        )
                    }
            }
        }
    }

    private fun signCaptureManifest(
        captureId: String?,
        manifest: ByteArray?,
        result: MethodChannel.Result,
    ) {
        val alias = captureKeyAlias(captureId)
        if (alias == null || manifest == null || manifest.isEmpty() || manifest.size > MAX_MANIFEST_BYTES) {
            result.error("invalid_capture_manifest", "The capture record is invalid.", null)
            return
        }
        signingExecutor.execute {
            val signed =
                runCatching {
                    val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }
                    val privateKey =
                        keyStore.getKey(alias, null) as? PrivateKey
                            ?: throw IllegalStateException("No capture key for this window.")
                    val chain =
                        keyStore.getCertificateChain(alias)
                            ?: throw IllegalStateException("The capture key has no attestation.")
                    val signer =
                        Signature.getInstance("SHA256withECDSA").apply {
                            initSign(privateKey)
                            update(manifest)
                        }
                    mapOf(
                        "signature" to derSignatureToP1363(signer.sign()),
                        "certificateChain" to chain.map { it.encoded },
                    )
                }
            runOnUiThread {
                signed
                    .onSuccess(result::success)
                    .onFailure { error ->
                        result.error(
                            "capture_signing_failed",
                            "Device signing is unavailable.",
                            error.javaClass.simpleName,
                        )
                    }
            }
        }
    }

    private fun generateCaptureKey(
        alias: String,
        attestationChallenge: ByteArray,
        preferStrongBox: Boolean,
    ) {
        val generator =
            KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_EC,
                ANDROID_KEY_STORE,
            )
        val builder =
            KeyGenParameterSpec
                .Builder(alias, KeyProperties.PURPOSE_SIGN)
                .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setAttestationChallenge(attestationChallenge)
        if (preferStrongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setIsStrongBoxBacked(true)
        }
        try {
            generator.initialize(builder.build())
            generator.generateKeyPair()
        } catch (error: StrongBoxUnavailableException) {
            if (!preferStrongBox) throw error
            generateCaptureKey(alias, attestationChallenge, preferStrongBox = false)
        } catch (error: ProviderException) {
            // A busy or failing StrongBox reports a provider error; the TEE
            // still gives an attested key.
            if (!preferStrongBox) throw error
            generateCaptureKey(alias, attestationChallenge, preferStrongBox = false)
        }
    }

    private fun hasStrongBox(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)

    /**
     * Deletes keys from windows that have closed, and the long-lived key
     * earlier builds signed every capture with.
     */
    private fun deleteStaleCaptureKeys(
        keyStore: KeyStore,
        keep: String,
    ) {
        val cutoff = System.currentTimeMillis() - STALE_CAPTURE_KEY_MILLIS
        for (alias in keyStore.aliases().toList()) {
            if (alias == keep || !alias.startsWith(CAPTURE_KEY_PREFIX)) continue
            val createdAt = keyStore.getCreationDate(alias)?.time
            if (alias == LEGACY_CAPTURE_KEY_ALIAS || createdAt == null || createdAt < cutoff) {
                keyStore.deleteEntry(alias)
            }
        }
    }

    /** The keystore alias for one capture window, or null for a malformed id. */
    private fun captureKeyAlias(captureId: String?): String? =
        captureId?.takeIf { CAPTURE_ID_PATTERN.matches(it) }?.let { "$CAPTURE_KEY_PREFIX$it" }

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
        const val CAPTURE_KEY_PREFIX = "verily_capture_"
        const val LEGACY_CAPTURE_KEY_ALIAS = "verily_capture_provenance_v1"
        const val ANDROID_KEY_STORE = "AndroidKeyStore"
        const val MAX_MANIFEST_BYTES = 4096

        // Key Attestation accepts challenges up to 128 bytes; Verily's is a
        // 32-byte SHA-256.
        const val MAX_ATTESTATION_CHALLENGE_BYTES = 128
        const val COORDINATE_BYTES = 32

        // Longer than any capture window lives on the server.
        const val STALE_CAPTURE_KEY_MILLIS = 2 * 60 * 60 * 1000L
        val CAPTURE_ID_PATTERN = Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
    }
}
