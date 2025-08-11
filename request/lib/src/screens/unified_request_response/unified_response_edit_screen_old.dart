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
  
  // Ride response controllers
  final _fareController = TextEditingController();
  final _vehicleDescriptionController = TextEditingController();
  final _driverNotesController = TextEditingController();
  final _specialConsiderationsController = TextEditingController();
  
  // Price comparison response controllers
  final _comparisonPriceController = TextEditingController();
  final _providerNameController = TextEditingController();
  final _linkOrContactController = TextEditingController();

  // Common state variables
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  List<String> _uploadedImages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    // Populate common fields
    _messageController.text = widget.response.message;
    _priceController.text = widget.response.price?.toString() ?? '';
    _availableFrom = widget.response.availableFrom;
    _availableUntil = widget.response.availableUntil;
    _uploadedImages = List.from(widget.response.images);

    // Populate type-specific fields from additionalInfo
    final additionalInfo = widget.response.additionalInfo;

    switch (widget.request.type) {
      case RequestType.item:
        _offerPriceController.text = additionalInfo['offerPrice']?.toString() ?? '';
        _itemConditionController.text = additionalInfo['itemCondition'] ?? '';
        _offerDescriptionController.text = additionalInfo['offerDescription'] ?? '';
        _deliveryCostController.text = additionalInfo['deliveryCost']?.toString() ?? '';
        _estimatedDeliveryController.text = additionalInfo['estimatedDelivery'] ?? '';
        _warrantyController.text = additionalInfo['warranty'] ?? '';
        break;

      case RequestType.service:
        _estimatedCostController.text = additionalInfo['estimatedCost']?.toString() ?? '';
        _timeframeController.text = additionalInfo['timeframe'] ?? '';
        _solutionDescriptionController.text = additionalInfo['solutionDescription'] ?? '';
        _hourlyRateController.text = additionalInfo['hourlyRate']?.toString() ?? '';
        break;

      case RequestType.rental:
        _rentalPriceController.text = additionalInfo['rentalPrice']?.toString() ?? '';
        _rentalItemConditionController.text = additionalInfo['rentalItemCondition'] ?? '';
        _rentalDescriptionController.text = additionalInfo['rentalDescription'] ?? '';
        _securityDepositController.text = additionalInfo['securityDeposit']?.toString() ?? '';
        break;

      case RequestType.delivery:
        _deliveryFeeController.text = additionalInfo['deliveryFee']?.toString() ?? '';
        _estimatedPickupTimeController.text = additionalInfo['estimatedPickupTime'] ?? '';
        _estimatedDropoffTimeController.text = additionalInfo['estimatedDropoffTime'] ?? '';
        break;

      case RequestType.ride:
        _fareController.text = additionalInfo['fare']?.toString() ?? '';
        _vehicleDescriptionController.text = additionalInfo['vehicleDescription'] ?? '';
        _driverNotesController.text = additionalInfo['driverNotes'] ?? '';
        _specialConsiderationsController.text = additionalInfo['specialConsiderations'] ?? '';
        break;

      case RequestType.price:
        _comparisonPriceController.text = additionalInfo['comparisonPrice']?.toString() ?? '';
        _providerNameController.text = additionalInfo['providerName'] ?? '';
        _linkOrContactController.text = additionalInfo['linkOrContact'] ?? '';
        break;
    }
  }

  @override
  void dispose() {
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
    _fareController.dispose();
    _vehicleDescriptionController.dispose();
    _driverNotesController.dispose();
    _comparisonPriceController.dispose();
    _providerNameController.dispose();
    _linkOrContactController.dispose();
    _specialConsiderationsController.dispose();
    super.dispose();
  }

  // Role validation to ensure only appropriate users can respond to specific requests
  String? _validateUserRole(UserModel user) {
    switch (widget.request.type) {
      case RequestType.delivery:
        // Check if user has delivery role
        if (!user.hasRole(UserRole.delivery)) {
          return 'delivery_business_required';
        }
        // Check if delivery role is approved
        if (!user.isRoleVerified(UserRole.delivery)) {
          return 'delivery_business_verification_required';
        }
        break;
        
      case RequestType.ride:
        // Check if user has driver role
        if (!user.hasRole(UserRole.driver)) {
          return 'driver_registration_required';
        }
        // Check if driver role is approved
        if (!user.isRoleVerified(UserRole.driver)) {
          return 'driver_verification_required';
        }
        break;
        
      default:
        // For other request types (item, service, rental), no specific role validation required
        return null;
    }
    return null;
  }

  void _navigateToRegistration() {
    switch (widget.request.type) {
      case RequestType.delivery:
        // Navigate to delivery registration
        Navigator.pushNamed(context, '/delivery-registration');
        break;
      case RequestType.ride:
        // Navigate to driver registration
        Navigator.pushNamed(context, '/driver-registration');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Response - ${widget.request.type.name.toUpperCase()}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateResponse,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Update',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request Context Card
              _buildRequestContextCard(),
              const SizedBox(height: 20),
              
              // Type-specific response fields
              _buildResponseForm(),
              
              const SizedBox(height: 20),
              
              // Common fields
              _buildCommonFields(),
              
              const SizedBox(height: 100), // Space for floating button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestContextCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 12),
            Text(
              widget.request.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.request.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseForm() {
    switch (widget.request.type) {
      case RequestType.item:
        return _buildItemResponseForm();
      case RequestType.service:
        return _buildServiceResponseForm();
      case RequestType.rental:
        return _buildRentalResponseForm();
      case RequestType.delivery:
        return _buildDeliveryResponseForm();
      case RequestType.ride:
        return _buildRideResponseForm();
      case RequestType.price:
        return _buildPriceResponseForm();
    }
  }

  Widget _buildItemResponseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Offer Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _offerPriceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Offer Price',
            hintText: 'Enter your offer price',
            prefixText: '₨ ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter an offer price';
            if (double.tryParse(value!) == null) return 'Please enter a valid price';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _itemConditionController,
          decoration: const InputDecoration(
            labelText: 'Item Condition',
            hintText: 'New, Used, Like New, etc.',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please specify item condition' : null,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _offerDescriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Item Description',
            hintText: 'Describe the item you\'re offering',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please describe the item' : null,
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _deliveryCostController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Delivery Cost',
                  hintText: 'Delivery fee',
                  prefixText: '₨ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _estimatedDeliveryController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Time',
                  hintText: '2-3 days',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _warrantyController,
          decoration: const InputDecoration(
            labelText: 'Warranty/Guarantee',
            hintText: '1 year warranty, 30-day return, etc.',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceResponseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Offer Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _estimatedCostController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Estimated Cost',
            hintText: 'Total estimated cost',
            prefixText: '₨ ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter estimated cost';
            if (double.tryParse(value!) == null) return 'Please enter a valid amount';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _timeframeController,
          decoration: const InputDecoration(
            labelText: 'Completion Timeframe',
            hintText: '2-3 days, 1 week, etc.',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please specify timeframe' : null,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _solutionDescriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Solution Description',
            hintText: 'Describe how you will complete this service',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please describe your solution' : null,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _hourlyRateController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hourly Rate (Optional)',
            hintText: 'If applicable',
            prefixText: '₨ ',
            suffixText: '/hour',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildRentalResponseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rental Offer Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _rentalPriceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Rental Price',
            hintText: 'Per day/week/month',
            prefixText: '₨ ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter rental price';
            if (double.tryParse(value!) == null) return 'Please enter a valid price';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _rentalItemConditionController,
          decoration: const InputDecoration(
            labelText: 'Item Condition',
            hintText: 'Excellent, Good, Fair, etc.',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please specify condition' : null,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _rentalDescriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Item Description',
            hintText: 'Describe the rental item',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please describe the item' : null,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _securityDepositController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Security Deposit',
            hintText: 'Refundable deposit amount',
            prefixText: '₨ ',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryResponseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Service Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _deliveryFeeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Delivery Fee',
            hintText: 'Total delivery cost',
            prefixText: '₨ ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter delivery fee';
            if (double.tryParse(value!) == null) return 'Please enter a valid amount';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _estimatedPickupTimeController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Time',
                  hintText: 'When you can pickup',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please specify pickup time' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _estimatedDropoffTimeController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Time',
                  hintText: 'When you can deliver',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please specify delivery time' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRideResponseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ride Offer Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _fareController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Fare',
            hintText: 'Your fare for this ride',
            prefixText: '₨ ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter fare amount';
            if (double.tryParse(value!) == null) return 'Please enter a valid fare';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _vehicleDescriptionController,
          decoration: const InputDecoration(
            labelText: 'Vehicle Description',
            hintText: 'Car model, color, etc.',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please describe your vehicle' : null,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _driverNotesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Driver Notes',
            hintText: 'Any additional information for the passenger',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _specialConsiderationsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Special Considerations',
            hintText: 'Pet-friendly, wheelchair accessible, etc.',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceResponseForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _comparisonPriceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price',
            hintText: 'Current market price',
            prefixText: '₨ ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please enter price';
            if (double.tryParse(value!) == null) return 'Please enter a valid price';
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _providerNameController,
          decoration: const InputDecoration(
            labelText: 'Provider/Store Name',
            hintText: 'Where this price is available',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please enter provider name' : null,
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _linkOrContactController,
          decoration: const InputDecoration(
            labelText: 'Link or Contact',
            hintText: 'Website link, phone number, or address',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildCommonFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Additional message or details',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value?.isEmpty ?? true ? 'Please enter a message' : null,
        ),
        const SizedBox(height: 16),
        
        // Availability dates
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(isFrom: true),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available From', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        _availableFrom != null 
                            ? '${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year}'
                            : 'Select date',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(isFrom: false),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Until', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        _availableUntil != null 
                            ? '${_availableUntil!.day}/${_availableUntil!.month}/${_availableUntil!.year}'
                            : 'Select date',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Image upload
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

  Future<void> _selectDate({required bool isFrom}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isFrom 
          ? (_availableFrom ?? DateTime.now())
          : (_availableUntil ?? DateTime.now().add(const Duration(days: 7))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isFrom) {
          _availableFrom = date;
        } else {
          _availableUntil = date;
        }
      });
    }
  }

  Color _getTypeColor(RequestType type) {
    switch (type) {
      case RequestType.item:
        return Colors.blue;
      case RequestType.service:
        return Colors.green;
      case RequestType.rental:
        return Colors.orange;
      case RequestType.delivery:
        return Colors.purple;
      case RequestType.ride:
        return Colors.teal;
      case RequestType.price:
        return Colors.red;
    }
  }

  Map<String, dynamic> _buildAdditionalInfo() {
    final additionalInfo = <String, dynamic>{};
    
    switch (widget.request.type) {
      case RequestType.item:
        additionalInfo.addAll({
          'offerPrice': double.tryParse(_offerPriceController.text),
          'itemCondition': _itemConditionController.text,
          'offerDescription': _offerDescriptionController.text,
          'deliveryCost': double.tryParse(_deliveryCostController.text),
          'estimatedDelivery': _estimatedDeliveryController.text,
          'warranty': _warrantyController.text,
        });
        break;
      case RequestType.service:
        additionalInfo.addAll({
          'estimatedCost': double.tryParse(_estimatedCostController.text),
          'timeframe': _timeframeController.text,
          'solutionDescription': _solutionDescriptionController.text,
          'hourlyRate': double.tryParse(_hourlyRateController.text),
        });
        break;
      case RequestType.rental:
        additionalInfo.addAll({
          'rentalPrice': double.tryParse(_rentalPriceController.text),
          'rentalItemCondition': _rentalItemConditionController.text,
          'rentalDescription': _rentalDescriptionController.text,
          'securityDeposit': double.tryParse(_securityDepositController.text),
        });
        break;
      case RequestType.delivery:
        additionalInfo.addAll({
          'deliveryFee': double.tryParse(_deliveryFeeController.text),
          'estimatedPickupTime': _estimatedPickupTimeController.text,
          'estimatedDropoffTime': _estimatedDropoffTimeController.text,
        });
        break;
      case RequestType.ride:
        additionalInfo.addAll({
          'fare': double.tryParse(_fareController.text),
          'vehicleDescription': _vehicleDescriptionController.text,
          'driverNotes': _driverNotesController.text,
          'specialConsiderations': _specialConsiderationsController.text,
        });
        break;
      case RequestType.price:
        additionalInfo.addAll({
          'comparisonPrice': double.tryParse(_comparisonPriceController.text),
          'providerName': _providerNameController.text,
          'linkOrContact': _linkOrContactController.text,
        });
        break;
    }
    
    return additionalInfo;
  }

  Future<void> _updateResponse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await _userService.getCurrentUserModel();
      if (currentUser == null) {
        throw Exception('User not found');
      }

      // Role-based validation
      final validationError = _validateUserRole(currentUser);
      if (validationError != null) {
        setState(() {
          _isLoading = false;
        });
        
        // Show user-friendly error messages
        String message;
        String actionLabel = 'Register';
        
        switch (validationError) {
          case 'delivery_business_required':
            message = 'You need to register as a delivery business to respond to delivery requests';
            break;
          case 'delivery_business_verification_required':
            message = 'Your delivery business registration is pending approval. Please wait for verification.';
            actionLabel = 'Check Status';
            break;
          case 'driver_registration_required':
            message = 'You need to register as a driver to respond to ride requests';
            break;
          case 'driver_verification_required':
            message = 'Your driver registration is pending approval. Please wait for verification.';
            actionLabel = 'Check Status';
            break;
          default:
            message = 'You don\'t have permission to respond to this request';
            actionLabel = 'Learn More';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: actionLabel == 'Register' ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: () {
                // Navigate to appropriate registration screen
                _navigateToRegistration();
              },
            ) : null,
          ),
        );
        return;
      }

      // Get price from type-specific controller if available
      double? responsePrice = double.tryParse(_priceController.text);
      if (responsePrice == null) {
        switch (widget.request.type) {
          case RequestType.item:
            responsePrice = double.tryParse(_offerPriceController.text);
            break;
          case RequestType.service:
            responsePrice = double.tryParse(_estimatedCostController.text);
            break;
          case RequestType.rental:
            responsePrice = double.tryParse(_rentalPriceController.text);
            break;
          case RequestType.delivery:
            responsePrice = double.tryParse(_deliveryFeeController.text);
            break;
          case RequestType.ride:
            responsePrice = double.tryParse(_fareController.text);
            break;
          case RequestType.price:
            responsePrice = double.tryParse(_comparisonPriceController.text);
            break;
        }
      }

      await _requestService.updateResponse(
        responseId: widget.response.id,
        message: _messageController.text,
        price: responsePrice,
        availableFrom: _availableFrom,
        availableUntil: _availableUntil,
        images: _uploadedImages,
        additionalInfo: _buildAdditionalInfo(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
