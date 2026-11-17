import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/domain/entities/expense_receipt.dart';
import 'package:octet_pulse_app/domain/services/currency_converter.dart';
import 'package:octet_pulse_app/domain/services/ocr_receipt_parser.dart';
import 'package:octet_pulse_app/presentation/expense/bloc/expense_bloc.dart';
import 'package:octet_pulse_app/presentation/expense/bloc/expense_event.dart';
import 'package:octet_pulse_app/presentation/expense/bloc/expense_state.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('CurrencyConverter Unit Tests', () {
    test('converts PKR, EUR, AED, GBP to USD base correctly', () {
      expect(
        CurrencyConverter.convertToUsd(
          amount: 10000.0,
          fromCurrency: CurrencyCode.pkr,
        ),
        closeTo(36.0, 0.01),
      );
      expect(
        CurrencyConverter.convertToUsd(
          amount: 100.0,
          fromCurrency: CurrencyCode.eur,
        ),
        closeTo(108.0, 0.01),
      );
      expect(
        CurrencyConverter.convertToUsd(
          amount: 500.0,
          fromCurrency: CurrencyCode.aed,
        ),
        closeTo(136.0, 0.01),
      );
      expect(
        CurrencyConverter.convertToUsd(
          amount: 50.0,
          fromCurrency: CurrencyCode.gbp,
        ),
        closeTo(64.0, 0.01),
      );
      expect(
        CurrencyConverter.convertToUsd(
          amount: 100.0,
          fromCurrency: CurrencyCode.usd,
        ),
        100.0,
      );
    });

    test('formats currency tokens with correct symbol prefixes', () {
      expect(
        CurrencyConverter.formatAmount(8500.0, CurrencyCode.pkr),
        'PKR 8500.00',
      );
      expect(
        CurrencyConverter.formatAmount(48.50, CurrencyCode.usd),
        '\$48.50',
      );
      expect(
        CurrencyConverter.formatAmount(350.0, CurrencyCode.aed),
        'AED 350.00',
      );
      expect(CurrencyConverter.formatAmount(25.0, CurrencyCode.eur), '€25.00');
    });
  });

  group('OcrReceiptParser Unit Tests', () {
    test('parses Fuel receipt with PKR currency, tax and total', () {
      const fuelReceipt = '''
SHELL PAKISTAN LIMITED
DHA Phase 5 Filling Station, Lahore
Date: 2026-11-16
Fuel: V-Power Petrol
Volume: 28.33 Litres
Subtotal: PKR 7,225.00
GST (17%): PKR 1,275.00
Grand Total: PKR 8,500.00
Payment Mode: Corporate Card
''';
      final result = OcrReceiptParser.parse(fuelReceipt);

      expect(result.merchantName, contains('SHELL'));
      expect(result.currency, CurrencyCode.pkr);
      expect(result.category, ExpenseCategory.fuel);
      expect(result.taxAmount, 1275.0);
      expect(result.totalAmount, 8500.0);
      expect(result.usdEquivalent, closeTo(30.60, 0.01));
      expect(result.confidenceScore, greaterThan(0.5));
    });

    test('parses Dining receipt with client lunch and PRA tax', () {
      const diningReceipt = '''
PEARL CONTINENTAL HOTEL LAHORE
Marco Polo Restaurant - Client Lunch
Date: 2026-11-14
Executive Buffet x 4: PKR 10,800.00
Beverages: PKR 1,312.50
PRA Sales Tax: PKR 1,938.00
Total Amount: PKR 14,250.00
''';
      final result = OcrReceiptParser.parse(diningReceipt);

      expect(result.merchantName, contains('PEARL CONTINENTAL'));
      expect(result.currency, CurrencyCode.pkr);
      expect(result.category, ExpenseCategory.clientLunch);
      expect(result.taxAmount, 1938.0);
      expect(result.totalAmount, 14250.0);
      expect(result.usdEquivalent, closeTo(51.30, 0.01));
    });

    test('parses Transit receipt with USD currency and trip details', () {
      const transitReceipt = '''
UBER TECHNOLOGIES INC.
Trip Receipt - Airport Business Express
Date: 2026-11-12
Pickup: Terminal 2 Executive Gate
Trip Fare: \$36.50
Transit Tax: \$4.25
Total Charged: \$48.50 USD
''';
      final result = OcrReceiptParser.parse(transitReceipt);

      expect(result.merchantName, contains('UBER'));
      expect(result.currency, CurrencyCode.usd);
      expect(result.category, ExpenseCategory.transit);
      expect(result.taxAmount, 4.25);
      expect(result.totalAmount, 48.50);
      expect(result.usdEquivalent, 48.50);
    });
  });

  group('ExpenseReceipt Entity Tests', () {
    test('serialization roundtrip preserves all fields', () {
      final now = DateTime.now();
      final receipt = ExpenseReceipt(
        id: 'EXP-999',
        employeeId: 'EMP-101',
        employeeName: 'Safeer Hussain',
        merchantName: 'Shell Filling Station',
        category: ExpenseCategory.fuel,
        currency: CurrencyCode.pkr,
        rawAmount: 8500.0,
        taxAmount: 1275.0,
        exchangeRateToUsd: 0.0036,
        usdEquivalent: 30.60,
        receiptDate: now,
        rawOcrText: 'Shell Fuel Receipt Test',
        status: ExpenseStatus.submitted,
        reimbursementBatchId: null,
        createdAt: now,
      );

      final map = receipt.toMap();
      final reconstructed = ExpenseReceipt.fromMap(map);

      expect(reconstructed.id, receipt.id);
      expect(reconstructed.employeeName, receipt.employeeName);
      expect(reconstructed.merchantName, receipt.merchantName);
      expect(reconstructed.category, receipt.category);
      expect(reconstructed.currency, receipt.currency);
      expect(reconstructed.rawAmount, receipt.rawAmount);
      expect(reconstructed.taxAmount, receipt.taxAmount);
      expect(reconstructed.usdEquivalent, receipt.usdEquivalent);
      expect(reconstructed.status, receipt.status);
    });

    test('lifecycle permission getters report correct actionable states', () {
      final now = DateTime.now();
      final draft = ExpenseReceipt(
        id: 'EXP-1',
        employeeId: 'EMP-101',
        employeeName: 'Safeer',
        merchantName: 'Vendor',
        category: ExpenseCategory.officeSupplies,
        currency: CurrencyCode.usd,
        rawAmount: 50.0,
        taxAmount: 5.0,
        exchangeRateToUsd: 1.0,
        usdEquivalent: 50.0,
        receiptDate: now,
        rawOcrText: '',
        status: ExpenseStatus.submitted,
        createdAt: now,
      );

      expect(draft.canApprove, isTrue);
      expect(draft.canReimburse, isFalse);
      expect(draft.canReject, isTrue);

      final approved = draft.copyWith(status: ExpenseStatus.approved);
      expect(approved.canApprove, isFalse);
      expect(approved.canReimburse, isTrue);
      expect(approved.canReject, isTrue);

      final reimbursed = approved.copyWith(status: ExpenseStatus.reimbursed);
      expect(reimbursed.canApprove, isFalse);
      expect(reimbursed.canReimburse, isFalse);
      expect(reimbursed.canReject, isFalse);
    });
  });

  group('ExpenseBloc State Machine Tests', () {
    late FakeExpenseRepository repository;
    final now = DateTime.now();

    final sampleReceipt = ExpenseReceipt(
      id: 'EXP-SAMPLE-1',
      employeeId: 'EMP-101',
      employeeName: 'Safeer Hussain',
      merchantName: 'Shell DHA',
      category: ExpenseCategory.fuel,
      currency: CurrencyCode.pkr,
      rawAmount: 8500.0,
      taxAmount: 1275.0,
      exchangeRateToUsd: 0.0036,
      usdEquivalent: 30.60,
      receiptDate: now,
      rawOcrText: 'Sample OCR text',
      status: ExpenseStatus.submitted,
      createdAt: now,
    );

    setUp(() {
      repository = FakeExpenseRepository();
      repository.expenses = [sampleReceipt];
    });

    blocTest<ExpenseBloc, ExpenseState>(
      'loads expenses and computes metrics',
      build: () => ExpenseBloc(repository),
      act: (bloc) => bloc.add(const LoadExpensesEvent()),
      verify: (bloc) {
        expect(bloc.state.expenses.length, 1);
        expect(bloc.state.filteredExpenses.length, 1);
        expect(bloc.state.pendingCount, 1);
        expect(bloc.state.totalReimbursableUsd, closeTo(30.60, 0.01));
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'scans OCR text and populates activeOcrResult',
      build: () => ExpenseBloc(repository),
      act: (bloc) => bloc.add(
        const ScanOcrTextEvent('''
UBER TECHNOLOGIES
Total: \$45.00
Transit Tax: \$3.50
Date: 2026-11-17
'''),
      ),
      verify: (bloc) {
        expect(bloc.state.activeOcrResult, isNotNull);
        expect(bloc.state.activeOcrResult!.totalAmount, 45.0);
        expect(bloc.state.activeOcrResult!.category, ExpenseCategory.transit);
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'submits expense claim and prepends to list',
      build: () => ExpenseBloc(repository),
      seed: () => ExpenseState(
        expenses: [sampleReceipt],
        filteredExpenses: [sampleReceipt],
      ),
      act: (bloc) {
        final newReceipt = sampleReceipt.copyWith(
          id: 'EXP-SAMPLE-2',
          merchantName: 'Serena Hotel Islamabad',
          category: ExpenseCategory.lodging,
          rawAmount: 25000.0,
          usdEquivalent: 90.0,
        );
        bloc.add(SubmitExpenseClaimEvent(newReceipt));
      },
      verify: (bloc) {
        expect(bloc.state.expenses.length, 2);
        expect(bloc.state.expenses.first.id, 'EXP-SAMPLE-2');
        expect(bloc.state.feedbackMessage, contains('submitted successfully'));
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'updates expense status to approved and then reimbursed',
      build: () => ExpenseBloc(repository),
      seed: () => ExpenseState(
        expenses: [sampleReceipt],
        filteredExpenses: [sampleReceipt],
        selectedExpense: sampleReceipt,
      ),
      act: (bloc) => bloc.add(
        const UpdateExpenseStatusEvent(
          receiptId: 'EXP-SAMPLE-1',
          status: ExpenseStatus.approved,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.expenses.first.status, ExpenseStatus.approved);
        expect(bloc.state.feedbackMessage, contains('Approved'));
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'filters expenses by category',
      build: () => ExpenseBloc(repository),
      seed: () {
        final second = sampleReceipt.copyWith(
          id: 'EXP-SAMPLE-2',
          category: ExpenseCategory.clientLunch,
        );
        return ExpenseState(
          expenses: [sampleReceipt, second],
          filteredExpenses: [sampleReceipt, second],
        );
      },
      act: (bloc) => bloc.add(
        const FilterExpensesEvent(category: ExpenseCategory.clientLunch),
      ),
      verify: (bloc) {
        expect(bloc.state.filteredExpenses.length, 1);
        expect(
          bloc.state.filteredExpenses.first.category,
          ExpenseCategory.clientLunch,
        );
      },
    );

    blocTest<ExpenseBloc, ExpenseState>(
      'deletes expense and removes from list',
      build: () => ExpenseBloc(repository),
      seed: () => ExpenseState(
        expenses: [sampleReceipt],
        filteredExpenses: [sampleReceipt],
      ),
      act: (bloc) => bloc.add(const DeleteExpenseEvent('EXP-SAMPLE-1')),
      verify: (bloc) {
        expect(bloc.state.expenses, isEmpty);
        expect(bloc.state.filteredExpenses, isEmpty);
      },
    );
  });
}
