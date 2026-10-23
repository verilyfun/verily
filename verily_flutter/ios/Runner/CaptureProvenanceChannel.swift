import DeviceCheck
import Flutter
import Foundation
import Security

/// Hosts `app.verily/capture_provenance` on iOS: the App Attest key an
/// iPhone signs its captures with.
///
/// Dart decides when to register a key and what to sign; this side wraps
/// `DCAppAttestService` and keeps each account's key identifier in the
/// Keychain. The key itself never leaves the Secure Enclave, and the server
/// learns it only from the attestation Apple signs.
final class CaptureProvenanceChannel {
  private static let name = "app.verily/capture_provenance"

  private let service = DCAppAttestService.shared
  private let keychain = AppAttestKeychain()

  /// Registers the channel's handler on [messenger], which keeps it alive.
  static func register(with messenger: FlutterBinaryMessenger) {
    let handler = CaptureProvenanceChannel()
    FlutterMethodChannel(name: name, binaryMessenger: messenger)
      .setMethodCallHandler { call, result in handler.handle(call, result: result) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "appAttestSupported": result(service.isSupported)
    case "readAppAttestKey": readKey(arguments, result: result)
    case "generateAppAttestKey": generateKey(arguments, result: result)
    case "attestAppAttestKey": attestKey(arguments, result: result)
    case "markAppAttestKeyRegistered": markRegistered(arguments, result: result)
    case "generateAppAttestAssertion": generateAssertion(arguments, result: result)
    case "discardAppAttestKey": discardKey(arguments, result: result)
    case "generateDeviceCheckToken": generateDeviceCheckToken(result: result)
    default: result(FlutterMethodNotImplemented)
    }
  }

  /// Ephemeral token for server-owned durable abuse flags. It is sent only
  /// with the capture assertion; the server never stores it.
  private func generateDeviceCheckToken(result: @escaping FlutterResult) {
    let device = DCDevice.current
    guard device.isSupported else { return result(Self.unsupported) }
    device.generateToken { token, error in
      DispatchQueue.main.async { Self.complete(result, data: token, error: error) }
    }
  }

  private func readKey(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard let account = Self.account(arguments) else { return result(Self.invalidRequest) }
    do {
      guard let stored = try keychain.read(account: account) else { return result(nil) }
      result(["keyId": stored.keyId, "registered": stored.registered])
    } catch {
      result(Self.keychainFailure(error))
    }
  }

  private func generateKey(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard let account = Self.account(arguments) else { return result(Self.invalidRequest) }
    guard service.isSupported else { return result(Self.unsupported) }
    service.generateKey { keyId, error in
      DispatchQueue.main.async {
        if let error { return result(Self.appAttestFailure(error)) }
        guard let keyId else { return result(Self.unexpectedResponse) }
        do {
          // Recorded before attestation: Apple says to keep the identifier,
          // because the key cannot be used or found again without it.
          try self.keychain.write(.init(keyId: keyId, registered: false), account: account)
          result(keyId)
        } catch {
          result(Self.keychainFailure(error))
        }
      }
    }
  }

  private func attestKey(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard let keyId = Self.keyId(arguments), let hash = Self.clientDataHash(arguments) else {
      return result(Self.invalidRequest)
    }
    service.attestKey(keyId, clientDataHash: hash) { attestation, error in
      DispatchQueue.main.async { Self.complete(result, data: attestation, error: error) }
    }
  }

  private func markRegistered(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard let account = Self.account(arguments), let keyId = Self.keyId(arguments) else {
      return result(Self.invalidRequest)
    }
    do {
      // Only the key this account generated can become its signing key.
      guard try keychain.read(account: account)?.keyId == keyId else {
        return result(FlutterError(code: "invalid_key", message: Self.unavailableMessage, details: nil))
      }
      try keychain.write(.init(keyId: keyId, registered: true), account: account)
      result(nil)
    } catch {
      result(Self.keychainFailure(error))
    }
  }

  private func generateAssertion(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard let keyId = Self.keyId(arguments), let hash = Self.clientDataHash(arguments) else {
      return result(Self.invalidRequest)
    }
    service.generateAssertion(keyId, clientDataHash: hash) { assertion, error in
      DispatchQueue.main.async { Self.complete(result, data: assertion, error: error) }
    }
  }

