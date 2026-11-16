import '../entities/shift_swap_notification.dart';
import '../entities/shift_swap_proposal.dart';

abstract class ShiftSwapRepository {
  Future<List<ShiftSwapProposal>> getProposals();
  Future<ShiftSwapProposal> createProposal(ShiftSwapProposal proposal);
  Future<ShiftSwapProposal> counterProposal({
    required String proposalId,
    required DateTime newTargetShiftDate,
    required ShiftType newTargetShiftType,
    required String counterReason,
  });
  Future<ShiftSwapProposal> acceptProposal(String proposalId);
  Future<ShiftSwapProposal> approveProposalByLead({
    required String proposalId,
    required String leadName,
  });
  Future<ShiftSwapProposal> rejectProposal({
    required String proposalId,
    required String rejectionReason,
  });
  Future<ShiftSwapProposal> cancelProposal(String proposalId);
  Stream<ShiftSwapNotification> get notificationStream;
  Future<List<ShiftSwapNotification>> getNotifications();
  Future<void> markNotificationRead(String notificationId);
}
