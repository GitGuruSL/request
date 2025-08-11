import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/enhanced_request_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../widgets/image_upload_widget.dart';
import '../../utils/currency_helper.dart';

class UnifiedResponseEditScreen extends StatefulWidget {
  final RequestModel request;
  final ResponseModel response;
  
  const UnifiedResponseEditScreen({
    super.key, 
    required this.request,
    required this.response,
  });

  @override
  State<UnifiedResponseEditScreen> createState() => _UnifiedResponseEditScreenState();
}

class _UnifiedResponseEditScreenState extends State<UnifiedResponseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Common controllers
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  
  // Item response controllers
  final _offerPriceController = TextEditingController();
  final _itemConditionController = TextEditingController();
  final _offerDescriptionController = TextEditingController();
  final _deliveryCostController = TextEditingController();
  final _estimatedDeliveryController = TextEditingController();
  final _warrantyController = TextEditingController();
  
  // Service response controllers
  final _estimatedCostController = TextEditingController();
  final _timeframeController = TextEditingController();
  final _solutionDescriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  // Rental response controllers
  final _rentalPriceController = TextEditingController();
  final _rentalItemConditionController = TextEditingController();
  final _rentalDescriptionController = TextEditingController();
  final _securityDepositController = TextEditingController();
  
  // Delivery response controllers
  final _deliveryFeeController = TextEditingController();
  final _estimatedPickupTimeController = TextEditingController();
  final _estimatedDropoffTimeController = TextEditingController();
  final _packageSizeController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _deliveryNotesController = TextEditingController();
  
  // Ride response controllers
  final _fareController = TextEditingController();
  final _routeDescriptionController = TextEditingController();
  final _driverNotesController = TextEditingController();
  
  // Common fields
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  List<String> _uploadedImages = [];
  String _selectedCurrency = 'LKR';
  UserModel? _currentUser;
  bool _isLoading = false;
  
  // Type-specific fields
  bool _hasWarranty = false;
  bool _includesDelivery = false;
  String _vehicleType = 'sedan';
  String _packageSize = 'small';
  bool _fragileItems = false;
  bool _expressDelivery = false;
  String _serviceType = 'one_time';
  bool _emergencyService = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _initializeFormData();
  }

  void _initializeFormData() {
    // Initialize with existing response data
    final response = widget.response;
    
    // Common fields
    _messageController.text = response.message ?? '';
    _priceController.text = response.price?.toString() ?? '';
    _selectedCurrency = response.currency ?? 'LKR';
    _availableFrom = response.availableFrom;
    _availableUntil = response.availableUntil;
    _uploadedImages = List<String>.from(response.images ?? []);
    
    // Type-specific fields from additionalInfo
    final info = response.additionalInfo ?? {};
    
    switch (widget.request.type) {
      case RequestType.item:
        _offerPriceController.text = info['offerPrice']?.toString() ?? '';
        _itemConditionController.text = info['itemCondition'] ?? '';
        _offerDescriptionController.text = info['offerDescription'] ?? '';
        _deliveryCostController.text = info['deliveryCost']?.toString() ?? '';
        _estimatedDeliveryController.text = info['estimatedDelivery'] ?? '';
        _warrantyController.text = info['warranty'] ?? '';
        _hasWarranty = info['hasWarranty'] ?? false;
        _includesDelivery = info['includesDelivery'] ?? false;
        break;
        
      case RequestType.service:
        _estimatedCostController.text = info['estimatedCost']?.toString() ?? '';
        _timeframeController.text = info['timeframe'] ?? '';
        _solutionDescriptionController.text = info['solutionDescription'] ?? '';
        _hourlyRateController.text = info['hourlyRate']?.toString() ?? '';
        _serviceType = info['serviceType'] ?? 'one_time';
        _emergencyService = info['emergencyService'] ?? false;
        break;
        
      case RequestType.rental:
        _rentalPriceController.text = info['rentalPrice']?.toString() ?? '';
        _rentalItemConditionController.text = info['itemCondition'] ?? '';
        _rentalDescriptionController.text = info['description'] ?? '';
        _securityDepositController.text = info['securityDeposit']?.toString() ?? '';
        break;
        
      case RequestType.delivery:
        _deliveryFeeController.text = info['deliveryFee']?.toString() ?? '';
        _estimatedPickupTimeController.text = info['estimatedPickupTime'] ?? '';
        _estimatedDropoffTimeController.text = info['estimatedDropoffTime'] ?? '';
        _packageSizeController.text = info['packageSize'] ?? '';
        _specialInstructionsController.text = info['specialInstructions'] ?? '';
        _deliveryNotesController.text = info['deliveryNotes'] ?? '';
        _packageSize = info['packageSize'] ?? 'small';
        _fragileItems = info['fragileItems'] ?? false;
        _expressDelivery = info['expressDelivery'] ?? false;
        break;
        
      case RequestType.ride:
        _fareController.text = info['fare']?.toString() ?? '';
        _routeDescriptionController.text = info['routeDescription'] ?? '';
        _driverNotesController.text = info['driverNotes'] ?? '';
        _vehicleType = info['vehicleType'] ?? 'sedan';
        break;
        
      case RequestType.price:
        // Price comparison requests don't have responses
        break;
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
          if (user != null) {
            _selectedCurrency = 'LKR'; // Default currency since UserModel doesn't have currency field
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _messageController.dispose();
    _priceController.dispose();
    _offerPriceController.dispose();
    _itemConditionController.dispose();
    _offerDescriptionController.dispose();
    _deliveryCostController.dispose();
    _estimatedDeliveryController.dispose();
    _warrantyController.dispose();
    _estimatedCostController.dispose();
    _timeframeController.dispose();
    _solutionDescriptionController.dispose();
    _hourlyRateController.dispose();
    _rentalPriceController.dispose();
    _rentalItemConditionController.dispose();
    _rentalDescriptionController.dispose();
    _securityDepositController.dispose();
    _deliveryFeeController.dispose();
    _estimatedPickupTimeController.dispose();
    _estimatedDropoffTimeController.dispose();
    _packageSizeController.dispose();
    _specialInstructionsController.dispose();
    _deliveryNotesController.dispose();
    _fareController.dispose();
    _routeDescriptionController.dispose();
    _driverNotesController.dispose();
    super.dispose();
  }

  Color _getTypeColor(RequestType type) {
    switch (type) {
      case RequestType.ride:
        return Colors.blue;
      case RequestType.delivery:
        return Colors.green;
      case RequestType.item:
        return Colors.orange;
      case RequestType.service:
        return Colors.purple;
      case RequestType.rental:
        return Colors.teal;
      case RequestType.price:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Response'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_currentUser != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  _currentUser!.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Request summary header
                _buildRequestHeader(),
                
                // Form content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCommonFields(),
                          const SizedBox(height: 24),
                          _buildTypeSpecificFields(),
                          const SizedBox(height: 24),
                          _buildAvailabilitySection(),
                          const SizedBox(height: 24),
                          _buildImageUploadSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Submit button
                _buildSubmitButton(),
              ],
            ),
    );
  }

  Widget _buildRequestHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(widget.request.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getTypeColor(widget.request.type).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  widget.request.type.name.toUpperCase(),
                  style: TextStyle(
                    color: _getTypeColor(widget.request.type),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const Spacer(),
              if (widget.request.budget != null)
                Text(
                  'Budget: ${CurrencyHelper.instance.formatPrice(widget.request.budget!)}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.request.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.request.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.request.description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Response Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Message field
        TextFormField(
          controller: _messageController,
          decoration: const InputDecoration(
            labelText: 'Your Response Message',
            hintText: 'Provide details about your offer...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide a response message';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Price field
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Your Price',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your price';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: ['LKR', 'USD', 'EUR', 'GBP'].map((currency) {
                  return DropdownMenuItem(
                    value: currency,
                    child: Text(currency),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCurrency = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (widget.request.type) {
      case RequestType.item:
        return _buildItemFields();
      case RequestType.service:
        return _buildServiceFields();
      case RequestType.rental:
        return _buildRentalFields();
      case RequestType.delivery:
        return _buildDeliveryFields();
      case RequestType.ride:
        return _buildRideFields();
      case RequestType.price:
        return const SizedBox(); // Price comparison doesn't have response fields
    }
  }

  Widget _buildItemFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _offerPriceController,
          decoration: InputDecoration(
            labelText: 'Your Offer Price',
            border: const OutlineInputBorder(),
            prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _itemConditionController,
          decoration: const InputDecoration(
            labelText: 'Item Condition',
            hintText: 'New, Used, Refurbished, etc.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _offerDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Item Description',
            hintText: 'Describe the item you\'re offering...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Checkbox(
              value: _hasWarranty,
              onChanged: (value) => setState(() => _hasWarranty = value ?? false),
            ),
            const Text('Includes warranty'),
          ],
        ),
        
        if (_hasWarranty) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _warrantyController,
            decoration: const InputDecoration(
              labelText: 'Warranty Details',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _includesDelivery,
              onChanged: (value) => setState(() => _includesDelivery = value ?? false),
            ),
            const Text('Includes delivery'),
          ],
        ),
        
        if (_includesDelivery) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _deliveryCostController,
                  decoration: InputDecoration(
                    labelText: 'Delivery Cost',
                    border: const OutlineInputBorder(),
                    prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _estimatedDeliveryController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Time',
                    hintText: '1-3 days',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildServiceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _estimatedCostController,
          decoration: InputDecoration(
            labelText: 'Estimated Cost',
            border: const OutlineInputBorder(),
            prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _timeframeController,
          decoration: const InputDecoration(
            labelText: 'Estimated Timeframe',
            hintText: '2-3 hours, 1-2 days, etc.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _solutionDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Solution Description',
            hintText: 'Describe how you will solve this...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: _serviceType,
          decoration: const InputDecoration(
            labelText: 'Service Type',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'one_time', child: Text('One-time Service')),
            DropdownMenuItem(value: 'recurring', child: Text('Recurring Service')),
            DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
            DropdownMenuItem(value: 'consultation', child: Text('Consultation')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _serviceType = value;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _hourlyRateController,
          decoration: InputDecoration(
            labelText: 'Hourly Rate (if applicable)',
            border: const OutlineInputBorder(),
            prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Checkbox(
              value: _emergencyService,
              onChanged: (value) => setState(() => _emergencyService = value ?? false),
            ),
            const Text('Available for emergency calls'),
          ],
        ),
      ],
    );
  }

  Widget _buildRentalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rental Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _rentalPriceController,
          decoration: InputDecoration(
            labelText: 'Rental Price per Day',
            border: const OutlineInputBorder(),
            prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _rentalItemConditionController,
          decoration: const InputDecoration(
            labelText: 'Item Condition',
            hintText: 'Excellent, Good, Fair, etc.',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _rentalDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Rental Description',
            hintText: 'Describe the rental item...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _securityDepositController,
          decoration: InputDecoration(
            labelText: 'Security Deposit',
            border: const OutlineInputBorder(),
            prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildDeliveryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _deliveryFeeController,
          decoration: InputDecoration(
            labelText: 'Delivery Fee',
            border: const OutlineInputBorder(),
            prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _estimatedPickupTimeController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Pickup Time',
                  hintText: '30 mins, 1 hour, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _estimatedDropoffTimeController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Delivery Time',
                  hintText: '2 hours, same day, etc.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: _packageSize,
          decoration: const InputDecoration(
            labelText: 'Package Size Capacity',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'small', child: Text('Small (up to 5kg)')),
            DropdownMenuItem(value: 'medium', child: Text('Medium (5-20kg)')),
            DropdownMenuItem(value: 'large', child: Text('Large (20-50kg)')),
            DropdownMenuItem(value: 'extra_large', child: Text('Extra Large (50kg+)')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _packageSize = value;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _specialInstructionsController,
          decoration: const InputDecoration(
            labelText: 'Special Handling Instructions',
            hintText: 'Fragile, temperature sensitive, etc.',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Checkbox(
              value: _fragileItems,
              onChanged: (value) => setState(() => _fragileItems = value ?? false),
            ),
            const Text('Can handle fragile items'),
          ],
        ),
        
        Row(
          children: [
            Checkbox(
              value: _expressDelivery,
              onChanged: (value) => setState(() => _expressDelivery = value ?? false),
            ),
            const Text('Express delivery available'),
          ],
        ),
        
        const SizedBox(height: 12),
        TextFormField(
          controller: _deliveryNotesController,
          decoration: const InputDecoration(
            labelText: 'Additional Notes',
            hintText: 'Any additional information...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildRideFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ride Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _fareController,
          decoration: InputDecoration(
            labelText: 'Your Fare',
            border: const OutlineInputBorder(),
            prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          value: _vehicleType,
          decoration: const InputDecoration(
            labelText: 'Vehicle Type',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'sedan', child: Text('Sedan')),
            DropdownMenuItem(value: 'suv', child: Text('SUV')),
            DropdownMenuItem(value: 'hatchback', child: Text('Hatchback')),
            DropdownMenuItem(value: 'van', child: Text('Van')),
            DropdownMenuItem(value: 'pickup', child: Text('Pickup Truck')),
            DropdownMenuItem(value: 'motorbike', child: Text('Motorbike')),
            DropdownMenuItem(value: 'tuk', child: Text('Three-Wheeler')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _vehicleType = value;
              });
            }
          },
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _routeDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Route Description',
            hintText: 'Describe your preferred route...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _driverNotesController,
          decoration: const InputDecoration(
            labelText: 'Driver Notes',
            hintText: 'Any additional information for the passenger...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Availability',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDateTime(context, true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available From',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _availableFrom != null 
                            ? '${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year} ${_availableFrom!.hour.toString().padLeft(2, '0')}:${_availableFrom!.minute.toString().padLeft(2, '0')}'
                            : 'Select date & time',
                        style: TextStyle(
                          fontSize: 16,
                          color: _availableFrom != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectDateTime(context, false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Until',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _availableUntil != null 
                            ? '${_availableUntil!.day}/${_availableUntil!.month}/${_availableUntil!.year} ${_availableUntil!.hour.toString().padLeft(2, '0')}:${_availableUntil!.minute.toString().padLeft(2, '0')}'
                            : 'Select date & time',
                        style: TextStyle(
                          fontSize: 16,
                          color: _availableUntil != null ? Colors.black : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ImageUploadWidget(
          initialImages: _uploadedImages,
          uploadPath: 'responses/${widget.response.id}_${DateTime.now().millisecondsSinceEpoch}',
          onImagesChanged: (images) {
            setState(() {
              _uploadedImages = images;
            });
          },
          maxImages: 5,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateResponse,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getTypeColor(widget.request.type),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading 
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Update Response',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isFromDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null && mounted) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        
        setState(() {
          if (isFromDate) {
            _availableFrom = dateTime;
          } else {
            _availableUntil = dateTime;
          }
        });
      }
    }
  }

  Map<String, dynamic> _getAdditionalInfo() {
    final Map<String, dynamic> info = {};
    
    switch (widget.request.type) {
      case RequestType.item:
        info['offerPrice'] = double.tryParse(_offerPriceController.text);
        info['itemCondition'] = _itemConditionController.text;
        info['offerDescription'] = _offerDescriptionController.text;
        info['hasWarranty'] = _hasWarranty;
        info['includesDelivery'] = _includesDelivery;
        if (_hasWarranty) {
          info['warranty'] = _warrantyController.text;
        }
        if (_includesDelivery) {
          info['deliveryCost'] = double.tryParse(_deliveryCostController.text);
          info['estimatedDelivery'] = _estimatedDeliveryController.text;
        }
        break;
        
      case RequestType.service:
        info['estimatedCost'] = double.tryParse(_estimatedCostController.text);
        info['timeframe'] = _timeframeController.text;
        info['solutionDescription'] = _solutionDescriptionController.text;
        info['serviceType'] = _serviceType;
        info['emergencyService'] = _emergencyService;
        if (_hourlyRateController.text.isNotEmpty) {
          info['hourlyRate'] = double.tryParse(_hourlyRateController.text);
        }
        break;
        
      case RequestType.rental:
        info['rentalPrice'] = double.tryParse(_rentalPriceController.text);
        info['itemCondition'] = _rentalItemConditionController.text;
        info['description'] = _rentalDescriptionController.text;
        if (_securityDepositController.text.isNotEmpty) {
          info['securityDeposit'] = double.tryParse(_securityDepositController.text);
        }
        break;
        
      case RequestType.delivery:
        info['deliveryFee'] = double.tryParse(_deliveryFeeController.text);
        info['estimatedPickupTime'] = _estimatedPickupTimeController.text;
        info['estimatedDropoffTime'] = _estimatedDropoffTimeController.text;
        info['packageSize'] = _packageSize;
        info['specialInstructions'] = _specialInstructionsController.text;
        info['deliveryNotes'] = _deliveryNotesController.text;
        info['fragileItems'] = _fragileItems;
        info['expressDelivery'] = _expressDelivery;
        break;
        
      case RequestType.ride:
        info['fare'] = double.tryParse(_fareController.text);
        info['vehicleType'] = _vehicleType;
        info['routeDescription'] = _routeDescriptionController.text;
        info['driverNotes'] = _driverNotesController.text;
        break;
        
      case RequestType.price:
        // Price comparison doesn't have additional info
        break;
    }
    
    return info;
  }

  Future<void> _updateResponse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final price = double.tryParse(_priceController.text.trim());
      
      await _requestService.updateResponse(
        responseId: widget.response.id,
        message: _messageController.text.trim(),
        price: price,
        currency: _selectedCurrency,
        availableFrom: _availableFrom,
        availableUntil: _availableUntil,
        images: _uploadedImages,
        additionalInfo: _getAdditionalInfo(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating response: $e'),
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
