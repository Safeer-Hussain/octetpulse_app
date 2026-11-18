import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../entities/liveness_challenge.dart';

class LivenessService {
  static const double lowLightThresholdLux = 20.0;
  static const String _attestationSalt =
      'OCTET_PULSE_FACIAL_LIVENESS_SALT_2026';
  static final _random = Random();
  static const _uuid = Uuid();

  static List<LivenessAction> generateChallengeSequence({int count = 2}) {
    final pool = List<LivenessAction>.from(LivenessAction.values);
    pool.shuffle(_random);
    return pool.take(count).toList();
  }

  static LivenessAttestation createAttestation({
    required String employeeId,
    required List<LivenessAction> completedActions,
    required double luxLevel,
    bool isFallbackUsed = false,
  }) {
    final challengeId = 'CHAL-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final timestamp = DateTime.now();

    final payload = [
      challengeId,
      employeeId,
      completedActions.map((a) => a.name).join(','),
      luxLevel.toStringAsFixed(1),
      isFallbackUsed ? 'FALLBACK_SUPERVISOR_PIN' : 'BIOMETRIC_PASS',
      timestamp.millisecondsSinceEpoch.toString(),
      _attestationSalt,
    ].join(':');

    final hash = sha256.convert(utf8.encode(payload)).toString();

    // Confidence score based on biometric actions vs fallback
    final confidence = isFallbackUsed
        ? 0.75
        : (0.95 + (_random.nextDouble() * 0.04));

    return LivenessAttestation(
      challengeId: challengeId,
      employeeId: employeeId,
      completedActions: completedActions,
      confidenceScore: (confidence * 100).round() / 100,
      luxLevel: luxLevel,
      isFallbackUsed: isFallbackUsed,
      attestationHash: hash,
      timestamp: timestamp,
    );
  }

  static bool verifyAttestation({
    required LivenessAttestation attestation,
    required String expectedEmployeeId,
  }) {
    if (attestation.employeeId != expectedEmployeeId) return false;
    if (attestation.attestationHash.isEmpty) return false;
    return true;
  }

  static double simulateAmbientLux({bool simulateLowLight = false}) {
    if (simulateLowLight) {
      return 8.0 + (_random.nextDouble() * 8.0); // 8-16 lux (< 20 threshold)
    }
    return 110.0 + (_random.nextDouble() * 80.0); // 110-190 lux (optimal)
  }
}
