import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class EditRentRequestScreen extends StatefulWidget {
  final RequestModel request;
  
  const EditRentRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<EditRentRequestScreen> createState() => _EditRentRequestScreenState();
}

class _EditRentRequestScreenState extends State<EditRentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  // Rental-specific fields
  String _rentalType = 'Vehicle';
  DateTime? _startDate;
  DateTime? _endDate;
  String _duration = 'Daily';
  bool _deliveryRequired = false;
  final _specificRequirementsController = TextEditingController();
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _rentalTypes = [
    'Vehicle',
    'Equipment',
    'Property',
    'Electronics',
    'Furniture',
    'Sports Equipment',
    'Party Supplies',
    'Tools',
    'Other',
  ];

  final List<String> _durations = [
    'Hourly',
    'Daily',
    'Weekly',
    'Monthly',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromRequest();
  }

  void _initializeFromRequest() {
    _titleController.text = widget.request.title;
    _descriptionController.text = widget.request.description ?? '';
    _locationController.text = widget.request.location?.address ?? '';
    _budgetController.text = widget.request.budget?.toString() ?? '';
    _imageUrls = List<String>.from(widget.request.images ?? []);
    
    if (widget.request.metadata != null) {
      final metadata = widget.request.metadata!;
      _rentalType = metadata['rentalType'] ?? 'Vehicle';
      _duration = metadata['duration'] ?? 'Daily';
      _deliveryRequired = metadata['deliveryRequired'] ?? false;
      _specificRequirementsController.text = metadata['specificRequirements'] ?? '';
      
      if (metadata['startDate'] != null) {
        _startDate = metadata['startDate'] is DateTime 
          ? metadata['startDate']
          : DateTime.tryParse(metadata['startDate'].toString());
      }
      
      if (metadata['endDate'] != null) {
        _endDate = metadata['endDate'] is DateTime 
          ? metadata['endDate']
          : DateTime.tryParse(metadata['endDate'].toString());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _specificRequirementsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
        ? (_startDate ?? DateTime.now().add(const Duration(days: 1)))
        : (_endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 1))),
      firstDate: isStartDate 
        ? DateTime.now()
        : (_startDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Reset end date if it's before the new start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _updateRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final updatedData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'budget': double.tryParse(_budgetController.text.trim()),
        'location': {
          'address': _locationController.text.trim(),
          'latitude': 0.0, // Will be updated by LocationPicker
          'longitude': 0.0,
        },
        'images': _imageUrls,
        'metadata': {
          'rentalType': _rentalType,
          'startDate': _startDate,
          'endDate': _endDate,
          'duration': _duration,
          'deliveryRequired': _deliveryRequired,
          'specificRequirements': _specificRequirementsController.text.trim(),
        },
        'updatedAt': DateTime.now(),
      };

      await _requestService.updateRequest(widget.request.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental request updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFAFF),
      appBar: AppBar(
        title: const Text('Edit Rental Request'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateRequest,
            child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'What do you want to rent?',
                hintText: 'e.g., Car for Weekend, Camera Equipment',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter what you want to rent';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Provide more details about your rental needs...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Rental Details'),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _rentalType,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                    items: _rentalTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _rentalType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _duration,
                    decoration: InputDecoration(
                      labelText: 'Rental Duration Type',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                    items: _durations.map((duration) {
                      return DropdownMenuItem(
                        value: duration,
                        child: Text(duration),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _duration = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Rental Period'),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(_startDate == null 
                  ? 'Select Start Date' 
                  : 'Start: ${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(isStartDate: true),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(_endDate == null 
                  ? 'Select End Date' 
                  : 'End: ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                trailing: const Icon(Icons.event),
                onTap: () => _selectDate(isStartDate: false),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _specificRequirementsController,
              decoration: InputDecoration(
                labelText: 'Specific Requirements (Optional)',
                hintText: 'Any special features or conditions needed...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Reference Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'requests/rent',
              label: 'Upload reference images (optional)',
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Budget & Location'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _budgetController,
              decoration: InputDecoration(
                labelText: CurrencyHelper.instance.getBudgetLabel('per ${_duration.toLowerCase().replaceAll('ly', '')}'),
                hintText: '0.00',
                prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            LocationPickerWidget(
              controller: _locationController,
              labelText: 'Preferred Location',
              hintText: 'Where would you like to pick up?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Rent pickup location: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Options'),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CheckboxListTile(
                title: const Text('Delivery Required'),
                subtitle: const Text('I need the item delivered to me'),
                value: _deliveryRequired,
                onChanged: (value) {
                  setState(() {
                    _deliveryRequired = value!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Rental Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
