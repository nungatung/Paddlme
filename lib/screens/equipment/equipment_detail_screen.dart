import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/equipment_model.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/image_carousel.dart';
import '../../widgets/review_card.dart';
import '../../widgets/equipment_card.dart';
import '../booking/date_selection_screen.dart';
import '../../services/auth_service.dart';
import '../equipment/edit_equipment_screen.dart';
import '../../services/favourites_service.dart';

class EquipmentDetailScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const EquipmentDetailScreen({
    super.key,
    required this. equipment,
  });

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  final _authService = AuthService();
  final _favoritesService = FavoritesService();

  // Mock reviews
  List<Review> _getReviews() {
    return [
      Review(
        userName: 'Mike Chen',
        userAvatarUrl: 'https://i.pravatar.cc/150?  img=12',
        rating: 5.0,
        comment: 'Awesome kayak! Very stable and comfortable. Sarah was super helpful with instructions. Highly recommend!',
        date: DateTime.  now().subtract(const Duration(days: 14)),
      ),
      Review(
        userName: 'Emma Wilson',
        userAvatarUrl: 'https://i.pravatar.cc/150? img=5',
        rating: 5.0,
        comment: 'Perfect for beginners. Had a great time exploring the bay. Equipment was in excellent condition.',
        date: DateTime. now().subtract(const Duration(days: 21)),
      ),
      Review(
        userName: 'Jake Roberts',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
        rating: 4.5,
        comment: 'Great experience overall. The kayak was exactly as described. Would rent again!',
        date: DateTime. now().subtract(const Duration(days: 35)),
      ),
    ];
  }


  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
  }

  Future<void> _checkIfFavorited() async {
    final user = _authService.currentUser;
    
    if (user == null) {
      setState(() => _isLoadingFavorite = false);
      return;
    }

    try {
      final isFavorited = await _favoritesService.isFavorited(
        user.uid,
        widget.equipment.id,
      );
      
      if (mounted) {
        setState(() {
          _isFavorite = isFavorited;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Scrollable Content
          CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor:   Colors.white,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius:   8,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  if (_authService.currentUser?. uid == widget.equipment. ownerId)
                    Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:  Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black87),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditEquipmentScreen(equipment: widget.equipment),
                            ),
                          );
                          
                          if (result == true && mounted) {
                            // Refresh or go back
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  
                  // Share button
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons. share, color: Colors.black87),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share functionality coming soon!')),
                        );
                      },
                    ),
                  ),
                  
                  // Favorite button
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:  Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: _isLoadingFavorite
                        ?  const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.black87,
                            ),
                            onPressed: () async {
                              final user = _authService.currentUser;
                              
                              if (user == null) {
                                // Show login prompt
                                ScaffoldMessenger. of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please login to save favorites'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              // Optimistic update
                              setState(() {
                                _isFavorite = !_isFavorite;
                              });

                              try {
                                final newStatus = await _favoritesService. toggleFavorite(
                                  user.uid,
                                  widget.equipment.id,
                                  ! _isFavorite,  // Pass previous state
                                );

                                if (mounted) {
                                  setState(() {
                                    _isFavorite = newStatus;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        newStatus 
                                            ? '❤️ Added to favorites' 
                                            : 'Removed from favorites',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );

                                  // Return true to signal favorite was changed
                                  Navigator.pop(context, true);
                                }
                              } catch (e) {
                                // Revert on error
                                if (mounted) {
                                  setState(() {
                                    _isFavorite = !_isFavorite;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error:  $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ImageCarousel(
                    imageUrls: widget.equipment.imageUrls,
                    height: 300,
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Basic Info
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment:   CrossAxisAlignment.start,
                        children: [
                          // Title & Verified Badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.equipment.title,
                                  style: TextStyle(
                                    fontSize:   isTablet ? 28 : 24,
                                    fontWeight:  FontWeight.bold,
                                  ),
                                ),
                              ),
                              // ✅ Removed isVerified check - doesn't exist in model
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Rating & Type
                          Row(
                            children: [
                              if (widget.equipment.reviewCount > 0) ...[
                                const Icon(Icons.star, size: 20, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.equipment.displayRating} (${widget.equipment.reviewCount} reviews)',  // ✅ Fixed
                                  style:   const TextStyle(
                                    fontSize: 15,
                                    fontWeight:   FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('•', style: TextStyle(color: Colors.grey[400])),
                                const SizedBox(width: 12),
                              ],
                              Text(
                                '${widget.equipment.category. icon} ${widget.equipment.category. displayName}',  // ✅ Fixed
                                style:  TextStyle(
                                  fontSize:   15,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Location
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.equipment.location,
                                  style: TextStyle(
                                    fontSize:  15,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Owner Info
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.  all(20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: widget.equipment.ownerImageUrl != null  // ✅ Fixed
                                ? NetworkImage(widget.equipment.ownerImageUrl!)
                                : null,
                            backgroundColor: Colors.grey[200],
                            child: widget.equipment.ownerImageUrl == null
                                ? const Icon(Icons. person, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:  CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hosted by',
                                  style:   TextStyle(
                                    fontSize:  12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.equipment.ownerName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight:   FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              // TODO: Navigate to owner profile
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Owner profile coming soon!')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text('View Profile'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Description
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.  all(20),
                      child: Column(
                        crossAxisAlignment:  CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style:  TextStyle(
                              fontSize:  18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height:  12),
                          Text(
                            widget.equipment.description,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.  grey[700],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // What's Included
                    if (widget.equipment.features.isNotEmpty)  // ✅ Fixed
                      Container(
                        color:  Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:  CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "What's Included",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ... widget.equipment.features.map((feature) => _buildIncludedItem(feature)),  // ✅ Fixed
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Reviews Section
                    if (widget.equipment.reviewCount > 0)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.  all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 24, color: AppColors.accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${widget.equipment.displayRating} • ${widget.equipment.reviewCount} reviews',  // ✅ Fixed
                                      style:   const TextStyle(
                                        fontSize: 18,
                                        fontWeight:   FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    // TODO: Show all reviews
                                  },
                                  child: const Text('See all'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._getReviews().take(2).map((review) => ReviewCard(review:   review)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // ✅ NEW: Delivery Options
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Options',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height:  16),
                          
                          // Pickup option
                          if (widget.equipment.requiresPickup)
                            _buildDeliveryOption(
                              Icons.store,
                              'Pickup Available',
                              'Collect from ${widget.equipment.location}',
                              Colors.blue,
                            ),
                          
                          if (widget.equipment.requiresPickup && widget.equipment.offersDelivery)
                            const SizedBox(height: 12),
                          
                          // Delivery option
                          if (widget.equipment.offersDelivery)
                            _buildDeliveryOption(
                              Icons.local_shipping,
                              'Delivery Available',
                              widget.equipment.deliveryFeeText ??  'Contact owner for delivery',
                              Colors.green,
                            ),
                          
                          if (widget.equipment.offersDelivery && widget.equipment.deliveryRadius != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 40),
                              child: Text(
                                'Within ${widget.equipment.deliveryRadius! .toStringAsFixed(0)}km radius',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Bottom spacing for sticky button
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // Sticky Bottom Bar with Price & Book Button
          Positioned(
            bottom:  0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets. all(isTablet ? 24 : 16),
              decoration: BoxDecoration(
                color: Colors.  white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius:   10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Price
                    Column(
                      crossAxisAlignment:   CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text:  TextSpan(
                            children:  [
                              TextSpan(
                                text: widget.equipment.pricePerHourText,  // ✅ Fixed
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight:  FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Book Now Button
                    Expanded(
                      child: SizedBox(
                        height:   56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DateSelectionScreen(
                                  equipment: widget.equipment,
                                ),
                              ),
                            );
                          },
                          style:  ElevatedButton.styleFrom(
                            backgroundColor: AppColors. accent,
                            foregroundColor:   Colors.white,
                            elevation: 0,
                          ),
                          child: const Text(
                            'Book Now',
                            style:  TextStyle(
                              fontSize: 18,
                              fontWeight:  FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludedItem(String item) {
    return Padding(
      padding: const EdgeInsets. only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors. success. withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: AppColors. success,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item,
            style:  TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDeliveryOption(IconData icon, String title, String subtitle, Color color) {
  return Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color. withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      Icon(Icons.check_circle, color: color, size: 20),
    ],
  );
}
}