package dev.verily.attest

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.StrongBoxUnavailableException
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import dev.leptoskit.bridge.NativePlugin
import dev.leptoskit.bridge.PluginException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.ProviderException
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Verily device attestation plugin for Android (`"verily-attest"`).
 *
 * Ports Verily's per-window Android KeyStore P-256 attestation (StrongBox
 * preferred with TEE fallback, DER -> IEEE P1363 64-byte signature, full X.509
 * chain export, stale key cleanup) and Play Integrity Standard API token
 * requests bound to `requestHash`.
 */
class VerilyAttestPlugin(
    context: Context,
) : NativePlugin {
    override val name: String = "verily-attest"
    override val methods: IntArray = intArrayOf(0, 1, 2)

    private val appContext = context.applicationContext
    @Volatile
    private var integrityTokenProvider: StandardIntegrityManager.StandardIntegrityTokenProvider? = null
    @Volatile
    private var closed = false

    override suspend fun invoke(method: Int, payload: ByteArray): ByteArray {
        if (closed) throw PluginException.cancelled()
        return when (method) {
            0 -> handlePrepareCaptureKey(payload)
            1 -> handleSignCaptureManifest(payload)
            2 -> handleRequestPlayIntegrity(payload)
            else -> throw PluginException.unavailable()
        }
    }

    override fun close() {
        closed = true
        integrityTokenProvider = null
    }

    private suspend fun handlePrepareCaptureKey(payload: ByteArray): ByteArray {
        val reader = WireReader(payload)
        val captureId = reader.readString()
        val challenge = reader.readBytes()
        reader.finish()

        val alias = captureKeyAlias(captureId) ?: throw PluginException.invalidArgument()
        if (challenge.isEmpty() || challenge.size > MAX_ATTESTATION_CHALLENGE_BYTES) {
            throw PluginException.invalidArgument()
        }

        withContext(Dispatchers.IO) {
            val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }
            deleteStaleCaptureKeys(keyStore, keep = alias)
            if (!keyStore.containsAlias(alias)) {
                generateCaptureKey(alias, challenge, preferStrongBox = hasStrongBox())
            }
        }
        return ByteArray(0)
    }

    private suspend fun handleSignCaptureManifest(payload: ByteArray): ByteArray {
        val reader = WireReader(payload)
        val captureId = reader.readString()
        val manifest = reader.readBytes()
        reader.finish()

        val alias = captureKeyAlias(captureId) ?: throw PluginException.invalidArgument()
        if (manifest.isEmpty() || manifest.size > MAX_MANIFEST_BYTES) {
            throw PluginException.invalidArgument()
        }

        val (sigP1363, chainDer) = withContext(Dispatchers.IO) {
            val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }
            val privateKey = keyStore.getKey(alias, null) as? PrivateKey
                ?: throw PluginException.nativeError()
            val chain = keyStore.getCertificateChain(alias)
                ?: throw PluginException.nativeError()
            val signer = Signature.getInstance("SHA256withECDSA").apply {
                initSign(privateKey)
                update(manifest)
            }
            derSignatureToP1363(signer.sign()) to chain.map { it.encoded }
        }

        val out = WireWriter()
        out.writeBytes(sigP1363)
        out.writeU32(chainDer.size)
        for (cert in chainDer) {
            out.writeBytes(cert)
        }
        return out.toByteArray()
    }

    private suspend fun handleRequestPlayIntegrity(payload: ByteArray): ByteArray {
        val reader = WireReader(payload)
        val requestHash = reader.readString()
        val lo = reader.readU32().toLong() and 0xFFFF_FFFFL
        val hi = reader.readU32().toLong() and 0xFFFF_FFFFL
        reader.finish()

        val cloudProjectNumber = lo or (hi shl 32)
        if (requestHash.isBlank() || cloudProjectNumber <= 0L) {
            throw PluginException.invalidArgument()
        }

        val provider = integrityTokenProvider ?: prepareIntegrityProvider(cloudProjectNumber).also {
            integrityTokenProvider = it
        }
        val token = try {
            requestToken(provider, requestHash)
        } catch (err: Exception) {
            integrityTokenProvider = null
            throw PluginException.nativeError()
        }

        val out = WireWriter()
        out.writeBytes(token.toByteArray(Charsets.UTF_8))
        return out.toByteArray()
    }

    private suspend fun prepareIntegrityProvider(
        cloudProjectNumber: Long,
    ): StandardIntegrityManager.StandardIntegrityTokenProvider =
        suspendCancellableCoroutine { cont ->
            val manager = IntegrityManagerFactory.createStandard(appContext)
            manager
                .prepareIntegrityToken(
                    StandardIntegrityManager.PrepareIntegrityTokenRequest.builder()
                        .setCloudProjectNumber(cloudProjectNumber)
                        .build(),
                )
                .addOnSuccessListener { prepared -> cont.resume(prepared) }
                .addOnFailureListener { cont.resumeWithException(PluginException.nativeError()) }
        }

    private suspend fun requestToken(
        provider: StandardIntegrityManager.StandardIntegrityTokenProvider,
        requestHash: String,
    ): String =
        suspendCancellableCoroutine { cont ->
            provider
                .request(
                    StandardIntegrityManager.StandardIntegrityTokenRequest.builder()
                        .setRequestHash(requestHash)
                        .build(),
                )
                .addOnSuccessListener { response -> cont.resume(response.token()) }
                .addOnFailureListener { err -> cont.resumeWithException(err) }
        }

    private fun generateCaptureKey(
        alias: String,
        attestationChallenge: ByteArray,
        preferStrongBox: Boolean,
    ) {
        val generator = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, ANDROID_KEY_STORE)
        val builder = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_SIGN)
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
            if (!preferStrongBox) throw error
            generateCaptureKey(alias, attestationChallenge, preferStrongBox = false)
        }
    }

    private fun hasStrongBox(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
            appContext.packageManager.hasSystemFeature(PackageManager.FEATURE_STRONGBOX_KEYSTORE)

    private fun deleteStaleCaptureKeys(keyStore: KeyStore, keep: String) {
        val cutoff = System.currentTimeMillis() - STALE_CAPTURE_KEY_MILLIS
        for (alias in keyStore.aliases().toList()) {
            if (alias == keep || !alias.startsWith(CAPTURE_KEY_PREFIX)) continue
            val createdAt = keyStore.getCreationDate(alias)?.time
            if (alias == LEGACY_CAPTURE_KEY_ALIAS || createdAt == null || createdAt < cutoff) {
                keyStore.deleteEntry(alias)
            }
        }
    }

    private fun captureKeyAlias(captureId: String): String? =
        captureId.takeIf { CAPTURE_ID_PATTERN.matches(it) }?.let { "$CAPTURE_KEY_PREFIX$it" }

    private fun derSignatureToP1363(der: ByteArray): ByteArray {
        var index = 0
        require(der[index++].toInt() and 0xff == 0x30)
        val seqLen = readDerLength(der, index)
        index += seqLen.second
        require(seqLen.first == der.size - index)
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
        val intLen = readDerLength(der, index)
        index += intLen.second
        var valueOffset = index
        var valueLength = intLen.first
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
        return index + intLen.first
    }

    private fun readDerLength(der: ByteArray, index: Int): Pair<Int, Int> {
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

    private class WireReader(private val bytes: ByteArray) {
        private var pos = 0

        fun readU32(): Int {
            if (pos + 4 > bytes.size) throw PluginException.invalidArgument()
            val v = ByteBuffer.wrap(bytes, pos, 4).order(ByteOrder.LITTLE_ENDIAN).int
            pos += 4
            return v
        }

        fun readBytes(): ByteArray {
            val len = readU32()
            if (len < 0 || pos + len > bytes.size) throw PluginException.invalidArgument()
            val out = bytes.copyOfRange(pos, pos + len)
            pos += len
            return out
        }

        fun readString(): String = String(readBytes(), Charsets.UTF_8)

        fun finish() {
            if (pos != bytes.size) throw PluginException.invalidArgument()
        }
    }

    private class WireWriter {
        private val stream = ByteArrayOutputStream(256)

        fun writeU32(value: Int) {
            stream.write(ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN).putInt(value).array())
        }

        fun writeBytes(value: ByteArray) {
            writeU32(value.size)
            stream.write(value)
        }

        fun toByteArray(): ByteArray = stream.toByteArray()
    }

    private companion object {
        const val CAPTURE_KEY_PREFIX = "verily_capture_"
        const val LEGACY_CAPTURE_KEY_ALIAS = "verily_capture_provenance_v1"
        const val ANDROID_KEY_STORE = "AndroidKeyStore"
        const val MAX_MANIFEST_BYTES = 4096
        const val MAX_ATTESTATION_CHALLENGE_BYTES = 128
        const val COORDINATE_BYTES = 32
        const val STALE_CAPTURE_KEY_MILLIS = 2 * 60 * 60 * 1000L
        val CAPTURE_ID_PATTERN =
            Regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
    }
}
