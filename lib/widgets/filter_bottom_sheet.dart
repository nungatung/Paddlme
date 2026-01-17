import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/equipment_model.dart';
import '../models/equipment_filters.dart';

class FilterBottomSheet extends StatefulWidget {
  final EquipmentFilters initialFilters;
  final Function(EquipmentFilters) onApply;

  const FilterBottomSheet({
    super.key,
    required this. initialFilters,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<EquipmentCategory> _selectedTypes;
  late RangeValues _priceRange;
  late double _maxDistance;
  late double _minRating;
  late bool _verifiedOnly;

  @override
  void initState() {
    super.initState();
    _selectedTypes = widget.initialFilters.types ?? [];
    _priceRange = RangeValues(
      widget.initialFilters.minPrice ??  0,
      widget.initialFilters.maxPrice ?? 200,
    );
    _maxDistance = widget.initialFilters.maxDistance ?? 50;
    _minRating = widget.initialFilters.minRating ?? 0;
    _verifiedOnly = widget.initialFilters.verifiedOnly ?? false;
  }

  void _clearFilters() {
    setState(() {
      _selectedTypes.clear();
      _priceRange = const RangeValues(0, 200);
      _maxDistance = 50;
      _minRating = 0;
      _verifiedOnly = false;
    });
  }

  void _applyFilters() {
    final filters = EquipmentFilters(
      types: _selectedTypes. isEmpty ? null : _selectedTypes,
      minPrice: _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: _priceRange.end < 200 ? _priceRange.end : null,
      maxDistance: _maxDistance < 50 ? _maxDistance :  null,
      minRating:  _minRating > 0 ? _minRating : null,
      verifiedOnly: _verifiedOnly ?  true : null,
    );

    widget.onApply(filters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color:  Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius. circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:  const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]! ),
              ),
            ),
            child: Column(
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Title & Clear button
                Row(
                  mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed:  _clearFilters,
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filters Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Equipment Type
                  _buildSectionTitle('Equipment Type'),
                  const SizedBox(height: 12),
                  _buildEquipmentTypeChips(),

                  const SizedBox(height: 32),

                  // Price Range
                  _buildSectionTitle('Price Range (per hour)'),
                  const SizedBox(height: 12),
                  _buildPriceRangeSlider(),

                  const SizedBox(height: 32),

                  // Distance
                  _buildSectionTitle('Distance'),
                  const SizedBox(height: 12),
                  _buildDistanceSlider(),

                  const SizedBox(height: 32),

                  // Rating
                  _buildSectionTitle('Minimum Rating'),
                  const SizedBox(height: 12),
                  _buildRatingSelector(),

                  const SizedBox(height: 32),

                  // Verified Only
                  _buildVerifiedToggle(),

                  const SizedBox(height: 100), // Space for buttons
                ],
              ),
            ),
          ),

          // Apply Button (Fixed at bottom)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius:  10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:  _applyFilters,
                  style: ElevatedButton. styleFrom(
                    backgroundColor:  AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildEquipmentTypeChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: EquipmentCategory.values.map((type) {
        final isSelected = _selectedTypes.contains(type);
        final typeInfo = _getTypeInfo(type);

        return FilterChip(
          label:  Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(typeInfo['emoji']!),
              const SizedBox(width: 8),
              Text(typeInfo['name']!),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedTypes.add(type);
              } else {
                _selectedTypes.remove(type);
              }
            });
          },
          backgroundColor: Colors.grey[100],
          selectedColor: AppColors.primary.withOpacity(0.1),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color:  isSelected ? AppColors.primary : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          side: BorderSide(
            color: isSelected ?  AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 :  1,
          ),
        );
      }).toList(),
    );
  }

  Map<String, String> _getTypeInfo(EquipmentCategory type) {
    switch (type) {
      case EquipmentCategory.kayak:
        return {'emoji': '🚣', 'name': 'Kayak'};
      case EquipmentCategory.sup:
        return {'emoji': '🏄', 'name': 'SUP Board'};
      case EquipmentCategory.jetSki:
        return {'emoji': '🚤', 'name': 'Jet Ski'};
      case EquipmentCategory.boat:
        return {'emoji': '⛵', 'name': 'Boat'};
      case EquipmentCategory.canoe:
        return {'emoji': '🛶', 'name': 'Canoe'};
      case EquipmentCategory.other:
        return {'emoji': '🌊', 'name': 'Other'};

    }
  }

  Widget _buildPriceRangeSlider() {
    return Column(
      children: [
        RangeSlider(
          values: _priceRange,
          min: 0,
          max:  200,
          divisions: 20,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primary.withOpacity(0.2),
          labels: RangeLabels(
            'NZ\$${_priceRange.start.round()}',
            'NZ\$${_priceRange.end. round()}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NZ\$${_priceRange.start.round()}/hr',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'NZ\$${_priceRange.end. round()}/hr',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      children: [
        Slider(
          value: _maxDistance,
          min: 1,
          max: 50,
          divisions: 49,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primary.withOpacity(0.2),
          label: '${_maxDistance. round()} km',
          onChanged: (value) {
            setState(() {
              _maxDistance = value;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Within ${_maxDistance.round()} km',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children:  [0, 3, 4, 4.5]. map((rating) {
        final isSelected = _minRating == rating;
        return InkWell(
          onTap: () {
            setState(() {
              _minRating = rating.toDouble();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ?  AppColors.primary : Colors.grey[100],
              borderRadius:  BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rating > 0) ...[
                  Text(
                    rating.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.star,
                    size: 18,
                    color: isSelected ? Colors.white :  AppColors.warning,
                  ),
                ] else
                  Text(
                    'Any',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors. black87,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVerifiedToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success. withOpacity(0.1),
              borderRadius: BorderRadius. circular(8),
            ),
            child:  const Icon(
              Icons.verified,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width:  16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verified Only',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Show only verified equipment',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors. grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _verifiedOnly,
            onChanged: (value) {
              setState(() {
                _verifiedOnly = value;
              });
            },
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}