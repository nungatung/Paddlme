import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/equipment_model.dart';
import '../../core/theme/app_colors.dart';
import 'booking_confirmation_screen.dart';
import '../../models/booking_model.dart'; 
import '../../services/auth_service.dart'; 
import '../../services/booking_service.dart';


class BookingSummaryScreen extends StatefulWidget {
  final EquipmentModel equipment;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double totalHours;
  final double totalPrice;

  const BookingSummaryScreen({
    super. key,
    required this.equipment,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.totalHours,
    required this.totalPrice,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  String _deliveryOption = 'pickup'; // 'pickup' or 'delivery'
  String _deliveryAddress = '';
  bool _agreeToTerms = false;
  bool _isProcessing = false;

  double get _deliveryFee => _deliveryOption == 'delivery' ?  15.0 : 0.0;
  double get _serviceFee => widget.totalPrice * 0.1; // 10% service fee
  double get _grandTotal => widget.totalPrice + _deliveryFee + _serviceFee;

  void _processBooking() async {
  if (_deliveryOption == 'delivery' && _deliveryAddress.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter a delivery address'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  if (!_agreeToTerms) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please agree to the rental terms'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  setState(() {
    _isProcessing = true;
  });

  try {
    final authService = AuthService();
    final currentUser = authService.currentUser!;
    
    // Create booking object
    final booking = Booking(
      id: '', // Will be set by Firestore
      equipmentId: widget.equipment.id,
      equipmentTitle: widget.equipment.title,
      equipmentImageUrl: widget.equipment.imageUrls.isNotEmpty 
          ? widget.equipment.imageUrls.first 
          : '',
      ownerId: widget.equipment.ownerId,
      ownerName: widget.equipment.ownerName,
      renterId: currentUser.uid,
      renterName: currentUser.displayName ?? 'Unknown',
      startDate: widget.startDate,
      endDate: widget.endDate,
      startTime: widget.startTime.format(context),
      endTime: widget.endTime.format(context),
      totalPrice: _grandTotal,
      status: BookingStatus.pending, // Start as pending
      deliveryOption: _deliveryOption,
      deliveryAddress: _deliveryOption == 'delivery' ? _deliveryAddress : null,
      bookingReference: 'WS${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      bookingDate: DateTime.now(),
    );

    // Save to Firestore
    final bookingService = BookingService();
    final bookingId = await bookingService.createBooking(booking);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(
            equipment: widget.equipment,
            startDate: widget.startDate,
            endDate: widget.endDate,
            startTime: widget.startTime,
            endTime: widget.endTime,
            totalPrice: _grandTotal,
            deliveryOption: _deliveryOption,
            deliveryAddress: _deliveryAddress,
            bookingReference: booking.bookingReference,
            status: BookingStatus.pending, // Pass status to show "Pending Approval"
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating booking: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Booking Summary'),
        backgroundColor: Colors.white,
        foregroundColor: Colors. black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Equipment Info
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child:  Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.equipment.imageUrls.first,
                            width: 80,
                            height:  80,
                            fit:  BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width:  16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.equipment.title,
                                style: const TextStyle(
                                  fontSize:  16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height:  4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child:  Text(
                                      widget. equipment.location,
                                      style: TextStyle(
                                        fontSize:  13,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Booking Details
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:  FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Date',
                          widget.startDate == widget.endDate
                              ? DateFormat('MMM d, yyyy').format(widget.startDate)
                              : '${DateFormat('MMM d').format(widget.startDate)} - ${DateFormat('MMM d, yyyy').format(widget.endDate)}',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.access_time,
                          'Time',
                          '${widget.startTime.format(context)} - ${widget.endTime.format(context)}',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.schedule,
                          'Duration',
                          '${widget. totalHours.toStringAsFixed(1)} hours',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Delivery Options
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets. all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Option',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDeliveryOption(
                          'pickup',
                          'Pickup',
                          'Pick up at ${widget.equipment.location}',
                          Icons.directions_walk,
                          'Free',
                        ),
                        const SizedBox(height: 12),
                        _buildDeliveryOption(
                          'delivery',
                          'Delivery',
                          'We\'ll deliver to your location',
                          Icons.local_shipping,
                          'NZ\$15.00',
                        ),
                        if (_deliveryOption == 'delivery') ...[
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (value) => setState(() => _deliveryAddress = value),
                            decoration: InputDecoration(
                              labelText:  'Delivery Address',
                              hintText: 'Enter your address',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide. none,
                              ),
                              prefixIcon: const Icon(Icons.home),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Price Breakdown
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPriceRow(
                          'Equipment rental (${widget.totalHours.toStringAsFixed(1)}h)',
                          widget.totalPrice,
                        ),
                        _buildPriceRow('Service fee (10%)', _serviceFee),
                        if (_deliveryFee > 0) _buildPriceRow('Delivery fee', _deliveryFee),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'NZ\$${_grandTotal.toStringAsFixed(2)}',
                              style:  const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Terms & Conditions
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() {
                              _agreeToTerms = value ??  false;
                            });
                          },
                          activeColor: AppColors.primary,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _agreeToTerms = !_agreeToTerms;
                              });
                            },
                            child:  Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text:  TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    height: 1.4,
                                  ),
                                  children: const [
                                    TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Rental Terms & Conditions',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Cancellation Policy',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

          // Bottom Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child:  SafeArea(
              child:  SizedBox(
                width:  double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor:  Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width:  24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm & Pay',
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryOption(
    String value,
    String title,
    String subtitle,
    IconData icon,
    String price,
  ) {
    final isSelected = _deliveryOption == value;

    return InkWell(
      onTap: () {
        setState(() {
          _deliveryOption = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primary. withOpacity(0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.grey[600],
            ),
            const SizedBox(width: 16),
            Expanded(
              child:  Column(
                crossAxisAlignment:  CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:  FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style:  TextStyle(
                      fontSize: 13,
                      color: Colors. grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
          Text(
            'NZ\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}