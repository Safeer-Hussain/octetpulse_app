import 'package:equatable/equatable.dart';

import '../../../domain/entities/shift_swap_notification.dart';
import '../../../domain/entities/shift_swap_proposal.dart';

abstract class ShiftSwapEvent extends Equatable {
  const ShiftSwapEvent();

  @override
  List<Object?> get props => [];
}

class LoadShiftSwapsEvent extends ShiftSwapEvent {
  const LoadShiftSwapsEvent();
}

class ProposeShiftSwapEvent extends ShiftSwapEvent {
  final ShiftSwapProposal proposal;

  const ProposeShiftSwapEvent(this.proposal);

  @override
  List<Object?> get props => [proposal];
}

class CounterShiftSwapEvent extends ShiftSwapEvent {
  final String proposalId;
  final DateTime newTargetShiftDate;
  final ShiftType newTargetShiftType;
  final String counterReason;

  const CounterShiftSwapEvent({
    required this.proposalId,
    required this.newTargetShiftDate,
    required this.newTargetShiftType,
    required this.counterReason,
  });

  @override
  List<Object?> get props => [
    proposalId,
    newTargetShiftDate,
    newTargetShiftType,
    counterReason,
  ];
}

class AcceptShiftSwapEvent extends ShiftSwapEvent {
  final String proposalId;

  const AcceptShiftSwapEvent(this.proposalId);

  @override
  List<Object?> get props => [proposalId];
}

class LeadApproveShiftSwapEvent extends ShiftSwapEvent {
  final String proposalId;
  final String leadName;

  const LeadApproveShiftSwapEvent({
    required this.proposalId,
    required this.leadName,
  });

  @override
  List<Object?> get props => [proposalId, leadName];
}

class RejectShiftSwapEvent extends ShiftSwapEvent {
  final String proposalId;
  final String rejectionReason;

  const RejectShiftSwapEvent({
    required this.proposalId,
    required this.rejectionReason,
  });

  @override
  List<Object?> get props => [proposalId, rejectionReason];
}

class CancelShiftSwapEvent extends ShiftSwapEvent {
  final String proposalId;

  const CancelShiftSwapEvent(this.proposalId);

  @override
  List<Object?> get props => [proposalId];
}

class FilterShiftSwapsEvent extends ShiftSwapEvent {
  final String selectedDepartment;
  final ShiftSwapStatus? selectedStatus;

  const FilterShiftSwapsEvent({
    this.selectedDepartment = 'All',
    this.selectedStatus,
  });

  @override
  List<Object?> get props => [selectedDepartment, selectedStatus];
}

class NotificationReceivedEvent extends ShiftSwapEvent {
  final ShiftSwapNotification notification;

  const NotificationReceivedEvent(this.notification);

  @override
  List<Object?> get props => [notification];
}

class DismissNotificationEvent extends ShiftSwapEvent {
  final String notificationId;

  const DismissNotificationEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}
