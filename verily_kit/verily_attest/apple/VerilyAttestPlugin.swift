import DeviceCheck
import Foundation
import LeptosKitBridge
import Security

/// Verily device attestation plugin for iOS (`"verily-attest"`).
///
/// Wraps `DCAppAttestService` (one Secure Enclave key per account persisted in
/// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` Keychain) and
/// `DCDevice.current.generateToken` (DeviceCheck).
@MainActor
public final class VerilyAttestPlugin: NativePlugin {
    public let name = "verily-attest"
    public let methods: [UInt32] = [10, 11, 12, 13, 14, 15, 16, 17]

    private let service = DCAppAttestService.shared
    private let keychain = AppAttestKeychain()
    private var closed = false

    public init() {}

    public func invoke(method: UInt32, payload: NativeBuffer) async throws -> Data {
        guard !closed else { throw PluginError.cancelled }
        let data = Data(payload)
        switch method {
        case 10:
            guard data.isEmpty else { throw PluginError.invalidArgument }
            var out = Data()
            appendU32(&out, service.isSupported ? 1 : 0)
            return out
        case 11:
            let account = try readSingleAccount(data)
            let stored = try keychain.read(account: account)
            var out = Data()
            if let stored {
                appendU32(&out, 1)
                appendBytes(&out, Data(stored.keyId.utf8))
                appendU32(&out, stored.registered ? 1 : 0)
            } else {
                appendU32(&out, 0)
            }
            return out
        case 12:
            let account = try readSingleAccount(data)
            guard service.isSupported else { throw PluginError.unavailable }
            let keyId = try await service.generateKey()
            try keychain.write(.init(keyId: keyId, registered: false), account: account)
            var out = Data()
            appendBytes(&out, Data(keyId.utf8))
            return out
        case 13:
            let (keyId, hash) = try readKeyHash(data)
            let attestation = try await service.attestKey(keyId, clientDataHash: hash)
            var out = Data()
            appendBytes(&out, attestation)
            return out
        case 14:
            var offset = 0
            let account = try readString(data, &offset)
            let keyId = try readString(data, &offset)
            guard offset == data.count, Self.validAccount(account), Self.validKeyId(keyId) else {
                throw PluginError.invalidArgument
            }
            guard try keychain.read(account: account)?.keyId == keyId else {
                throw PluginError.invalidArgument
            }
            try keychain.write(.init(keyId: keyId, registered: true), account: account)
            return Data()
        case 15:
            let (keyId, hash) = try readKeyHash(data)
            let assertion = try await service.generateAssertion(keyId, clientDataHash: hash)
            var out = Data()
            appendBytes(&out, assertion)
            return out
        case 16:
            let account = try readSingleAccount(data)
            try keychain.delete(account: account)
            return Data()
        case 17:
            guard data.isEmpty else { throw PluginError.invalidArgument }
            guard DCDevice.current.isSupported else { throw PluginError.unavailable }
            let token = try await DCDevice.current.generateToken()
            var out = Data()
            appendBytes(&out, token)
            return out
        default:
            throw PluginError.unavailable
        }
    }

    public func close() {
        closed = true
    }

    private func readSingleAccount(_ data: Data) throws -> String {
        var offset = 0
        let account = try readString(data, &offset)
        guard offset == data.count, Self.validAccount(account) else {
            throw PluginError.invalidArgument
        }
        return account
    }

    private func readKeyHash(_ data: Data) throws -> (String, Data) {
        var offset = 0
        let keyId = try readString(data, &offset)
        let hash = try readBytes(data, &offset)
        guard offset == data.count, Self.validKeyId(keyId), hash.count == 32 else {
            throw PluginError.invalidArgument
        }
        return (keyId, hash)
    }

    private static func validAccount(_ account: String) -> Bool {
        account.range(
            of: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
            options: .regularExpression
        ) != nil
    }

    private static func validKeyId(_ keyId: String) -> Bool {
        Data(base64Encoded: keyId)?.count == 32
    }

    private func appendU32(_ out: inout Data, _ value: UInt32) {
        var le = value.littleEndian
        withUnsafeBytes(of: &le) { out.append(contentsOf: $0) }
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

    private func readBytes(_ data: Data, _ offset: inout Int) throws -> Data {
        let len = Int(try readU32(data, &offset))
        guard len >= 0, offset + len <= data.count else { throw PluginError.invalidArgument }
        let slice = data.subdata(in: offset..<(offset + len))
        offset += len
        return slice
    }

    private func readString(_ data: Data, _ offset: inout Int) throws -> String {
        let bytes = try readBytes(data, &offset)
        guard let str = String(data: bytes, encoding: .utf8) else {
            throw PluginError.invalidArgument
        }
        return str
    }
}

private struct AppAttestKeychain {
    struct StoredKey: Codable, Equatable {
        let keyId: String
        let registered: Bool
    }

    private let service = "app.verily.app-attest"

    func read(account: String) throws -> StoredKey? {
        var query = itemQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw PluginError.nativeError
        }
        return try JSONDecoder().decode(StoredKey.self, from: data)
    }

    func write(_ key: StoredKey, account: String) throws {
        let data = try JSONEncoder().encode(key)
        let updated = SecItemUpdate(
            itemQuery(account: account) as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updated == errSecSuccess { return }
        guard updated == errSecItemNotFound else { throw PluginError.nativeError }
        var item = itemQuery(account: account)
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
            throw PluginError.nativeError
        }
    }

    func delete(account: String) throws {
        let status = SecItemDelete(itemQuery(account: account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PluginError.nativeError
        }
    }

    private func itemQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
