import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/equipment_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add equipment to user's favorites
  Future<void> addToFavorites(String userId, String equipmentId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoriteEquipmentIds': FieldValue.arrayUnion([equipmentId]),
      });
      debugPrint('✅ Added $equipmentId to favorites');
    } catch (e) {
      debugPrint('❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  /// Remove equipment from user's favorites
  Future<void> removeFromFavorites(String userId, String equipmentId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoriteEquipmentIds': FieldValue.arrayRemove([equipmentId]),
      });
      debugPrint('✅ Removed $equipmentId from favorites');
    } catch (e) {
      debugPrint('❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String userId, String equipmentId, bool currentlyFavorited) async {
    try {
      if (currentlyFavorited) {
        await removeFromFavorites(userId, equipmentId);
        return false;
      } else {
        await addToFavorites(userId, equipmentId);
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Get user's favorite equipment IDs
  Future<List<String>> getFavoriteIds(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (! doc.exists) {
        return [];
      }

      final data = doc.data();
      return List<String>.from(data? ['favoriteEquipmentIds'] ?? []);
    } catch (e) {
      debugPrint('❌ Error getting favorite IDs: $e');
      return [];
    }
  }

  /// Get full equipment details for user's favorites
  Future<List<EquipmentModel>> getFavoriteEquipment(String userId) async {
    try {
      // Get favorite IDs
      final favoriteIds = await getFavoriteIds(userId);

      if (favoriteIds.isEmpty) {
        return [];
      }

      // Firestore has a limit of 10 items for 'in' queries
      // If more than 10, we need to batch the requests
      List<EquipmentModel> allFavorites = [];

      // Split into chunks of 10
      for (int i = 0; i < favoriteIds.length; i += 10) {
        final chunk = favoriteIds. skip(i).take(10).toList();
        
        final querySnapshot = await _firestore
            .collection('equipment')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        final equipment = querySnapshot.docs
            .map((doc) => EquipmentModel.fromMap(doc.data()))
            .toList();

        allFavorites.addAll(equipment);
      }

      debugPrint('✅ Loaded ${allFavorites.length} favorite equipment');
      return allFavorites;
    } catch (e) {
      debugPrint('❌ Error getting favorite equipment: $e');
      return [];
    }
  }

  /// Stream of user's favorite equipment (real-time updates)
  Stream<List<String>> streamFavoriteIds(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data();
      return List<String>.from(data?['favoriteEquipmentIds'] ?? []);
    });
  }

  /// Check if equipment is favorited
  Future<bool> isFavorited(String userId, String equipmentId) async {
    try {
      final favoriteIds = await getFavoriteIds(userId);
      return favoriteIds.contains(equipmentId);
    } catch (e) {
      debugPrint('❌ Error checking favorite status: $e');
      return false;
    }
  }
}