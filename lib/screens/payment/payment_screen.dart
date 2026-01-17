import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../models/payment_method_model.dart';
import '../../widgets/payment_method_card.dart';
import '../booking/booking_summary_screen.dart';
import '../../models/equipment_model.dart';

class PaymentScreen extends StatefulWidget {
  final EquipmentModel equipment;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double totalHours;
  final double totalPrice;

  const PaymentScreen({
    super.key,
    required this.equipment,
    required this. startDate,
    required this. endDate,
    required this. startTime,
    required this. endTime,
    required this. totalHours,
    required this.totalPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Mock saved payment methods
  final List<PaymentMethod> _savedPaymentMethods = [
    PaymentMethod(
      id: '1',
      cardType: CardType.visa,
      last4: '4242',
      expiryMonth:  '12',
      expiryYear: '25',
      cardholderName:  'John Smith',
      isDefault: true,
    ),
    PaymentMethod(
      id: '2',
      cardType: CardType. mastercard,
      last4: '8888',
      expiryMonth:  '09',
      expiryYear:  '26',
      cardholderName:  'John Smith',
    ),
  ];

  String? _selectedPaymentMethodId;
  bool _showAddCardForm = false;

  // Add card form controllers
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cardholderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _saveCard = true;

  @override
  void initState() {
    super.initState();
    // Select default card
    final defaultCard = _savedPaymentMethods. firstWhere(
      (card) => card.isDefault,
      orElse: () => _savedPaymentMethods.first,
    );
    _selectedPaymentMethodId = defaultCard.id;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderNameController.dispose();
    _expiryDateController. dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _proceedToSummary() {
    if (_showAddCardForm) {
      if (! _formKey.currentState!. validate()) {
        return;
      }
      // TODO: Process new card
    } else if (_selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryScreen(
          equipment:  widget.equipment,
          startDate: widget.startDate,
          endDate: widget.endDate,
          startTime: widget.startTime,
          endTime: widget.endTime,
          totalHours: widget.totalHours,
          totalPrice: widget.totalPrice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment Method'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child:  Column(
                crossAxisAlignment:  CrossAxisAlignment.start,
                children: [
                  // Saved Payment Methods
                  if (! _showAddCardForm && _savedPaymentMethods.isNotEmpty) ...[
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saved Payment Methods',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ... (_savedPaymentMethods.map((method) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: PaymentMethodCard(
                                  paymentMethod: method,
                                  isSelected: _selectedPaymentMethodId == method.id,
                                  onTap: () {
                                    setState(() {
                                      _selectedPaymentMethodId = method.id;
                                      _showAddCardForm = false;
                                    });
                                  },
                                  onDelete: method.isDefault
                                      ? null
                                      : () {
                                          // TODO: Implement delete
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Delete payment method'),
                                            ),
                                          );
                                        },
                                ),
                              ))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Add New Card Button
                    Container(
                      color: Colors. white,
                      padding: const EdgeInsets.all(20),
                      child: OutlinedButton. icon(
                        onPressed:  () {
                          setState(() {
                            _showAddCardForm = true;
                            _selectedPaymentMethodId = null;
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Card'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(color: Colors.grey[300]! ),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],

                  // Add Card Form
                  if (_showAddCardForm) ...[
                    Container(
                      color: Colors. white,
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment:  CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Add New Card',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_savedPaymentMethods.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _showAddCardForm = false;
                                        _selectedPaymentMethodId =
                                            _savedPaymentMethods.first.id;
                                      });
                                    },
                                    child: const Text('Cancel'),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Card Number
                            const Text(
                              'Card Number',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _cardNumberController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(16),
                                _CardNumberFormatter(),
                              ],
                              decoration: InputDecoration(
                                hintText: '1234 5678 9012 3456',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide. none,
                                ),
                                prefixIcon: const Icon(Icons.credit_card),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter card number';
                                }
                                if (value.replaceAll(' ', '').length < 16) {
                                  return 'Card number must be 16 digits';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Cardholder Name
                            const Text(
                              'Cardholder Name',
                              style:  TextStyle(
                                fontSize:  14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller:  _cardholderNameController,
                              textCapitalization: TextCapitalization. words,
                              decoration: InputDecoration(
                                hintText: 'John Smith',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter cardholder name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Expiry & CVV
                            Row(
                              children: [
                                Expanded(
                                  child:  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Expiry Date',
                                        style: TextStyle(
                                          fontSize:  14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _expiryDateController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                          _ExpiryDateFormatter(),
                                        ],
                                        decoration: InputDecoration(
                                          hintText: 'MM/YY',
                                          filled: true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          if (value.length < 5) {
                                            return 'Invalid';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child:  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CVV',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _cvvController,
                                        keyboardType:  TextInputType.number,
                                        obscureText: true,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                        ],
                                        decoration: InputDecoration(
                                          hintText: '123',
                                          filled:  true,
                                          fillColor: Colors.grey[100],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Required';
                                          }
                                          if (value. length < 3) {
                                            return 'Invalid';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Save Card Checkbox
                            CheckboxListTile(
                              value: _saveCard,
                              onChanged: (value) {
                                setState(() {
                                  _saveCard = value ??  true;
                                });
                              },
                              title: const Text('Save card for future use'),
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Security Notice
                  Container(
                    color: Colors. blue[50],
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.lock_outline, color: Colors.blue[700], size: 24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:  CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Payment',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:  FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your payment information is encrypted and secure',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Continue Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius:  10,
                  offset:  const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _proceedToSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor:  Colors.white,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card Number Formatter (adds spaces)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text. replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Expiry Date Formatter (adds /)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}