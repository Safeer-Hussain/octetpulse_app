import 'package:equatable/equatable.dart';

import '../../../domain/entities/expense_receipt.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpensesEvent extends ExpenseEvent {
  final String? employeeId;

  const LoadExpensesEvent({this.employeeId});

  @override
  List<Object?> get props => [employeeId];
}

class ScanOcrTextEvent extends ExpenseEvent {
  final String rawOcrText;

  const ScanOcrTextEvent(this.rawOcrText);

  @override
  List<Object?> get props => [rawOcrText];
}

class SubmitExpenseClaimEvent extends ExpenseEvent {
  final ExpenseReceipt receipt;

  const SubmitExpenseClaimEvent(this.receipt);

  @override
  List<Object?> get props => [receipt];
}

class UpdateExpenseStatusEvent extends ExpenseEvent {
  final String receiptId;
  final ExpenseStatus status;

  const UpdateExpenseStatusEvent({
    required this.receiptId,
    required this.status,
  });

  @override
  List<Object?> get props => [receiptId, status];
}

class FilterExpensesEvent extends ExpenseEvent {
  final ExpenseCategory? category;
  final ExpenseStatus? status;

  const FilterExpensesEvent({this.category, this.status});

  @override
  List<Object?> get props => [category, status];
}

class SelectExpenseEvent extends ExpenseEvent {
  final ExpenseReceipt? receipt;

  const SelectExpenseEvent(this.receipt);

  @override
  List<Object?> get props => [receipt];
}

class DeleteExpenseEvent extends ExpenseEvent {
  final String receiptId;

  const DeleteExpenseEvent(this.receiptId);

  @override
  List<Object?> get props => [receiptId];
}
