import 'package:flutter/material.dart';
import '../models/equipment_model.dart';
import '../core/theme/app_colors.dart';
import '../services/favourites_service.dart';
import '../services/auth_service.dart';

class EquipmentCard extends StatefulWidget {
  final EquipmentModel equipment;
  final VoidCallback onTap;

  const EquipmentCard({
    super.key,
    required this.equipment,
    required this.onTap,
  });

  @override
  State<EquipmentCard> createState() => _EquipmentCardState();
}

class _EquipmentCardState extends State<EquipmentCard> {
  final _favoritesService = FavoritesService();
  final _authService = AuthService();
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

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
      if (mounted) {
        setState(() => _isLoadingFavorite = false);
      }
    }
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

    final previousState = _isFavorite;
    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      final newState = await _favoritesService.toggleFavorite(
        user.uid,
        widget.equipment.id,
        previousState,
      );

      if (mounted) {
        setState(() {
          _isFavorite = newState;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newState 
                  ? '❤️ Added to favorites' 
                  : 'Removed from favorites',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      
      if (mounted) {
        setState(() {
          _isFavorite = previousState;
        });

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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section - takes more space (62% of card)
            Flexible(
              flex: 62,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: AspectRatio(
                      aspectRatio: 1.3, // Reduced from 1.5 - taller image
                      child: widget.equipment.imageUrls.isNotEmpty
                          ? Image.network(
                              widget.equipment.imageUrls.first,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder();
                              },
                            )
                          : _buildPlaceholder(),
                    ),
                  ),

                  // Favorite button overlay
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isLoadingFavorite
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: 20,
                                color: _isFavorite ? Colors.red : Colors.grey[600],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details section - compressed (38% of card)
            Flexible(
              flex: 38,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title - larger and bolder
                    Text(
                      widget.equipment.title,
                      style: const TextStyle(
                        fontSize: 16, // Increased from 14
                        fontWeight: FontWeight.w700, // Bolder
                        color: Colors.black87,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1, // Reduced to 1 line
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 3),

                    // Location - improved readability
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            widget.equipment.location,
                            style: TextStyle(
                              fontSize: 13, // Increased from 12
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Rating & Price Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Rating
                        if (widget.equipment.reviewCount > 0)
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.equipment.rating.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontSize: 14, // Increased
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                ' (${widget.equipment.reviewCount})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),

                          const Spacer(),

                        // Add this SizedBox to push price down
                        const SizedBox(height: 8),

                        // Price - prominent pill badge
                        Container(                
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                'NZ\$${widget.equipment.pricePerHour.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 17, // Increased from 18
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  height: 1,
                                ),
                              ),
                              Text(
                                '/hr',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary.withOpacity(0.7),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.kayaking,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}