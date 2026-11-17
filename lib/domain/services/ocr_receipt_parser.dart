import 'package:intl/intl.dart';

import '../entities/expense_receipt.dart';
import 'currency_converter.dart';

class ParsedOcrResult {
  final String merchantName;
  final DateTime receiptDate;
  final CurrencyCode currency;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double usdEquivalent;
  final ExpenseCategory category;
  final double confidenceScore;
  final Map<String, String> extractedTokens;

  const ParsedOcrResult({
    required this.merchantName,
    required this.receiptDate,
    required this.currency,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.usdEquivalent,
    required this.category,
    required this.confidenceScore,
    required this.extractedTokens,
  });
}

class OcrReceiptParser {
  static ParsedOcrResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final tokens = <String, String>{};
    int matchedTokensCount = 0;

    // 1. Currency Extraction
    final currency = _extractCurrency(rawText);
    tokens['currency'] = currency.code;
    matchedTokensCount++;

    // 2. Merchant Name
    final merchant = _extractMerchant(lines);
    tokens['merchant'] = merchant;
    if (merchant != 'Corporate Vendor') matchedTokensCount++;

    // 3. Receipt Date
    final date = _extractDate(rawText);
    tokens['date'] = DateFormat('yyyy-MM-dd').format(date);
    matchedTokensCount++;

    // 4. Tax Extraction
    final tax = _extractTax(rawText);
    tokens['tax'] = tax.toStringAsFixed(2);
    if (tax > 0) matchedTokensCount++;

    // 5. Total & Subtotal Extraction
    final total = _extractTotal(rawText);
    tokens['total'] = total.toStringAsFixed(2);
    if (total > 0) matchedTokensCount++;

    final subtotal = total > tax ? total - tax : total;
    tokens['subtotal'] = subtotal.toStringAsFixed(2);

    // 6. Category Auto-Classification
    final category = _classifyCategory(rawText, merchant);
    tokens['category'] = category.displayName;

    // 7. USD Equivalent
    final usdEquivalent = CurrencyConverter.convertToUsd(
      amount: total,
      fromCurrency: currency,
    );
    tokens['usdEquivalent'] = '\$${usdEquivalent.toStringAsFixed(2)}';

    // Confidence Score (0.0 to 1.0)
    final confidence = (matchedTokensCount / 5.0).clamp(0.2, 1.0);

