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
import '../../services/location_service.dart';
import '../../widgets/location_picker.dart';
import '../main_navigation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ListEquipmentScreen extends StatefulWidget {
  const ListEquipmentScreen({super. key});

  @override
  State<ListEquipmentScreen> createState() => _ListEquipmentScreenState();
}

class _ListEquipmentScreenState extends State<ListEquipmentScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  
  // Services
  final _equipmentService = EquipmentService();
  final _storageService = StorageService();
  final _authService = AuthService();
  final _userService = UserService();

  // Form data
  EquipmentCategory?  _selectedType;  // ✅ Changed from EquipmentType
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pricePerHourController = TextEditingController();  // ✅ Renamed
  String? _selectedLocation;  // ✅ Changed
  final _beachController = TextEditingController();
  
  // Image handling
  final List<File> _selectedImages = [];  // ✅ Changed to File list
  final List<String> _photoUrls = [];  // Keep for preview
  final List<Uint8List> _selectedImageBytes = [];  // For web
  
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


  
  
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _beachController.dispose();
    _newItemController.dispose();
    _deliveryFeeController.dispose();
    _deliveryRadiusController.dispose();
    super.dispose();
  }

  
  void _nextStep() {
  // Step 0: Type selection
  if (_currentStep == 0 && _selectedType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select equipment type'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  // Step 1: Basic details validation
  if (_currentStep == 1 && ! _formKey.currentState!.validate()) {
    return;
  }

  // Step 2: Photo upload validation
  if (_currentStep == 2 && _photoUrls.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please add at least one photo'),
        backgroundColor: AppColors.error,
      ),
    );
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
    setState(() {
      _currentStep++;
    });
  } else {
    _publishListing();
  }
}

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
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
        // For web:  store bytes
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes.add(bytes);
          _photoUrls.add(image.path);
        });
      } else {
        // For mobile: store file
        final file = File(image.path);
        setState(() {
          _selectedImages.add(file);
          _photoUrls.add(image.path);
        });
      }
    }
  }

  // Update photo grid to show local files
  Widget _buildPhotoUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add photos of your equipment',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Great photos help your listing stand out.  Add at least one photo.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),

        // Photo Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:  2,
            crossAxisSpacing: 16,
            mainAxisSpacing:  16,
            childAspectRatio: 1,
          ),
          itemCount:  _photoUrls.length + 1,  // ✅ FIXED:  Use _photoUrls instead
          itemBuilder: (context, index) {
            if (index == _photoUrls.length) {  // ✅ FIXED
              // Add photo button
              return InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child:  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:  AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Photo preview - show local file
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: kIsWeb
                      ? Image. memory(
                          _selectedImageBytes[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          _selectedImages[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () {
                        setState(() {
                          if (kIsWeb) {
                            _selectedImageBytes.removeAt(index);  // ✅ Remove from bytes
                          } else {
                            _selectedImages.removeAt(index);  // ✅ Remove from files
                          }
                          _photoUrls.removeAt(index);  // ✅ Always remove from URLs
                        });
                        debugPrint('✅ Image removed. Total: ${_photoUrls.length}');
                      },
                    ),
                  ),
                ),
                if (index == 0)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Cover',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),

        if (_photoUrls.isNotEmpty) ...[  // ✅ FIXED:  Use _photoUrls
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children:  [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The first photo will be your cover image',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors. blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

Future<void> _publishListing() async {
  // Validate location is selected
  if (_selectedLocation == null || _selectedLocation! .isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a location'),
        backgroundColor: AppColors.error,
      ),
    );
    setState(() => _currentStep = 5); // Go back to location step
    return;
  }

  setState(() => _isPublishing = true);

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          SizedBox(height: 16),
          Text('Publishing your listing...'),
        ],
      ),
    ),
  );

  try {
    // Get current user
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to create a listing');
    }

    // Get user data
    final userData = await _userService.getUserByUid(currentUser.uid);
    if (userData == null) {
      throw Exception('User data not found');
    }

    // Step 1: Upload images to Firebase Storage
  List<String> uploadedImageUrls = [];

  if (_photoUrls.isNotEmpty) {  // ✅ Check _photoUrls
    try {
      final tempId = DateTime.now().millisecondsSinceEpoch. toString();
      
      if (kIsWeb) {
        // ✅ For web: upload bytes
        uploadedImageUrls = await _storageService.uploadEquipmentImagesWeb(
          tempId,
          _selectedImageBytes,
        );
      } else {
        // ✅ For mobile:  upload files
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

    // Step 2: Create equipment model
    final equipment = EquipmentModel(
      id: '', // Will be set by Firestore
      ownerId: currentUser.uid,
      ownerName: userData.name,
      ownerImageUrl: userData.profileImageUrl,
      title: _titleController.text. trim(),
      description: _descriptionController.text.trim(),
      category: _selectedType! ,
      pricePerHour: double.parse(_pricePerHourController.text),
      imageUrls: uploadedImageUrls,
      location: _selectedLocation!,
      latitude: null, // Can add coordinates later
      longitude: null,
      isAvailable: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      features: _includedItems,
      capacity: 1, // Can make this customizable later
      offersDelivery: _offersDelivery,
      deliveryFee: _offersDelivery && _deliveryFeeController.text.isNotEmpty
          ? double.parse(_deliveryFeeController.text)
          : null,
      deliveryRadius: _offersDelivery && _deliveryRadiusController.text.isNotEmpty
          ? double.parse(_deliveryRadiusController. text)
          : null,
      requiresPickup: _requiresPickup,
    );

    // Step 3: Save to Firestore
    final equipmentId = await _equipmentService.createEquipment(equipment);

    debugPrint('✅ Equipment created with ID: $equipmentId');

    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    // Step 4: Show success dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors. success,
                  size: 32,
                ),
              ),
              const SizedBox(width:  16),
              const Expanded(
                child: Text('Listing Published! '),
              ),
            ],
          ),
          content: const Text(
            'Your equipment is now available for rent.  You\'ll receive notifications when someone books it.',
          ),
          actions: [
            TextButton(
              onPressed:  () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainNavigation()),
                  (route) => false,
                );
              },
              child: const Text('Done'),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    // Close loading dialog
    if (mounted) {
      Navigator.pop(context);
    }

    // Show error
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('List Equipment'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: List.generate(8, (index) {  // ✅ Changed from 7 to 8
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 7 ? 8 :  0),  // ✅ Changed
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? AppColors.primary
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  'Step ${_currentStep + 1} of 8',  // ✅ Changed from 7 to 8
                  style:  TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Step Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors. white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius:  10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 56),
                          side: BorderSide(color: Colors.grey[300]! ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton. styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 56),
                      ),
                      child: Text(
                        _currentStep < 7 ? 'Continue' : 'Publish Listing',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
        return _buildDeliveryOptions(); // New
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

  // Step 1: Equipment Type
  Widget _buildTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What type of equipment are you listing?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the category that best describes your equipment',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),
        
        _buildTypeCard(
          EquipmentCategory.kayak,
          Icons.kayaking,
          'Kayak',
          'Single or tandem kayaks',
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          EquipmentCategory.sup,
          Icons.surfing,
          'SUP Board',
          'Stand-up paddleboards',
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          EquipmentCategory.jetSki,
          Icons.directions_boat,
          'Jet Ski',
          'Personal watercraft',
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          EquipmentCategory.boat,
          Icons.sailing,
          'Boat',
          'Small boats and dinghies',
        ),
        const SizedBox(height: 16),
        _buildTypeCard(
          EquipmentCategory.other,
          Icons.waves,
          'Other',
          'Other water sports equipment',
        ),
      ],
    );
  }

  Widget _buildTypeCard(EquipmentCategory type, IconData icon, String title, String subtitle) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets. all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary. withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ?  AppColors.primary :  Colors.grey[600],
              ),
            ),
            const SizedBox(width:  16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:  TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.black87,
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
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 28,
              ),
          ],
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
          const Text(
            'Tell us about your equipment',
            style: TextStyle(
              fontSize:  24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide details that will help renters find and choose your listing',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height:  32),

          // Title
          const Text(
            'Listing Title',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'e.g.  Ocean Kayak Scrambler - Perfect for Bay Exploring',
              filled: true,
              fillColor:  Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius. circular(12),
                borderSide: BorderSide(color: Colors.grey[300]! ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
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

          const SizedBox(height:  24),

          // Description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Describe your equipment, its condition, and what makes it special.. .',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
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

          const SizedBox(height:  24),

          // What's Included
          const Text(
            "What's Included",
            style: TextStyle(
              fontSize:  16,
              fontWeight:  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items that come with the rental',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),

          // Included items list
          ..._includedItems.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors. white,
                  borderRadius:  BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors. success, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(item),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                      onPressed: () {
                        setState(() {
                          _includedItems.remove(item);
                        });
                      },
                    ),
                  ],
                ),
              )),

          // Add item field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newItemController,
                  decoration:  InputDecoration(
                    hintText: 'e.g. Life jacket',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:  BorderSide(color: Colors. grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
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
                      _includedItems.add(_newItemController. text.trim());
                      _newItemController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors. white,
                  minimumSize: const Size(56, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: Photo Upload - removed duplicate, using the one at line 131


  // Step 4:  Pricing
  Widget _buildPricing() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set your price',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can always change this later',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Price per hour
          const Text(
            'Price per hour',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pricePerHourController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: '35',
              filled: true,
              fillColor:  Colors.white,
              prefixText: 'NZ\$: ',
              prefixStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,    
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius. circular(12),
                borderSide: BorderSide(color:  Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            validator: (value) {
              if (value == null || value. isEmpty) {
                return 'Please enter a price';
              }
              final price = int.tryParse(value);
              if (price == null || price < 10) {
                return 'Minimum price is NZ\$10';
              }
              return null;
            },
          ),

          const SizedBox(height:  32),

          // Pricing suggestions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius:  BorderRadius.circular(16),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Text(
                      'Pricing Tips',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTip('Similar kayaks rent for \$30-45/hour'),

              ],
            ),
          ),

          const SizedBox(height:  24),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.green[800],
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
      const Text(
        'Delivery Options',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'How will renters get your equipment?',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: 32),

      // Pickup Option
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]! ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Allow Pickup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:  FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Renters can collect equipment from you',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors. grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _requiresPickup,
              onChanged: (value) {
                setState(() => _requiresPickup = value);
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      // Delivery Option
      Container(
        padding:  const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offer Delivery',
                    style:  TextStyle(
                      fontSize:  16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can deliver equipment to renters',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value:  _offersDelivery,
              onChanged: (value) {
                setState(() => _offersDelivery = value);
              },
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),

      // Delivery Details (show only if delivery is enabled)
      if (_offersDelivery) ...[
        const SizedBox(height: 24),

        // Delivery Fee
        const Text(
          'Delivery Fee (NZD)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight. w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _deliveryFeeController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: '20',
            filled: true,
            fillColor:  Colors.white,
            prefixText: 'NZ\$ ',
            prefixStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            helperText: 'One-time fee for delivery and pickup',
            border: OutlineInputBorder(
              borderRadius: BorderRadius. circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        // Delivery Radius
        const Text(
          'Delivery Radius (km)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _deliveryRadiusController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter. digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: '10',
            filled: true,
            fillColor: Colors.white,
            suffixText: 'km',
            suffixStyle: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            helperText: 'Maximum distance you\'ll deliver',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],

      const SizedBox(height:  24),

      // Info box
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Tips',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Offering delivery can increase bookings\n'
                    '• Set a fair fee to cover your time and fuel\n'
                    '• You can update these options anytime',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[800],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  
  // Step 6: Availability Calendar
  Widget _buildAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Set your availability',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mark dates when your equipment is NOT available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 32),

        // Available all days toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]! ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available every day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your equipment is always available',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors. grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _availableAllDays,
                onChanged: (value) {
                  setState(() {
                    _availableAllDays = value;
                    if (value) {
                      _unavailableDates.clear();
                    }
                  });
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Calendar (only show if not available all days)
        if (!_availableAllDays) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border. all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Block unavailable dates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap dates to mark them as unavailable',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime. now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) {
                    return _unavailableDates.any((d) => isSameDay(d, day));
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (selectedDay. isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
                      return;
                    }
                    
                    setState(() {
                      _focusedDay = focusedDay;
                      
                      if (_unavailableDates.any((d) => isSameDay(d, selectedDay))) {
                        _unavailableDates.removeWhere((d) => isSameDay(d, selectedDay));
                      } else {
                        _unavailableDates. add(selectedDay);
                      }
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color:  AppColors.primary. withOpacity(0.3),
                      shape: BoxShape. circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Row(
                  children: [
                    _buildLegendItem(AppColors.primary. withOpacity(0.3), 'Today'),
                    const SizedBox(width: 16),
                    _buildLegendItem(AppColors.error, 'Unavailable'),
                  ],
                ),
                if (_unavailableDates.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '${_unavailableDates.length} date(s) marked as unavailable',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Info box
          Container(
            padding:  const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You can update availability anytime',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your calendar from your profile after publishing',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors. blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Quick unavailability options
        if (! _availableAllDays) ...[
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildQuickActionChip(
                'Block next 7 days',
                () {
                  setState(() {
                    for (int i = 0; i < 7; i++) {
                      _unavailableDates.add(DateTime.now().add(Duration(days: i)));
                    }
                  });
                },
              ),
              _buildQuickActionChip(
                'Block weekends',
                () {
                  setState(() {
                    for (int i = 0; i < 60; i++) {
                      final date = DateTime.now().add(Duration(days: i));
                      if (date.weekday == DateTime.saturday || date.weekday == DateTime. sunday) {
                        _unavailableDates.add(date);
                      }
                    }
                  });
                },
              ),
              _buildQuickActionChip(
                'Clear all',
                () {
                  setState(() {
                    _unavailableDates.clear();
                  });
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height:  16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape. circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style:  TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey[300]! ),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
  
  
 // Step 7: Location
  Widget _buildLocation() {
    return Form(
      key: _formKey,  // ✅ Add this Form wrapper
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where are you located?',
            style:  TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Renters will use this to find equipment near them',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Beach/Location Name
          const Text(
            'Beach or Location Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _beachController,
            decoration: InputDecoration(
              hintText: 'e.g.  Stanmore Bay Beach',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.beach_access),
              border: OutlineInputBorder(
                borderRadius: BorderRadius. circular(12),
                borderSide: BorderSide(color: Colors.grey[300]! ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            validator: (value) {
              if (value == null || value. isEmpty) {
                return 'Please enter a location';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // ✅ General Location with MapTiler picker
          const Text(
            'General Area',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LocationPicker(
            selectedLocation: _selectedLocation,
            onLocationSelected:  (location) {
              setState(() => _selectedLocation = location);
            },
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your exact address won\'t be shared until a booking is confirmed',
                    style:  TextStyle(
                      fontSize: 13,
                      color: Colors. blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

 // Step 8: Review
  Widget _buildReview() {
    final String typeEmoji = _selectedType?.icon ?? '🌊';  // ✅ Use category icon

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review your listing',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Make sure everything looks good before publishing',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height:  32),

        // Preview Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image - show local file
              if (_selectedImages. isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: kIsWeb  // ✅ Check if running on web
                      ? Image.network(
                          _photoUrls. first,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          _selectedImages.first,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      _titleController.text,
                      style: const TextStyle(
                        fontSize:  20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Type & Location
                    Row(
                      children: [
                        Text(
                          typeEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on, size: 16, color: Colors. grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _beachController.text,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors. grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Prices (both per hour and per day)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'NZ \$',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              _pricePerHourController.text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '/hour',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _descriptionController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    // ...  rest of your existing review content (included items, availability, etc.)
                    
                    if (_includedItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        "What's Included",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._includedItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                                const SizedBox(width: 12),
                                Text(item, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          )),
                    ],

                    // Location display
                    if (_selectedLocation != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedLocation! ,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.beach_access, size: 18, color: Colors.grey[600]),
                          const SizedBox(width:  8),
                          Expanded(
                            child: Text(
                              _beachController.text,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Availability info (your existing code)
                    if (! _availableAllDays && _unavailableDates.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border. all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event_busy, size: 18, color: Colors.orange[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_unavailableDates. length} unavailable date(s) set',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_availableAllDays) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:  FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height:  12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius:  BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Available every day',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Edit buttons (your existing code)
        _buildEditButton('Edit Details', 1),
        _buildEditButton('Edit Photos', 2),
        _buildEditButton('Edit Pricing', 3),
        _buildEditButton('Edit Delivery & Pickup', 4),
        _buildEditButton('Edit Availability', 5),
        _buildEditButton('Edit Location', 6),
      ],
    );
  }

  Widget _buildEditButton(String text, int step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _currentStep = step;
          });
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:  [
            Text(text),
            const Icon(Icons.edit, size: 18),
          ],
        ),
      ),
    );
  }
}