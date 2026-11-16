import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/core/theme/app_theme.dart';
import 'package:octet_pulse_app/domain/entities/shift_swap_proposal.dart';
import 'package:octet_pulse_app/presentation/shift_swap/bloc/shift_swap_bloc.dart';
import 'package:octet_pulse_app/presentation/shift_swap/bloc/shift_swap_event.dart';
import 'package:octet_pulse_app/presentation/shift_swap/views/shift_swap_exchange_view.dart';

import '../fakes/fake_repositories.dart';

void main() {
  final now = DateTime(2026, 11, 18, 8, 0);

  final sampleProposal1 = ShiftSwapProposal(
    id: 'SWAP-WIDGET-01',
    requesterId: 'EMP-101',
    requesterName: 'Safeer Hussain',
    requesterRole: 'Principal Architect',
    targetPeerId: 'EMP-102',
    targetPeerName: 'Zainab Tariq',
    targetPeerRole: 'Lead Flutter Engineer',
    department: 'Mobile Engineering',
    requesterShiftDate: now.add(const Duration(days: 1)),
    requesterShiftType: ShiftType.morning,
    targetShiftDate: now.add(const Duration(days: 3)),
    targetShiftType: ShiftType.evening,
    reason: 'Architecture Sync with client engineering team',
    status: ShiftSwapStatus.proposed,
    createdAt: now.subtract(const Duration(hours: 3)),
    updatedAt: now.subtract(const Duration(hours: 3)),
  );

  final sampleProposal2 = ShiftSwapProposal(
    id: 'SWAP-WIDGET-02',
    requesterId: 'EMP-105',
    requesterName: 'Tariq Mahmood',
    requesterRole: 'Field Operations Lead',
    targetPeerId: 'EMP-106',
    targetPeerName: 'Usman Khan',
    targetPeerRole: 'Senior Field Specialist',
    department: 'Field Operations',
    requesterShiftDate: now.add(const Duration(days: 2)),
    requesterShiftType: ShiftType.night,
    targetShiftDate: now.add(const Duration(days: 4)),
    targetShiftType: ShiftType.morning,
    reason: 'Vehicle repair schedule',
    counterReason: 'Can only cover evening rotation',
    status: ShiftSwapStatus.countered,
    createdAt: now.subtract(const Duration(hours: 10)),
    updatedAt: now.subtract(const Duration(hours: 2)),
  );

  Widget createSubject({
    required bool isDark,
    required FakeShiftSwapRepository repo,
  }) {
    return BlocProvider<ShiftSwapBloc>(
      create: (_) => ShiftSwapBloc(repo)..add(const LoadShiftSwapsEvent()),
      child: MaterialApp(
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: const Scaffold(body: ShiftSwapExchangeView()),
      ),
    );
  }

  testWidgets(
    'ShiftSwapExchangeView renders metric cards, department filter chips, and proposals',
    (WidgetTester tester) async {
      final repo = FakeShiftSwapRepository();
      repo.proposals = [sampleProposal1, sampleProposal2];

      await tester.pumpWidget(createSubject(isDark: true, repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Active Negotiations: '), findsOneWidget);
      expect(find.text('Total Proposals: '), findsOneWidget);
      expect(find.text('Mobile Engineering'), findsWidgets);
      expect(find.text('Field Operations'), findsWidgets);
      expect(find.text('Proposed'), findsWidgets);
      expect(find.text('Countered'), findsWidgets);
      expect(find.text('Safeer Hussain -> Zainab Tariq'), findsOneWidget);
      expect(find.text('Tariq Mahmood -> Usman Khan'), findsOneWidget);
    },
  );

  testWidgets(
    'ShiftSwapExchangeView opens Propose Shift Swap bottom sheet modal',
    (WidgetTester tester) async {
      final repo = FakeShiftSwapRepository();
      repo.proposals = [sampleProposal1];

      await tester.pumpWidget(createSubject(isDark: false, repo: repo));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Propose Peer Shift Swap'), findsOneWidget);
      expect(find.text('Your Current Shift (Giving Away)'), findsOneWidget);
      expect(find.text('Peer Shift Desired (In Exchange)'), findsOneWidget);
      expect(find.text('Dispatch Shift Swap Proposal'), findsOneWidget);
    },
  );

  testWidgets(
    'ShiftSwapExchangeView renders cleanly on 800x360 landscape viewport with zero overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeShiftSwapRepository();
      repo.proposals = [sampleProposal1, sampleProposal2];

      await tester.pumpWidget(createSubject(isDark: true, repo: repo));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Negotiation Audit Trail'), findsOneWidget);
      expect(find.text('Safeer Hussain -> Zainab Tariq'), findsOneWidget);
    },
  );
}
