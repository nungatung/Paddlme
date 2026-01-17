import 'package:flutter/material.dart';
import 'package:wave_share/core/theme/app_colors.dart';
import 'package:wave_share/services/location_service.dart';

class LocationPicker extends StatefulWidget {
  final String? selectedLocation;
  final Function(String) onLocationSelected;

  const LocationPicker({
    super.key,
    this.selectedLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _searchController = TextEditingController();
  List<LocationResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController. dispose();
    super.dispose();
  }

  Future<void> _searchLocations(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await LocationService.searchLocation(query);
      if (mounted) {
        setState(() {
          _searchResults = List<LocationResult>.from(results);
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error:  $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLocationPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]! ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_outlined, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.selectedLocation ?? 'Select your location',
                style: TextStyle(
                  fontSize: 16,
                  color: widget.selectedLocation != null 
                      ? Colors.black87 
                      : Colors.grey[600],
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors. grey[400]),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context:  context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment:  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search for a city, suburb, or region...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setModalState(() => _searchResults = []);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setModalState(() {});
                    _searchLocations(value);
                  },
                ),

                const SizedBox(height: 16),

                // Loading Indicator
                if (_isSearching)
                  const Center(
                    child:  Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Search Results
                if (! _isSearching && _searchResults.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final location = _searchResults[index];
                        final isSelected = location.displayName == widget.selectedLocation;

                        return ListTile(
                          leading: Text(
                            location.typeIcon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            location. text,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight. bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            location.displayName,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors. grey[600],
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: AppColors.primary)
                              : null,
                          onTap: () {
                            widget.onLocationSelected(location.displayName);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),

                // Empty State
                if (! _isSearching && _searchResults.isEmpty && _searchController.text.length >= 2)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No locations found',
                            style:  TextStyle(
                              fontSize:  16,
                              color: Colors. grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching for a city or suburb',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Initial State
                if (_searchController. text.length < 2 && _searchResults.isEmpty)
                  Expanded(
                    child:  Center(
                      child: Column(
                        mainAxisAlignment:  MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_searching, size: 64, color:  Colors.grey[300]),
                          const SizedBox(height:  16),
                          Text(
                            'Start typing to search',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search for cities, suburbs, or regions in NZ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}