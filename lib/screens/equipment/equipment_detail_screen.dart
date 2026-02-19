import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    required this.equipment,
    required String equipmentId,
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

  final ScrollController _scrollController = ScrollController();
  bool _showBottomBar = true;
  double _lastScrollPosition = 0;

  List<Review> _getReviews() {
    return [
      Review(
        userName: 'Mike Chen',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=12',
        rating: 5.0,
        comment:
            'Awesome kayak! Very stable and comfortable. Sarah was super helpful with instructions. Highly recommend!',
        date: DateTime.now().subtract(const Duration(days: 14)),
      ),
      Review(
        userName: 'Emma Wilson',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=5',
        rating: 5.0,
        comment:
            'Perfect for beginners. Had a great time exploring the bay. Equipment was in excellent condition.',
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

  List<OwnerReview> _getOwnerReviews() {
    return [
      OwnerReview(
        userName: 'Jessica Lee',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=1',
        rating: 5.0,
        comment:
            '${widget.equipment.ownerName} is an amazing host! Very responsive and the equipment was exactly as described. Highly recommend renting from them!',
        date: DateTime.now().subtract(const Duration(days: 5)),
      ),
      OwnerReview(
        userName: 'Tom Wilson',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=3',
        rating: 5.0,
        comment:
            'Great communication and flexible with pickup times. Equipment was clean and well-maintained. Will definitely rent again!',
        date: DateTime.now().subtract(const Duration(days: 18)),
      ),
      OwnerReview(
        userName: 'Sarah Chen',
        userAvatarUrl: 'https://i.pravatar.cc/150?img=9',
        rating: 4.5,
        comment:
            'Very professional and helpful. Gave us great tips on where to go. The gear was top quality!',
        date: DateTime.now().subtract(const Duration(days: 32)),
      ),
    ];
  }

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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

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

      Navigator.pop(context);

      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
            conversationId: conversationId,
            otherUserId: widget.equipment.ownerId,
            otherUserName: widget.equipment.ownerName,
            otherUserAvatarUrl: widget.equipment.ownerImageUrl,
            equipmentTitle: widget.equipment.title,
            equipmentImageUrl: widget.equipment.imageUrls.isNotEmpty
                ? widget.equipment.imageUrls.first
                : null,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkIfFavorited();
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

  void _onScroll() {
    final currentScroll = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final shouldShow = currentScroll < _lastScrollPosition ||
        currentScroll <= 50 ||
        currentScroll >= maxScroll - 100;

    if (shouldShow != _showBottomBar) {
      setState(() {
        _showBottomBar = shouldShow;
      });
    }

    _lastScrollPosition = currentScroll;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: isLargeTablet
                    ? screenHeight * 0.5
                    : isTablet
                        ? screenHeight * 0.45
                        : screenHeight * 0.4,
                pinned: true,
                backgroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _buildActionButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  if (_authService.currentUser?.uid == widget.equipment.ownerId)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildActionButton(
                        icon: Icons.edit_rounded,
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
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildFavoriteButton(),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ImageCarousel(
                    imageUrls: widget.equipment.imageUrls,
                    height: isLargeTablet
                        ? screenHeight * 0.5
                        : isTablet
                            ? screenHeight * 0.45
                            : screenHeight * 0.4,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(isTablet),
                    const SizedBox(height: 8),
                    _buildOwnerSection(isTablet),
                    const SizedBox(height: 8),
                    _buildDescriptionSection(),
                    const SizedBox(height: 8),
                    if (widget.equipment.features.isNotEmpty)
                      _buildFeaturesSection(),
                    const SizedBox(height: 8),
                    _buildDeliverySection(),
                    const SizedBox(height: 8),
                    if (widget.equipment.reviewCount > 0)
                      _buildReviewsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _showBottomBar ? 0 : -120,
            left: 0,
            right: 0,
            child: _buildBottomBar(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: const Color(0xFF1A1A2E), size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _isLoadingFavorite ? null : _toggleFavorite,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: _isLoadingFavorite
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(_isFavorite),
                      color: _isFavorite
                          ? Colors.red[400]
                          : const Color(0xFF1A1A2E),
                      size: 22,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final user = _authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to save favorites'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    HapticFeedback.lightImpact();

    try {
      final newStatus = await _favoritesService.toggleFavorite(
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
            content: Row(
              children: [
                Icon(
                  newStatus
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(newStatus
                    ? 'Added to favorites'
                    : 'Removed from favorites'),
              ],
            ),
            backgroundColor: newStatus ? Colors.red[400] : Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
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
            content: Text('Error: $e'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Widget _buildTitleSection(bool isTablet) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.equipment.title,
            style: TextStyle(
              fontSize: isTablet ? 30 : 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.equipment.reviewCount > 0) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 18, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.equipment.displayRating}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${widget.equipment.reviewCount})',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      widget.equipment.location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerSection(bool isTablet) {
    final isOwner = _authService.currentUser?.uid == widget.equipment.ownerId;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.2),
                      AppColors.primary.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: widget.equipment.ownerImageUrl != null
                      ? NetworkImage(widget.equipment.ownerImageUrl!)
                      : null,
                  backgroundColor: Colors.white,
                  child: widget.equipment.ownerImageUrl == null
                      ? Icon(Icons.person_rounded, color: Colors.grey[400])
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hosted by',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.equipment.ownerName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isOwner) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _contactOwner,
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 18),
                      label: const Text(
                        'Message',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1.5),
                        foregroundColor: AppColors.primary,
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
                            bio:
                                'Passionate about water sports and sharing amazing equipment with the community. I\'ve been renting out my gear for over 3 years!',
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
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is your listing',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.equipment.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's Included",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: widget.equipment.features
                .map((feature) => _buildFeatureChip(feature))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            feature,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.equipment.requiresPickup)
            _buildDeliveryOption(
              Icons.store_rounded,
              'Pickup Available',
              'Collect from ${widget.equipment.location}',
              AppColors.primary,
            ),
          if (widget.equipment.requiresPickup &&
              widget.equipment.offersDelivery)
            const SizedBox(height: 12),
          if (widget.equipment.offersDelivery)
            _buildDeliveryOption(
              Icons.local_shipping_rounded,
              'Delivery Available',
              widget.equipment.deliveryFeeText ??
                  'Contact owner for delivery details',
              Colors.green[600]!,
            ),
          if (widget.equipment.offersDelivery &&
              widget.equipment.deliveryRadius != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    'Within ${widget.equipment.deliveryRadius!.toStringAsFixed(0)}km radius',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(
      IconData icon, String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: color, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Container(
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.star_rounded,
                        size: 24, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.equipment.displayRating} • ${widget.equipment.reviewCount} reviews',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._getReviews().take(2).map((review) => ReviewCard(review: review)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isTablet) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 28 : 20,
        16,
        isTablet ? 28 : 20,
        20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.equipment.pricePerHourText,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'per hour',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: AppColors.accent.withOpacity(0.4),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
