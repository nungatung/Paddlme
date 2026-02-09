import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/auth_service.dart';
import '../../services/booking_service.dart';
import '../../core/theme/app_colors.dart';

class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final bookingService = BookingService();
    final currentUser = authService.currentUser!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Bookings'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'All Bookings'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
          ),
        ),
        body: TabBarView(
          children: [
            // Pending Bookings
            _PendingBookingsList(
              bookingService: bookingService,
              ownerId: currentUser.uid,
            ),
            // All Bookings
            _AllBookingsList(
              bookingService: bookingService,
              ownerId: currentUser.uid,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingBookingsList extends StatelessWidget {
  final BookingService bookingService;
  final String ownerId;

  const _PendingBookingsList({
    required this.bookingService,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: bookingService.getPendingBookings(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No pending requests',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _PendingBookingCard(
              booking: booking,
              onAccept: () => _acceptBooking(context, booking),
              onDecline: () => _declineBooking(context, booking),
            );
          },
        );
      },
    );
  }

  void _acceptBooking(BuildContext context, Booking booking) async {
    try {
      await bookingService.confirmBooking(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _declineBooking(BuildContext context, Booking booking) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for declining:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'Not available'),
            child: const Text('Decline'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );

    if (reason != null) {
      try {
        await bookingService.declineBooking(booking.id, reason);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking declined')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _PendingBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _PendingBookingCard({
    required this.booking,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Renter info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.renterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Wants to rent ${booking.equipmentTitle}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const Divider(height: 24),
            
            // Booking details
            _buildInfoRow(Icons.calendar_today, 'Date', 
                '${booking.startDate.day}/${booking.startDate.month}/${booking.startDate.year}'),
            _buildInfoRow(Icons.access_time, 'Time', '${booking.startTime} - ${booking.endTime}'),
            _buildInfoRow(Icons.attach_money, 'Total', 'NZ\$${booking.totalPrice.toStringAsFixed(2)}'),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AllBookingsList extends StatelessWidget {
  final BookingService bookingService;
  final String ownerId;

  const _AllBookingsList({
    required this.bookingService,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Booking>>(
      stream: bookingService.getOwnerBookings(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const Center(child: Text('No bookings yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  booking.equipmentImageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(booking.renterName),
              subtitle: Text('${booking.equipmentTitle} • ${booking.statusText}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.statusText,
                  style: TextStyle(
                    color: booking.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}