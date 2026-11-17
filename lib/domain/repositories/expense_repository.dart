import '../entities/expense_receipt.dart';

abstract class ExpenseRepository {
  Future<List<ExpenseReceipt>> getExpenses({String? employeeId});
  Future<ExpenseReceipt> saveExpense(ExpenseReceipt receipt);
  Future<ExpenseReceipt> updateExpenseStatus(
    String receiptId,
    ExpenseStatus status,
  );
  Future<void> deleteExpense(String receiptId);
  Future<double> getTotalReimbursementUsd();
}
