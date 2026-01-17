import 'package:flutter/material.dart';
import '../models/payment_method_model.dart';
import '../core/theme/app_colors.dart';

class PaymentMethodCard extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const PaymentMethodCard({
    super.key,
    required this. paymentMethod,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  });

  IconData get _cardIcon {
    switch (paymentMethod.cardType) {
      case CardType.visa:
        return Icons.credit_card;
      case CardType.mastercard:
        return Icons.credit_card;
      case CardType.amex:
        return Icons.credit_card;
      case CardType.discover:
        return Icons.credit_card;
    }
  }

  Color get _cardColor {
    switch (paymentMethod.cardType) {
      case CardType.visa:
        return Colors.blue[700]!;
      case CardType. mastercard:
        return Colors. orange[700]!;
      case CardType.amex:
        return Colors.green[700]! ;
      case CardType.discover:
        return Colors.purple[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppColors.primary. withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            // Card Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardColor. withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:  Icon(
                _cardIcon,
                color: _cardColor,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Card Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        paymentMethod. cardTypeString,
                        style: const TextStyle(
                          fontSize:  16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (paymentMethod.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success. withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paymentMethod.maskedNumber,
                    style:  TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expires ${paymentMethod.expiryDate}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors. grey[500],
                    ),
                  ),
                ],
              ),
            ),

            // Selection Indicator or Delete
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              )
            else if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}