    return ParsedOcrResult(
      merchantName: merchant,
      receiptDate: date,
      currency: currency,
      subtotal: subtotal,
      taxAmount: tax,
      totalAmount: total,
      usdEquivalent: usdEquivalent,
      category: category,
      confidenceScore: confidence,
      extractedTokens: tokens,
    );
  }

  static CurrencyCode _extractCurrency(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('pkr') ||
        lower.contains('rs.') ||
        lower.contains('rupees') ||
        lower.contains('pakistan')) {
      return CurrencyCode.pkr;
    }
    if (lower.contains('usd') || lower.contains('\$')) {
      return CurrencyCode.usd;
    }
    if (lower.contains('eur') || lower.contains('€')) {
      return CurrencyCode.eur;
    }
    if (lower.contains('aed') ||
        lower.contains('dirham') ||
        lower.contains('dhs')) {
      return CurrencyCode.aed;
    }
    if (lower.contains('gbp') || lower.contains('£')) {
      return CurrencyCode.gbp;
    }
    return CurrencyCode.pkr;
  }

  static String _extractMerchant(List<String> lines) {
    if (lines.isEmpty) return 'Corporate Vendor';

    // Top enterprise brand patterns
    final brands = [
      'Shell',
      'Total Parco',
      'PSO',
      'Attock Petroleum',
      'Pearl Continental',
      'Serena Hotel',
      'Marriott',
      'McDonald\'s',
      'KFC',
      'Gloria Jean\'s',
      'Subway',
      'Uber',
      'Careem',
      'Daewoo Express',
      'PIA',
      'Emirates',
      'Staples',
      'Office Depot',
    ];

    for (final line in lines.take(5)) {
      for (final brand in brands) {
        if (line.toLowerCase().contains(brand.toLowerCase())) {
          return line;
        }
      }
    }

    // Default to the first line that doesn't contain pure numbers, receipt headers, or dates
    for (final line in lines.take(4)) {
      final isHeader =
          line.toLowerCase().contains('receipt') ||
          line.toLowerCase().contains('invoice') ||
          line.toLowerCase().contains('tax invoice') ||
          line.toLowerCase().contains('cash memo');
      final hasLetters = RegExp(r'[A-Za-z]').hasMatch(line);
      if (!isHeader && hasLetters && line.length > 2) {
        return line;
      }
    }

    return lines.first;
  }

  static DateTime _extractDate(String text) {
    // 1. YYYY-MM-DD
    final isoMatch = RegExp(
      r'\b(20\d{2})[-/.](0[1-9]|1[0-2])[-/.](0[1-9]|[12]\d|3[01])\b',
    ).firstMatch(text);
    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);
      return DateTime(y, m, d);
    }

    // 2. DD/MM/YYYY or DD-MM-YYYY
    final dmyMatch = RegExp(
      r'\b(0[1-9]|[12]\d|3[01])[-/.](0[1-9]|1[0-2])[-/.](20\d{2})\b',
    ).firstMatch(text);
    if (dmyMatch != null) {
      final d = int.parse(dmyMatch.group(1)!);
      final m = int.parse(dmyMatch.group(2)!);
      final y = int.parse(dmyMatch.group(3)!);
      return DateTime(y, m, d);
    }

    // 3. DD Month YYYY (e.g. 15 Nov 2026, 15 November 2026)
    final textDateMatch = RegExp(
      r'\b(0[1-9]|[12]\d|3[01])\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s,]+(20\d{2})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (textDateMatch != null) {
      try {
        final d = textDateMatch.group(1)!;
        final mStr = textDateMatch.group(2)!;
        final y = textDateMatch.group(3)!;
        return DateFormat('dd MMM yyyy').parse('$d $mStr $y');
      } catch (_) {}
    }

    return DateTime.now();
  }

  static double _extractTax(String text) {
    final taxPatterns = [
      RegExp(
        r'(?:GST|Sales Tax|Tax|VAT|Govt Tax)\s*(?:\(\d+%\))?\s*[:=]?\s*(?:[A-Za-z$€£.]+)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(r'\bTax\s*[:=]\s*([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (final pattern in taxPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        final val = double.tryParse(raw);
        if (val != null) return val;
      }
    }
    return 0.0;
  }

  static double _extractTotal(String text) {
    final totalPatterns = [
      RegExp(
        r'\b(?:Grand Total|Total Amount|Total Paid|Total Due|Net Total|Amount Due|Total Charged)\s*[:=]?\s*(?:[A-Za-z$€£.]+)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'\bTotal\b\s*[:=]?\s*(?:[A-Za-z$€£.]+)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'\bCharged\b\s*[:=]?\s*(?:[A-Za-z$€£.]+)?\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in totalPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        final val = double.tryParse(raw);
        if (val != null && val > 0) return val;
      }
    }

    // Fallback: search for all currency amounts and pick the largest plausible amount
    final amountsRegex = RegExp(r'(?:[\$€£]|PKR|Rs\.?|AED)?\s*([\d,]+\.\d{2})');
    final matches = amountsRegex.allMatches(text);
    double maxAmount = 0.0;
    for (final m in matches) {
      final raw = m.group(1)!.replaceAll(',', '');
      final val = double.tryParse(raw) ?? 0.0;
      if (val > maxAmount && val < 1000000) {
        maxAmount = val;
      }
    }

    return maxAmount > 0 ? maxAmount : 0.0;
  }

  static ExpenseCategory _classifyCategory(String text, String merchant) {
    final combined = '$text $merchant'.toLowerCase();

    if (combined.contains('petrol') ||
        combined.contains('fuel') ||
        combined.contains('diesel') ||
        combined.contains('cng') ||
        combined.contains('gas station') ||
        combined.contains('pso') ||
        combined.contains('shell') ||
        combined.contains('attock') ||
        combined.contains('litres') ||
        combined.contains('liters')) {
      return ExpenseCategory.fuel;
    }

    if (combined.contains('dining') ||
        combined.contains('restaurant') ||
        combined.contains('lunch') ||
        combined.contains('dinner') ||
        combined.contains('cafe') ||
        combined.contains('coffee') ||
        combined.contains('food') ||
        combined.contains('meal') ||
        combined.contains('buffet') ||
        combined.contains('mcdonald') ||
        combined.contains('kfc') ||
        combined.contains('subway') ||
        combined.contains('beverage')) {
      return ExpenseCategory.clientLunch;
    }

    if (combined.contains('uber') ||
        combined.contains('careem') ||
        combined.contains('taxi') ||
        combined.contains('transit') ||
        combined.contains('flight') ||
        combined.contains('airline') ||
        combined.contains('daewoo') ||
        combined.contains('fare') ||
        combined.contains('toll')) {
      return ExpenseCategory.transit;
    }

    if (combined.contains('hotel') ||
        combined.contains('resort') ||
        combined.contains('room') ||
        combined.contains('lodging') ||
        combined.contains('suites') ||
        combined.contains('marriott') ||
        combined.contains('stay') ||
        combined.contains('check-in')) {
      return ExpenseCategory.lodging;
    }

    if (combined.contains('paper') ||
        combined.contains('stationery') ||
        combined.contains('print') ||
        combined.contains('staples') ||
        combined.contains('hardware') ||
        combined.contains('keyboard') ||
        combined.contains('mouse') ||
        combined.contains('cable') ||
        combined.contains('supplies')) {
      return ExpenseCategory.officeSupplies;
    }

    return ExpenseCategory.officeSupplies;
  }
}
