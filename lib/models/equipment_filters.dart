import 'equipment_model.dart';

class EquipmentFilters {
  final List<EquipmentCategory>? types;
  final double? minPrice;
  final double? maxPrice;
  final double? maxDistance; // in km
  final double? minRating;
  final bool? verifiedOnly;

  EquipmentFilters({
    this. types,
    this.minPrice,
    this.maxPrice,
    this.maxDistance,
    this.minRating,
    this.verifiedOnly,
  });

  bool get hasActiveFilters {
    return (types != null && types!.isNotEmpty) ||
        minPrice != null ||
        maxPrice != null ||
        maxDistance != null ||
        minRating != null ||
        (verifiedOnly != null && verifiedOnly! );
  }

  int get activeFilterCount {
    int count = 0;
    if (types != null && types!. isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (maxDistance != null) count++;
    if (minRating != null) count++;
    if (verifiedOnly != null && verifiedOnly!) count++;
    return count;
  }

  EquipmentFilters copyWith({
    List<EquipmentCategory>? types,
    double? minPrice,
    double? maxPrice,
    double? maxDistance,
    double? minRating,
    bool? verifiedOnly,
  }) {
    return EquipmentFilters(
      types:  types ??  this.types,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      maxDistance: maxDistance ?? this. maxDistance,
      minRating: minRating ?? this.minRating,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }

  EquipmentFilters clear() {
    return EquipmentFilters();
  }
}