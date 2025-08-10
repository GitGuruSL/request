import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class CreateRentRequestScreen extends StatefulWidget {
  const CreateRentRequestScreen({super.key});

  @override
  State<CreateRentRequestScreen> createState() => _CreateRentRequestScreenState();
}

class _CreateRentRequestScreenState extends State<CreateRentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _allowedKmController = TextEditingController();
  final _extraKmRateController = TextEditingController();
  
  // Rental-specific fields
  String _rentalType = 'Vehicle';
  DateTime? _startDate;
  DateTime? _endDate;
  String _duration = 'Daily';
  bool _deliveryRequired = false;
  final _specificRequirementsController = TextEditingController();
  List<String> _imageUrls = [];
  String _allowedKmOption = '100 KM';
  bool _includeInsurance = false;

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

  final List<String> _allowedKmOptions = [
    '50 KM',
    '100 KM',
    '150 KM',
    '200 KM',
    '300 KM',
    '500 KM',
    'Unlimited',
    'Custom',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _allowedKmController.dispose();
    _extraKmRateController.dispose();
    _specificRequirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFAFF),
      appBar: AppBar(
        title: const Text('Create Rental Request'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.key, color: Colors.indigo[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rental Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[600],
                            ),
                          ),
                          const Text(
                            'Need to rent something? Find what you need!',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
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

              // Rental Details
              _buildSectionTitle('Rental Details'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
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
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
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
              const SizedBox(height: 24),

              // Rental Period
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

              // Reference Images
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

              // Budget & Location
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

              // Mileage (for Vehicle rentals)
              if (_rentalType == 'Vehicle') ...[
                _buildSectionTitle('Mileage/KM Limits'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Allowed KM/Mileage',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _allowedKmOption,
                        decoration: const InputDecoration(
                          hintText: 'Select allowed KM',
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                        ),
                        items: _allowedKmOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _allowedKmOption = value!;
                          });
                        },
                      ),
                      if (_allowedKmOption == 'Custom') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _allowedKmController,
                          decoration: const InputDecoration(
                            labelText: 'Custom KM Limit',
                            hintText: 'Enter custom KM limit',
                            filled: true,
                            fillColor: Colors.white,
                            border: InputBorder.none,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _extraKmRateController,
                        decoration: InputDecoration(
                          labelText: CurrencyHelper.instance.getPriceLabel('Extra KM Rate'),
                          hintText: 'Rate per extra KM',
                          prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                          filled: true,
                          fillColor: Colors.white,
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Options
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

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
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
                          'Create Rental Request',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
        ? DateTime.now().add(const Duration(days: 1))
        : (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
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

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
      // Check if user has verified phone number
      final currentUser = await _userService.getCurrentUserModel();
      if (currentUser == null || !currentUser.isPhoneVerified) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your phone number to create requests'),
            ),
          );
        }
        return;
      }

      // Create the rental-specific data
      Map<String, String> specifications = {
        'duration': _duration,
        'specificRequirements': _specificRequirementsController.text.trim(),
      };
      
      // Add mileage information for vehicle rentals
      if (_rentalType == 'Vehicle') {
        String allowedKm = _allowedKmOption == 'Custom' 
            ? _allowedKmController.text.trim() 
            : _allowedKmOption.replaceAll(' KM', '').replaceAll('Unlimited', '-1');
        
        specifications.addAll({
          'allowedKm': allowedKm,
          'extraKmRate': _extraKmRateController.text.trim(),
          'kmUnit': 'KM',
        });
      }
      
      final rentalData = RentalRequestData(
        itemCategory: _rentalType,
        startDate: _startDate!,
        endDate: _endDate!,
        isFlexibleDates: false,
        specifications: specifications,
        needsDelivery: _deliveryRequired,
      );

      final requestId = await _requestService.createRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: RequestType.rental,
        budget: double.tryParse(_budgetController.text),
        currency: CurrencyHelper.instance.getCurrency(),
        typeSpecificData: rentalData.toMap(),
        tags: ['rental', _rentalType.toLowerCase().replaceAll(' ', '_')],
        location: LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          address: _locationController.text.trim(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental request created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating request: $e'),
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
}
