import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../../models/equipment_model.dart';
import '../../core/theme/app_colors.dart';
import '../main_navigation.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final EquipmentModel equipment;
  final DateTime startDate;
  final DateTime endDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final double totalPrice;
  final String deliveryOption;
  final String deliveryAddress;

  const BookingConfirmationScreen({
    super.key,
    required this.equipment,
    required this. startDate,
    required this. endDate,
    required this. startTime,
    required this. endTime,
    required this. totalPrice,
    required this. deliveryOption,
    required this.deliveryAddress,
  });

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  late ConfettiController _confettiController;
  final String _bookingReference = 'WS${DateTime.now().millisecondsSinceEpoch. toString().substring(7)}';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // Success Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color:  AppColors.success. withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppColors.success,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  const Text(
                    'Booking Confirmed! ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Your rental is all set.  We\'ve sent a confirmation to your email.',
                    style: TextStyle(
                      fontSize:  16,
                      color:  Colors.grey[600],
                    ),
                    textAlign:  TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // Booking Reference
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary. withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary. withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Booking Reference',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bookingReference,
                          style: const TextStyle(
                            fontSize:  24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Equipment Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border. all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment. start,
                      children: [
                        // Equipment Info
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image. network(
                                widget.equipment.imageUrls.first,
                                width: 80,
                                height: 80,
                                fit: BoxFit. cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.equipment.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight:  FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.equipment.location,
                                    style: TextStyle(
                                      fontSize:  14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 32),

                        // Date & Time
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Date',
                          widget. startDate == widget.endDate
                              ? DateFormat('EEEE, MMM d, yyyy').format(widget.startDate)
                              : '${DateFormat('MMM d').format(widget.startDate)} - ${DateFormat('MMM d, yyyy').format(widget.endDate)}',
                        ),
                        const SizedBox(height:  16),
                        _buildInfoRow(
                          Icons.access_time,
                          'Time',
                          '${widget.startTime.format(context)} - ${widget.endTime.format(context)}',
                        ),
                        const SizedBox(height:  16),
                        _buildInfoRow(
                          widget.deliveryOption == 'pickup' ? Icons.directions_walk : Icons.local_shipping,
                          widget.deliveryOption == 'pickup' ? 'Pickup' :  'Delivery',
                          widget.deliveryOption == 'pickup'
                              ? widget.equipment.location
                              : widget. deliveryAddress,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.payments,
                          'Total Paid',
                          'NZ\$${widget.totalPrice.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Owner Contact Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration:  BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next Steps',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.equipment.ownerName} will contact you 24 hours before your rental.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainNavigation()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor:  Colors.white,
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width:  double.infinity,
                    height: 56,
                    child: OutlinedButton. icon(
                      onPressed:  () {
                        // TODO: Navigate to bookings screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('My Bookings screen coming soon!')),
                        );
                      },
                      icon:  const Icon(Icons.calendar_today),
                      label:  const Text(
                        'View My Bookings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment. topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              colors: const [
                AppColors.primary,
                AppColors.accent,
                AppColors.success,
                Colors.blue,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
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
        ),
      ],
    );
  }
}