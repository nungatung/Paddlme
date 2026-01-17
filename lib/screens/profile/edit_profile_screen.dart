import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wave_share/core/theme/app_colors.dart';
import 'package:wave_share/models/user_model.dart';
import 'package:wave_share/services/user_service.dart';
import 'package:wave_share/services/storage_service.dart';
import 'package:wave_share/services/auth_service.dart';
import 'package:wave_share/widgets/location_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({
    super.key,
    required this. user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userService = UserService();
  final _storageService = StorageService();
  final _authService = AuthService();

  File? _selectedImage;
  String? _selectedLocation;
  bool _isLoading = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user. name;
    _bioController. text = widget.user.bio ??  '';
    _phoneController.text = widget.user.phoneNumber ?? '';
    _selectedLocation = widget.user.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context:  context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child:  Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap:  () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromGallery();
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                    _imageChanged = true;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap:  () async {
                Navigator.pop(context);
                final image = await _storageService.pickImageFromCamera();
                if (image != null) {
                  setState(() {
                    _selectedImage = image;
                    _imageChanged = true;
                  });
                }
              },
            ),
            if (widget.user.profileImageUrl != null || _selectedImage != null)
              ListTile(
                leading:  const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _imageChanged = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState! .validate()) return;

    setState(() => _isLoading = true);

    try {
      String? profileImageUrl = widget.user.profileImageUrl;

      // Upload new profile picture if changed
      if (_imageChanged) {
        if (_selectedImage != null) {
          // Delete old image if exists
          if (widget.user.profileImageUrl != null) {
            try {
              await _storageService.deleteProfilePicture(widget.user.profileImageUrl!);
            } catch (e) {
              debugPrint('Error deleting old image: $e');
            }
          }
          
          // Upload new image
          profileImageUrl = await _storageService.uploadProfilePicture(
            widget.user.uid,
            _selectedImage!,
          );
        } else {
          // Remove profile picture
          if (widget.user.profileImageUrl != null) {
            try {
              await _storageService. deleteProfilePicture(widget. user.profileImageUrl!);
            } catch (e) {
              debugPrint('Error deleting image: $e');
            }
          }
          profileImageUrl = null;
        }
      }

      // Update user data
      await _userService.updateUser(widget.user.uid, {
        'name': _nameController.text. trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text. trim(),
        'location': _selectedLocation,
        'phoneNumber': _phoneController.text.trim().isEmpty ? null : _phoneController. text.trim(),
        'profileImageUrl': profileImageUrl,
      });

      // Update Firebase Auth display name
      await _authService. currentUser?.updateDisplayName(_nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!  🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:  Text('Error:  $e'),
            backgroundColor: Colors. red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:  const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isLoading ? null : _saveProfile,
              child: _isLoading
                  ? const SizedBox(
                      width:  20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Picture
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : widget.user.profileImageUrl != null
                            ? NetworkImage(widget.user.profileImageUrl!) as ImageProvider
                            : null,
                    child: _selectedImage == null && widget.user.profileImageUrl == null
                        ? Icon(Icons.person, size: 60, color: Colors.grey[400])
                        : null,
                  ),
                  Positioned(
                    bottom:  0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child:  Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText:  'Name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius. circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Bio
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others about yourself.. .',
                prefixIcon: const Icon(Icons. edit_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            LocationPicker(
              selectedLocation: _selectedLocation,
              onLocationSelected: (location) {
                setState(() => _selectedLocation = location);
              },
            ),

            const SizedBox(height: 16),

            // Phone Number
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                hintText: '+64 21 123 4567',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]! ),
              ),
              child:  Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your profile helps renters learn more about you! ',
                      style: TextStyle(
                        color: Colors. blue[900],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}