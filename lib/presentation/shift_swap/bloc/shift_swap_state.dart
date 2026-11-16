import 'package:equatable/equatable.dart';

import '../../../domain/entities/shift_swap_notification.dart';
import '../../../domain/entities/shift_swap_proposal.dart';

class ShiftSwapState extends Equatable {
  final bool isLoading;
  final List<ShiftSwapProposal> proposals;
  final List<ShiftSwapProposal> filteredProposals;
  final String selectedDepartment;
  final ShiftSwapStatus? selectedStatus;
  final ShiftSwapProposal? selectedProposal;
  final List<ShiftSwapNotification> notifications;
  final ShiftSwapNotification? latestNotification;
  final String? feedbackMessage;
  final String? errorMessage;

  const ShiftSwapState({
    this.isLoading = false,
    this.proposals = const [],
    this.filteredProposals = const [],
    this.selectedDepartment = 'All',
    this.selectedStatus,
    this.selectedProposal,
    this.notifications = const [],
    this.latestNotification,
    this.feedbackMessage,
    this.errorMessage,
  });

  int get pendingCount => proposals
      .where(
        (p) =>
            p.status == ShiftSwapStatus.proposed ||
            p.status == ShiftSwapStatus.countered,
      )
      .length;

  int get approvedCount =>
      proposals.where((p) => p.status == ShiftSwapStatus.leadApproved).length;

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  ShiftSwapState copyWith({
    bool? isLoading,
    List<ShiftSwapProposal>? proposals,
    List<ShiftSwapProposal>? filteredProposals,
    String? selectedDepartment,
    ShiftSwapStatus? selectedStatus,
    bool clearSelectedStatus = false,
    ShiftSwapProposal? selectedProposal,
    bool clearSelectedProposal = false,
    List<ShiftSwapNotification>? notifications,
    ShiftSwapNotification? latestNotification,
    bool clearLatestNotification = false,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ShiftSwapState(
      isLoading: isLoading ?? this.isLoading,
      proposals: proposals ?? this.proposals,
      filteredProposals: filteredProposals ?? this.filteredProposals,
      selectedDepartment: selectedDepartment ?? this.selectedDepartment,
      selectedStatus: clearSelectedStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      selectedProposal: clearSelectedProposal
          ? null
          : (selectedProposal ?? this.selectedProposal),
      notifications: notifications ?? this.notifications,
      latestNotification: clearLatestNotification
          ? null
          : (latestNotification ?? this.latestNotification),
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    proposals,
    filteredProposals,
    selectedDepartment,
    selectedStatus,
    selectedProposal,
    notifications,
    latestNotification,
    feedbackMessage,
    errorMessage,
  ];
}
