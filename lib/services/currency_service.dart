class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final double rateToEur; // 1 EUR = rateToEur of this currency

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.rateToEur,
  });
}

class CurrencyService {
  static const List<CurrencyInfo> currencies = [
    CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', rateToEur: 1.0),
    CurrencyInfo(code: 'USD', name: 'Dollaro Statunitense', symbol: '\$', rateToEur: 1.08),
    CurrencyInfo(code: 'GBP', name: 'Sterlina Britannica', symbol: '£', rateToEur: 0.85),
    CurrencyInfo(code: 'JPY', name: 'Yen Giapponese', symbol: '¥', rateToEur: 170.0),
    CurrencyInfo(code: 'CNY', name: 'Yuan Cinese', symbol: '¥', rateToEur: 7.85),
    CurrencyInfo(code: 'KRW', name: 'Won Sudcoreano', symbol: '₩', rateToEur: 1500.0),
    CurrencyInfo(code: 'AED', name: 'Dirham Emirati Arabi', symbol: 'د.إ', rateToEur: 3.97),
    CurrencyInfo(code: 'MAD', name: 'Dirham Marocchino', symbol: 'د.م.', rateToEur: 10.75),
    CurrencyInfo(code: 'AUD', name: 'Dollaro Australiano', symbol: 'A\$', rateToEur: 1.62),
    CurrencyInfo(code: 'INR', name: 'Rupia Indiana', symbol: '₹', rateToEur: 90.0),
    CurrencyInfo(code: 'NZD', name: 'Dollaro Neozelandese', symbol: 'NZ\$', rateToEur: 1.76),
    CurrencyInfo(code: 'IDR', name: 'Rupia Indonesiana', symbol: 'Rp', rateToEur: 17500.0),
    CurrencyInfo(code: 'DKK', name: 'Corona Danese', symbol: 'kr', rateToEur: 7.46),
    CurrencyInfo(code: 'PLN', name: 'Zloty Polacco', symbol: 'zł', rateToEur: 4.30),
    CurrencyInfo(code: 'CZK', name: 'Corona Ceca', symbol: 'Kč', rateToEur: 24.80),
    CurrencyInfo(code: 'RON', name: 'Leu Rumeno', symbol: 'lei', rateToEur: 4.97),
    CurrencyInfo(code: 'MDL', name: 'Leu Moldavo', symbol: 'L', rateToEur: 19.20),
    CurrencyInfo(code: 'SEK', name: 'Corona Svedese', symbol: 'kr', rateToEur: 11.20),
    CurrencyInfo(code: 'CHF', name: 'Franco Svizzero', symbol: 'CHF', rateToEur: 0.96),
    CurrencyInfo(code: 'NOK', name: 'Corona Norvegese', symbol: 'kr', rateToEur: 11.40),
    CurrencyInfo(code: 'ISK', name: 'Corona Islandese', symbol: 'kr', rateToEur: 148.0),
    CurrencyInfo(code: 'ALL', name: 'Lek Albanese', symbol: 'Lek', rateToEur: 100.0),
    CurrencyInfo(code: 'TRY', name: 'Lira Turca', symbol: '₺', rateToEur: 35.0),
    CurrencyInfo(code: 'RUB', name: 'Rublo Russo', symbol: '₽', rateToEur: 96.0),
    CurrencyInfo(code: 'CAD', name: 'Dollaro Canadese', symbol: 'C\$', rateToEur: 1.48),
    CurrencyInfo(code: 'XOF', name: 'Franco CFA', symbol: 'CFA', rateToEur: 655.957),
    CurrencyInfo(code: 'EGP', name: 'Sterlina Egiziana', symbol: 'E£', rateToEur: 50.0),
    CurrencyInfo(code: 'ZAR', name: 'Rand Sudafricano', symbol: 'R', rateToEur: 19.50),
  ];

  static double convert(double amount, String fromCode, String toCode) {
    if (fromCode == toCode) return amount;
    final from = currencies.firstWhere((c) => c.code == fromCode, orElse: () => currencies[0]);
    final to = currencies.firstWhere((c) => c.code == toCode, orElse: () => currencies[0]);

    // First convert to EUR
    final amountInEur = amount / from.rateToEur;
    // Then convert to target currency
    return amountInEur * to.rateToEur;
  }

  static String getSymbol(String code) {
    return currencies.firstWhere((c) => c.code == code, orElse: () => currencies[0]).symbol;
  }

  static String getName(String code) {
    return currencies.firstWhere((c) => c.code == code, orElse: () => currencies[0]).name;
  }
}
