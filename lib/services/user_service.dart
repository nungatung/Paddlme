import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wave_share/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create user document in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection. doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Get user by UID
  Future<UserModel?> getUserByUid(String uid) async {
    try {
      final doc = await _usersCollection. doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // ✅ Get email by username (for login)
  Future<String?> getEmailByUsername(String username) async {
    try {
      final querySnapshot = await _usersCollection
          .where('username', isEqualTo: username. toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first. data() as Map<String, dynamic>;
        return userData['email'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get email by username: $e');
    }
  }

  // ✅ Check if username exists (for validation)
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _usersCollection
          .where('username', isEqualTo: username. toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check username:  $e');
    }
  }

  // Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection. doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}