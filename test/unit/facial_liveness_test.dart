import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/domain/entities/attendance_record.dart';
import 'package:octet_pulse_app/domain/entities/liveness_challenge.dart';
import 'package:octet_pulse_app/domain/services/liveness_service.dart';

void main() {
  group('LivenessService & LivenessChallenge Unit Tests', () {
    test(
      'generateChallengeSequence returns expected count of valid actions',
      () {
        final sequence = LivenessService.generateChallengeSequence(count: 2);
        expect(sequence.length, equals(2));
        expect(
          sequence.every((action) => LivenessAction.values.contains(action)),
          isTrue,
        );
      },
    );

    test(
      'createAttestation generates valid SHA-256 hash and attestation record',
      () {
        final actions = [LivenessAction.blink, LivenessAction.smile];
        final attestation = LivenessService.createAttestation(
          employeeId: 'EMP-101',
          completedActions: actions,
          luxLevel: 145.0,
          isFallbackUsed: false,
        );

        expect(attestation.challengeId, startsWith('CHAL-'));
        expect(attestation.employeeId, equals('EMP-101'));
        expect(attestation.completedActions, equals(actions));
        expect(attestation.luxLevel, equals(145.0));
        expect(attestation.isFallbackUsed, isFalse);
        expect(attestation.confidenceScore, greaterThanOrEqualTo(0.95));
        expect(attestation.attestationHash, isNotEmpty);
        expect(
          attestation.attestationHash.length,
          equals(64),
        ); // SHA-256 hex string length
      },
    );

    test('createAttestation with fallback supervisor PIN generates valid override attestation', () {
      final attestation = LivenessService.createAttestation(
        employeeId: 'EMP-102',
        completedActions: const [],
        luxLevel: 12.0,
        isFallbackUsed: true,
      );

      expect(attestation.isFallbackUsed, isTrue);
      expect(attestation.confidenceScore, equals(0.75));
      expect(attestation.attestationHash, isNotEmpty);
    });

    test(
      'verifyAttestation validates correct employee ID and non-empty hash',
      () {
        final attestation = LivenessService.createAttestation(
          employeeId: 'EMP-101',
          completedActions: [LivenessAction.nod],
          luxLevel: 120.0,
        );

        expect(
          LivenessService.verifyAttestation(
            attestation: attestation,
            expectedEmployeeId: 'EMP-101',
          ),
          isTrue,
        );

        expect(
          LivenessService.verifyAttestation(
            attestation: attestation,
            expectedEmployeeId: 'EMP-999',
          ),
          isFalse,
        );
      },
    );

    test(
      'simulateAmbientLux outputs expected ranges for normal vs low light',
      () {
        final normalLux = LivenessService.simulateAmbientLux(
          simulateLowLight: false,
        );
        expect(normalLux, greaterThanOrEqualTo(20.0));

        final lowLux = LivenessService.simulateAmbientLux(
          simulateLowLight: true,
        );
        expect(lowLux, lessThan(20.0));
      },
    );

    test(
      'LivenessAttestation toMap and fromMap roundtrip preserves all fields',
      () {
        final original = LivenessService.createAttestation(
          employeeId: 'EMP-555',
          completedActions: [LivenessAction.turnHead, LivenessAction.smile],
          luxLevel: 88.5,
          isFallbackUsed: false,
        );

        final map = original.toMap();
        final reconstructed = LivenessAttestation.fromMap(map);

        expect(reconstructed.challengeId, equals(original.challengeId));
        expect(reconstructed.employeeId, equals(original.employeeId));
        expect(
          reconstructed.completedActions,
          equals(original.completedActions),
        );
        expect(reconstructed.confidenceScore, equals(original.confidenceScore));
        expect(reconstructed.luxLevel, equals(original.luxLevel));
        expect(reconstructed.isFallbackUsed, equals(original.isFallbackUsed));
        expect(reconstructed.attestationHash, equals(original.attestationHash));
      },
    );

    test(
      'AttendanceRecord preserves biometric liveness fields across copyWith',
      () {
        final now = DateTime.now();
        final record = AttendanceRecord(
          id: 'ATT-777',
          employeeId: 'EMP-101',
          employeeName: 'Safeer Hussain',
          checkInTime: now,
          durationSeconds: 3600,
          status: 'Clocked In',
          isWithinGeofence: true,
          latitude: 31.47,
          longitude: 74.30,
          geofenceDistanceMeters: 14.2,
          livenessAttestationHash: 'abc123def456789',
          isBiometricallyVerified: true,
          livenessLuxLevel: 130.5,
        );

        expect(record.livenessAttestationHash, equals('abc123def456789'));
        expect(record.isBiometricallyVerified, isTrue);
        expect(record.livenessLuxLevel, equals(130.5));

        final updated = record.copyWith(
          status: 'Clocked Out',
          isBiometricallyVerified: true,
          livenessLuxLevel: 140.0,
        );
        expect(updated.livenessAttestationHash, equals('abc123def456789'));
        expect(updated.isBiometricallyVerified, isTrue);
        expect(updated.livenessLuxLevel, equals(140.0));
        expect(updated.status, equals('Clocked Out'));
      },
    );
  });
}
