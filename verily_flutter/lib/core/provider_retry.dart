/// Riverpod 3 retries a failed provider on its own with exponential backoff.
///
/// Verily shows every failed load with an explicit retry action instead, so a
/// failure stays visible and the server is not called again behind the
/// person's back. Pass this as the `retry` of every root `ProviderScope`.
Duration? noAutomaticProviderRetry(int retryCount, Object error) => null;
