import 'package:flutter/material.dart';

enum LivenessAction {
  blink,
  smile,
  nod,
  turnHead;

  String get displayName {
    switch (this) {
      case LivenessAction.blink:
        return 'Blink Eyes';
      case LivenessAction.smile:
        return 'Smile';
      case LivenessAction.nod:
        return 'Nod Head';
      case LivenessAction.turnHead:
        return 'Turn Head';
    }
  }

  String get instruction {
    switch (this) {
      case LivenessAction.blink:
        return 'Blink both eyes naturally for liveness verification';
      case LivenessAction.smile:
        return 'Smile toward the front sensor for anti-spoofing check';
      case LivenessAction.nod:
        return 'Nod your head downward to verify spatial depth';
      case LivenessAction.turnHead:
        return 'Turn head slightly sideways to map 3D contours';
    }
  }

  IconData get icon {
    switch (this) {
      case LivenessAction.blink:
        return Icons.visibility;
      case LivenessAction.smile:
        return Icons.sentiment_satisfied_alt;
      case LivenessAction.nod:
        return Icons.arrow_downward;
      case LivenessAction.turnHead:
        return Icons.swap_horizontal_circle_outlined;
    }
  }
}

class LivenessAttestation {
  final String challengeId;
  final String employeeId;
  final List<LivenessAction> completedActions;
  final double confidenceScore;
  final double luxLevel;
  final bool isFallbackUsed;
  final String attestationHash;
  final DateTime timestamp;

  const LivenessAttestation({
    required this.challengeId,
    required this.employeeId,
    required this.completedActions,
    required this.confidenceScore,
    required this.luxLevel,
    required this.isFallbackUsed,
    required this.attestationHash,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'employeeId': employeeId,
      'completedActions': completedActions.map((a) => a.name).toList(),
      'confidenceScore': confidenceScore,
      'luxLevel': luxLevel,
      'isFallbackUsed': isFallbackUsed ? 1 : 0,
      'attestationHash': attestationHash,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LivenessAttestation.fromMap(Map<String, dynamic> map) {
    return LivenessAttestation(
      challengeId: map['challengeId'] as String,
      employeeId: map['employeeId'] as String,
      completedActions: (map['completedActions'] as List<dynamic>)
          .map(
            (e) => LivenessAction.values.firstWhere(
              (a) => a.name == e,
              orElse: () => LivenessAction.blink,
            ),
          )
          .toList(),
      confidenceScore: (map['confidenceScore'] as num).toDouble(),
      luxLevel: (map['luxLevel'] as num).toDouble(),
      isFallbackUsed:
          map['isFallbackUsed'] == 1 || map['isFallbackUsed'] == true,
      attestationHash: map['attestationHash'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
