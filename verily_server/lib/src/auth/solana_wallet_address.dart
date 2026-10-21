import 'package:verily_server/src/auth/solana_auth_verify.dart';

/// Returns [walletAddress] trimmed after proving it decodes to a 32-byte
/// Solana public key.
String validatedSolanaWalletAddress(String walletAddress) {
  final normalized = walletAddress.trim();
  decodeBase58PublicKey(normalized);

  return normalized;
}

/// A short, recognizable label such as `7xKX…sAsU`.
String solanaWalletLabel(String walletAddress) {
  if (walletAddress.length <= 12) {
    return walletAddress;
  }

  return '${walletAddress.substring(0, 4)}…${walletAddress.substring(walletAddress.length - 4)}';
}
