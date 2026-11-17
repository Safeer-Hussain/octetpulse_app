import 'package:flutter/material.dart';

enum ExpenseCategory {
  fuel,
  clientLunch,
  transit,
  lodging,
  officeSupplies;

  String get displayName {
    switch (this) {
      case ExpenseCategory.fuel:
        return 'Fuel & Mileage';
      case ExpenseCategory.clientLunch:
        return 'Client Dining';
      case ExpenseCategory.transit:
        return 'Transit & Flights';
      case ExpenseCategory.lodging:
        return 'Lodging & Hotel';
      case ExpenseCategory.officeSupplies:
        return 'Office & Hardware';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.fuel:
        return Icons.local_gas_station;
      case ExpenseCategory.clientLunch:
        return Icons.restaurant;
      case ExpenseCategory.transit:
        return Icons.local_taxi;
      case ExpenseCategory.lodging:
        return Icons.hotel;
      case ExpenseCategory.officeSupplies:
        return Icons.business_center;
    }
  }
}

enum CurrencyCode {
  pkr,
  usd,
  eur,
  aed,
  gbp;

  String get code => name.toUpperCase();

  String get symbol {
    switch (this) {
      case CurrencyCode.pkr:
        return 'PKR';
      case CurrencyCode.usd:
        return '\$';
      case CurrencyCode.eur:
        return '€';
      case CurrencyCode.aed:
        return 'AED';
      case CurrencyCode.gbp:
        return '£';
    }
  }

  double get defaultExchangeRateToUsd {
    switch (this) {
      case CurrencyCode.pkr:
        return 0.0036; // 1 USD = ~278 PKR
      case CurrencyCode.usd:
        return 1.0;
      case CurrencyCode.eur:
        return 1.08;
      case CurrencyCode.aed:
        return 0.272; // 1 USD = ~3.67 AED
      case CurrencyCode.gbp:
        return 1.28;
    }
  }

  static CurrencyCode fromString(String str) {
    final lower = str.trim().toLowerCase();
    if (lower == 'pkr' || lower == 'rs' || lower == 'rs.') {
      return CurrencyCode.pkr;
    }
    if (lower == 'usd' || lower == '\$') {
      return CurrencyCode.usd;
    }
    if (lower == 'eur' || lower == '€') {
      return CurrencyCode.eur;
    }
    if (lower == 'aed' || lower == 'dhs') {
      return CurrencyCode.aed;
    }
    if (lower == 'gbp' || lower == '£') {
      return CurrencyCode.gbp;
    }
    return CurrencyCode.pkr;
  }
}

enum ExpenseStatus {
  draft,
  submitted,
  approved,
  reimbursed,
  rejected;

  String get displayName {
    switch (this) {
      case ExpenseStatus.draft:
        return 'Draft';
      case ExpenseStatus.submitted:
        return 'Submitted';
      case ExpenseStatus.approved:
        return 'Approved';
      case ExpenseStatus.reimbursed:
        return 'Reimbursed';
      case ExpenseStatus.rejected:
        return 'Rejected';
    }
  }
}

class ExpenseReceipt {
  final String id;
  final String employeeId;
  final String employeeName;
  final String merchantName;
  final ExpenseCategory category;
  final CurrencyCode currency;
  final double rawAmount;
  final double taxAmount;
  final double exchangeRateToUsd;
  final double usdEquivalent;
  final DateTime receiptDate;
  final String rawOcrText;
  final ExpenseStatus status;
  final String? reimbursementBatchId;
  final DateTime createdAt;

  const ExpenseReceipt({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.merchantName,
    required this.category,
    required this.currency,
    required this.rawAmount,
    required this.taxAmount,
    required this.exchangeRateToUsd,
    required this.usdEquivalent,
    required this.receiptDate,
    required this.rawOcrText,
    required this.status,
    this.reimbursementBatchId,
    required this.createdAt,
  });

  bool get canApprove => status == ExpenseStatus.submitted;
  bool get canReimburse => status == ExpenseStatus.approved;
  bool get canReject =>
      status == ExpenseStatus.submitted || status == ExpenseStatus.approved;

  ExpenseReceipt copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? merchantName,
    ExpenseCategory? category,
    CurrencyCode? currency,
    double? rawAmount,
    double? taxAmount,
    double? exchangeRateToUsd,
    double? usdEquivalent,
    DateTime? receiptDate,
    String? rawOcrText,
    ExpenseStatus? status,
    String? reimbursementBatchId,
    DateTime? createdAt,
  }) {
    return ExpenseReceipt(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      merchantName: merchantName ?? this.merchantName,
      category: category ?? this.category,
      currency: currency ?? this.currency,
      rawAmount: rawAmount ?? this.rawAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      exchangeRateToUsd: exchangeRateToUsd ?? this.exchangeRateToUsd,
      usdEquivalent: usdEquivalent ?? this.usdEquivalent,
      receiptDate: receiptDate ?? this.receiptDate,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      status: status ?? this.status,
      reimbursementBatchId: reimbursementBatchId ?? this.reimbursementBatchId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'employeeName': employeeName,
      'merchantName': merchantName,
      'category': category.name,
      'currency': currency.name,
      'rawAmount': rawAmount,
      'taxAmount': taxAmount,
      'exchangeRateToUsd': exchangeRateToUsd,
      'usdEquivalent': usdEquivalent,
      'receiptDate': receiptDate.toIso8601String(),
      'rawOcrText': rawOcrText,
      'status': status.name,
      'reimbursementBatchId': reimbursementBatchId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseReceipt.fromMap(Map<String, dynamic> map) {
    return ExpenseReceipt(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String,
      merchantName: map['merchantName'] as String,
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => ExpenseCategory.fuel,
      ),
      currency: CurrencyCode.values.firstWhere(
        (c) => c.name == map['currency'],
        orElse: () => CurrencyCode.pkr,
      ),
      rawAmount: (map['rawAmount'] as num).toDouble(),
      taxAmount: (map['taxAmount'] as num).toDouble(),
      exchangeRateToUsd: (map['exchangeRateToUsd'] as num).toDouble(),
      usdEquivalent: (map['usdEquivalent'] as num).toDouble(),
      receiptDate: DateTime.parse(map['receiptDate'] as String),
      rawOcrText: map['rawOcrText'] as String,
      status: ExpenseStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ExpenseStatus.submitted,
      ),
      reimbursementBatchId: map['reimbursementBatchId'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
