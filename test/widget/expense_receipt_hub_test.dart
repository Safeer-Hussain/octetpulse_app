import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/core/theme/app_theme.dart';
import 'package:octet_pulse_app/domain/entities/expense_receipt.dart';
import 'package:octet_pulse_app/presentation/expense/bloc/expense_bloc.dart';
import 'package:octet_pulse_app/presentation/expense/bloc/expense_event.dart';
import 'package:octet_pulse_app/presentation/expense/views/expense_receipt_hub_view.dart';
import 'package:octet_pulse_app/presentation/expense/views/ocr_camera_scanner_sheet.dart';

import '../fakes/fake_repositories.dart';

void main() {
  final now = DateTime.now();

  final sampleReceipt1 = ExpenseReceipt(
    id: 'EXP-101',
    employeeId: 'EMP-101',
    employeeName: 'Safeer Hussain',
    merchantName: 'Shell Fuel Station - DHA Phase 5',
    category: ExpenseCategory.fuel,
    currency: CurrencyCode.pkr,
    rawAmount: 8500.0,
    taxAmount: 1275.0,
    exchangeRateToUsd: 0.0036,
    usdEquivalent: 30.60,
    receiptDate: now.subtract(const Duration(days: 1)),
    rawOcrText: 'Shell Fuel Station DHA Phase 5',
    status: ExpenseStatus.submitted,
    createdAt: now.subtract(const Duration(days: 1)),
  );

  final sampleReceipt2 = ExpenseReceipt(
    id: 'EXP-102',
    employeeId: 'EMP-101',
    employeeName: 'Safeer Hussain',
    merchantName: 'Pearl Continental Executive Dining',
    category: ExpenseCategory.clientLunch,
    currency: CurrencyCode.pkr,
    rawAmount: 14250.0,
    taxAmount: 2137.50,
    exchangeRateToUsd: 0.0036,
    usdEquivalent: 51.30,
    receiptDate: now.subtract(const Duration(days: 3)),
    rawOcrText: 'Pearl Continental Hotel Lahore Marco Polo',
    status: ExpenseStatus.approved,
    createdAt: now.subtract(const Duration(days: 3)),
  );

  Widget createSubject({
    required bool isDark,
    required FakeExpenseRepository repo,
  }) {
    return BlocProvider<ExpenseBloc>(
      create: (_) => ExpenseBloc(repo)..add(const LoadExpensesEvent()),
      child: MaterialApp(
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: const Scaffold(body: ExpenseReceiptHubView()),
      ),
    );
  }

  testWidgets(
    'ExpenseReceiptHubView renders metric chips, category filters, and receipts',
    (WidgetTester tester) async {
      final repo = FakeExpenseRepository();
      repo.expenses = [sampleReceipt1, sampleReceipt2];

      await tester.pumpWidget(createSubject(isDark: true, repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Reimbursable: '), findsOneWidget);
      expect(find.text('Approvals: '), findsOneWidget);
      expect(find.text('Receipts: '), findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Fuel & Mileage'), findsWidgets);
      expect(find.text('Client Dining'), findsWidgets);
      expect(find.text('Shell Fuel Station - DHA Phase 5'), findsOneWidget);
      expect(find.text('Pearl Continental Executive Dining'), findsOneWidget);
      expect(find.text('\$30.60 USD'), findsOneWidget);
      expect(find.text('\$51.30 USD'), findsOneWidget);
    },
  );

  testWidgets(
    'ExpenseReceiptHubView opens Optical Receipt Scanner modal and parses preset',
    (WidgetTester tester) async {
      final repo = FakeExpenseRepository();
      repo.expenses = [sampleReceipt1];

      await tester.pumpWidget(createSubject(isDark: false, repo: repo));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(OcrCameraScannerSheet), findsOneWidget);
      expect(find.text('Optical Expense Receipt Scanner'), findsOneWidget);
      expect(find.text('Live Token Extraction Matrix'), findsOneWidget);
      expect(find.text('Submit for Reimbursement'), findsOneWidget);
    },
  );

  testWidgets(
    'ExpenseReceiptHubView renders cleanly on 800x360 landscape viewport with zero overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeExpenseRepository();
      repo.expenses = [sampleReceipt1, sampleReceipt2];

      await tester.pumpWidget(createSubject(isDark: true, repo: repo));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('OCR Token Inspection & Audit'), findsOneWidget);
      expect(find.text('Shell Fuel Station - DHA Phase 5'), findsOneWidget);
    },
  );
}
