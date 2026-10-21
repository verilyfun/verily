// Auto-generated. Do not edit.
// ignore_for_file: type=lint, constant_identifier_names

/// Error codes for the VerilyEscrow program.

/// The signer is not the escrow's creator.
/// Message: "The signer is not the escrow's creator."
const int verilyEscrowErrorNotCreator = 0x0; // 0

/// The signer is not the escrow's arbiter.
/// Message: "The signer is not the escrow's arbiter."
const int verilyEscrowErrorNotArbiter = 0x1; // 1

/// The mint or a token account does not hold the escrow's reward token.
/// Message: "The mint or a token account does not hold the escrow's reward token."
const int verilyEscrowErrorMintMismatch = 0x2; // 2

/// The vault is not the escrow's associated token account for its mint.
/// Message: "The vault is not the escrow's associated token account for its mint."
const int verilyEscrowErrorVaultMismatch = 0x3; // 3

/// Each payout must be at least one token atom.
/// Message: "Each payout must be at least one token atom."
const int verilyEscrowErrorInvalidPayoutAmount = 0x4; // 4

/// The number of payouts must be from 1 to 2048.
/// Message: "The number of payouts must be from 1 to 2048."
const int verilyEscrowErrorInvalidMaxPayouts = 0x5; // 5

/// The refund delay must be from 3 to 30 days.
/// Message: "The refund delay must be from 3 to 30 days."
const int verilyEscrowErrorInvalidRefundDelay = 0x6; // 6

/// The expiry must be in the future and its refund time must fit in an i64.
/// Message: "The expiry must be in the future and its refund time must fit in an i64."
const int verilyEscrowErrorInvalidExpiry = 0x7; // 7

/// The payout amount times the number of payouts does not fit in a u64.
/// Message: "The payout amount times the number of payouts does not fit in a u64."
const int verilyEscrowErrorBudgetOverflow = 0x8; // 8

/// The arbiter must be a real key that is not the creator.
/// Message: "The arbiter must be a real key that is not the creator."
const int verilyEscrowErrorInvalidArbiter = 0x9; // 9

/// The payout index is not below the escrow's number of payouts.
/// Message: "The payout index is not below the escrow's number of payouts."
const int verilyEscrowErrorPayoutIndexOutOfRange = 0xa; // 10

/// This payout index was already released.
/// Message: "This payout index was already released."
const int verilyEscrowErrorPayoutAlreadyReleased = 0xb; // 11

/// The refund window has opened, so no more payouts can be released.
/// Message: "The refund window has opened, so no more payouts can be released."
const int verilyEscrowErrorReleaseWindowClosed = 0xc; // 12

/// The escrow can close only from its refund time or once every payout is released.
/// Message: "The escrow can close only from its refund time or once every payout is released."
const int verilyEscrowErrorEscrowStillOpen = 0xd; // 13

/// A payout cannot go to a token account the escrow itself owns.
/// Message: "A payout cannot go to a token account the escrow itself owns."
const int verilyEscrowErrorInvalidRecipient = 0xe; // 14

/// Map of error codes to human-readable messages.
const Map<int, String> _verilyEscrowErrorMessages = {
  verilyEscrowErrorNotCreator: 'The signer is not the escrow\'s creator.',
  verilyEscrowErrorNotArbiter: 'The signer is not the escrow\'s arbiter.',
  verilyEscrowErrorMintMismatch:
      'The mint or a token account does not hold the escrow\'s reward token.',
  verilyEscrowErrorVaultMismatch:
      'The vault is not the escrow\'s associated token account for its mint.',
  verilyEscrowErrorInvalidPayoutAmount:
      'Each payout must be at least one token atom.',
  verilyEscrowErrorInvalidMaxPayouts:
      'The number of payouts must be from 1 to 2048.',
  verilyEscrowErrorInvalidRefundDelay:
      'The refund delay must be from 3 to 30 days.',
  verilyEscrowErrorInvalidExpiry: 'The expiry must be in the future and its refund time must fit in an i64.',
  verilyEscrowErrorBudgetOverflow:
      'The payout amount times the number of payouts does not fit in a u64.',
  verilyEscrowErrorInvalidArbiter:
      'The arbiter must be a real key that is not the creator.',
  verilyEscrowErrorPayoutIndexOutOfRange:
      'The payout index is not below the escrow\'s number of payouts.',
  verilyEscrowErrorPayoutAlreadyReleased:
      'This payout index was already released.',
  verilyEscrowErrorReleaseWindowClosed:
      'The refund window has opened, so no more payouts can be released.',
  verilyEscrowErrorEscrowStillOpen: 'The escrow can close only from its refund time or once every payout is released.',
  verilyEscrowErrorInvalidRecipient:
      'A payout cannot go to a token account the escrow itself owns.',
};

/// Get the error message for a VerilyEscrow program error code.
String? getVerilyEscrowErrorMessage(int code) {
  return _verilyEscrowErrorMessages[code];
}

/// Check if an error code belongs to the VerilyEscrow program.
bool isVerilyEscrowError(int code) {
  return _verilyEscrowErrorMessages.containsKey(code);
}