  private func discardKey(_ arguments: [String: Any], result: @escaping FlutterResult) {
    guard let account = Self.account(arguments) else { return result(Self.invalidRequest) }
    do {
      try keychain.delete(account: account)
      result(nil)
    } catch {
      result(Self.keychainFailure(error))
    }
  }

  /// Answers with the bytes App Attest returned, or the error it reported.
  private static func complete(_ result: FlutterResult, data: Data?, error: Error?) {
    if let error { return result(appAttestFailure(error)) }
    guard let data else { return result(unexpectedResponse) }
    result(FlutterStandardTypedData(bytes: data))
  }

  // MARK: Arguments

  /// A Verily account id: a lowercase UUID.
  private static func account(_ arguments: [String: Any]) -> String? {
    guard let account = arguments["account"] as? String,
          account.range(of: accountPattern, options: .regularExpression) != nil
    else { return nil }
    return account
  }

  /// Apple's key identifier: the key's SHA-256, base64.
  private static func keyId(_ arguments: [String: Any]) -> String? {
    guard let keyId = arguments["keyId"] as? String,
          Data(base64Encoded: keyId)?.count == 32
    else { return nil }
    return keyId
  }

  /// A SHA-256 digest the server can recompute.
  private static func clientDataHash(_ arguments: [String: Any]) -> Data? {
    guard let hash = arguments["clientDataHash"] as? FlutterStandardTypedData,
          hash.data.count == 32
    else { return nil }
    return hash.data
  }

  private static let accountPattern =
    "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"

  // MARK: Errors

  // The type names help diagnosis without exposing key material or device
  // detail to the person.
  private static let unavailableMessage = "Device signing is unavailable."

  private static let invalidRequest = FlutterError(
    code: "invalid_app_attest_request",
    message: "The device signing request is invalid.",
    details: nil
  )

  private static let unsupported = FlutterError(
    code: "unsupported",
    message: unavailableMessage,
    details: nil
  )

  private static let unexpectedResponse = FlutterError(
    code: "app_attest_failed",
    message: unavailableMessage,
    details: nil
  )

  /// Maps `DCError` to the codes Dart acts on: `server_unavailable` (retry
  /// later with the same key) and `invalid_key` (make a new one).
  private static func appAttestFailure(_ error: Error) -> FlutterError {
    let code: String
    switch (error as? DCError)?.code {
    case .serverUnavailable?: code = "server_unavailable"
    case .invalidKey?: code = "invalid_key"
    case .featureUnsupported?: code = "unsupported"
    default: code = "app_attest_failed"
    }
    return FlutterError(
      code: code,
      message: unavailableMessage,
      details: String(describing: type(of: error))
    )
  }

  private static func keychainFailure(_ error: Error) -> FlutterError {
    FlutterError(
      code: "keychain_failed",
      message: unavailableMessage,
      details: String(describing: type(of: error))
    )
  }
}

/// Each account's App Attest key identifier, kept in the Keychain on this
/// device only: Apple's keys do not survive a restore or migration, so
/// neither does the record of them.
struct AppAttestKeychain {
  struct StoredKey: Codable, Equatable {
    let keyId: String

    /// Whether the server accepted the key's attestation.
    let registered: Bool
  }

  struct Failure: Error {
    let status: OSStatus
  }

  private let service = "app.verily.app-attest"

  func read(account: String) throws -> StoredKey? {
    var query = itemQuery(account: account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess, let data = item as? Data else { throw Failure(status: status) }
    return try JSONDecoder().decode(StoredKey.self, from: data)
  }

  func write(_ key: StoredKey, account: String) throws {
    let data = try JSONEncoder().encode(key)
    let updated = SecItemUpdate(
      itemQuery(account: account) as CFDictionary,
      [kSecValueData as String: data] as CFDictionary
    )
    if updated == errSecSuccess { return }
    guard updated == errSecItemNotFound else { throw Failure(status: updated) }
    var item = itemQuery(account: account)
    item[kSecValueData as String] = data
    item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let added = SecItemAdd(item as CFDictionary, nil)
    guard added == errSecSuccess else { throw Failure(status: added) }
  }

  func delete(account: String) throws {
    let status = SecItemDelete(itemQuery(account: account) as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else { throw Failure(status: status) }
  }

  private func itemQuery(account: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
  }
}
