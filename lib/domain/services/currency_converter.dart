import '../entities/expense_receipt.dart';

class CurrencyConverter {
  static const Map<CurrencyCode, double> _exchangeRatesToUsd = {
    CurrencyCode.usd: 1.0,
    CurrencyCode.pkr: 0.0036, // ~278 PKR per USD
    CurrencyCode.eur: 1.08, // ~0.93 EUR per USD
    CurrencyCode.aed: 0.272, // ~3.67 AED per USD
    CurrencyCode.gbp: 1.28, // ~0.78 GBP per USD
  };

  static double getRateToUsd(CurrencyCode currency) {
    return _exchangeRatesToUsd[currency] ?? 1.0;
  }

  static double convertToUsd({
    required double amount,
    required CurrencyCode fromCurrency,
  }) {
    final rate = getRateToUsd(fromCurrency);
    final converted = amount * rate;
    return (converted * 100).round() / 100;
  }

  static double convertFromUsd({
    required double usdAmount,
    required CurrencyCode targetCurrency,
  }) {
    final rate = getRateToUsd(targetCurrency);
    if (rate <= 0) return usdAmount;
    final converted = usdAmount / rate;
    return (converted * 100).round() / 100;
  }

  static String formatAmount(double amount, CurrencyCode currency) {
    final symbol = currency.symbol;
    if (currency == CurrencyCode.pkr || currency == CurrencyCode.aed) {
      return '$symbol ${amount.toStringAsFixed(2)}';
    }
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}
