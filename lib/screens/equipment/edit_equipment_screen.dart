import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../models/equipment_model.dart';
import '../../services/equipment_service.dart';
import '../../widgets/location_picker.dart';

class EditEquipmentScreen extends StatefulWidget {
  final EquipmentModel equipment;

  const EditEquipmentScreen({
    super.key,
    required this. equipment,
  });

  @override
  State<EditEquipmentScreen> createState() => _EditEquipmentScreenState();
}

class _EditEquipmentScreenState extends State<EditEquipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _equipmentService = EquipmentService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _pricePerHourController;
  late TextEditingController _beachController;
  
  String? _selectedLocation;
  List<String> _includedItems = [];
  final _newItemController = TextEditingController();
  bool _isAvailable = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing values
    _titleController = TextEditingController(text: widget.equipment.title);
    _descriptionController = TextEditingController(text: widget.equipment.description);
    _pricePerHourController = TextEditingController(
      text: widget.equipment.pricePerHour.toStringAsFixed(0),
    );
    _beachController = TextEditingController(text: widget.equipment.location);
    _selectedLocation = widget.equipment.location;
    _includedItems = List.from(widget.equipment.features);
    _isAvailable = widget.equipment.isAvailable;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pricePerHourController.dispose();
    _beachController. dispose();
    _newItemController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!. validate()) return;

    setState(() => _isSaving = true);

    try {
      // Update equipment data
      await _equipmentService. updateEquipment(widget.equipment.id, {
        'title': _titleController.text. trim(),
        'description': _descriptionController.text.trim(),
        'pricePerHour':  double.parse(_pricePerHourController. text),
        'location': _selectedLocation ?? _beachController.text.trim(),
        'features': _includedItems,
        'isAvailable': _isAvailable,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Equipment updated successfully!  🎉'),
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
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteEquipment() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: const Text(
          'Are you sure you want to delete this listing?  This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);

      try {
        await _equipmentService.deleteEquipment(widget.equipment.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Equipment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Go back and refresh
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting:  $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
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
          'Edit Equipment',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _deleteEquipment,
          ),
          // Save button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
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
            // Availability Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isAvailable ? Colors.green[50] : Colors.orange[50],
                borderRadius:  BorderRadius.circular(12),
                border: Border.all(
                  color: _isAvailable ? Colors.green[200]! : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isAvailable ? Icons.check_circle : Icons.pause_circle,
                    color: _isAvailable ? Colors.green[700] : Colors.orange[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:  CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isAvailable ?  'Available for Rent' : 'Unavailable',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isAvailable ? Colors.green[900] : Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isAvailable
                              ? 'Your equipment can be booked'
                              : 'Your equipment is hidden from search',
                          style: TextStyle(
                            fontSize: 13,
                            color: _isAvailable ? Colors.green[800] : Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAvailable,
                    onChanged: (value) {
                      setState(() => _isAvailable = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                hintText: 'e.g. Ocean Kayak Scrambler',
                filled: true,
                fillColor:  Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
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
                hintText: 'Describe your equipment...',
                filled: true,
                fillColor:  Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Price
            const Text(
              'Price per hour (NZD)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller:  _pricePerHourController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                prefixText: 'NZ\$ ',
                prefixStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius:  BorderRadius.circular(12),
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

            const SizedBox(height: 24),

            // Location
            const Text(
              'Beach or Location',
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
                fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.beach_access),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a location';
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
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border. all(color: Colors.grey[300]! ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
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
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
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
                    foregroundColor: Colors.white,
                    minimumSize: const Size(56, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius:  BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changes will be saved immediately. Photos and category cannot be edited.',
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
        ),
      ),
    );
  }
}