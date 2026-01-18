import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Upload profile picture (MOBILE - File)
  Future<String> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference ref =
          _storage.ref().child('profile_pictures').child(fileName);

      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // ✅ Upload profile picture (WEB - Uint8List bytes)
  Future<String> uploadProfilePictureWeb(
      String userId, Uint8List imageBytes) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference ref =
          _storage.ref().child('profile_pictures').child(fileName);

      final UploadTask uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image (web): $e');
    }
  }

  // Delete profile picture
  Future<void> deleteProfilePicture(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // ✅ Upload multiple equipment images (MOBILE - File)
  Future<List<String>> uploadEquipmentImages(
      String equipmentId, List<File> imageFiles) async {
    try {
      final List<String> uploadedUrls = [];

      for (int i = 0; i < imageFiles.length; i++) {
        final String fileName = '${equipmentId}_$i.jpg';
        final Reference ref =
            _storage.ref().child('equipment_images').child(fileName);

        final UploadTask uploadTask = ref.putFile(imageFiles[i]);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        uploadedUrls.add(downloadUrl);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload equipment images: $e');
    }
  }

  // ✅ NEW:  Upload multiple equipment images (WEB - Uint8List bytes)
  Future<List<String>> uploadEquipmentImagesWeb(
      String equipmentId, List<Uint8List> imageBytes) async {
    try {
      final List<String> uploadedUrls = [];

      for (int i = 0; i < imageBytes.length; i++) {
        final String fileName = '${equipmentId}_$i.jpg';
        final Reference ref =
            _storage.ref().child('equipment_images').child(fileName);

        // ✅ Use putData for web (bytes instead of File)
        final UploadTask uploadTask = ref.putData(
          imageBytes[i],
          SettableMetadata(contentType: 'image/jpeg'),
        );

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        uploadedUrls.add(downloadUrl);
      }

      return uploadedUrls;
    } catch (e) {
      throw Exception('Failed to upload equipment images (web): $e');
    }
  }

  // Delete multiple equipment images
  Future<void> deleteEquipmentImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        final Reference ref = _storage.refFromURL(url);
        await ref.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete equipment images: $e');
    }
  }
}
