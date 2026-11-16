import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/shift_swap_proposal.dart';
import '../../../domain/repositories/shift_swap_repository.dart';
import 'shift_swap_event.dart';
import 'shift_swap_state.dart';

class ShiftSwapBloc extends Bloc<ShiftSwapEvent, ShiftSwapState> {
  final ShiftSwapRepository _repository;
  StreamSubscription? _notifSubscription;

  ShiftSwapBloc(this._repository) : super(const ShiftSwapState()) {
    on<LoadShiftSwapsEvent>(_onLoadShiftSwaps);
    on<ProposeShiftSwapEvent>(_onProposeShiftSwap);
    on<CounterShiftSwapEvent>(_onCounterShiftSwap);
    on<AcceptShiftSwapEvent>(_onAcceptShiftSwap);
    on<LeadApproveShiftSwapEvent>(_onLeadApproveShiftSwap);
    on<RejectShiftSwapEvent>(_onRejectShiftSwap);
    on<CancelShiftSwapEvent>(_onCancelShiftSwap);
    on<FilterShiftSwapsEvent>(_onFilterShiftSwaps);
    on<NotificationReceivedEvent>(_onNotificationReceived);
    on<DismissNotificationEvent>(_onDismissNotification);

    _notifSubscription = _repository.notificationStream.listen((notif) {
      add(NotificationReceivedEvent(notif));
    });
  }

  List<ShiftSwapProposal> _applyFilter({
    required List<ShiftSwapProposal> list,
    required String department,
    ShiftSwapStatus? status,
  }) {
    return list.where((p) {
      final matchesDept = department == 'All' || p.department == department;
      final matchesStatus = status == null || p.status == status;
      return matchesDept && matchesStatus;
    }).toList();
  }

