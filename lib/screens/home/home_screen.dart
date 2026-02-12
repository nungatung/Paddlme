import 'package:flutter/material.dart';
import 'package:wave_share/services/booking_status_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';  
import '../../widgets/equipment_card.dart';
import '../equipment/equipment_detail_screen.dart';
import '../list_equipment/list_equipment_screen.dart';  
import '../../models/equipment_filters.dart';
import '../../widgets/filter_bottom_sheet.dart';
import 'dart:async';
import '../../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _equipmentService = EquipmentService();
  
  List<EquipmentModel> _allEquipment = [];
  List<EquipmentModel> _filteredEquipment = [];
  EquipmentCategory? _selectedType;
  
  // ✅ Unified search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  final ScrollController _categoryScrollController = ScrollController();
  EquipmentFilters _currentFilters = EquipmentFilters();
  
  bool _showLeftArrow = false;
  bool _showRightArrow = true;
  bool _isLoading = true;
  
  // ✅ Location suggestions
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _showLocationSuggestions = false;
  Timer? _debounce;
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    _checkBookingStatuses();
  
    
    _categoryScrollController.addListener(_updateArrowVisibility);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrowVisibility();
    });
  }

  Future<void> _checkBookingStatuses() async {
    final statusService = BookingStatusService();
    await statusService.checkAndActivateBookings();
    await statusService.checkAndCloseBookings();
  }



  void _updateArrowVisibility() {
    if (_categoryScrollController.hasClients) {
      setState(() {
        _showLeftArrow = _categoryScrollController.offset > 10;
        _showRightArrow = _categoryScrollController.offset <
            _categoryScrollController.position.maxScrollExtent - 10;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode. dispose();
    _categoryScrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadEquipment() async {
    setState(() => _isLoading = true);
    
    try {
      final equipment = await _equipmentService. getAllEquipment();
      
      debugPrint('✅ Loaded ${equipment.length} equipment from Firestore');
      
      if (mounted) {
        setState(() {
          _allEquipment = equipment;
          _filteredEquipment = equipment;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading equipment:  $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterByType(EquipmentCategory? type) {
    setState(() {
      _selectedType = type;
      _currentFilters = EquipmentFilters();
      
      final query = _searchController.text;
      
      if (query.isEmpty) {
        if (type == null) {
          _filteredEquipment = _allEquipment;
        } else {
          _filteredEquipment = _allEquipment.where((e) => e.category == type).toList();
        }
      } else {
        _searchEquipment(query);
      }
    });
  }

  // ��� UPDATED: Unified search that handles BOTH equipment and location
  void _searchEquipment(String query) {
    // Cancel previous debounce
    if (_debounce?.isActive ??  false) _debounce! .cancel();
    
    // Debounce for location search
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // Try location search if query looks like a location (3+ chars)
      if (query.length >= 3 && ! _showLocationSuggestions) {
        try {
          final suggestions = await LocationService. searchLocation(query);
          if (mounted && suggestions.isNotEmpty) {
            setState(() {
              _locationSuggestions = suggestions;
              _showLocationSuggestions = true;
            });
          }
        } catch (e) {
          debugPrint('Location search error: $e');
        }
      }
    });
    
    // Immediate equipment search
    setState(() {
      if (query.isEmpty) {
        _showLocationSuggestions = false;
        _locationSuggestions. clear();
        
        if (_currentFilters.hasActiveFilters) {
          _applyFilters(_currentFilters);
        } else if (_selectedType != null) {
          _filteredEquipment = _allEquipment.where((e) => e.category == _selectedType).toList();
        } else {
          _filteredEquipment = _allEquipment;
        }
      } else {
        // Search equipment by title, description, or location
        _filteredEquipment = _allEquipment.where((e) {
          final matchesSearch = e.title.toLowerCase().contains(query.toLowerCase()) ||
              e.location.toLowerCase().contains(query.toLowerCase()) ||
              e.description. toLowerCase().contains(query.toLowerCase());
          
          final matchesType = _selectedType == null || e.category == _selectedType;
          final matchesFilters = _meetsFilterCriteria(e);
          
          return matchesSearch && matchesType && matchesFilters;
        }).toList();
      }
    });
  }

  void _selectLocation(String locationName) {
    setState(() {
      _selectedLocation = locationName;
      _searchController.text = '';
      _showLocationSuggestions = false;
      _locationSuggestions.clear();
      
      // Filter by location
      _filteredEquipment = _allEquipment.where((equipment) {
        return equipment.location.toLowerCase().contains(locationName.toLowerCase());
      }).toList();
      
      debugPrint('🗺️ Filtered by location: $locationName (${_filteredEquipment. length} results)');
    });
    
    _searchFocusNode.unfocus();
  }

  void _clearLocationFilter() {
    setState(() {
      _selectedLocation = null;
      _searchController.clear();
      _showLocationSuggestions = false;
      _locationSuggestions.clear();
      _filteredEquipment = _allEquipment;
    });
  }

  void _applyFilters(EquipmentFilters filters) {
    setState(() {
      _currentFilters = filters;
      
      if (filters.hasActiveFilters) {
        _selectedType = null;
      }
      
      final query = _searchController.text;
      
      _filteredEquipment = _allEquipment.where((equipment) {
        if (query.isNotEmpty) {
          final matchesSearch = equipment.title. toLowerCase().contains(query.toLowerCase()) ||
              equipment.location.toLowerCase().contains(query.toLowerCase()) ||
              equipment.description. toLowerCase().contains(query.toLowerCase());
          if (! matchesSearch) return false;
        }
        
        if (filters.types != null && filters.types! .isNotEmpty) {
          if (!filters.types!.contains(equipment.category)) return false;
        }

        if (filters.minPrice != null && equipment.pricePerHour < filters.minPrice!) {
          return false;
        }
        if (filters.maxPrice != null && equipment.pricePerHour > filters.maxPrice!) {
          return false;
        }

        if (filters.minRating != null && equipment.rating < filters.minRating!) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  bool _meetsFilterCriteria(EquipmentModel equipment) {
    if (!_currentFilters.hasActiveFilters) return true;

    if (_currentFilters.types != null && _currentFilters.types!. isNotEmpty) {
      if (!_currentFilters.types! .contains(equipment.category)) return false;
    }

    if (_currentFilters.minPrice != null && equipment.pricePerHour < _currentFilters.minPrice!) {
      return false;
    }
    if (_currentFilters.maxPrice != null && equipment.pricePerHour > _currentFilters.maxPrice!) {
      return false;
    }

    if (_currentFilters.minRating != null && equipment.rating < _currentFilters. minRating!) {
      return false;
    }

    return true;
  }

  void _scrollLeft() {
    _categoryScrollController.animateTo(
      _categoryScrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _categoryScrollController.animateTo(
      _categoryScrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return GestureDetector(
      onTap: () {
        // Hide suggestions when tapping outside
        if (_showLocationSuggestions) {
          setState(() {
            _showLocationSuggestions = false;
          });
        }
        _searchFocusNode.unfocus();
      },
      child:  Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment:  CrossAxisAlignment.start,
                  children: [
                  
                    const SizedBox(height: 16),

                    // ✅ Active Location Filter Badge
                    if (_selectedLocation != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary. withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary. withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _selectedLocation!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight:  FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _clearLocationFilter,
                              child:  const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ✅ Unified Search Bar
                    Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _searchEquipment,
                          decoration:  InputDecoration(
                            hintText: 'Search equipment or location...',
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius. circular(12),
                              borderSide: BorderSide. none,
                            ),
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: Row(
                              mainAxisSize:  MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _showLocationSuggestions = false;
                                        _locationSuggestions.clear();
                                        _filteredEquipment = _allEquipment;
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(Icons.tune, color: AppColors.primary),
                                      if (_currentFilters.hasActiveFilters)
                                        Positioned(
                                          right: -2,
                                          top: -2,
                                          child:  Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: AppColors.error,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight:  16,
                                            ),
                                            child: Text(
                                              '${_currentFilters.activeFilterCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight:  FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => FilterBottomSheet(
                                        initialFilters: _currentFilters,
                                        onApply: _applyFilters,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          ),
                        ),

                        // ✅ Location Suggestions Dropdown
                        if (_showLocationSuggestions && _locationSuggestions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 200),
                            child: Column(
                              crossAxisAlignment:  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding:  const EdgeInsets.all(12),
                                  child: Text(
                                    'Locations',
                                    style: TextStyle(
                                      fontSize:  12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.only(bottom: 8),
                                    itemCount:  _locationSuggestions.length,
                                    separatorBuilder: (context, index) => Divider(
                                      height: 1,
                                      color: Colors.grey[200],
                                    ),
                                    itemBuilder: (context, index) {
                                      final suggestion = _locationSuggestions[index];
                                      return ListTile(
                                        dense: true,
                                        leading: Text(
                                          suggestion['type_icon'] ?? '📍',
                                          style:  const TextStyle(fontSize: 18),
                                        ),
                                        title: Text(
                                          suggestion['display_name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight:  FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: suggestion['place_type'] != null
                                            ? Text(
                                                suggestion['place_type'],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:  Colors.grey[600],
                                                ),
                                              )
                                            : null,
                                        onTap: () {
                                          _selectLocation(suggestion['display_name'] ?? '');
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Category Chips
                    SizedBox(
                      height: 42,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 40), // Reduced left padding, keep right for arrow
                            child: SingleChildScrollView(
                              controller: _categoryScrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildCategoryChip('All', null, Icons.waves),
                                  const SizedBox(width: 8),
                                  _buildCategoryChip('Kayaks', EquipmentCategory.kayak, Icons.kayaking),
                                  const SizedBox(width: 8),
                                  _buildCategoryChip('SUPs', EquipmentCategory.sup, Icons.surfing),
                                  const SizedBox(width: 8),
                                  _buildCategoryChip('Jet Skis', EquipmentCategory.jetSki, Icons.directions_boat),
                                  const SizedBox(width: 8),
                                  _buildCategoryChip('Boats', EquipmentCategory.boat, Icons.directions_boat_filled),
                                  const SizedBox(width: 16), // Extra padding at end
                                ],
                              ),
                            ),
                          ),

                          if (_showLeftArrow)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.0),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _scrollLeft,
                                        customBorder: const CircleBorder(),
                                        child: const Icon(
                                          Icons.chevron_left,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          if (_showRightArrow)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.0),
                                      Colors.white,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _scrollRight,
                                        customBorder: const CircleBorder(),
                                        child: const Icon(
                                          Icons.chevron_right,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Equipment Grid
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadEquipment,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredEquipment.isEmpty
                          ? _buildEmptyState()
                          : GridView.builder(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 12,
                                top: 12,
                                bottom: 100,
                              ),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                childAspectRatio: 0.72,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _filteredEquipment.length,
                              itemBuilder: (context, index) {
                                return EquipmentCard(
                                  equipment: _filteredEquipment[index],
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EquipmentDetailScreen(
                                          equipment: _filteredEquipment[index], equipmentId: '',
                                        ),
                                      ),
                                    );
                                    _loadEquipment();
                                  },
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFiltered = _currentFilters.hasActiveFilters || 
                       _searchController.text.isNotEmpty ||
                       _selectedType != null ||
                       _selectedLocation != null;
    
    if (isFiltered) {
      return ListView(
        padding: const EdgeInsets.all(40),
        children: [
          const SizedBox(height: 60),
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No equipment found',
            style:  TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Try adjusting your filters or search query',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton. icon(
            onPressed: () {
              setState(() {
                _currentFilters = EquipmentFilters();
                _selectedType = null;
                _selectedLocation = null;
                _searchController.clear();
                _filteredEquipment = _allEquipment;
              });
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
            ),
          ),
        ],
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.kayaking,
            size: 80,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'No Equipment Available Yet',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Be the first to list your water sports equipment and start earning! ',
          style: TextStyle(
            fontSize: 17,
            color: Colors.grey[600],
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton. icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ListEquipmentScreen(),
              ),
            );
            
            if (result == true) {
              _loadEquipment();
            }
          },
          icon: const Icon(Icons.add_circle_outline, size: 24),
          label: const Text(
            'List Your Equipment',
            style: TextStyle(fontSize: 18),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors. white,
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton. icon(
          onPressed: _loadEquipment,
          icon:  const Icon(Icons.refresh),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, EquipmentCategory?  type, IconData icon) {
    final isSelected = _selectedType == type;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) => _filterByType(selected ?  type : null),
      backgroundColor:  Colors.white,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white :  Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey[300]!,
      ),
    );
  }
  
}