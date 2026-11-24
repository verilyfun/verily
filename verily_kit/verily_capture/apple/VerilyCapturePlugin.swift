import AVFoundation
import CoreLocation
import CoreMotion
import CryptoKit
import Foundation
import LeptosKitBridge

/// Verily live capture plugin for iOS (`"verily-capture"`).
///
/// Supports fresh photo, video, microphone audio, QR scanning, motion trace,
/// location observation, and streaming upload of SHA-256-verified captures.
/// Never opens the photo library or document picker.
@MainActor
public final class VerilyCapturePlugin: NSObject, NativePlugin {
    public let name = "verily-capture"
    public let methods: [UInt32] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

    private struct StoredCapture {
        let url: URL
        let sha256Hex: String
        let mimeType: String
    }

    private var captures: [String: StoredCapture] = [:]
    private var audioRecorder: AVAudioRecorder?
    private var activeAudioURL: URL?
    private var closed = false

    public override init() {
        super.init()
    }

    public func invoke(method: UInt32, payload: NativeBuffer) async throws -> Data {
        guard !closed else { throw PluginError.cancelled }
        let data = Data(payload)
        switch method {
        case 3:
            var offset = 0
            _ = try readU32(data, &offset)
            guard offset == data.count else { throw PluginError.invalidArgument }
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("audio_\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
            let recorder = try AVAudioRecorder(url: url, settings: settings)
            guard recorder.record() else { throw PluginError.nativeError }
            audioRecorder = recorder
            activeAudioURL = url
            return Data()
        case 4:
            guard data.isEmpty, let recorder = audioRecorder, let url = activeAudioURL else {
                throw PluginError.invalidArgument
            }
            recorder.stop()
            audioRecorder = nil
            activeAudioURL = nil
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            let durationMs = UInt32(max(0, Int(CMTimeGetSeconds(duration) * 1000)))
            return try registerCapture(url: url, mimeType: "audio/mp4", durationMs: durationMs)
        case 6:
            var offset = 0
            let durationMs = max(500, min(30_000, Int(try readU32(data, &offset))))
            guard offset == data.count else { throw PluginError.invalidArgument }
            let motion = CMMotionManager()
            guard motion.isDeviceMotionAvailable else { throw PluginError.unavailable }
            motion.deviceMotionUpdateInterval = 0.02
            var rows: [[Int64]] = []
            var startTime: TimeInterval?
            let queue = OperationQueue()
            motion.startDeviceMotionUpdates(to: queue) { dm, _ in
                guard let dm else { return }
                let t0 = startTime ?? {
                    startTime = dm.timestamp
                    return dm.timestamp
                }()
                let elapsedUs = max(0, Int64((dm.timestamp - t0) * 1_000_000))
                if rows.count < 1000 && (rows.isEmpty || elapsedUs > rows.last![0]) {
                    let g = dm.rotationRate
                    let a = dm.userAcceleration
                    let gr = dm.gravity
                    rows.append([
                        elapsedUs,
                        Int64((g.x * 1_000_000).rounded()),
                        Int64((g.y * 1_000_000).rounded()),
                        Int64((g.z * 1_000_000).rounded()),
                        Int64(((a.x + gr.x) * 9.80665 * 1_000_000).rounded()),
                        Int64(((a.y + gr.y) * 9.80665 * 1_000_000).rounded()),
                        Int64(((a.z + gr.z) * 9.80665 * 1_000_000).rounded()),
                    ])
                }
            }
            try await Task.sleep(nanoseconds: UInt64(durationMs) * 1_000_000)
            motion.stopDeviceMotionUpdates()
            let jsonObj: [String: Any] = ["version": 1, "samples": rows]
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObj)
            var out = Data()
            appendBytes(&out, jsonData)
            return out
        case 7:
            guard data.isEmpty else { throw PluginError.invalidArgument }
            let manager = CLLocationManager()
            guard let loc = manager.location else { throw PluginError.unavailable }
            let isSimulated = loc.sourceInformation?.isSimulatedBySoftware ?? false
            var out = Data()
            appendF64(&out, loc.coordinate.latitude)
            appendF64(&out, loc.coordinate.longitude)
            appendF64(&out, loc.horizontalAccuracy)
            appendI64(&out, Int64(loc.timestamp.timeIntervalSince1970 * 1000))
            appendU32(&out, isSimulated ? 1 : 0)
            return out
        case 8:
            var offset = 0
            let fileId = try readString(data, &offset)
            let uploadUrlStr = try readString(data, &offset)
            let mimeType = try readString(data, &offset)
            let expectedSha = try readString(data, &offset)
            guard offset == data.count,
                  let stored = captures[fileId],
                  stored.sha256Hex == expectedSha,
                  let url = URL(string: uploadUrlStr)
            else {
                throw PluginError.invalidArgument
            }
            let fileBytes = try Data(contentsOf: stored.url)
            let actualSha = SHA256.hash(data: fileBytes).map { String(format: "%02x", $0) }.joined()
            guard actualSha == expectedSha else { throw PluginError.nativeError }
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue(mimeType, forHTTPHeaderField: "Content-Type")
            let (_, resp) = try await URLSession.shared.upload(for: req, fromFile: stored.url)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw PluginError.nativeError
            }
            let versionId = http.value(forHTTPHeaderField: "x-amz-version-id") ?? ""
            var out = Data()
            appendBytes(&out, Data(versionId.utf8))
            return out
        case 9:
            var offset = 0
            let fileId = try readString(data, &offset)
            guard offset == data.count else { throw PluginError.invalidArgument }
            if let removed = captures.removeValue(forKey: fileId) {
                try? FileManager.default.removeItem(at: removed.url)
            }
            return Data()
        default:
            throw PluginError.unavailable
        }
    }

    public func close() {
        closed = true
        audioRecorder?.stop()
        for entry in captures.values {
            try? FileManager.default.removeItem(at: entry.url)
        }
        captures.removeAll()
    }

    private func registerCapture(url: URL, mimeType: String, durationMs: UInt32) throws -> Data {
        let bytes = try Data(contentsOf: url)
        let sha = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        let fileId = UUID().uuidString
        captures[fileId] = StoredCapture(url: url, sha256Hex: sha, mimeType: mimeType)
        var out = Data()
        appendBytes(&out, Data(fileId.utf8))
        appendBytes(&out, Data(sha.utf8))
        appendI64(&out, Int64(bytes.count))
        appendBytes(&out, Data(mimeType.utf8))
        appendU32(&out, durationMs)
        return out
    }

    private func appendU32(_ out: inout Data, _ value: UInt32) {
        var le = value.littleEndian
        withUnsafeBytes(of: &le) { out.append(contentsOf: $0) }
    }

    private func appendI64(_ out: inout Data, _ value: Int64) {
        var le = value.littleEndian
        withUnsafeBytes(of: &le) { out.append(contentsOf: $0) }
    }

    private func appendF64(_ out: inout Data, _ value: Double) {
        var bits = value.bitPattern.littleEndian
        withUnsafeBytes(of: &bits) { out.append(contentsOf: $0) }
    }

    private func appendBytes(_ out: inout Data, _ bytes: Data) {
        appendU32(&out, UInt32(bytes.count))
        out.append(bytes)
    }

    private func readU32(_ data: Data, _ offset: inout Int) throws -> UInt32 {
        guard offset + 4 <= data.count else { throw PluginError.invalidArgument }
        let value = data.subdata(in: offset..<(offset + 4)).withUnsafeBytes {
            $0.load(as: UInt32.self).littleEndian
        }
        offset += 4
        return value
    }

    private func readString(_ data: Data, _ offset: inout Int) throws -> String {
        let len = Int(try readU32(data, &offset))
        guard len >= 0, offset + len <= data.count else { throw PluginError.invalidArgument }
        let slice = data.subdata(in: offset..<(offset + len))
        offset += len
        guard let str = String(data: slice, encoding: .utf8) else {
            throw PluginError.invalidArgument
        }
        return str
    }
}
