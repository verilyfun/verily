import 'package:verily_server/src/action_verification/key_attestation/x509.dart';

/// Apple's App Attestation Root CA, pinned from
/// `https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem`
/// (fetched 22 Oct 2026; certificate SHA-256
/// `1C:B9:82:3B:A2:8B:A6:AD:…:62:42:C9:32`, file SHA-256 `c778d09a…`).
///
/// An ECDSA P-384 root valid from 18 March 2020 to 15 March 2045. It signs
/// "Apple App Attestation CA 1", which issues each attested key's
/// three-day credential certificate. Pinned rather than fetched, so a network
/// attacker or a misconfigured proxy can never add a root; compare it with
/// Apple's page if Apple announces a new one.
final List<X509Certificate> appleAppAttestationRoots = List.unmodifiable([
  certificateFromPem(_appAttestationRoot),
]);

const _appAttestationRoot = '''
-----BEGIN CERTIFICATE-----
MIICITCCAaegAwIBAgIQC/O+DvHN0uD7jG5yH2IXmDAKBggqhkjOPQQDAzBSMSYw
JAYDVQQDDB1BcHBsZSBBcHAgQXR0ZXN0YXRpb24gUm9vdCBDQTETMBEGA1UECgwK
QXBwbGUgSW5jLjETMBEGA1UECAwKQ2FsaWZvcm5pYTAeFw0yMDAzMTgxODMyNTNa
Fw00NTAzMTUwMDAwMDBaMFIxJjAkBgNVBAMMHUFwcGxlIEFwcCBBdHRlc3RhdGlv
biBSb290IENBMRMwEQYDVQQKDApBcHBsZSBJbmMuMRMwEQYDVQQIDApDYWxpZm9y
bmlhMHYwEAYHKoZIzj0CAQYFK4EEACIDYgAERTHhmLW07ATaFQIEVwTtT4dyctdh
NbJhFs/Ii2FdCgAHGbpphY3+d8qjuDngIN3WVhQUBHAoMeQ/cLiP1sOUtgjqK9au
Yen1mMEvRq9Sk3Jm5X8U62H+xTD3FE9TgS41o0IwQDAPBgNVHRMBAf8EBTADAQH/
MB0GA1UdDgQWBBSskRBTM72+aEH/pwyp5frq5eWKoTAOBgNVHQ8BAf8EBAMCAQYw
CgYIKoZIzj0EAwMDaAAwZQIwQgFGnByvsiVbpTKwSga0kP0e8EeDS4+sQmTvb7vn
53O5+FRXgeLhpJ06ysC5PrOyAjEAp5U4xDgEgllF7En3VcE3iexZZtKeYnpqtijV
oyFraWVIyd/dganmrduC1bmTBGwD
-----END CERTIFICATE-----
''';
