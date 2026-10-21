import 'package:verily_flutter/features/wallet/mobile_wallet.dart';
import 'package:verily_flutter/l10n/l10n.dart';

/// What to tell someone whose wallet request ended with [failure].
String walletFailureMessage(AppLocalizations l10n, WalletFailure failure) =>
    switch (failure) {
      WalletFailure.unavailable => l10n.meWalletFailureUnavailable,
      WalletFailure.cancelled => l10n.meWalletFailureCancelled,
      WalletFailure.timedOut => l10n.meWalletFailureTimedOut,
      WalletFailure.wrongAccount => l10n.meWalletFailureWrongAccount,
      WalletFailure.invalidResponse => l10n.meWalletFailureInvalidResponse,
      WalletFailure.failed => l10n.meWalletFailureFailed,
    };

/// A wallet address with its middle elided, such as `7t4r…xqP1`.
String shortWalletAddress(String address) => address.length <= 10
    ? address
    : '${address.substring(0, 4)}…${address.substring(address.length - 4)}';
