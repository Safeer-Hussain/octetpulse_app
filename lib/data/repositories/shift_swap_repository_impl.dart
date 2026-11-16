import 'dart:async';

import '../../domain/entities/shift_swap_notification.dart';
import '../../domain/entities/shift_swap_proposal.dart';
import '../../domain/repositories/shift_swap_repository.dart';
import '../datasources/local/app_database.dart';

class ShiftSwapRepositoryImpl implements ShiftSwapRepository {
  final AppDatabase _db;
  final StreamController<ShiftSwapNotification> _notificationController =
      StreamController<ShiftSwapNotification>.broadcast();

  ShiftSwapRepositoryImpl(this._db);

  @override
  Stream<ShiftSwapNotification> get notificationStream =>
      _notificationController.stream;

  @override
  Future<List<ShiftSwapProposal>> getProposals() async {
    final db = await _db.database;
    final maps = await db.query(
      'shift_swap_proposals',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => ShiftSwapProposal.fromMap(m)).toList();
  }

  @override
  Future<ShiftSwapProposal> createProposal(ShiftSwapProposal proposal) async {
    final db = await _db.database;
    await db.insert('shift_swap_proposals', proposal.toMap());

    final notif = ShiftSwapNotification(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      proposalId: proposal.id,
      title: 'New Shift Swap Proposal',
      message:
          '${proposal.requesterName} proposed swapping ${proposal.requesterShiftType.shortName} shift with you.',
      timestamp: DateTime.now(),
    );
    await db.insert('shift_swap_notifications', notif.toMap());
    _notificationController.add(notif);

    return proposal;
  }

  @override
  Future<ShiftSwapProposal> counterProposal({
    required String proposalId,
    required DateTime newTargetShiftDate,
    required ShiftType newTargetShiftType,
    required String counterReason,
  }) async {
    final db = await _db.database;
    final results = await db.query(
      'shift_swap_proposals',
      where: 'id = ?',
      whereArgs: [proposalId],
    );
    if (results.isEmpty) {
      throw Exception('Shift swap proposal $proposalId not found.');
    }

    final current = ShiftSwapProposal.fromMap(results.first);
    final updated = current.copyWith(
      targetShiftDate: newTargetShiftDate,
      targetShiftType: newTargetShiftType,
      counterReason: counterReason,
      status: ShiftSwapStatus.countered,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'shift_swap_proposals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [proposalId],
    );

    final notif = ShiftSwapNotification(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      proposalId: proposalId,
      title: 'Shift Swap Counter Offer',
      message:
          '${current.targetPeerName} countered proposal with ${newTargetShiftType.shortName} shift.',
      timestamp: DateTime.now(),
    );
    await db.insert('shift_swap_notifications', notif.toMap());
    _notificationController.add(notif);

    return updated;
  }

  @override
  Future<ShiftSwapProposal> acceptProposal(String proposalId) async {
    final db = await _db.database;
    final results = await db.query(
      'shift_swap_proposals',
      where: 'id = ?',
      whereArgs: [proposalId],
    );
    if (results.isEmpty) {
      throw Exception('Shift swap proposal $proposalId not found.');
    }

    final current = ShiftSwapProposal.fromMap(results.first);
    final updated = current.copyWith(
      status: ShiftSwapStatus.accepted,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'shift_swap_proposals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [proposalId],
    );

    final notif = ShiftSwapNotification(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      proposalId: proposalId,
      title: 'Shift Swap Accepted',
      message:
          '${current.targetPeerName} accepted your shift swap! Awaiting Team Lead approval.',
      timestamp: DateTime.now(),
    );
    await db.insert('shift_swap_notifications', notif.toMap());
    _notificationController.add(notif);

    return updated;
  }

  @override
  Future<ShiftSwapProposal> approveProposalByLead({
    required String proposalId,
    required String leadName,
  }) async {
    final db = await _db.database;
    final results = await db.query(
      'shift_swap_proposals',
      where: 'id = ?',
      whereArgs: [proposalId],
    );
    if (results.isEmpty) {
      throw Exception('Shift swap proposal $proposalId not found.');
    }

    final current = ShiftSwapProposal.fromMap(results.first);
    final updated = current.copyWith(
      status: ShiftSwapStatus.leadApproved,
      approvedByLeadName: leadName,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'shift_swap_proposals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [proposalId],
    );

    final notif = ShiftSwapNotification(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      proposalId: proposalId,
      title: 'Shift Swap Approved by Lead',
      message:
          'Lead $leadName approved shift swap between ${current.requesterName} and ${current.targetPeerName}. Roster updated.',
      timestamp: DateTime.now(),
    );
    await db.insert('shift_swap_notifications', notif.toMap());
    _notificationController.add(notif);

    return updated;
  }

  @override
  Future<ShiftSwapProposal> rejectProposal({
    required String proposalId,
    required String rejectionReason,
  }) async {
    final db = await _db.database;
    final results = await db.query(
      'shift_swap_proposals',
      where: 'id = ?',
      whereArgs: [proposalId],
    );
    if (results.isEmpty) {
      throw Exception('Shift swap proposal $proposalId not found.');
    }

    final current = ShiftSwapProposal.fromMap(results.first);
    final updated = current.copyWith(
      status: ShiftSwapStatus.rejected,
      rejectionReason: rejectionReason,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'shift_swap_proposals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [proposalId],
    );

    final notif = ShiftSwapNotification(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      proposalId: proposalId,
      title: 'Shift Swap Rejected',
      message: 'Proposal $proposalId was rejected: $rejectionReason',
      timestamp: DateTime.now(),
    );
    await db.insert('shift_swap_notifications', notif.toMap());
    _notificationController.add(notif);

    return updated;
  }

  @override
  Future<ShiftSwapProposal> cancelProposal(String proposalId) async {
    final db = await _db.database;
    final results = await db.query(
      'shift_swap_proposals',
      where: 'id = ?',
      whereArgs: [proposalId],
    );
    if (results.isEmpty) {
      throw Exception('Shift swap proposal $proposalId not found.');
    }

    final current = ShiftSwapProposal.fromMap(results.first);
    final updated = current.copyWith(
      status: ShiftSwapStatus.cancelled,
      updatedAt: DateTime.now(),
    );

    await db.update(
      'shift_swap_proposals',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [proposalId],
    );

    return updated;
  }

  @override
  Future<List<ShiftSwapNotification>> getNotifications() async {
    final db = await _db.database;
    final maps = await db.query(
      'shift_swap_notifications',
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => ShiftSwapNotification.fromMap(m)).toList();
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    final db = await _db.database;
    await db.update(
      'shift_swap_notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }
}
