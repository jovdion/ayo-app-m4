import 'package:intl/intl.dart';

class CurrencyHelper {
  static final Map<String, double> _exchangeRates = {
    'IDR': 1.0,
    'USD': 0.000061,
    'EUR': 0.000054,
    'JPY': 0.0088,
    'KRW': 0.084,
    'SGD': 0.000079,
    'MYR': 0.00026,
    'CNY': 0.00044,
  };

 




 
  static List<String> get supportedCurrencies => _exchangeRates.keys.toList();

  static final Map<String, String> _currencySymbols = {
    'IDR': 'Rp',
    'USD': r'$',
    'EUR': '€',
    'JPY': '¥',
    'KRW': '₩',
    'SGD': r'S$',
    'MYR': 'RM',
    'CNY': '¥',
  };

  // Combined pattern for all currency formats
  static final RegExp _fullPattern = RegExp(
    r'(?:(\$|Rp\.?|€|¥|S\$|RM)\s*(\d+(?:\.\d{3})*(?:[,.]\d+)?)|(\d+(?:\.\d{3})*(?:[,.]\d+)?)\s*(IDR|USD|EUR|JPY|KRW|SGD|MYR|CNY))',
    caseSensitive: false,
  );

  static bool hasCurrency(String text) {
    return _fullPattern.hasMatch(text);
  }

  static List<Map<String, dynamic>> extractCurrenciesFromText(String text) {
    List<Map<String, dynamic>> results = [];

    var matches = _fullPattern.allMatches(text);

    for (var match in matches) {
      try {
        String? symbol = match.group(1);
        String? amount;
        String currency;

        if (symbol != null) {
          // Symbol first format (e.g., $50, Rp 50.000)
          amount = match.group(2);
          currency = _findCurrencyBySymbol(symbol);
        } else {
          // Code last format (e.g., 50 USD, 50.000 IDR)
          amount = match.group(3);
          currency = match.group(4)!.toUpperCase();
        }

        if (amount != null) {
          // Remove dots for IDR amounts
          if (currency == 'IDR') {
            amount = amount.replaceAll('.', '');
          }

          // Convert comma to dot for decimal point
          amount = amount.replaceAll(',', '.');

          double parsedAmount;
          try {
            parsedAmount = double.parse(amount);
          } catch (e) {
            print('Error parsing amount: $amount');
            continue;
          }

          results.add({
            'amount': parsedAmount,
            'currency': currency,
          });
        }
      } catch (e) {
        print('Error processing match: $e');
        continue;
      }
    }

    return results;
  }

  static String _findCurrencyBySymbol(String text) {
    String upperText = text.toUpperCase().trim().replaceAll('.', '');

    // Direct symbol to currency mapping
    final Map<String, String> symbolToCurrency = {
      r'$': 'USD',
      'RP': 'IDR',
      '€': 'EUR',
      '¥': 'JPY',
      '₩': 'KRW',
      r'S$': 'SGD',
      'RM': 'MYR',
    };

    // Try exact match first
    for (var entry in symbolToCurrency.entries) {
      if (upperText == entry.key) {
        return entry.value;
      }
    }

    // Try partial match for compound symbols
    for (var entry in symbolToCurrency.entries) {
      if (upperText.contains(entry.key)) {
        return entry.value;
      }
    }

    return upperText;
  }

  static double convertCurrency(
      double amount, String fromCurrency, String toCurrency) {
    // Handle currency symbols
    fromCurrency = _normalizeCurrency(fromCurrency);
    toCurrency = _normalizeCurrency(toCurrency);

    if (fromCurrency == toCurrency) return amount;

    // Convert to IDR first (base currency)
    final amountInIDR = amount / _exchangeRates[fromCurrency]!;

    // Convert from IDR to target currency
    return amountInIDR * _exchangeRates[toCurrency]!;
  }

  static String _normalizeCurrency(String currency) {
    currency = currency.toUpperCase().trim().replaceAll('.', '');

    // If it's already a valid currency code, return it
    if (_exchangeRates.containsKey(currency)) {
      return currency;
    }

    // Check if it's a symbol and convert to currency code
    return _findCurrencyBySymbol(currency);
  }

  static String formatCurrency(double amount, String currency) {
    final symbol = _currencySymbols[currency] ?? currency;

    // Special handling for IDR to show proper formatting
    if (currency == 'IDR') {
      final formatter = NumberFormat('#,###', 'id_ID');
      String formatted = formatter.format(amount);
      // Replace commas with dots for thousand separators
      formatted = formatted.replaceAll(',', '.');
      return '$symbol $formatted';
    }

    // For USD, EUR use 2 decimal places
    if (['USD', 'EUR', 'SGD'].contains(currency)) {
      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: symbol,
        decimalDigits: 2,
      );
      return formatter.format(amount).replaceFirst(symbol, '$symbol ');
    }

    // For JPY, KRW use 0 decimal places
    if (['JPY', 'KRW'].contains(currency)) {
      final formatter = NumberFormat.currency(
        locale: 'en_US',
        symbol: symbol,
        decimalDigits: 0,
      );
      return formatter.format(amount).replaceFirst(symbol, '$symbol ');
    }

    // Default formatting for other currencies
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
      decimalDigits: 2,
    );

    String formatted = formatter.format(amount);
    return formatted.replaceFirst(symbol, '$symbol ');
  }
}
