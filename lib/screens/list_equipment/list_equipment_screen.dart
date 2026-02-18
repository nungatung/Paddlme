import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

import '../../widgets/location_picker.dart';
import '../main_navigation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ListEquipmentScreen extends StatefulWidget {
  const ListEquipmentScreen({super.key});

  @override
  State<ListEquipmentScreen> createState() => _ListEquipmentScreenState();
}

class _ListEquipmentScreenState extends State<ListEquipmentScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Services
  final _equipmentService = EquipmentService();
  final _storageService = StorageService();
  final _authService = AuthService();
  final _userService = UserService();

  // Form data
  EquipmentCategory? _selectedType;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerHourController = TextEditingController();
  String? _selectedLocation;
  final _beachController = TextEditingController();

  // Image handling
  final List<File> _selectedImages = [];
  final List<String> _photoUrls = [];
  final List<Uint8List> _selectedImageBytes = [];

  final List<String> _includedItems = [];
  final _newItemController = TextEditingController();

  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _unavailableDates = {};
  bool _availableAllDays = true;
  bool _isPublishing = false;

  // Delivery options
  bool _offersDelivery = false;
  bool _requiresPickup = true;
  final _deliveryFeeController = TextEditingController();
  final _deliveryRadiusController = TextEditingController();

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _beachController.dispose();
    _newItemController.dispose();
    _deliveryFeeController.dispose();
    _deliveryRadiusController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Step 0: Type selection
    if (_currentStep == 0 && _selectedType == null) {
      _showErrorSnackBar('Please select equipment type');
      return;
    }

    // Step 1: Basic details validation
    if (_currentStep == 1 && !_formKey.currentState!.validate()) {
      return;
    }

    // Step 2: Photo upload validation
    if (_currentStep == 2 && _photoUrls.isEmpty) {
      _showErrorSnackBar('Please add at least one photo');
      return;
    }

    // Step 3: Pricing validation
    if (_currentStep == 3 && !_formKey.currentState!.validate()) {
      return;
    }

    // Step 6: Location validation
    if (_currentStep == 6 && !_formKey.currentState!.validate()) {
      return;
    }

    // Step 7: Review - final step
    if (_currentStep < 7) {
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep++;
        });
        _animationController.forward();
      });
    } else {
      _publishListing();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _animationController.reverse().then((_) {
        setState(() {
          _currentStep--;
        });
        _animationController.forward();
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes.add(bytes);
          _photoUrls.add(image.path);
        });
      } else {
        final file = File(image.path);
        setState(() {
          _selectedImages.add(file);
          _photoUrls.add(image.path);
        });
      }
    }
  }

  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Add photos of your equipment',
          'Great photos help your listing stand out. Add at least one photo.',
        ),
        const SizedBox(height: 32),

        // Photo Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: _photoUrls.length + 1,
          itemBuilder: (context, index) {
            if (index == _photoUrls.length) {
              return _buildAddPhotoButton();
            }

            return _buildPhotoPreview(index);
          },
        ),

        if (_photoUrls.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildInfoCard(
            icon: Icons.info_outline,
            color: Colors.blue,
            title: 'The first photo will be your cover image',
          ),
        ],
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickImage,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(int index) {
    return Hero(
      tag: 'photo_$index',
      child: Material(
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              kIsWeb
                  ? Image.memory(
                      _selectedImageBytes[index],
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                    ),
              // Gradient overlay for better visibility of controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      setState(() {
                        if (kIsWeb) {
                          _selectedImageBytes.removeAt(index);
                        } else {
                          _selectedImages.removeAt(index);
                        }
                        _photoUrls.removeAt(index);
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Cover',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publishListing() async {
    if (_selectedLocation == null || _selectedLocation!.isEmpty) {
      _showErrorSnackBar('Please select a location');
      setState(() => _currentStep = 5);
      return;
    }

    setState(() => _isPublishing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Publishing your listing...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to create a listing');
      }

      final userData = await _userService.getUserByUid(currentUser.uid);
      if (userData == null) {
        throw Exception('User data not found');
      }

      List<String> uploadedImageUrls = [];

      if (_photoUrls.isNotEmpty) {
        try {
          final tempId = DateTime.now().millisecondsSinceEpoch.toString();

          if (kIsWeb) {
            uploadedImageUrls = await _storageService.uploadEquipmentImagesWeb(
              tempId,
              _selectedImageBytes,
            );
          } else {
            uploadedImageUrls = await _storageService.uploadEquipmentImages(
              tempId,
              _selectedImages,
            );
          }
        } catch (e) {
          debugPrint('Storage upload failed: $e');
          uploadedImageUrls = [
            'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800',
          ];
        }
      }

      final equipment = EquipmentModel(
        id: '',
        ownerId: currentUser.uid,
        ownerName: userData.name,
        ownerImageUrl: userData.profileImageUrl,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedType!,
        pricePerHour: double.parse(_pricePerHourController.text),
        imageUrls: uploadedImageUrls,
        location: _selectedLocation!,
        latitude: null,
        longitude: null,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        features: _includedItems,
        capacity: 1,
        offersDelivery: _offersDelivery,
        deliveryFee: _offersDelivery && _deliveryFeeController.text.isNotEmpty
            ? double.parse(_deliveryFeeController.text)
            : null,
        deliveryRadius:
            _offersDelivery && _deliveryRadiusController.text.isNotEmpty
                ? double.parse(_deliveryRadiusController.text)
                : null,
        requiresPickup: _requiresPickup,
      );

      final equipmentId = await _equipmentService.createEquipment(equipment);

      debugPrint('✅ Equipment created with ID: $equipmentId');

      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.all(32),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.2),
                        AppColors.success.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Listing Published!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your equipment is now available for rent. You\'ll receive notifications when someone books it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const MainNavigation()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }

      debugPrint('❌ Error publishing listing: $e');
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'List Equipment',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              children: [
                Row(
                  children: List.generate(8, (index) {
                    return Expanded(
                      child: Container(
                        height: 6,
                        margin: EdgeInsets.only(right: index < 7 ? 6 : 0),
                        decoration: BoxDecoration(
                          gradient: index <= _currentStep
                              ? LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          color: index <= _currentStep ? null : Colors.grey[200],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Step ${_currentStep + 1} of 8',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Step Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepContent(),
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: _currentStep == 0 ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  if (_currentStep > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          foregroundColor: Colors.grey[700],
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  _currentStep == 0
                    ? SizedBox(
                        width: 240,
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      )
                    : Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentStep < 7 ? 'Continue' : 'Publish Listing',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              if (_currentStep < 7) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ] else ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.publish_rounded, size: 20),
                              ],
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildTypeSelection();
      case 1:
        return _buildBasicDetails();
      case 2:
        return _buildPhotoUpload();
      case 3:
        return _buildPricing();
      case 4:
        return _buildDeliveryOptions();
      case 5:
        return _buildAvailability();
      case 6:
        return _buildLocation();
      case 7:
        return _buildReview();
      default:
        return Container();
    }
  }

  // Helper method for consistent step headers
  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Helper method for info cards
  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color.withOpacity(0.8), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(0.9),
                    height: 1.4,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Equipment Type
  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'What type of equipment are you listing?',
          'Select the category that best describes your equipment',
        ),
        const SizedBox(height: 32),
        _buildTypeCard(
          EquipmentCategory.kayak,
          Icons.kayaking_rounded,
          'Kayak',
          'Single or double kayaks',
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          EquipmentCategory.sup,
          Icons.surfing_rounded,
          'SUP Board',
          'Stand-up paddleboards',
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          EquipmentCategory.jetSki,
          Icons.directions_boat_rounded,
          'Jet Ski',
          'Personal watercraft',
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          EquipmentCategory.boat,
          Icons.sailing_rounded,
          'Boat',
          'Small boats and dinghies',
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          EquipmentCategory.other,
          Icons.waves_rounded,
          'Other',
          'Other water sports equipment',
        ),
      ],
    );
  }

  Widget _buildTypeCard(
      EquipmentCategory type, IconData icon, String title, String subtitle) {
    final isSelected = _selectedType == type;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedType = type;
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey[200]!,
                width: isSelected ? 2.5 : 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.15),
                              AppColors.primary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: isSelected ? AppColors.primary : Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primary : Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 2: Basic Details
  Widget _buildBasicDetails() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Tell us about your equipment',
            'Provide details that will help renters find and choose your listing',
          ),
          const SizedBox(height: 32),

          // Title
          _buildInputLabel('Listing Title'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _titleController,
            decoration: _buildInputDecoration(
              hintText: 'e.g. Seaflo Single Sit-On Kayak - Perfect for Bay Exploring',
              prefixIcon: Icons.title_rounded,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              if (value.length < 10) {
                return 'Title should be at least 10 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          // Description
          _buildInputLabel('Description'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _descriptionController,
            maxLines: 6,
            decoration: _buildInputDecoration(
              hintText: 'Describe your equipment, its condition, and what makes it special...',
              prefixIcon: Icons.description_outlined,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              if (value.length < 50) {
                return 'Description should be at least 50 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          // What's Included
          _buildInputLabel("What's Included"),
          const SizedBox(height: 6),
          Text(
            'Add items that come with the rental',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // Included items list
          if (_includedItems.isNotEmpty) ...[
            ..._includedItems.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              _includedItems.remove(item);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Add item field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newItemController,
                  decoration: _buildInputDecoration(
                    hintText: 'e.g. Life jacket',
                    prefixIcon: Icons.add_circle_outline_rounded,
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() {
                        _includedItems.add(value.trim());
                        _newItemController.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_newItemController.text.trim().isNotEmpty) {
                    setState(() {
                      _includedItems.add(_newItemController.text.trim());
                      _newItemController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(56, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Icon(Icons.add_rounded, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.grey[400], size: 22)
          : null,
      suffixIcon: suffixIcon,
      helperText: helperText,
      helperStyle: TextStyle(
        color: Colors.grey[500],
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.error.withOpacity(0.5), width: 1.5),
      ),
    );
  }

  // Step 4: Pricing
  Widget _buildPricing() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Set your price',
            'You can always change this later',
          ),
          const SizedBox(height: 32),

          // Price per hour
          _buildInputLabel('Price per hour'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _pricePerHourController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: _buildInputDecoration(
              hintText: '35',
              prefixIcon: Icons.attach_money_rounded,
            ).copyWith(
              prefixText: 'NZ\$ ',
              prefixStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a price';
              }
              final price = int.tryParse(value);
              if (price == null || price < 10) {
                return 'Minimum price is NZ\$10';
              }
              return null;
            },
          ),

          const SizedBox(height: 40),

          // Pricing suggestions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[50]!,
                  Colors.green[50]!.withOpacity(0.5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: Colors.green[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Pricing Tips',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.green[900],
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTip('Single kayaks generally rent for \$30-40/hour'),
                _buildTip('Double kayaks generally rent for \$40-50/hour'),
                _buildTip('Stand-up Paddle Boards generally rent for \$30-35/hour'),
                _buildTip('Jet Skis generally rent for \$160-200/hour'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green[400],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.green[800],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 5: Delivery Options
  Widget _buildDeliveryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Delivery Options',
          'How will renters get your equipment?',
        ),
        const SizedBox(height: 32),

        // Pickup Option
        _buildOptionCard(
          title: 'Allow Pickup',
          subtitle: 'Renters can collect equipment from you',
          icon: Icons.storefront_rounded,
          value: _requiresPickup,
          onChanged: (value) => setState(() => _requiresPickup = value),
          color: Colors.orange,
        ),

        const SizedBox(height: 16),

        // Delivery Option
        _buildOptionCard(
          title: 'Offer Delivery',
          subtitle: 'You can deliver equipment to renters',
          icon: Icons.local_shipping_rounded,
          value: _offersDelivery,
          onChanged: (value) => setState(() => _offersDelivery = value),
          color: AppColors.primary,
        ),

        // Delivery Details (show only if delivery is enabled)
        if (_offersDelivery) ...[
          const SizedBox(height: 32),

          // Delivery Fee
          _buildInputLabel('Delivery Fee (NZD)'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _deliveryFeeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: _buildInputDecoration(
              hintText: '20',
              prefixIcon: Icons.attach_money_rounded,
              helperText: 'One-time fee for delivery and pickup',
            ).copyWith(
              prefixText: 'NZ\$ ',
              prefixStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 24),

          // Delivery Radius
          _buildInputLabel('Delivery Radius (km)'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _deliveryRadiusController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: _buildInputDecoration(
              hintText: '10',
              prefixIcon: Icons.radar_rounded,
              helperText: 'Maximum distance you\'ll deliver',
            ).copyWith(
              suffixText: 'km',
              suffixStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Info box
        _buildInfoCard(
          icon: Icons.info_outline_rounded,
          color: Colors.blue,
          title: 'Delivery Tips',
          subtitle: '• Offering delivery can increase bookings\n'
              '• Set a fair fee to cover your time and fuel\n'
              '• You can update these options anytime',
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.grey[200]!,
          width: value ? 2 : 1.5,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value ? color.withOpacity(0.1) : Colors.grey[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: value ? color : Colors.grey[500],
              size: 26,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: value ? color : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  // Step 6: Availability Calendar
  Widget _buildAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Set your availability',
          'Mark dates when your equipment is not available',
        ),
        const SizedBox(height: 32),

        // Available all days toggle
        _buildOptionCard(
          title: 'Available every day',
          subtitle: 'Your equipment is always available',
          icon: Icons.event_available_rounded,
          value: _availableAllDays,
          onChanged: (value) {
            setState(() {
              _availableAllDays = value;
              if (value) {
                _unavailableDates.clear();
              }
            });
          },
          color: AppColors.success,
        ),

        const SizedBox(height: 28),

        // Calendar (only show if not available all days)
        if (!_availableAllDays) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Block unavailable dates',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap dates to mark them as unavailable',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return _unavailableDates.any((d) => isSameDay(d, day));
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (selectedDay.isBefore(
                        DateTime.now().subtract(const Duration(days: 1)))) {
                      return;
                    }

                    setState(() {
                      _focusedDay = focusedDay;

                      if (_unavailableDates
                          .any((d) => isSameDay(d, selectedDay))) {
                        _unavailableDates
                            .removeWhere((d) => isSameDay(d, selectedDay));
                      } else {
                        _unavailableDates.add(selectedDay);
                      }
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.error.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(6),
                    defaultTextStyle: const TextStyle(fontSize: 15),
                    weekendTextStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.red[400],
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.grey[700],
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Legend
                Row(
                  children: [
                    _buildLegendItem(
                      AppColors.primary.withOpacity(0.2),
                      'Today',
                      isToday: true,
                    ),
                    const SizedBox(width: 20),
                    _buildLegendItem(AppColors.error, 'Unavailable'),
                  ],
                ),
                if (_unavailableDates.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_unavailableDates.length} date(s) marked as unavailable',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.error.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Info box
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            color: Colors.blue,
            title: 'You can update availability anytime',
            subtitle: 'Manage your calendar from your profile after publishing',
          ),

          // Quick unavailability options
          const SizedBox(height: 28),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickActionChip(
                'Block next 7 days',
                Icons.date_range_rounded,
                () {
                  setState(() {
                    for (int i = 0; i < 7; i++) {
                      _unavailableDates
                          .add(DateTime.now().add(Duration(days: i)));
                    }
                  });
                },
              ),
              _buildQuickActionChip(
                'Block weekends',
                Icons.weekend_rounded,
                () {
                  setState(() {
                    for (int i = 0; i < 60; i++) {
                      final date = DateTime.now().add(Duration(days: i));
                      if (date.weekday == DateTime.saturday ||
                          date.weekday == DateTime.sunday) {
                        _unavailableDates.add(date);
                      }
                    }
                  });
                },
              ),
              _buildQuickActionChip(
                'Clear all',
                Icons.clear_all_rounded,
                () {
                  setState(() {
                    _unavailableDates.clear();
                  });
                },
                isDestructive: true,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isToday = false}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return ActionChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isDestructive ? Colors.red[600] : AppColors.primary,
      ),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: isDestructive ? Colors.red[50] : Colors.white,
      side: BorderSide(
        color: isDestructive ? Colors.red[200]! : Colors.grey[300]!,
      ),
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDestructive ? Colors.red[700] : Colors.black87,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // Step 7: Location
  Widget _buildLocation() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Where are you located?',
            'Renters will use this to find equipment near them',
          ),
          const SizedBox(height: 32),

          // Beach/Location Name
          _buildInputLabel('Beach or Location Name'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _beachController,
            decoration: _buildInputDecoration(
              hintText: 'e.g. Stanmore Bay Beach',
              prefixIcon: Icons.beach_access_rounded,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
          ),

          const SizedBox(height: 28),

          // General Location with MapTiler picker
          _buildInputLabel('General Area'),
          const SizedBox(height: 10),
          LocationPicker(
            selectedLocation: _selectedLocation,
            onLocationSelected: (location) {
              setState(() => _selectedLocation = location);
            },
          ),

          const SizedBox(height: 28),

          _buildInfoCard(
            icon: Icons.privacy_tip_outlined,
            color: Colors.purple,
            title: 'Your exact address won\'t be shared',
          ),
        ],
      ),
    );
  }

  // Step 8: Review
  Widget _buildReview() {
    final String typeEmoji = _selectedType?.icon ?? '🌊';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Review your listing',
          'Make sure everything looks good before publishing',
        ),
        const SizedBox(height: 24),

        // Preview Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image - show local file
              if (_selectedImages.isNotEmpty)
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Stack(
                    children: [
                      kIsWeb
                          ? Image.network(
                              _photoUrls.first,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              _selectedImages.first,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                            ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Price badge
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'NZ\$',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                _pricePerHourController.text,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '/hr',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        typeEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Title
                    Text(
                      _titleController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _beachController.text,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Divider(color: Colors.grey[200], thickness: 1),
                    const SizedBox(height: 24),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _descriptionController.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),

                    if (_includedItems.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[200], thickness: 1),
                      const SizedBox(height: 24),
                      const Text(
                        "What's Included",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _includedItems.map((item) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],

                    // Location display
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[200], thickness: 1),
                      const SizedBox(height: 24),
                      const Text(
                        'Location Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.location_on_rounded,
                        _selectedLocation!,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        Icons.beach_access_rounded,
                        _beachController.text,
                      ),
                    ],

                    // Availability info
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey[200], thickness: 1),
                    const SizedBox(height: 24),
                    const Text(
                      'Availability',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_availableAllDays && _unavailableDates.isNotEmpty)
                      _buildStatusCard(
                        icon: Icons.event_busy_rounded,
                        color: Colors.orange,
                        text: '${_unavailableDates.length} unavailable date(s) set',
                      )
                    else
                      _buildStatusCard(
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                        text: 'Available every day',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Edit buttons
        const Text(
          'Need to make changes?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 16),
        _buildEditButton('Edit Details', 1, Icons.edit_note_rounded),
        _buildEditButton('Edit Photos', 2, Icons.photo_library_rounded),
        _buildEditButton('Edit Pricing', 3, Icons.attach_money_rounded),
        _buildEditButton('Edit Delivery & Pickup', 4, Icons.local_shipping_rounded),
        _buildEditButton('Edit Availability', 5, Icons.calendar_today_rounded),
        _buildEditButton('Edit Location', 6, Icons.location_on_rounded),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(String text, int step, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentStep = step;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}