import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/equipment_model.dart';
import '../widgets/equipment_card.dart';
import '../screens/equipment/equipment_detail_screen.dart';

class OwnerProfileBottomSheet extends StatelessWidget {
  final String ownerId;
  final String ownerName;
  final String?  ownerImageUrl;
  final String location;
  final String?  bio;
  final List<EquipmentModel> ownerListings;
  final List<OwnerReview> ownerReviews;
  final double rating;
  final int reviewCount;

  const OwnerProfileBottomSheet({
    super.key,
    required this. ownerId,
    required this.ownerName,
    this.ownerImageUrl,
    required this.location,
    this.bio,
    this.ownerListings = const [],
    this.ownerReviews = const [],
    this. rating = 0.0,
    this.reviewCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize:  0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Profile Header
              Column(
                children: [
                  // Profile Image
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius:  12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child:  CircleAvatar(
                      radius: 60,
                      backgroundImage: ownerImageUrl != null
                          ? NetworkImage(ownerImageUrl!)
                          : null,
                      backgroundColor: Colors.grey[200],
                      child: ownerImageUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Text(
                    ownerName,
                    style: const TextStyle(
                      fontSize:  26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize:  MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 16, color: AppColors.accent),
                        SizedBox(width: 6),
                        Text(
                          'LOCAL EXPERT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'From $location',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors. grey[700],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          icon: Icons.inventory_2_outlined,
                          label: 'Listings',
                          value: ownerListings. length. toString(),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        _buildStatItem(
                          icon: Icons. star,
                          label: 'Rating',
                          value: rating > 0 ? rating.toStringAsFixed(1) : 'New',
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors. grey[300],
                        ),
                        _buildStatItem(
                          icon: Icons.rate_review_outlined,
                          label: 'Reviews',
                          value:  reviewCount.toString(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bio Section
                  if (bio != null && bio! .isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bio',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            bio!,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors. grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Message feature coming soon!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 20),
                              label: const Text(
                                'Message',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors. primary,
                                  width:  2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Scroll to listings section
                                // (Already visible below)
                              },
                              icon: const Icon(Icons.grid_view, size: 20),
                              label: const Text(
                                'View Listings',
                                style:  TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),

              // ✅ Owner's Other Listings Section
              if (ownerListings.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child:  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${ownerListings.length} Listing${ownerListings.length != 1 ? 's' :  ''}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height:  280,
                  child: ListView. builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: ownerListings.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: EquipmentCard(
                          equipment: ownerListings[index],
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EquipmentDetailScreen(
                                  equipment: ownerListings[index],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // ✅ Owner Reviews Section
              if (ownerReviews.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets. symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.accent, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '${rating. toStringAsFixed(1)} • $reviewCount Review${reviewCount != 1 ?  's' : ''} about ${ownerName. split(' ').first}',
                        style: const TextStyle(
                          fontSize:  18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height:  16),
                ... ownerReviews.map((review) => _buildOwnerReviewCard(review)),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerReviewCard(OwnerReview review) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]! ),
      ),
      child: Column(
        crossAxisAlignment:  CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius:  20,
                backgroundImage: review.userAvatarUrl != null
                    ? NetworkImage(review.userAvatarUrl!)
                    :  null,
                backgroundColor: Colors. grey[300],
                child: review.userAvatarUrl == null
                    ? const Icon(Icons.person, size: 20, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ... List.generate(
                          5,
                          (index) => Icon(
                            index < review.rating. floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) return '${(difference / 7).floor()} weeks ago';
    if (difference < 365) return '${(difference / 30).floor()} months ago';
    return '${(difference / 365).floor()} years ago';
  }
}

// ✅ NEW:  Owner Review Model
class OwnerReview {
  final String userName;
  final String?  userAvatarUrl;
  final double rating;
  final String comment;
  final DateTime date;

  OwnerReview({
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });
}