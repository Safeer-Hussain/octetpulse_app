import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/domain/entities/shift_swap_notification.dart';
import 'package:octet_pulse_app/domain/entities/shift_swap_proposal.dart';
import 'package:octet_pulse_app/presentation/shift_swap/bloc/shift_swap_bloc.dart';
import 'package:octet_pulse_app/presentation/shift_swap/bloc/shift_swap_event.dart';
import 'package:octet_pulse_app/presentation/shift_swap/bloc/shift_swap_state.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('ShiftSwapProposal Entity Tests', () {
    test('serialization roundtrip preserves all proposal fields', () {
      final now = DateTime(2026, 11, 17, 10, 0);
      final proposal = ShiftSwapProposal(
        id: 'SWAP-001',
        requesterId: 'EMP-101',
        requesterName: 'Safeer Hussain',
        requesterRole: 'Principal Architect',
        targetPeerId: 'EMP-102',
        targetPeerName: 'Zainab Tariq',
        targetPeerRole: 'Lead Flutter Engineer',
        department: 'Mobile Engineering',
        requesterShiftDate: now,
        requesterShiftType: ShiftType.morning,
        targetShiftDate: now.add(const Duration(days: 2)),
        targetShiftType: ShiftType.evening,
        reason: 'Architecture Sync with client security team',
        counterReason: null,
        rejectionReason: null,
        approvedByLeadName: null,
        status: ShiftSwapStatus.proposed,
        createdAt: now,
        updatedAt: now,
      );

      final map = proposal.toMap();
      final reconstituted = ShiftSwapProposal.fromMap(map);

      expect(reconstituted.id, proposal.id);
      expect(reconstituted.requesterName, proposal.requesterName);
      expect(reconstituted.targetPeerName, proposal.targetPeerName);
      expect(reconstituted.requesterShiftType, ShiftType.morning);
      expect(reconstituted.targetShiftType, ShiftType.evening);
      expect(reconstituted.status, ShiftSwapStatus.proposed);
      expect(reconstituted.canCounter, true);
      expect(reconstituted.canAccept, true);
      expect(reconstituted.canApproveByLead, false);
    });

    test('permission predicates check state transitions accurately', () {
      final now = DateTime.now();
      var proposal = ShiftSwapProposal(
        id: 'SWAP-002',
        requesterId: 'EMP-105',
        requesterName: 'Tariq Mahmood',
        requesterRole: 'Field Operations Lead',
        targetPeerId: 'EMP-106',
        targetPeerName: 'Usman Khan',
        targetPeerRole: 'Senior Field Specialist',
        department: 'Field Operations',
        requesterShiftDate: now,
        requesterShiftType: ShiftType.night,
        targetShiftDate: now.add(const Duration(days: 1)),
        targetShiftType: ShiftType.morning,
        reason: 'Vehicle maintenance',
        status: ShiftSwapStatus.accepted,
        createdAt: now,
        updatedAt: now,
      );

      expect(proposal.canApproveByLead, true);
      expect(proposal.canCounter, false);

      proposal = proposal.copyWith(status: ShiftSwapStatus.leadApproved);
      expect(proposal.canApproveByLead, false);
      expect(proposal.canAccept, false);
      expect(proposal.canReject, false);
    });
  });

  group('ShiftSwapBloc State Machine Tests', () {
    late FakeShiftSwapRepository repository;
    final now = DateTime(2026, 11, 18, 9, 0);

    final sampleProposal = ShiftSwapProposal(
      id: 'SWAP-TEST-1',
      requesterId: 'EMP-101',
      requesterName: 'Safeer Hussain',
      requesterRole: 'Principal Architect',
      targetPeerId: 'EMP-102',
      targetPeerName: 'Zainab Tariq',
      targetPeerRole: 'Lead Flutter Engineer',
      department: 'Mobile Engineering',
      requesterShiftDate: now,
      requesterShiftType: ShiftType.morning,
      targetShiftDate: now.add(const Duration(days: 2)),
      targetShiftType: ShiftType.evening,
      reason: 'Architecture Sync',
      status: ShiftSwapStatus.proposed,
      createdAt: now,
      updatedAt: now,
    );

    setUp(() {
      repository = FakeShiftSwapRepository();
      repository.proposals = [sampleProposal];
    });

    blocTest<ShiftSwapBloc, ShiftSwapState>(
      'loads proposals and sets filtered proposals',
      build: () => ShiftSwapBloc(repository),
      act: (bloc) => bloc.add(const LoadShiftSwapsEvent()),
      verify: (bloc) {
        expect(bloc.state.proposals.length, 1);
        expect(bloc.state.filteredProposals.length, 1);
        expect(bloc.state.pendingCount, 1);
      },
    );

    blocTest<ShiftSwapBloc, ShiftSwapState>(
      'proposeShiftSwap inserts proposal and emits feedback',
      build: () => ShiftSwapBloc(repository),
      seed: () => ShiftSwapState(
        proposals: [sampleProposal],
        filteredProposals: [sampleProposal],
      ),
      act: (bloc) {
        final newProposal = sampleProposal.copyWith(
          id: 'SWAP-TEST-2',
          targetPeerId: 'EMP-103',
          targetPeerName: 'Hamza Malik',
        );
        bloc.add(ProposeShiftSwapEvent(newProposal));
      },
      verify: (bloc) {
        expect(bloc.state.proposals.length, 2);
        expect(bloc.state.proposals.first.id, 'SWAP-TEST-2');
        expect(
          bloc.state.feedbackMessage,
          contains('Shift swap proposal sent'),
        );
      },
    );

    blocTest<ShiftSwapBloc, ShiftSwapState>(
      'counterShiftSwap transitions state to countered',
      build: () => ShiftSwapBloc(repository),
      seed: () => ShiftSwapState(
        proposals: [sampleProposal],
        filteredProposals: [sampleProposal],
      ),
      act: (bloc) => bloc.add(
        CounterShiftSwapEvent(
          proposalId: 'SWAP-TEST-1',
          newTargetShiftDate: now.add(const Duration(days: 3)),
          newTargetShiftType: ShiftType.night,
          counterReason: 'Can only cover night shift',
        ),
      ),
      verify: (bloc) {
        final updated = bloc.state.proposals.first;
        expect(updated.status, ShiftSwapStatus.countered);
        expect(updated.counterReason, 'Can only cover night shift');
        expect(updated.targetShiftType, ShiftType.night);
      },
    );

    blocTest<ShiftSwapBloc, ShiftSwapState>(
      'acceptShiftSwap transitions state to accepted',
      build: () => ShiftSwapBloc(repository),
      seed: () => ShiftSwapState(
        proposals: [sampleProposal],
        filteredProposals: [sampleProposal],
      ),
      act: (bloc) => bloc.add(const AcceptShiftSwapEvent('SWAP-TEST-1')),
      verify: (bloc) {
        final updated = bloc.state.proposals.first;
        expect(updated.status, ShiftSwapStatus.accepted);
        expect(
          bloc.state.feedbackMessage,
          contains('Awaiting statutory Team Lead'),
        );
      },
    );

    blocTest<ShiftSwapBloc, ShiftSwapState>(
      'leadApproveShiftSwap transitions state to leadApproved and records lead signature',
      build: () => ShiftSwapBloc(repository),
      seed: () {
        final accepted = sampleProposal.copyWith(
          status: ShiftSwapStatus.accepted,
        );
        return ShiftSwapState(
          proposals: [accepted],
          filteredProposals: [accepted],
        );
      },
      act: (bloc) => bloc.add(
        const LeadApproveShiftSwapEvent(
          proposalId: 'SWAP-TEST-1',
          leadName: 'Safeer Hussain',
        ),
      ),
      verify: (bloc) {
        final updated = bloc.state.proposals.first;
        expect(updated.status, ShiftSwapStatus.leadApproved);
        expect(updated.approvedByLeadName, 'Safeer Hussain');
        expect(bloc.state.approvedCount, 1);
      },
    );

    blocTest<ShiftSwapBloc, ShiftSwapState>(
      'rejectShiftSwap transitions state to rejected with reason',
      build: () => ShiftSwapBloc(repository),
      seed: () => ShiftSwapState(
        proposals: [sampleProposal],
        filteredProposals: [sampleProposal],
      ),
      act: (bloc) => bloc.add(
        const RejectShiftSwapEvent(
          proposalId: 'SWAP-TEST-1',
          rejectionReason: 'Emergency on-call duty',
        ),
      ),
      verify: (bloc) {
        final updated = bloc.state.proposals.first;
        expect(updated.status, ShiftSwapStatus.rejected);
        expect(updated.rejectionReason, 'Emergency on-call duty');
      },
    );

    blocTest<ShiftSwapBloc, ShiftSwapState>(
      'department filter filters proposals correctly',
      build: () => ShiftSwapBloc(repository),
      seed: () {
        final fieldProp = sampleProposal.copyWith(
          id: 'SWAP-FIELD-1',
          department: 'Field Operations',
        );
        return ShiftSwapState(
          proposals: [sampleProposal, fieldProp],
          filteredProposals: [sampleProposal, fieldProp],
        );
      },
      act: (bloc) => bloc.add(
        const FilterShiftSwapsEvent(selectedDepartment: 'Field Operations'),
      ),
      verify: (bloc) {
        expect(bloc.state.filteredProposals.length, 1);
        expect(
          bloc.state.filteredProposals.first.department,
          'Field Operations',
        );
      },
    );

    blocTest<ShiftSwapBloc, ShiftSwapState>(
      'receives live push notification from stream',
      build: () => ShiftSwapBloc(repository),
      act: (bloc) {
        final notif = ShiftSwapNotification(
          id: 'NOTIF-PUSH-1',
          proposalId: 'SWAP-TEST-1',
          title: 'Shift Swap Alert',
          message: 'Colleague accepted shift proposal',
          timestamp: DateTime.now(),
        );
        bloc.add(NotificationReceivedEvent(notif));
      },
      verify: (bloc) {
        expect(bloc.state.notifications.length, 1);
        expect(bloc.state.latestNotification?.id, 'NOTIF-PUSH-1');
        expect(bloc.state.unreadNotificationCount, 1);
      },
    );
  });
}
