import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:solana_kit/solana_kit.dart';
import 'package:solana_kit_mobile_wallet_adapter/solana_kit_mobile_wallet_adapter.dart';
import 'package:solana_kit_mobile_wallet_adapter_protocol/solana_kit_mobile_wallet_adapter_protocol.dart';

/// Why a wallet request did not finish, in terms the screen can explain.
enum WalletFailure {
  /// No Mobile Wallet Adapter wallet on this device, or not Android.
  unavailable,

  /// The person declined in the wallet.
  cancelled,

  /// The wallet did not answer in time.
  timedOut,

  /// The wallet authorized a different account than the one required.
  wrongAccount,

  /// The wallet answered with something unusable.
  invalidResponse,

  /// Anything else; the cause is logged.
  failed,
}

class WalletException implements Exception {
  const WalletException(this.failure, [this.cause]);

  final WalletFailure failure;
  final Object? cause;

  @override
  String toString() =>
      'WalletException(${failure.name}${cause == null ? '' : ': $cause'})';
}

/// What a wallet can do once it has authorized one account for this app.
abstract interface class WalletConnection {
  /// The authorized account, base58.
  String get address;

  /// Signs the UTF-8 bytes of [message] and returns the 64-byte ed25519
  /// signature, base58.
  Future<String> signMessage(String message);

  /// Signs [wireTransaction] (serialized, unsigned) and sends it; returns the
  /// transaction signature, base58.
  Future<String> signAndSendTransaction(Uint8List wireTransaction);
}

/// The Solana chain a wallet request targets.
enum WalletChain {
  devnet('solana:devnet'),
  mainnet('solana:mainnet');

  const WalletChain(this.id);

  final String id;
}

/// A wallet on this device that can approve requests.
abstract interface class MobileWallet {
  /// Whether this platform can reach a wallet at all (Android only).
  bool get isSupported;

  /// Opens a wallet session on [chain], authorizes one account, runs [body]
  /// with it, and closes the session. Throws [WalletException].
  Future<T> connect<T>({
    required WalletChain chain,
    required Future<T> Function(WalletConnection wallet) body,
  });
}

/// Solana Mobile Wallet Adapter (Android). On other platforms
/// [isSupported] is false and [connect] throws
/// [WalletFailure.unavailable].
class MobileWalletAdapter implements MobileWallet {
  const MobileWalletAdapter();

  static final _identity = AppIdentity(
    uri: Uri.parse('https://verily.fun'),
    name: 'Verily',
  );

  @override
  bool get isSupported => isMwaSupported();

  @override
  Future<T> connect<T>({
    required WalletChain chain,
    required Future<T> Function(WalletConnection wallet) body,
  }) async {
    if (!isSupported || !await MwaClientHostApi().isWalletEndpointAvailable()) {
      throw const WalletException(WalletFailure.unavailable);
    }
    try {
      return await transact((wallet) async {
        final authorization = await wallet.authorize(
          identity: _identity,
          chain: chain.id,
        );
        if (authorization.accounts.isEmpty) {
          throw const WalletException(WalletFailure.invalidResponse);
        }
        final account = authorization.accounts.first;
        return body(
          _MwaConnection(
            wallet,
            account: account,
            address: _base58Address(account.address),
          ),
        );
      });
    } on WalletException {
      rethrow;
    } on SolanaError catch (error) {
      throw WalletException(_failureFor(error.code), error);
    } on MwaProtocolError catch (error) {
      throw WalletException(switch (error.code) {
        MwaProtocolErrorCode.authorizationFailed ||
        MwaProtocolErrorCode.notSigned => WalletFailure.cancelled,
        _ => WalletFailure.failed,
      }, error);
    }
  }

  static WalletFailure _failureFor(SolanaErrorCode code) => switch (code) {
    SolanaErrorCode.mwaWalletNotFound ||
    SolanaErrorCode.mwaPlatformNotSupported => WalletFailure.unavailable,
    SolanaErrorCode.mwaSessionTimeout => WalletFailure.timedOut,
    SolanaErrorCode.mwaSessionClosed ||
    SolanaErrorCode.mwaProtocolAuthorizationFailed => WalletFailure.cancelled,
    _ => WalletFailure.failed,
  };
}

class _MwaConnection implements WalletConnection {
  _MwaConnection(this._wallet, {required this._account, required this.address});

  final KitMobileWallet _wallet;
  final MwaAccount _account;

  @override
  final String address;

  @override
  Future<String> signMessage(String message) async {
    final messageBytes = Uint8List.fromList(utf8.encode(message));
    final signed = await _wallet.signMessages(
      addresses: [_account.address],
      payloads: [base64Encode(messageBytes)],
    );
    if (signed.length != 1) {
      throw const WalletException(WalletFailure.invalidResponse);
    }
    // Wallets return either the signature alone or the message followed by
    // its signature; the signature is always the last 64 bytes.
    final payload = base64Decode(signed.single);
    if (payload.length < 64) {
      throw const WalletException(WalletFailure.invalidResponse);
    }
    return _base58(Uint8List.sublistView(payload, payload.length - 64));
  }

  @override
  Future<String> signAndSendTransaction(Uint8List wireTransaction) async {
    final signatures = await _wallet.signAndSendTransactions(
      payloads: [base64Encode(wireTransaction)],
    );
    if (signatures.length != 1) {
      throw const WalletException(WalletFailure.invalidResponse);
    }
    final signature = base64Decode(signatures.single);
    if (signature.length != 64) {
      throw const WalletException(WalletFailure.invalidResponse);
    }
    return _base58(signature);
  }
}

String _base58Address(String encodedAddress) {
  final bytes = base64Decode(encodedAddress);
  if (bytes.length != 32) {
    throw const WalletException(WalletFailure.invalidResponse);
  }
  return _base58(bytes);
}

String _base58(List<int> bytes) =>
    getBase58Decoder().decode(Uint8List.fromList(bytes));

final mobileWalletProvider = Provider<MobileWallet>(
  (ref) => const MobileWalletAdapter(),
);
