import 'package:sqflite/sqflite.dart';

import '../../domain/entities/expense_receipt.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/local/app_database.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final AppDatabase _appDatabase;

  ExpenseRepositoryImpl(this._appDatabase);

  @override
  Future<List<ExpenseReceipt>> getExpenses({String? employeeId}) async {
    final db = await _appDatabase.database;
    final List<Map<String, dynamic>> results;
    if (employeeId != null) {
      results = await db.query(
        'expense_receipts',
        where: 'employeeId = ?',
        whereArgs: [employeeId],
        orderBy: 'createdAt DESC',
      );
    } else {
      results = await db.query('expense_receipts', orderBy: 'createdAt DESC');
    }
    return results.map((m) => ExpenseReceipt.fromMap(m)).toList();
  }

  @override
  Future<ExpenseReceipt> saveExpense(ExpenseReceipt receipt) async {
    final db = await _appDatabase.database;
    await db.insert(
      'expense_receipts',
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return receipt;
  }

  @override
  Future<ExpenseReceipt> updateExpenseStatus(
    String receiptId,
    ExpenseStatus status,
  ) async {
    final db = await _appDatabase.database;
    await db.update(
      'expense_receipts',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [receiptId],
    );

    final results = await db.query(
      'expense_receipts',
      where: 'id = ?',
      whereArgs: [receiptId],
      limit: 1,
    );
    if (results.isEmpty) {
      throw Exception('Expense receipt not found with id: $receiptId');
    }
    return ExpenseReceipt.fromMap(results.first);
  }

  @override
  Future<void> deleteExpense(String receiptId) async {
    final db = await _appDatabase.database;
    await db.delete(
      'expense_receipts',
      where: 'id = ?',
      whereArgs: [receiptId],
    );
  }

  @override
  Future<double> getTotalReimbursementUsd() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery(
      "SELECT SUM(usdEquivalent) as total FROM expense_receipts WHERE status = 'submitted' OR status = 'approved'",
    );
    final val = result.first['total'];
    if (val == null) return 0.0;
    return (val as num).toDouble();
  }
}
