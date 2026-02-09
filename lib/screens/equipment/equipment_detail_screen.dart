import 'package:flutter/material.dart';
import '../../models/equipment_model.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/image_carousel.dart';
import '../../widgets/review_card.dart';
import '../booking/date_selection_screen.dart';
import '../../services/auth_service.dart';
import '../equipment/edit_equipment_screen.dart';
import '../../services/favourites_service.dart';
import '../../widgets/owner_profile_bottom_sheet.dart';
import '../../services/equipment_service.dart';
import '../messages/chat_screen.dart'; 
import '../../services/messaging_service.dart'; 

class EquipmentDetailScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const EquipmentDetailScreen({
    super.key,
    required this.equipment, required String equipmentId,
  });

  @override
  State<EquipmentDetailScreen> createState() => _EquipmentDetailScreenState();
}

class _EquipmentDetailScreenState extends State<EquipmentDetailScreen> {
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;
  final _authService = AuthService();
  final _favoritesService = FavoritesService();
  final _equipmentService = EquipmentService();
  final _messagingService = MessagingService();

  // New
  final ScrollController _scrollController = ScrollController();
  bool _showBottomBar = true;
  double _lastScrollPosition = 0;

  // Mock reviews
  List<Review> _getReviews() {
    return [
      Review(
        userName: 'Mike Chen',
        userAvatarUrl: 'https://i.pravatar.cc/150? img=12',
        rating: 5.0,
        comment:
            'Awesome kayak!  Very stable and comfortable.  Sarah was super helpful with instructions.  Highly recommend!',
        date: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Review(
        userName: 'Emma Wilson',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=5',
        rating: 5.0,
        comment:
            'Perfect for beginners.  Had a great time exploring the bay. Equipment was in excellent condition.',
        date: DateTime.now().subtract(const Duration(days: 21)),
      ),
      Review(
        userName: 'Jake Roberts',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=8',
        rating: 4.5,
        comment:
            'Great experience overall. The kayak was exactly as described. Would rent again!',
        date: DateTime.now().subtract(const Duration(days: 35)),
      ),
    ];
  }

  // ✅ ADD:  Mock owner listings
  List<EquipmentModel> _getOwnerListings() {
    // Filter all equipment by this owner
    // For now, return mock data
    return [
      // You'll replace this with actual Firestore query
    ];
  }

  // ✅ ADD: Mock owner reviews
  List<OwnerReview> _getOwnerReviews() {
    return [
      OwnerReview(
        userName: 'Jessica Lee',
        userAvatarUrl: 'https://i.pravatar.cc/150? img=1',
        rating: 5.0,
        comment:
            '${widget.equipment.ownerName} is an amazing host!  Very responsive and the equipment was exactly as described.  Highly recommend renting from them!',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      OwnerReview(
        userName: 'Tom Wilson',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=3',
        rating: 5.0,
        comment:
            'Great communication and flexible with pickup times. Equipment was clean and well-maintained.  Will definitely rent again!',
        date: DateTime.now().subtract(const Duration(days: 18)),
      ),
      OwnerReview(
        userName: 'Sarah Chen',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=9',
        rating: 4.5,
        comment:
            'Very professional and helpful.  Gave us great tips on where to go.  The gear was top quality!',
        date: DateTime.now().subtract(const Duration(days: 32)),
      ),
    ];
  }

  // ✅ ADD THIS METHOD
  Future<void> _contactOwner() async {
    final user = _authService.currentUser;
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to contact the owner'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Don't allow messaging yourself
    if (user.uid == widget.equipment.ownerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot message yourself'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get or create conversation
      final conversationId = await _messagingService.getOrCreateConversation(
        otherUserId: widget.equipment.ownerId,
        otherUserName: widget.equipment.ownerName,
        otherUserAvatarUrl: widget.equipment.ownerImageUrl,
        equipmentId: widget.equipment.id,
        equipmentTitle: widget.equipment.title,
        equipmentImageUrl: widget.equipment.imageUrls.isNotEmpty
            ? widget.equipment.imageUrls.first
            : null,
      );

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to chat
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUserId: widget.equipment.ownerId,
            otherUserName: widget.equipment.ownerName,
            otherUserAvatarUrl: widget.equipment.ownerImageUrl,
            equipmentTitle: widget.equipment.title,
            equipmentImageUrl: widget.equipment.imageUrls.isNotEmpty
                ? widget.equipment.imageUrls.first
                : null,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
    // ✅ ADD THIS:
    _scrollController.addListener(_onScroll);
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

  // ✅ ADD THIS METHOD:
  void _onScroll() {
    final currentScroll = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // Show bottom bar if:
    // 1. Scrolling up
    // 2. At the top
    // 3. Near the bottom (last 100px)
    final shouldShow = currentScroll < _lastScrollPosition || // Scrolling up
        currentScroll <= 50 || // At top
        currentScroll >= maxScroll - 100; // Near bottom

    if (shouldShow != _showBottomBar) {
      setState(() {
        _showBottomBar = shouldShow;
      });
    }

    _lastScrollPosition = currentScroll;
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ✅ ADD THIS
    super.dispose();
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
            controller: _scrollController,
            slivers: [
              // ✅ UPDATED:  Taller App Bar with Better Image Display
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height *
                    0.45, // ✅ 45% of screen height
                pinned: true,
                backgroundColor: Colors.white,
                leading: Container(
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
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  if (_authService.currentUser?.uid == widget.equipment.ownerId)
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
                        icon: const Icon(Icons.edit, color: Colors.black87),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditEquipmentScreen(
                                  equipment: widget.equipment),
                            ),
                          );

                          if (result == true && mounted) {
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
                      icon: const Icon(Icons.share, color: Colors.black87),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Share functionality coming soon!')),
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
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: _isLoadingFavorite
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.black87,
                            ),
                            onPressed: () async {
                              final user = _authService.currentUser;

                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please login to save favorites'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _isFavorite = !_isFavorite;
                              });

                              try {
                                final newStatus =
                                    await _favoritesService.toggleFavorite(
                                  user.uid,
                                  widget.equipment.id,
                                  !_isFavorite,
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

                                  Navigator.pop(context, true);
                                }
                              } catch (e) {
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
                    height: MediaQuery.of(context).size.height *
                        0.45, // ✅ Match expanded height
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.equipment.title,
                            style: TextStyle(
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Rating & Type
                          Row(
                            children: [
                              if (widget.equipment.reviewCount > 0) ...[
                                const Icon(Icons.star,
                                    size: 20, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.equipment.displayRating} (${widget.equipment.reviewCount} reviews)',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('•',
                                    style: TextStyle(color: Colors.grey[400])),
                                const SizedBox(width: 12),
                              ],
                              Text(
                                '${widget.equipment.category.icon} ${widget.equipment.category.displayName}',
                                style: TextStyle(
                                  fontSize: 15,
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
                              const Icon(Icons.location_on,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.equipment.location,
                                  style: TextStyle(
                                    fontSize: 15,
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: widget.equipment.ownerImageUrl != null
                                    ? NetworkImage(widget.equipment.ownerImageUrl!)
                                    : null,
                                backgroundColor: Colors.grey[200],
                                child: widget.equipment.ownerImageUrl == null
                                    ? const Icon(Icons.person, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hosted by',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.equipment.ownerName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // ✅ BUTTONS ROW (only if not owner)
                          if (_authService.currentUser?.uid != widget.equipment.ownerId) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Message Button
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      onPressed: _contactOwner,
                                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                      label: const Text(
                                        'Message',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppColors.primary, width: 2),
                                        foregroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced padding
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // View Profile Button
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final ownerListings = await _equipmentService
                                            .getEquipmentByOwner(widget.equipment.ownerId);

                                        if (!mounted) return;

                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => OwnerProfileBottomSheet(
                                            ownerId: widget.equipment.ownerId,
                                            ownerName: widget.equipment.ownerName,
                                            ownerImageUrl: widget.equipment.ownerImageUrl,
                                            location: widget.equipment.location,
                                            bio: 'Passionate about water sports and sharing amazing equipment with the community. I\'ve been renting out my gear for over 3 years!',
                                            ownerListings: ownerListings,
                                            ownerReviews: _getOwnerReviews(),
                                            rating: 4.9,
                                            reviewCount: _getOwnerReviews().length,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8), // Reduced padding
                                      ),
                                      child: const Text(
                                        'View Profile',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ]
                          // ✅ If owner is viewing their own listing
                          else ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'This is your listing',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Description
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.equipment.description,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // What's Included
                    if (widget.equipment.features.isNotEmpty)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "What's Included",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...widget.equipment.features
                                .map((feature) => _buildIncludedItem(feature)),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // ✅ UPDATED: Delivery Options with Better Layout
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
                          const SizedBox(height: 16),

                          // ✅ Pickup option
                          if (widget.equipment.requiresPickup)
                            _buildDeliveryOption(
                              Icons.store,
                              'Pickup Available',
                              'Collect from ${widget.equipment.location}',
                              AppColors.primary,
                            ),

                          if (widget.equipment.requiresPickup &&
                              widget.equipment.offersDelivery)
                            const SizedBox(height: 16), // ✅ More spacing

                          // ✅ Delivery option
                          if (widget.equipment.offersDelivery)
                            _buildDeliveryOption(
                              Icons.local_shipping,
                              'Delivery Available',
                              widget.equipment.deliveryFeeText ??
                                  'Contact owner for delivery details',
                              Colors.green,
                            ),

                          // ✅ Delivery radius info
                          if (widget.equipment.offersDelivery &&
                              widget.equipment.deliveryRadius != null) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 44),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Within ${widget.equipment.deliveryRadius!.toStringAsFixed(0)}km radius',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Reviews Section
                    if (widget.equipment.reviewCount > 0)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 24, color: AppColors.accent),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${widget.equipment.displayRating} • ${widget.equipment.reviewCount} reviews',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
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
                            ..._getReviews()
                                .take(2)
                                .map((review) => ReviewCard(review: review)),
                          ],
                        ),
                      ),

                    // Bottom spacing for sticky button
                    const SizedBox(height: 165),
                  ],
                ),
              ),
            ],
          ),

          // ✅ UPDATED:  Animated Bottom Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showBottomBar ? 0 : -100, // ✅ Hide by moving down
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(isTablet ? 24 : 16),
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
                child: Row(
                  children: [
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.equipment.pricePerHourText,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Book Now Button
                    Expanded(
                      child: SizedBox(
                        height: 56,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 16,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            // ✅ Added Expanded to prevent overflow
            child: Text(
              item,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ UPDATED: Better delivery option widget
  Widget _buildDeliveryOption(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2, // ✅ Allow 2 lines for longer text
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 22),
        ],
      ),
    );
  }
}
