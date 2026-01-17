import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wave_share/models/equipment_model.dart';

class EquipmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference
  CollectionReference get _equipmentCollection => _firestore. collection('equipment');

  // Create equipment listing
  Future<String> createEquipment(EquipmentModel equipment) async {
    try {
      final docRef = await _equipmentCollection. add(equipment.toMap());
      
      // Update document with its own ID
      await docRef.update({'id': docRef.id});
      
      return docRef. id;
    } catch (e) {
      throw Exception('Failed to create equipment: $e');
    }
  }

  // Get equipment by ID
  Future<EquipmentModel?> getEquipmentById(String id) async {
    try {
      final doc = await _equipmentCollection. doc(id).get();
      if (doc.exists) {
        return EquipmentModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get equipment: $e');
    }
  }

  // Get all equipment
  Future<List<EquipmentModel>> getAllEquipment() async {
    try {
      final querySnapshot = await _equipmentCollection
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EquipmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get equipment: $e');
    }
  }

  // Get equipment by owner
  Future<List<EquipmentModel>> getEquipmentByOwner(String ownerId) async {
    try {
      final querySnapshot = await _equipmentCollection
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending:  true)
          .get();

      return querySnapshot.docs
          .map((doc) => EquipmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get owner equipment: $e');
    }
  }

  // Get equipment by category
  Future<List<EquipmentModel>> getEquipmentByCategory(EquipmentCategory category) async {
    try {
      final querySnapshot = await _equipmentCollection
          .where('category', isEqualTo: category.toString().split('.').last)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EquipmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get equipment by category: $e');
    }
  }

  // Search equipment by location
  Future<List<EquipmentModel>> searchByLocation(String location) async {
    try {
      final querySnapshot = await _equipmentCollection
          .where('location', isEqualTo: location)
          .where('isAvailable', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => EquipmentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search by location: $e');
    }
  }

  // Update equipment
  Future<void> updateEquipment(String id, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _equipmentCollection. doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update equipment: $e');
    }
  }

  // Delete equipment
  Future<void> deleteEquipment(String id) async {
    try {
      await _equipmentCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete equipment: $e');
    }
  }

  // Toggle availability
  Future<void> toggleAvailability(String id, bool isAvailable) async {
    try {
      await updateEquipment(id, {
        'isAvailable': isAvailable,
      });
    } catch (e) {
      throw Exception('Failed to toggle availability: $e');
    }
  }

  // Increment view count
  Future<void> incrementViewCount(String id) async {
    try {
      await _equipmentCollection.doc(id).update({
        'viewCount':  FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to increment view count: $e');
    }
  }

  // Stream of all equipment (real-time updates)
  Stream<List<EquipmentModel>> streamAllEquipment() {
    return _equipmentCollection
        . where('isAvailable', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EquipmentModel.fromFirestore(doc))
            .toList());
  }

  // Stream of owner's equipment
  Stream<List<EquipmentModel>> streamOwnerEquipment(String ownerId) {
    return _equipmentCollection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending:  true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EquipmentModel.fromFirestore(doc))
            .toList());
  }
}