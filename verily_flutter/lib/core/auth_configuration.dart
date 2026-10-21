/// Which sign-in methods this build offers.
///
/// Email sign-in is on unless a build turns it off; Google needs its OAuth
/// client configured on the server and in the build, so it is opt-in.
const emailAuthEnabled = bool.fromEnvironment(
  'VERILY_EMAIL_AUTH_ENABLED',
  defaultValue: true,
);

const googleAuthEnabled = bool.fromEnvironment('VERILY_GOOGLE_AUTH_ENABLED');
