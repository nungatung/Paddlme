import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../models/equipment_model.dart';
import '../widgets/equipment_card.dart';
import '../screens/equipment/equipment_detail_screen.dart';

class OwnerProfileBottomSheet extends StatefulWidget {
  final String ownerId;
  final String ownerName;
  final String? ownerImageUrl;
  final String location;
  final String? bio;
  final List<EquipmentModel> ownerListings;
  final List<OwnerReview> ownerReviews;
  final double rating;
  final int reviewCount;

  const OwnerProfileBottomSheet({
    super.key,
    required this.ownerId,
    required this.ownerName,
    this.ownerImageUrl,
    required this.location,
    this.bio,
    this.ownerListings = const [],
    this.ownerReviews = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  @override
  State<OwnerProfileBottomSheet> createState() => _OwnerProfileBottomSheetState();
}

class _OwnerProfileBottomSheetState extends State<OwnerProfileBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() => _scrollOffset = _scrollController.offset);
      });
    
    // Delay entrance animation slightly
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedChild(Widget child, int index, {double delay = 0}) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Interval(
          ((index * 0.1) + delay).clamp(0.0, 0.8),
          ((index * 0.1) + delay + 0.3).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calculate dynamic sizes
    final avatarRadius = isLargeTablet ? 70.0 : isTablet ? 60.0 : 50.0;
    final cardWidth = isLargeTablet ? 240.0 : isTablet ? 220.0 : 180.0;
    final horizontalPadding = isTablet ? 32.0 : 24.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      snap: true,
      snapSizes: const [0.5, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Handle bar
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // Profile Header
                SliverToBoxAdapter(
                  child: _buildAnimatedChild(
                    _buildProfileHeader(avatarRadius, horizontalPadding),
                    0,
                  ),
                ),

                // Stats Row
                SliverToBoxAdapter(
                  child: _buildAnimatedChild(
                    _buildStatsRow(horizontalPadding),
                    1,
                    delay: 0.1,
                  ),
                ),

                // Bio Section
                if (widget.bio != null && widget.bio!.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildAnimatedChild(
                      _buildBioSection(horizontalPadding),
                      2,
                      delay: 0.2,
                    ),
                  ),

                // Listings Section
                if (widget.ownerListings.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildAnimatedChild(
                      _buildListingsHeader(horizontalPadding),
                      3,
                      delay: 0.3,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildAnimatedChild(
                      _buildListingsCarousel(cardWidth),
                      4,
                      delay: 0.35,
                    ),
                  ),
                ],

                // Reviews Section
                if (widget.ownerReviews.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildAnimatedChild(
                      _buildReviewsHeader(horizontalPadding),
                      5,
                      delay: 0.4,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildAnimatedChild(
                            _buildOwnerReviewCard(widget.ownerReviews[index]),
                            6 + index,
                            delay: 0.45 + (index * 0.05),
                          );
                        },
                        childCount: widget.ownerReviews.length,
                      ),
                    ),
                  ),
                ],

                // Bottom padding for safe area
                SliverToBoxAdapter(
                  child: SizedBox(height: bottomPadding + 24),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(double avatarRadius, double horizontalPadding) {
    // Parallax effect on scroll
    final parallaxOffset = (_scrollOffset * 0.3).clamp(0.0, 30.0);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        children: [
          Transform.translate(
            offset: Offset(0, parallaxOffset),
            child: Hero(
              tag: 'owner_avatar_${widget.ownerId}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: widget.ownerImageUrl != null
                      ? NetworkImage(widget.ownerImageUrl!)
                      : null,
                  backgroundColor: Colors.grey[100],
                  child: widget.ownerImageUrl == null
                      ? Icon(Icons.person, size: avatarRadius * 0.6, color: Colors.grey[400])
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Name with verified badge inline
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  widget.ownerName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified,
                  size: 18,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withOpacity(0.15),
                  AppColors.accent.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  'LOCAL EXPERT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Location with tap to copy
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Clipboard.setData(ClipboardData(text: widget.location));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Location copied: ${widget.location}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(16),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    widget.location,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatsRow(double horizontalPadding) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            icon: Icons.inventory_2_outlined,
            label: 'Listings',
            value: widget.ownerListings.length.toString(),
            onTap: () {
              // Scroll to listings section
            },
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.star_rounded,
            label: 'Rating',
            value: widget.rating > 0 ? widget.rating.toStringAsFixed(1) : 'New',
            isAccent: widget.rating > 0,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.rate_review_outlined,
            label: 'Reviews',
            value: widget.reviewCount.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.grey[300]!,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool isAccent = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAccent ? AppColors.accent.withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isAccent ? AppColors.accent : AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.format_quote_rounded, size: 20, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              widget.bio!,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsHeader(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: 32,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.ownerListings.length} Listing${widget.ownerListings.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          if (widget.ownerListings.length > 2)
            TextButton(
              onPressed: () {
                // View all listings
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Row(
                children: [
                  Text(
                    'See All',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListingsCarousel(double cardWidth) {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.ownerListings.length,
        itemBuilder: (context, index) {
          return Container(
            width: cardWidth,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: EquipmentCard(
              equipment: widget.ownerListings[index],
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => 
                        EquipmentDetailScreen(
                          equipment: widget.ownerListings[index],
                          equipmentId: '',
                        ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsHeader(double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        top: 32,
        bottom: 16,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.star_rounded,
              size: 18,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${widget.rating.toStringAsFixed(1)} • ${widget.reviewCount} Review${widget.reviewCount != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerReviewCard(OwnerReview review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'reviewer_${review.userName}',
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: review.userAvatarUrl != null
                      ? NetworkImage(review.userAvatarUrl!)
                      : null,
                  backgroundColor: Colors.grey[200],
                  child: review.userAvatarUrl == null
                      ? Icon(Icons.person, size: 20, color: Colors.grey[400])
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              index < review.rating.floor()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _formatDate(review.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
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
              height: 1.5,
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
    if (difference < 30) return '${(difference / 7).floor()}w ago';
    if (difference < 365) return '${(difference / 30).floor()}mo ago';
    return '${(difference / 365).floor()}y ago';
  }
}

class OwnerReview {
  final String userName;
  final String? userAvatarUrl;
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