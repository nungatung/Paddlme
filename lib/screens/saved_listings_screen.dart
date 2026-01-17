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
    with AutomaticKeepAliveClientMixin {  // ✅ Add this mixin
  
  final _favoritesService = FavoritesService();
  final _authService = AuthService();

  List<EquipmentModel> _savedEquipment = [];
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;  // ✅ Keep state alive

  @override
  void initState() {
    super.initState();
    _loadSavedListings();
  }

  Future<void> _loadSavedListings() async {
    setState(() => _isLoading = true);  // ✅ Show loading
    
    final user = _authService.currentUser;
    
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final favorites = await _favoritesService. getFavoriteEquipment(user.uid);
      
      debugPrint('✅ Loaded ${favorites.length} saved listings');
      
      if (mounted) {
        setState(() {
          _savedEquipment = favorites;
          _isLoading = false;
        });
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
    super.build(context);  // ✅ Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Saved Listings'),
        backgroundColor:  Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // ✅ Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSavedListings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child:  CircularProgressIndicator())
          : _savedEquipment.isEmpty
              ? _buildEmptyState()
              : _buildSavedList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child:  Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height:  32),
            const Text(
              'No Saved Listings Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Save listings you\'re interested in to find them easily later',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton. icon(
                onPressed: () {
                  // ✅ Navigate to home screen properly
                  Navigator.pop(context);  // Go back to main navigation
                },
                icon: const Icon(Icons.search),
                label: const Text('Browse Equipment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedList() {
    return RefreshIndicator(
      onRefresh: _loadSavedListings,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing:  12,
        ),
        itemCount: _savedEquipment.length,
        itemBuilder: (context, index) {
          final equipment = _savedEquipment[index];
          
          return EquipmentCard(
            equipment: equipment,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EquipmentDetailScreen(equipment: equipment),
                ),
              );
              
              // ✅ Refresh if equipment was unfavorited
              if (result == true) {
                _loadSavedListings();
              }
            },
          );
        },
      ),
    );
  }
}