  Future<void> _onLoadShiftSwaps(
    LoadShiftSwapsEvent event,
    Emitter<ShiftSwapState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final proposals = await _repository.getProposals();
      final notifications = await _repository.getNotifications();
      final filtered = _applyFilter(
        list: proposals,
        department: state.selectedDepartment,
        status: state.selectedStatus,
      );

      emit(
        state.copyWith(
          isLoading: false,
          proposals: proposals,
          filteredProposals: filtered,
          selectedProposal: filtered.isNotEmpty ? filtered.first : null,
          notifications: notifications,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load shift swap proposals: $e',
        ),
      );
    }
  }

  Future<void> _onProposeShiftSwap(
    ProposeShiftSwapEvent event,
    Emitter<ShiftSwapState> emit,
  ) async {
    try {
      final created = await _repository.createProposal(event.proposal);
      final updatedList = [created, ...state.proposals];
      final filtered = _applyFilter(
        list: updatedList,
        department: state.selectedDepartment,
        status: state.selectedStatus,
      );

      emit(
        state.copyWith(
          proposals: updatedList,
          filteredProposals: filtered,
          selectedProposal: created,
          feedbackMessage:
              'Shift swap proposal sent to ${created.targetPeerName}. Peer notified.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Failed to submit shift swap proposal: $e',
        ),
      );
    }
  }

  Future<void> _onCounterShiftSwap(
    CounterShiftSwapEvent event,
    Emitter<ShiftSwapState> emit,
  ) async {
    try {
      final updated = await _repository.counterProposal(
        proposalId: event.proposalId,
        newTargetShiftDate: event.newTargetShiftDate,
        newTargetShiftType: event.newTargetShiftType,
        counterReason: event.counterReason,
      );

      final updatedList = state.proposals.map((p) {
        return p.id == updated.id ? updated : p;
      }).toList();

      final filtered = _applyFilter(
        list: updatedList,
        department: state.selectedDepartment,
        status: state.selectedStatus,
      );

      emit(
        state.copyWith(
          proposals: updatedList,
          filteredProposals: filtered,
          selectedProposal: updated,
          feedbackMessage:
              'Counter proposal sent with ${event.newTargetShiftType.shortName} shift.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to send counter offer: $e'));
    }
  }

  Future<void> _onAcceptShiftSwap(
    AcceptShiftSwapEvent event,
    Emitter<ShiftSwapState> emit,
  ) async {
    try {
      final updated = await _repository.acceptProposal(event.proposalId);
      final updatedList = state.proposals.map((p) {
        return p.id == updated.id ? updated : p;
      }).toList();

      final filtered = _applyFilter(
        list: updatedList,
        department: state.selectedDepartment,
        status: state.selectedStatus,
      );

      emit(
        state.copyWith(
          proposals: updatedList,
          filteredProposals: filtered,
          selectedProposal: updated,
          feedbackMessage: 'Shift swap agreed by peer! Awaiting statutory Team Lead sign-off.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to accept shift swap: $e'));
    }
  }

  Future<void> _onLeadApproveShiftSwap(
    LeadApproveShiftSwapEvent event,
    Emitter<ShiftSwapState> emit,
  ) async {
    try {
      final updated = await _repository.approveProposalByLead(
        proposalId: event.proposalId,
        leadName: event.leadName,
      );

      final updatedList = state.proposals.map((p) {
        return p.id == updated.id ? updated : p;
      }).toList();

      final filtered = _applyFilter(
        list: updatedList,
        department: state.selectedDepartment,
        status: state.selectedStatus,
      );

      emit(
        state.copyWith(
          proposals: updatedList,
          filteredProposals: filtered,
          selectedProposal: updated,
          feedbackMessage:
              'Statutory approval confirmed by ${event.leadName}. Roster updated.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to approve shift swap: $e'));
    }
  }

  Future<void> _onRejectShiftSwap(
    RejectShiftSwapEvent event,
    Emitter<ShiftSwapState> emit,
  ) async {
    try {
      final updated = await _repository.rejectProposal(
        proposalId: event.proposalId,
        rejectionReason: event.rejectionReason,
      );

      final updatedList = state.proposals.map((p) {
        return p.id == updated.id ? updated : p;
      }).toList();

      final filtered = _applyFilter(
        list: updatedList,
        department: state.selectedDepartment,
        status: state.selectedStatus,
      );

      emit(
        state.copyWith(
          proposals: updatedList,
          filteredProposals: filtered,
          selectedProposal: updated,
          feedbackMessage: 'Shift swap proposal declined.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to decline proposal: $e'));
    }
  }

  Future<void> _onCancelShiftSwap(
    CancelShiftSwapEvent event,
    Emitter<ShiftSwapState> emit,
  ) async {
    try {
      final updated = await _repository.cancelProposal(event.proposalId);
      final updatedList = state.proposals.map((p) {
        return p.id == updated.id ? updated : p;
      }).toList();

      final filtered = _applyFilter(
        list: updatedList,
        department: state.selectedDepartment,
        status: state.selectedStatus,
      );

      emit(
        state.copyWith(
          proposals: updatedList,
          filteredProposals: filtered,
          selectedProposal: updated,
          feedbackMessage: 'Shift swap proposal cancelled.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to cancel proposal: $e'));
    }
  }

  void _onFilterShiftSwaps(
    FilterShiftSwapsEvent event,
    Emitter<ShiftSwapState> emit,
  ) {
    final filtered = _applyFilter(
      list: state.proposals,
      department: event.selectedDepartment,
      status: event.selectedStatus,
    );

    emit(
      state.copyWith(
        selectedDepartment: event.selectedDepartment,
        selectedStatus: event.selectedStatus,
        clearSelectedStatus: event.selectedStatus == null,
        filteredProposals: filtered,
        selectedProposal: filtered.isNotEmpty ? filtered.first : null,
      ),
    );
  }

  void _onNotificationReceived(
    NotificationReceivedEvent event,
    Emitter<ShiftSwapState> emit,
  ) {
    final updated = [event.notification, ...state.notifications];
    emit(
      state.copyWith(
        notifications: updated,
        latestNotification: event.notification,
      ),
    );
  }

  Future<void> _onDismissNotification(
    DismissNotificationEvent event,
    Emitter<ShiftSwapState> emit,
  ) async {
    try {
      await _repository.markNotificationRead(event.notificationId);
      final updated = state.notifications.map((n) {
        return n.id == event.notificationId ? n.copyWith(isRead: true) : n;
      }).toList();

      emit(
        state.copyWith(
          notifications: updated,
          clearLatestNotification:
              state.latestNotification?.id == event.notificationId,
        ),
      );
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _notifSubscription?.cancel();
    return super.close();
  }
}
