import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import 'package:wave_share/services/booking_service.dart';
import '../models/booking_model.dart';
import '../core/theme/app_colors.dart';
import '../screens/equipment/equipment_detail_screen.dart';
import '../screens/reviews/leave_review_screen.dart';
import '../screens/messages/chat_screen.dart';
import '../services/messaging_service.dart';
import '../../services/equipment_service.dart';


class BookingCard extends StatelessWidget {
  final Booking booking;

  const BookingCard({
    super.key,
    required this.booking,
  });

  Color get _statusColor {
    switch (booking.status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.active:
        return AppColors.success;
      case BookingStatus.completed:
        return Colors.grey;
      case BookingStatus.cancelled:
      case BookingStatus.declined:
        return AppColors.error;
      case BookingStatus.closed:
        return AppColors.success;
    }
  }

  String get statusText {
  switch (status) {
    case BookingStatus.pending:
      return 'Pending Approval';
    case BookingStatus.confirmed:
      return 'Confirmed';
    case BookingStatus.active:
      return 'Active';
    case BookingStatus.completed:
      return 'Awaiting Review';
    case BookingStatus.cancelled:
      return 'Cancelled';
    case BookingStatus.declined:
      return 'Declined';
    default:
      return 'Unknown';
  }
}

  get status => null;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:  [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Equipment Info
          InkWell(
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              
              try {
                final equipmentService = EquipmentService();
                final equipment = await equipmentService.getEquipmentById(booking.equipmentId);
                
                if (!context.mounted) return;
                Navigator.pop(context);
                
                if (equipment != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EquipmentDetailScreen(equipment: equipment, equipmentId: '',),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error loading equipment: $e')),
                  );
                }
              }
            },
            child:  Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image. network(
                      booking.equipmentImageUrl,
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
                          booking.equipmentTitle,
                          style: const TextStyle(
                            fontSize:  16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                  

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
                      DateFormat('EEE, d MMM , yyyy').format(booking.startDate),
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
                            ? 'Pickup at ${booking.deliveryAddress}'
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
                if (booking.isPending || booking.isConfirmed) ...[
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
                                otherUserId: booking.ownerId,
                                otherUserName: booking.ownerName,
                                otherUserAvatarUrl: null,
                                equipmentId: booking.equipmentId,
                                equipmentTitle: booking.equipmentTitle,
                                equipmentImageUrl: booking.equipmentImageUrl.isNotEmpty
                                    ? booking.equipmentImageUrl.first
                                    : null,
                              );

                              if (!context.mounted) return;

                              Navigator.pop(context);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    conversationId: conversationId,
                                    otherUserId: booking.ownerId,
                                    otherUserName: booking.ownerName,
                                    otherUserAvatarUrl: null,
                                    equipmentTitle: booking.equipmentTitle,
                                    equipmentImageUrl: booking.equipmentImageUrl.isNotEmpty
                                        ? booking.equipmentImageUrl.first
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
                            'Message',
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced padding
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
                              height: 1.0,
                            ),
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Show review status or button for completed bookings
                if (booking.status == BookingStatus.completed) ...[
                  const SizedBox(height: 16),
                  
                  // Get current user ID synchronously
                  Builder(
                    builder: (context) {
                      final currentUser = AuthService().currentUser;
                      if (currentUser == null) return const SizedBox.shrink();
                      
                      final currentUserId = currentUser.uid;
                      final isRenter = currentUserId == booking.renterId;
                      final hasReviewed = isRenter ? booking.renterReviewed : booking.ownerReviewed;
                      
                      if (hasReviewed) {
                        // Show "Review Submitted" badge
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Review Submitted',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Show "Leave Review" button
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LeaveReviewScreen(booking: booking, isOwnerReview: false,),
                                ),
                              );
                            },
                            icon: const Icon(Icons.star_outline),
                            label: const Text('Leave a Review'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      }
                    },
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
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('Cancel Booking?'),
      content: const Text(
        'Are you sure you want to cancel this booking? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Booking'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
            
            try {
              // ACTUALLY CANCEL THE BOOKING
              await BookingService().cancelBooking(booking.id);
              
              if (!context.mounted) return;
              Navigator.pop(context); // Close loading
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              Navigator.pop(context); // Close loading
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error cancelling booking: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Cancel Booking'),
        ),
      ],
    ),
  );
}
}

extension on String {
  get first => null;
}
