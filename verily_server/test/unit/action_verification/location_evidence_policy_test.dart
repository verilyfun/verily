import 'package:test/test.dart';
import 'package:verily_server/src/action_verification/location_evidence_policy.dart';

void main() {
  const policy = LocationEvidencePolicy();
  final now = DateTime.utc(2026, 8, 27, 12);

  test('accepts a fresh observation without location history', () {
    final risk = policy.evaluate(
      now: now,
      current: _observation(
        capturedAt: now.subtract(const Duration(seconds: 30)),
      ),
    );

    expect(risk, LocationEvidenceRisk.none);
  });

  test('rejects stale and future observations', () {
    expect(
      policy.evaluate(
        now: now,
        current: _observation(
          capturedAt: now.subtract(const Duration(minutes: 6)),
        ),
      ),
      LocationEvidenceRisk.stale,
    );
    expect(
      policy.evaluate(
        now: now,
        current: _observation(capturedAt: now.add(const Duration(minutes: 2))),
      ),
      LocationEvidenceRisk.fromFuture,
    );
  });

  test('flags travel that exceeds the server-owned speed ceiling', () {
    // London to Paris in three and a half minutes.
    final risk = policy.evaluate(
      now: now,
      previous: _previous(
        distanceMeters: 343923,
        capturedAt: now.subtract(const Duration(minutes: 4)),
      ),
      current: _observation(
        capturedAt: now.subtract(const Duration(seconds: 30)),
      ),
    );

    expect(risk, LocationEvidenceRisk.implausibleTravel);
  });

  test('flags long-distance travel with no elapsed time', () {
    final capturedAt = now.subtract(const Duration(seconds: 30));

    expect(
      policy.evaluate(
        now: now,
        previous: _previous(distanceMeters: 60000, capturedAt: capturedAt),
        current: _observation(capturedAt: capturedAt),
      ),
      LocationEvidenceRisk.implausibleTravel,
    );
  });

  test('allows plausible travel and ignores short-distance GPS drift', () {
    // London to Berlin over two hours.
    expect(
      policy.evaluate(
        now: now,
        previous: _previous(
          distanceMeters: 933000,
          capturedAt: now.subtract(const Duration(hours: 2)),
        ),
        current: _observation(
          capturedAt: now.subtract(const Duration(seconds: 30)),
        ),
      ),
      LocationEvidenceRisk.none,
    );
    expect(
      policy.evaluate(
        now: now,
        previous: _previous(
          distanceMeters: 13,
          capturedAt: now.subtract(const Duration(seconds: 31)),
        ),
        current: _observation(
          capturedAt: now.subtract(const Duration(seconds: 30)),
        ),
      ),
      LocationEvidenceRisk.none,
    );
  });

  test('subtracts both accuracy radii before judging travel distance', () {
    // 50.01 km measured, but each fix may be off by 10 m, so the effective
    // distance falls under the 50 km travel threshold.
    expect(
      policy.evaluate(
        now: now,
        previous: _previous(
          distanceMeters: 50010,
          capturedAt: now.subtract(const Duration(seconds: 31)),
        ),
        current: _observation(
          capturedAt: now.subtract(const Duration(seconds: 30)),
        ),
      ),
      LocationEvidenceRisk.none,
    );
  });
}

LocationObservation _observation({required DateTime capturedAt}) =>
    LocationObservation(accuracyMeters: 10, capturedAt: capturedAt);

PreviousLocationObservation _previous({
  required double distanceMeters,
  required DateTime capturedAt,
}) => PreviousLocationObservation(
  distanceMeters: distanceMeters,
  accuracyMeters: 10,
  capturedAt: capturedAt,
);
