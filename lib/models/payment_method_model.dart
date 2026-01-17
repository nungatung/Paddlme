enum CardType {
  visa,
  mastercard,
  amex,
  discover,
}

class PaymentMethod {
  final String id;
  final CardType cardType;
  final String last4;
  final String expiryMonth;
  final String expiryYear;
  final String cardholderName;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.cardType,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cardholderName,
    this.isDefault = false,
  });

  String get cardTypeString {
    switch (cardType) {
      case CardType.visa:
        return 'Visa';
      case CardType.mastercard:
        return 'Mastercard';
      case CardType. amex:
        return 'American Express';
      case CardType.discover:
        return 'Discover';
    }
  }

  String get maskedNumber {
    return '**** **** **** $last4';
  }

  String get expiryDate {
    return '$expiryMonth/$expiryYear';
  }
}