import 'package:equatable/equatable.dart';

import '../../../domain/entities/expense_receipt.dart';
import '../../../domain/services/ocr_receipt_parser.dart';

class ExpenseState extends Equatable {
  final bool isLoading;
  final List<ExpenseReceipt> expenses;
  final List<ExpenseReceipt> filteredExpenses;
  final ExpenseReceipt? selectedExpense;
  final ExpenseCategory? selectedCategory;
  final ExpenseStatus? selectedStatus;
  final ParsedOcrResult? activeOcrResult;
  final double totalReimbursableUsd;
  final int pendingCount;
  final String? feedbackMessage;
  final String? errorMessage;

  const ExpenseState({
    this.isLoading = false,
    this.expenses = const [],
    this.filteredExpenses = const [],
    this.selectedExpense,
    this.selectedCategory,
    this.selectedStatus,
    this.activeOcrResult,
    this.totalReimbursableUsd = 0.0,
    this.pendingCount = 0,
    this.feedbackMessage,
    this.errorMessage,
  });

  ExpenseState copyWith({
    bool? isLoading,
    List<ExpenseReceipt>? expenses,
    List<ExpenseReceipt>? filteredExpenses,
    ExpenseReceipt? selectedExpense,
    bool clearSelectedExpense = false,
    ExpenseCategory? selectedCategory,
    bool clearSelectedCategory = false,
    ExpenseStatus? selectedStatus,
    bool clearSelectedStatus = false,
    ParsedOcrResult? activeOcrResult,
    bool clearActiveOcrResult = false,
    double? totalReimbursableUsd,
    int? pendingCount,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      filteredExpenses: filteredExpenses ?? this.filteredExpenses,
      selectedExpense: clearSelectedExpense
          ? null
          : (selectedExpense ?? this.selectedExpense),
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedStatus: clearSelectedStatus
          ? null
          : (selectedStatus ?? this.selectedStatus),
      activeOcrResult: clearActiveOcrResult
          ? null
          : (activeOcrResult ?? this.activeOcrResult),
      totalReimbursableUsd: totalReimbursableUsd ?? this.totalReimbursableUsd,
      pendingCount: pendingCount ?? this.pendingCount,
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
    expenses,
    filteredExpenses,
    selectedExpense,
    selectedCategory,
    selectedStatus,
    activeOcrResult,
    totalReimbursableUsd,
    pendingCount,
    feedbackMessage,
    errorMessage,
  ];
}
