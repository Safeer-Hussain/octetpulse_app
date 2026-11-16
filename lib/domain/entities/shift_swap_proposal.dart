import 'package:equatable/equatable.dart';

enum ShiftSwapStatus {
  proposed,
  countered,
  accepted,
  leadApproved,
  rejected,
  cancelled,
}

enum ShiftType {
  morning, // 08:00 - 16:00
  evening, // 16:00 - 00:00
  night, // 00:00 - 08:00
  onCall, // 24-hr Standby
}

extension ShiftTypeExtension on ShiftType {
  String get displayName {
    switch (this) {
      case ShiftType.morning:
        return 'Morning (08:00 - 16:00)';
      case ShiftType.evening:
        return 'Evening (16:00 - 00:00)';
      case ShiftType.night:
        return 'Night (00:00 - 08:00)';
      case ShiftType.onCall:
        return 'Weekend Standby (24h)';
    }
  }

  String get shortName {
    switch (this) {
      case ShiftType.morning:
        return 'Morning';
      case ShiftType.evening:
        return 'Evening';
      case ShiftType.night:
        return 'Night';
      case ShiftType.onCall:
        return 'On-Call';
    }
  }
}

class ShiftSwapProposal extends Equatable {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterRole;
  final String targetPeerId;
  final String targetPeerName;
  final String targetPeerRole;
  final String department;
  final DateTime requesterShiftDate;
  final ShiftType requesterShiftType;
  final DateTime targetShiftDate;
  final ShiftType targetShiftType;
  final String reason;
  final String? counterReason;
  final String? rejectionReason;
  final String? approvedByLeadName;
  final ShiftSwapStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShiftSwapProposal({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterRole,
    required this.targetPeerId,
    required this.targetPeerName,
    required this.targetPeerRole,
    required this.department,
    required this.requesterShiftDate,
    required this.requesterShiftType,
    required this.targetShiftDate,
    required this.targetShiftType,
    required this.reason,
    this.counterReason,
    this.rejectionReason,
    this.approvedByLeadName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canCounter =>
      status == ShiftSwapStatus.proposed || status == ShiftSwapStatus.countered;
  bool get canAccept =>
      status == ShiftSwapStatus.proposed || status == ShiftSwapStatus.countered;
  bool get canApproveByLead => status == ShiftSwapStatus.accepted;
  bool get canReject =>
      status == ShiftSwapStatus.proposed ||
      status == ShiftSwapStatus.countered ||
      status == ShiftSwapStatus.accepted;
  bool get canCancel =>
      status == ShiftSwapStatus.proposed || status == ShiftSwapStatus.countered;

  String get statusLabel {
    switch (status) {
      case ShiftSwapStatus.proposed:
        return 'Proposed';
      case ShiftSwapStatus.countered:
        return 'Countered';
      case ShiftSwapStatus.accepted:
        return 'Peer Accepted';
      case ShiftSwapStatus.leadApproved:
        return 'Lead Approved';
      case ShiftSwapStatus.rejected:
        return 'Rejected';
      case ShiftSwapStatus.cancelled:
        return 'Cancelled';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterRole': requesterRole,
      'targetPeerId': targetPeerId,
      'targetPeerName': targetPeerName,
      'targetPeerRole': targetPeerRole,
      'department': department,
      'requesterShiftDate': requesterShiftDate.toIso8601String(),
      'requesterShiftType': requesterShiftType.name,
      'targetShiftDate': targetShiftDate.toIso8601String(),
      'targetShiftType': targetShiftType.name,
      'reason': reason,
      'counterReason': counterReason,
      'rejectionReason': rejectionReason,
      'approvedByLeadName': approvedByLeadName,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ShiftSwapProposal.fromMap(Map<String, dynamic> map) {
    return ShiftSwapProposal(
      id: map['id'] as String,
      requesterId: map['requesterId'] as String,
      requesterName: map['requesterName'] as String,
      requesterRole: map['requesterRole'] as String? ?? 'Engineer',
      targetPeerId: map['targetPeerId'] as String,
      targetPeerName: map['targetPeerName'] as String,
      targetPeerRole: map['targetPeerRole'] as String? ?? 'Engineer',
      department: map['department'] as String,
      requesterShiftDate: DateTime.parse(map['requesterShiftDate'] as String),
      requesterShiftType: ShiftType.values.firstWhere(
        (e) => e.name == map['requesterShiftType'],
        orElse: () => ShiftType.morning,
      ),
      targetShiftDate: DateTime.parse(map['targetShiftDate'] as String),
      targetShiftType: ShiftType.values.firstWhere(
        (e) => e.name == map['targetShiftType'],
        orElse: () => ShiftType.evening,
      ),
      reason: map['reason'] as String? ?? '',
      counterReason: map['counterReason'] as String?,
      rejectionReason: map['rejectionReason'] as String?,
      approvedByLeadName: map['approvedByLeadName'] as String?,
      status: ShiftSwapStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ShiftSwapStatus.proposed,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  ShiftSwapProposal copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterRole,
    String? targetPeerId,
    String? targetPeerName,
    String? targetPeerRole,
    String? department,
    DateTime? requesterShiftDate,
    ShiftType? requesterShiftType,
    DateTime? targetShiftDate,
    ShiftType? targetShiftType,
    String? reason,
    String? counterReason,
    String? rejectionReason,
    String? approvedByLeadName,
    ShiftSwapStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftSwapProposal(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterRole: requesterRole ?? this.requesterRole,
      targetPeerId: targetPeerId ?? this.targetPeerId,
      targetPeerName: targetPeerName ?? this.targetPeerName,
      targetPeerRole: targetPeerRole ?? this.targetPeerRole,
      department: department ?? this.department,
      requesterShiftDate: requesterShiftDate ?? this.requesterShiftDate,
      requesterShiftType: requesterShiftType ?? this.requesterShiftType,
      targetShiftDate: targetShiftDate ?? this.targetShiftDate,
      targetShiftType: targetShiftType ?? this.targetShiftType,
      reason: reason ?? this.reason,
      counterReason: counterReason ?? this.counterReason,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      approvedByLeadName: approvedByLeadName ?? this.approvedByLeadName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    requesterId,
    requesterName,
    requesterRole,
    targetPeerId,
    targetPeerName,
    targetPeerRole,
    department,
    requesterShiftDate,
    requesterShiftType,
    targetShiftDate,
    targetShiftType,
    reason,
    counterReason,
    rejectionReason,
    approvedByLeadName,
    status,
    createdAt,
    updatedAt,
  ];
}
