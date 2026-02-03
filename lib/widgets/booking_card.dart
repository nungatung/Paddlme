import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../core/theme/app_colors.dart';
import '../screens/equipment/equipment_detail_screen.dart';
import '../screens/reviews/leave_review_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../services/messaging_service.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;

  const BookingCard({
    super.key,
    required this. booking,
  });

  Color get _statusColor {
    switch (booking. status) {
      case BookingStatus.upcoming:
        return AppColors.primary;
      case BookingStatus. active:
        return AppColors.success;
      case BookingStatus. completed:
        return Colors.grey;
      case BookingStatus.cancelled:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:  [
          BoxShadow(
            color: Colors.black. withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Equipment Info
          InkWell(
            onTap: () {
              Navigator. push(
                context,
                MaterialPageRoute(
                  builder: (_) => EquipmentDetailScreen(equipment: booking.equipment),
                ),
              );
            },
            child:  Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image. network(
                      booking.equipment.imageUrls.first,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.kayaking,
                            size: 32,
                            color: Colors. grey[400],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          booking.equipment.title,
                          style: const TextStyle(
                            fontSize:  16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Location
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                booking.equipment.location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor. withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            booking.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors. grey[200]),

          // Booking Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Date & Time
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEE, MMM d, yyyy').format(booking.startDate),
                      style: const TextStyle(
                        fontSize:  14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height:  8),

                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${booking.startTime} - ${booking.endTime}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight. w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Delivery Option
                Row(
                  children: [
                    Icon(
                      booking.deliveryOption == 'pickup' 
                          ? Icons.directions_walk 
                          : Icons.local_shipping,
                      size:  16,
                      color:  Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.deliveryOption == 'pickup'
                            ? 'Pickup at ${booking.equipment.location}'
                            : 'Delivery to ${booking.deliveryAddress}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Price & Reference
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NZ\$${booking.totalPrice. toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize:  18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Ref: ${booking.bookingReference}',
                          style:  TextStyle(
                            fontSize:  11,
                            color: Colors. grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Action Buttons (only for upcoming bookings)
                if (booking.isUpcoming) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Contact Owner Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              final messagingService = MessagingService();
                              final conversationId = await messagingService.getOrCreateConversation(
                                otherUserId: booking.equipment.ownerId,
                                otherUserName: booking.equipment.ownerName,
                                otherUserAvatarUrl: booking.equipment.ownerImageUrl,
                                equipmentId: booking.equipment.id,
                                equipmentTitle: booking.equipment.title,
                                equipmentImageUrl: booking.equipment.imageUrls.isNotEmpty
                                    ? booking.equipment.imageUrls.first
                                    : null,
                              );

                              if (!context.mounted) return;

                              Navigator.pop(context);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    conversationId: conversationId,
                                    otherUserId: booking.equipment.ownerId,
                                    otherUserName: booking.equipment.ownerName,
                                    otherUserAvatarUrl: booking.equipment.ownerImageUrl,
                                    equipmentTitle: booking.equipment.title,
                                    equipmentImageUrl: booking.equipment.imageUrls.isNotEmpty
                                        ? booking.equipment.imageUrls.first
                                        : null,
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text(
                            'Contact Owner',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size(0, 48),
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _showCancelDialog(context);
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Leave Review Button (for completed bookings)
                if (booking.status == BookingStatus. completed) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton. icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeaveReviewScreen(booking: booking),
                          ),
                        );
                      },
                      icon: const Icon(Icons.star_outline),
                      label:  const Text('Leave a Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius:  BorderRadius.circular(16),
        ),
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking?  This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed:  () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:  Text('Booking cancelled successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }
}