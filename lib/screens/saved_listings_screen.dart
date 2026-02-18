import 'package:flutter/material.dart';
import '../models/equipment_model.dart';
import '../services/favourites_service.dart';
import '../services/auth_service.dart';
import '../widgets/equipment_card.dart';
import 'equipment/equipment_detail_screen.dart';
import '../core/theme/app_colors.dart';

class SavedListingsScreen extends StatefulWidget {
  const SavedListingsScreen({super.key});

  @override
  State<SavedListingsScreen> createState() => _SavedListingsScreenState();
}

class _SavedListingsScreenState extends State<SavedListingsScreen> 
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  
  final _favoritesService = FavoritesService();
  final _authService = AuthService();

  List<EquipmentModel> _savedEquipment = [];
  bool _isLoading = true;
  
  late AnimationController _fadeController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _loadSavedListings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedListings() async {
    setState(() => _isLoading = true);
    
    final user = _authService.currentUser;
    
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final favorites = await _favoritesService.getFavoriteEquipment(user.uid);
      
      debugPrint('✅ Loaded ${favorites.length} saved listings');
      
      if (mounted) {
        setState(() {
          _savedEquipment = favorites;
          _isLoading = false;
        });
        _fadeController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('❌ Error loading saved listings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Saved Listings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          AnimatedRotation(
            turns: _isLoading ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh_rounded, size: 20),
              ),
              onPressed: _isLoading ? null : _loadSavedListings,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedEquipment.isEmpty
              ? _buildEmptyState()
              : _buildSavedList(isTablet),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[50]!,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Saved Listings Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Save listings you\'re interested in to find them easily later',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedList(bool isTablet) {
    final crossAxisCount = isTablet ? 3 : 2;
    final childAspectRatio = isTablet ? 0.8 : 0.75;
    
    return FadeTransition(
      opacity: _fadeController,
      child: RefreshIndicator(
        onRefresh: _loadSavedListings,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _savedEquipment.length,
          itemBuilder: (context, index) {
            final equipment = _savedEquipment[index];
            
            return AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                final delay = (index * 0.1).clamp(0.0, 0.5);
                final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _fadeController,
                    curve: Interval(delay, (delay + 0.3).clamp(0.0, 1.0), curve: Curves.easeOut),
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - animation.value)),
                    child: child,
                  ),
                );
              },
              child: EquipmentCard(
                equipment: equipment,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => 
                          EquipmentDetailScreen(
                            equipment: equipment, 
                            equipmentId: '',
                          ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                  
                  if (result == true) {
                    _loadSavedListings();
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }
}