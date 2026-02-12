import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../core/theme/app_colors.dart';
import '../main_navigation.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';

class LeaveReviewScreen extends StatefulWidget {
  final Booking booking;
  final bool isOwnerReview; // true if owner is reviewing renter, false if renter is reviewing owner/equipment

  const LeaveReviewScreen({
    super.key,
    required this.booking,
    this.isOwnerReview = false, // default to renter reviewing owner
  });

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  double _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authService = AuthService();
      final currentUser = authService.currentUser!;
      
      // Determine who is being reviewed
      final reviewedId = widget.isOwnerReview
          ? widget.booking.renterId    // Owner reviews renter
          : widget.booking.ownerId;     // Renter reviews owner
      
      final reviewerType = widget.isOwnerReview ? 'owner' : 'renter';

      await BookingService().submitReview(
        bookingId: widget.booking.id,
        reviewerId: currentUser.uid,
        reviewedId: reviewedId,
        reviewerType: reviewerType,
        rating: _rating,
        comment: _commentController.text,
      );

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Review Posted!'),
              ),
            ],
          ),
          content: Text(
            widget.isOwnerReview
                ? 'Thank you for reviewing this renter! Your feedback helps other owners make informed decisions.'
                : 'Thank you for your feedback! Your review helps other renters make informed decisions.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                );
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting review: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine who is being reviewed
    final reviewedName = widget.isOwnerReview 
        ? widget.booking.renterName  // Owner reviews renter
        : widget.booking.ownerName;   // Renter reviews owner
    
    final reviewedImage = widget.isOwnerReview
        ? null // You might want to add renter image to booking model
        : widget.booking.equipmentImageUrl;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Leave a Review'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ FIXED: Who is being reviewed Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: reviewedImage != null && reviewedImage.isNotEmpty
                              ? Image.network(
                                  reviewedImage,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderAvatar();
                                  },
                                )
                              : _buildPlaceholderAvatar(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isOwnerReview 
                                    ? 'Renter: $reviewedName'
                                    : 'Owner: $reviewedName',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (!widget.isOwnerReview) ...[
                                Text(
                                  widget.booking.equipmentTitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ] else ...[
                                Text(
                                  'Booking completed',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ✅ FIXED: Rating Section with Responsive Stars
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.isOwnerReview
                              ? 'How was this renter?'
                              : 'How was your experience?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final starSize = (availableWidth / 7).clamp(32.0, 48.0);
                            final spacing = (availableWidth / 35).clamp(4.0, 8.0);

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rating = index + 1.0;
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: spacing),
                                    child: Icon(
                                      index < _rating ? Icons.star : Icons.star_border,
                                      size: starSize,
                                      color: index < _rating
                                          ? AppColors.accent
                                          : Colors.grey[400],
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_rating > 0)
                          Text(
                            _getRatingText(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Comment Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share your experience',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isOwnerReview
                              ? 'Let others know about this renter'
                              : 'Let others know what you thought',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _commentController,
                          maxLines: 6,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: widget.isOwnerReview
                                ? 'The renter was respectful and returned the equipment on time...'
                                : 'The equipment was in great condition and the owner was very helpful...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Submit Button
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
            child: SafeArea(
              child: Center(
                child: SizedBox(
                  width: 240,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Review',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.person,
        color: AppColors.primary,
        size: 32,
      ),
    );
  }

  String _getRatingText() {
    if (_rating == 5) return 'Excellent! ⭐';
    if (_rating == 4) return 'Great! 👍';
    if (_rating == 3) return 'Good 👌';
    if (_rating == 2) return 'Fair 😐';
    return 'Poor 👎';
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue[800])),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}