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
    required this. equipment,
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

    // Optimistic update
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

        // ✅ Show feedback
        ScaffoldMessenger. of(context).showSnackBar(
          SnackBar(
            content:  Text(
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
      
      // Revert on error
      if (mounted) {
        setState(() {
          _isFavorite = previousState;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error:  $e'),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow:  [
            BoxShadow(
              color: Colors.black. withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with fixed aspect ratio
            Flexible(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1.5,
                      child: widget.equipment.imageUrls.isNotEmpty
                          ? Image.network(
                              widget.equipment.imageUrls. first,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder();
                              },
                            )
                          : _buildPlaceholder(),
                    ),
                  ),

                  // ✅ NEW:  Favorite button overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white. withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: _isLoadingFavorite
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: _isFavorite ? Colors.red : Colors.grey[600],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details section (keep your existing code)
            Flexible(
              flex: 5,
              child:  Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment:  CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.equipment.title,
                      style: const TextStyle(
                        fontSize:  14,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.equipment. location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
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
                                '${widget.equipment.rating. toStringAsFixed(1)} (${widget.equipment.reviewCount})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else
                          const SizedBox. shrink(),

                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              'NZ\$',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight. bold,
                                color: AppColors.primary,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              widget.equipment. pricePerHour.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                height: 1.0,
                              ),
                            ),
                            Text(
                              '/hr',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors. grey[600],
                                height: 1.0,
                              ),
                            ),
                          ],
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