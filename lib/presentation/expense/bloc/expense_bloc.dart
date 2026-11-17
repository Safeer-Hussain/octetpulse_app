import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/expense_receipt.dart';
import '../../../domain/repositories/expense_repository.dart';
import '../../../domain/services/ocr_receipt_parser.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseBloc(this._repository) : super(const ExpenseState()) {
    on<LoadExpensesEvent>(_onLoadExpenses);
    on<ScanOcrTextEvent>(_onScanOcrText);
    on<SubmitExpenseClaimEvent>(_onSubmitExpenseClaim);
    on<UpdateExpenseStatusEvent>(_onUpdateExpenseStatus);
    on<FilterExpensesEvent>(_onFilterExpenses);
    on<SelectExpenseEvent>(_onSelectExpense);
    on<DeleteExpenseEvent>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(
    LoadExpensesEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final list = await _repository.getExpenses(employeeId: event.employeeId);
      final totalReimbursable = await _repository.getTotalReimbursementUsd();
      final filtered = _applyFilter(
        list: list,
        category: state.selectedCategory,
        status: state.selectedStatus,
      );
      final pendingCount = list
          .where(
            (e) =>
                e.status == ExpenseStatus.submitted ||
                e.status == ExpenseStatus.approved,
          )
          .length;

      emit(
        state.copyWith(
          isLoading: false,
          expenses: list,
          filteredExpenses: filtered,
          selectedExpense: filtered.isNotEmpty ? filtered.first : null,
          totalReimbursableUsd: totalReimbursable,
          pendingCount: pendingCount,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load expense receipts: $e',
        ),
      );
    }
  }

  void _onScanOcrText(ScanOcrTextEvent event, Emitter<ExpenseState> emit) {
    if (event.rawOcrText.trim().isEmpty) {
      emit(state.copyWith(clearActiveOcrResult: true));
      return;
    }
    final parsed = OcrReceiptParser.parse(event.rawOcrText);
    emit(state.copyWith(activeOcrResult: parsed));
  }

  Future<void> _onSubmitExpenseClaim(
    SubmitExpenseClaimEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final saved = await _repository.saveExpense(event.receipt);
      final updated = [saved, ...state.expenses];
      final filtered = _applyFilter(
        list: updated,
        category: state.selectedCategory,
        status: state.selectedStatus,
      );
      final totalReimbursable = await _repository.getTotalReimbursementUsd();
      final pendingCount = updated
          .where(
            (e) =>
                e.status == ExpenseStatus.submitted ||
                e.status == ExpenseStatus.approved,
          )
          .length;

      emit(
        state.copyWith(
          expenses: updated,
          filteredExpenses: filtered,
          selectedExpense: saved,
          totalReimbursableUsd: totalReimbursable,
          pendingCount: pendingCount,
          clearActiveOcrResult: true,
          feedbackMessage:
              'Expense claim for ${saved.merchantName} submitted successfully (\$${saved.usdEquivalent.toStringAsFixed(2)} USD).',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to submit expense claim: $e'));
    }
  }

  Future<void> _onUpdateExpenseStatus(
    UpdateExpenseStatusEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      final updatedReceipt = await _repository.updateExpenseStatus(
        event.receiptId,
        event.status,
      );
      final updatedList = state.expenses.map((e) {
        return e.id == updatedReceipt.id ? updatedReceipt : e;
      }).toList();

      final filtered = _applyFilter(
        list: updatedList,
        category: state.selectedCategory,
        status: state.selectedStatus,
      );
      final totalReimbursable = await _repository.getTotalReimbursementUsd();
      final pendingCount = updatedList
          .where(
            (e) =>
                e.status == ExpenseStatus.submitted ||
                e.status == ExpenseStatus.approved,
          )
          .length;

      emit(
        state.copyWith(
          expenses: updatedList,
          filteredExpenses: filtered,
          selectedExpense: updatedReceipt,
          totalReimbursableUsd: totalReimbursable,
          pendingCount: pendingCount,
          feedbackMessage:
              'Expense ${updatedReceipt.id} updated to ${updatedReceipt.status.displayName}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update expense status: $e'));
    }
  }

  void _onFilterExpenses(
    FilterExpensesEvent event,
    Emitter<ExpenseState> emit,
  ) {
    final filtered = _applyFilter(
      list: state.expenses,
      category: event.category,
      status: event.status,
    );

    emit(
      state.copyWith(
        selectedCategory: event.category,
        clearSelectedCategory: event.category == null,
        selectedStatus: event.status,
        clearSelectedStatus: event.status == null,
        filteredExpenses: filtered,
        selectedExpense: filtered.isNotEmpty ? filtered.first : null,
      ),
    );
  }

  void _onSelectExpense(SelectExpenseEvent event, Emitter<ExpenseState> emit) {
    emit(
      state.copyWith(
        selectedExpense: event.receipt,
        clearSelectedExpense: event.receipt == null,
      ),
    );
  }

  Future<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    try {
      await _repository.deleteExpense(event.receiptId);
      final updatedList = state.expenses
          .where((e) => e.id != event.receiptId)
          .toList();
      final filtered = _applyFilter(
        list: updatedList,
        category: state.selectedCategory,
        status: state.selectedStatus,
      );
      final totalReimbursable = await _repository.getTotalReimbursementUsd();
      final pendingCount = updatedList
          .where(
            (e) =>
                e.status == ExpenseStatus.submitted ||
                e.status == ExpenseStatus.approved,
          )
          .length;

      emit(
        state.copyWith(
          expenses: updatedList,
          filteredExpenses: filtered,
          selectedExpense: filtered.isNotEmpty ? filtered.first : null,
          totalReimbursableUsd: totalReimbursable,
          pendingCount: pendingCount,
          feedbackMessage: 'Expense ${event.receiptId} removed.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete expense: $e'));
    }
  }

  List<ExpenseReceipt> _applyFilter({
    required List<ExpenseReceipt> list,
    ExpenseCategory? category,
    ExpenseStatus? status,
  }) {
    return list.where((item) {
      if (category != null && item.category != category) {
        return false;
      }
      if (status != null && item.status != status) {
        return false;
      }
      return true;
    }).toList();
  }
}
