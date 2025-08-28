import 'package:flutter/material.dart';
import '../../widgets/glass_page.dart';
import '../../theme/glass_theme.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/rest_request_service.dart' as rest;
import '../../widgets/image_upload_widget.dart';
import '../../services/country_service.dart';
import '../../widgets/accurate_location_picker_widget.dart';
import '../../widgets/category_picker.dart';
import '../../utils/currency_helper.dart';
import '../requests/ride/edit_ride_request_screen.dart';

class UnifiedRequestEditScreen extends StatefulWidget {
  final RequestModel request;

  const UnifiedRequestEditScreen({super.key, required this.request});

  @override
  State<UnifiedRequestEditScreen> createState() =>
      _UnifiedRequestEditScreenState();
}

class _UnifiedRequestEditScreenState extends State<UnifiedRequestEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedUserService _userService = EnhancedUserService();
  final rest.RestRequestService _restService = rest.RestRequestService.instance;

  // Common form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  // Item-specific controllers
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();

  // Service-specific controllers
  final _specialInstructionsController = TextEditingController();
  // Service module dynamic controllers/fields (mirror create screen)
  final _peopleCountController = TextEditingController(); // tours/events
  final _durationDaysController = TextEditingController(); // tours
  final _guestsCountController = TextEditingController(); // events
  final _areaSizeController = TextEditingController(); // construction (sqft)
  final _sessionsPerWeekController = TextEditingController(); // education
  final _experienceYearsController = TextEditingController(); // hiring
  bool _needsGuide = false; // tours
  bool _pickupRequiredForTour = false; // tours
  String _educationLevel = 'Beginner'; // education
  String _positionType = 'Full-time'; // hiring

  // Rental-specific controllers
  final _itemToRentController = TextEditingController();
  final _rentalItemController = TextEditingController();

  // Delivery-specific controllers
  final _pickupLocationController = TextEditingController();
  final _dropoffLocationController = TextEditingController();
  final _itemCategoryController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _dimensionsController = TextEditingController();

  RequestType _selectedType = RequestType.item;
  String? _selectedModule; // inferred module for service type
  String _selectedCondition = 'New';
  String _selectedUrgency = 'Flexible';
  String _selectedCategory = 'Electronics';
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubcategory;
  String _pickupDropoffPreference = 'pickup';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _preferredDateTime;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  DateTime? _preferredDeliveryTime;
  List<String> _imageUrls = [];
  bool _isLoading = false;

  // Location coordinates storage
  double? _selectedLatitude;
  double? _selectedLongitude;
  // Delivery specific coordinates
  double? _pickupLatitude;
  double? _pickupLongitude;
  double? _dropoffLatitude;
  double? _dropoffLongitude;

  final List<String> _conditions = [
    'New',
    'Used',
    'For Parts',
    'Any Condition'
  ];
  final List<String> _urgencyLevels = ['Flexible', 'ASAP', 'Specific Date'];
  // Additional lists kept minimal; extended catalogs handled by CategoryPicker

  @override
  void initState() {
    super.initState();
    _selectedType = widget.request.type;
    _populateFormFromRequest();
  }

  void _populateFormFromRequest() {
    // Populate common fields
    _titleController.text = widget.request.title;
    _descriptionController.text = widget.request.description.toString();
    _budgetController.text = widget.request.budget?.toString() ?? '';
    _imageUrls = List<String>.from(widget.request.images);

    // Set location if available
    if (widget.request.location != null) {
      _locationController.text = widget.request.location!.address;
      _selectedLatitude = widget.request.location!.latitude;
      _selectedLongitude = widget.request.location!.longitude;
    }

    // Populate type-specific data
    final typeData = widget.request.typeSpecificData;

    switch (widget.request.type) {
      case RequestType.item:
        _itemNameController.text = typeData['itemName']?.toString() ?? '';
        _selectedCategory = typeData['category']?.toString() ?? 'Electronics';
        _selectedCategoryId = typeData['categoryId']?.toString() ??
            typeData['category']?.toString();
        _selectedSubcategory = typeData['subcategory']?.toString();
        _selectedSubCategoryId = typeData['subcategoryId']?.toString() ??
            typeData['subcategory']?.toString();
        _quantityController.text = typeData['quantity']?.toString() ?? '';
        _selectedCondition = typeData['condition']?.toString() ?? 'New';

        // Ensure categoryId is set if we have a category
        if (_selectedCategory.isNotEmpty == true &&
            (_selectedCategoryId?.isEmpty ?? true)) {
          _selectedCategoryId = _selectedCategory;
        }
        break;

      case RequestType.service:
        _selectedCategory = typeData['serviceType']?.toString() ?? '';
        _selectedCategoryId = typeData['categoryId']?.toString() ??
            typeData['serviceType']?.toString();
        _selectedSubcategory = typeData['subcategory']?.toString();
        _selectedSubCategoryId = typeData['subcategoryId']?.toString() ??
            typeData['subcategory']?.toString();
        _selectedUrgency = typeData['urgency']?.toString() ?? 'Flexible';
        _selectedModule = typeData['module']?.toString();
        if (typeData['preferredDateTime'] != null) {
          _preferredDateTime = DateTime.fromMillisecondsSinceEpoch(
              typeData['preferredDateTime']);
        }

        // Hydrate moduleFields if present
        final mf = (typeData['moduleFields'] as Map?)?.cast<String, dynamic>();
        if (mf != null) {
          final module = _selectedModule?.toLowerCase();
          switch (module) {
            case 'tours':
              final pc = mf['peopleCount'];
              if (pc != null) _peopleCountController.text = pc.toString();
              final dd = mf['durationDays'];
              if (dd != null) _durationDaysController.text = dd.toString();
              _needsGuide = (mf['needsGuide'] == true);
              _pickupRequiredForTour = (mf['pickupRequired'] == true);
              break;
            case 'events':
              final gc = mf['guestsCount'];
              if (gc != null) _guestsCountController.text = gc.toString();
              break;
            case 'construction':
              final area = mf['areaSizeSqft'];
              if (area != null) _areaSizeController.text = area.toString();
              break;
            case 'education':
              final lvl = mf['level'];
              if (lvl is String && lvl.isNotEmpty) _educationLevel = lvl;
              final spw = mf['sessionsPerWeek'];
              if (spw != null) {
                _sessionsPerWeekController.text = spw.toString();
              }
              break;
            case 'hiring':
              final pt = mf['positionType'];
              if (pt is String && pt.isNotEmpty) _positionType = pt;
              final exp = mf['experienceYears'];
              if (exp != null) {
                _experienceYearsController.text = exp.toString();
              }
              break;
          }
        }

        // Ensure categoryId is set if we have a category
        if (_selectedCategory.isNotEmpty == true &&
            (_selectedCategoryId?.isEmpty ?? true)) {
          _selectedCategoryId = _selectedCategory;
        }
        break;

      case RequestType.delivery:
        _pickupLocationController.text =
            typeData['pickupLocation']?.toString() ?? '';
        _dropoffLocationController.text =
            typeData['dropoffLocation']?.toString() ?? '';

        // Load category data into the CategoryPicker variables
        _selectedCategory = typeData['itemCategory']?.toString() ??
            typeData['category']?.toString() ??
            '';
        _selectedCategoryId = typeData['categoryId']?.toString() ??
            typeData['itemCategory']?.toString() ??
            typeData['category']?.toString();
        _selectedSubcategory = typeData['subcategory']?.toString();
        _selectedSubCategoryId = typeData['subcategoryId']?.toString() ??
            typeData['subcategory']?.toString();

        _itemDescriptionController.text =
            typeData['itemDescription']?.toString() ?? '';
        _weightController.text = typeData['weight']?.toString() ?? '';
        _dimensionsController.text = typeData['dimensions']?.toString() ?? '';
        _specialInstructionsController.text =
            typeData['specialInstructions']?.toString() ?? '';

        // Handle preferredDeliveryTime - could be either a timestamp or string
        final deliveryTimeData = typeData['preferredDeliveryTime'];
        if (deliveryTimeData is int) {
          // It's a timestamp, convert to DateTime
          _preferredDeliveryTime =
              DateTime.fromMillisecondsSinceEpoch(deliveryTimeData);
        }

        // Ensure categoryId is set if we have a category
        if (_selectedCategory.isNotEmpty == true &&
            (_selectedCategoryId?.isEmpty ?? true)) {
          _selectedCategoryId = _selectedCategory;
        }
        break;

      case RequestType.rental:
        _itemToRentController.text = typeData['itemToRent']?.toString() ?? '';
        _selectedCategory = typeData['category']?.toString() ?? '';
        _selectedCategoryId = typeData['categoryId']?.toString() ??
            typeData['category']?.toString();
        _selectedSubcategory = typeData['subcategory']?.toString();
        _selectedSubCategoryId = typeData['subcategoryId']?.toString() ??
            typeData['subcategory']?.toString();
        _pickupDropoffPreference =
            typeData['pickupDropoffPreference']?.toString() ?? 'pickup';

        // Set both date formats for compatibility
        if (typeData['startDate'] != null) {
          _startDate =
              DateTime.fromMillisecondsSinceEpoch(typeData['startDate']);
          _startDateTime = _startDate; // Use same date for both
        }
        if (typeData['endDate'] != null) {
          _endDate = DateTime.fromMillisecondsSinceEpoch(typeData['endDate']);
          _endDateTime = _endDate; // Use same date for both
        }

        // If we have category data but _selectedCategoryId is empty, set it to category name
        if (_selectedCategory.isNotEmpty == true &&
            (_selectedCategoryId?.isEmpty ?? true)) {
          _selectedCategoryId = _selectedCategory;
        }
        break;

      default:
        break;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _specialInstructionsController.dispose();
    _itemToRentController.dispose();
    _rentalItemController.dispose();
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _itemCategoryController.dispose();
    _itemDescriptionController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    // dispose dynamic controllers
    _peopleCountController.dispose();
    _durationDaysController.dispose();
    _guestsCountController.dispose();
    _areaSizeController.dispose();
    _sessionsPerWeekController.dispose();
    _experienceYearsController.dispose();
    super.dispose();
  }

  // Removed unused _getTypeColor

  String _getTypeDisplayName(RequestType type) {
    switch (type) {
      case RequestType.item:
        return 'Item Request';
      case RequestType.service:
        return 'Service Request';
      case RequestType.delivery:
        return 'Delivery Request';
      case RequestType.rental:
        return 'Rental Request';
      case RequestType.ride:
        return 'Ride Request';
      case RequestType.price:
        return 'Price Request';
    }
  }

  String _getTypeDisplayNameWithModule() {
    if (_selectedType == RequestType.service && _selectedModule != null) {
      final m = _selectedModule!.toLowerCase();
      switch (m) {
        case 'item':
          return 'Item Request';
        case 'rent':
        case 'rental':
          return 'Rental Request';
        case 'delivery':
          return 'Delivery Request';
        case 'ride':
          return 'Ride Request';
        case 'tours':
          return 'Tour Request';
        case 'events':
          return 'Event Request';
        case 'construction':
          return 'Construction Request';
        case 'education':
          return 'Education Request';
        case 'hiring':
          return 'Hiring Request';
        case 'other':
          return 'Other Service Request';
      }
    }
    return _getTypeDisplayName(_selectedType);
  }

  Future<void> _showCategoryPicker() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => CategoryPicker(
          requestType: 'item',
          scrollController: scrollController,
        ),
      ),
    );

    if (result != null && result.containsKey('category')) {
      setState(() {
        _selectedCategory = result['category'] ?? 'Electronics';
        _selectedSubcategory =
            result['subcategory']; // Can be null for main categories
        _selectedCategoryId = _selectedCategory; // Set ID same as name for now
        _selectedSubCategoryId =
            _selectedSubcategory; // Set ID same as name for now
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Redirect ride requests to specific edit screen
    if (_selectedType == RequestType.ride) {
      return EditRideRequestScreen(request: widget.request);
    }

    return GlassPage(
      title: 'Edit ${_getTypeDisplayNameWithModule()}',
      appBarBackgroundColor: GlassTheme.isDarkMode
          ? const Color(0x1AFFFFFF)
          : const Color(0xCCFFFFFF),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassTheme.glassCard(child: _buildTypeSpecificFields()),
            ],
          ),
        ),
      ),
      bottomBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitRequest,
              style: GlassTheme.primaryButton,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Update ${_getTypeDisplayNameWithModule()}'),
            ),
          ),
        ),
      ),
    );
  }

  // Removed unused _buildCommonFields

  Widget _buildFlatField({required Widget child}) {
    return GlassTheme.glassCard(
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (_selectedType) {
      case RequestType.item:
        return _buildItemFields();
      case RequestType.service:
        return _buildServiceFields();
      case RequestType.delivery:
        return _buildDeliveryFields();
      case RequestType.rental:
        return _buildRentalFields();
      case RequestType.ride:
        return const SizedBox(); // Should not reach here due to redirect above
      case RequestType.price:
        return const SizedBox(); // Should not reach here due to redirect above
    }
  }

  Widget _buildItemFields() {
    return Column(
      children: [
        // Request Title
        _buildFlatField(
          child: TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Request Title',
              hintText: 'Enter a short, descriptive title',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Item Name
        _buildFlatField(
          child: TextFormField(
            controller: _itemNameController,
            decoration: const InputDecoration(
              labelText: 'Item Name',
              hintText: 'e.g., Sony PS-LX2 Turntable',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the item name';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Description
        _buildFlatField(
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Provide detailed information...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Category (Use Category Picker)
        _buildFlatField(
          child: TextFormField(
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Category',
              hintText: 'Select a category',
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            controller: TextEditingController(
              text: _selectedSubcategory != null
                  ? '$_selectedCategory > $_selectedSubcategory'
                  : _selectedCategory,
            ),
            onTap: _showCategoryPicker,
            validator: (value) {
              if (_selectedCategory == 'Electronics' &&
                  _selectedCategoryId == null) {
                return 'Please select a category';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Quantity
        _buildFlatField(
          child: TextFormField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              hintText: 'How many do you need?',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the quantity';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Desired Condition
        _buildFlatField(
          child: DropdownButtonFormField<String>(
            value: _selectedCondition,
            decoration: const InputDecoration(
              labelText: 'Desired Condition',
            ),
            items: _conditions.map((condition) {
              return DropdownMenuItem<String>(
                value: condition,
                child: Text(condition),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCondition = value!;
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        // Location (Use Location Picker Widget)
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              AccurateLocationPickerWidget(
                controller: _locationController,
                countryCode: CountryService.instance.countryCode,
                labelText: '',
                hintText: 'Enter item pickup location',
                isRequired: true,
                prefixIcon: Icons.location_on,
                onLocationSelected: (address, lat, lng) {
                  print('=== EDIT ITEM LOCATION CALLBACK ===');
                  print('Address: "$address"');
                  print('Latitude: $lat');
                  print('Longitude: $lng');
                  print('==================================');

                  setState(() {
                    _locationController.text = address;
                    _selectedLatitude = lat;
                    _selectedLongitude = lng;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Budget
        _buildFlatField(
          child: TextFormField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: CurrencyHelper.instance.getBudgetLabel(),
              hintText: 'Enter your budget range',
              prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Photo/Link
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo/Link (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload a picture of the item or provide a reference link',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ImageUploadWidget(
                initialImages: _imageUrls,
                uploadPath: 'request_images/items',
                onImagesChanged: (urls) {
                  setState(() {
                    _imageUrls = urls;
                  });
                },
                maxImages: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceFields() {
    return Column(
      children: [
        // Service Type (Use Category Picker)
        GestureDetector(
          onTap: () async {
            final result = await showModalBottomSheet<Map<String, String>>(
              context: context,
              isScrollControlled: true,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.9,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (context, scrollController) => CategoryPicker(
                  requestType: 'service',
                  module: _selectedModule,
                  scrollController: scrollController,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _selectedCategory = result['category'] ?? _selectedCategory;
                _selectedSubcategory =
                    result['subcategory'] ?? _selectedSubcategory;
                _selectedCategoryId = result['category'];
                _selectedSubCategoryId = result['subcategory'];
                _resetServiceDynamicFields();
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Type',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (_selectedCategory.isNotEmpty == true &&
                                _selectedSubcategory?.isNotEmpty == true)
                            ? '$_selectedCategory > $_selectedSubcategory'
                            : 'Select service category',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Request Title
        _buildFlatField(
          child: TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Request Title',
              hintText: 'Enter a short, descriptive title',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Description
        _buildFlatField(
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText:
                  'Provide detailed information about the service needed...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Location (Use Location Picker Widget)
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              AccurateLocationPickerWidget(
                controller: _locationController,
                countryCode: CountryService.instance.countryCode,
                labelText: '',
                hintText: 'Enter service location',
                isRequired: true,
                prefixIcon: Icons.location_on,
                onLocationSelected: (address, lat, lng) {
                  setState(() {
                    _locationController.text = address;
                    _selectedLatitude = lat;
                    _selectedLongitude = lng;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Preferred Date & Time (Remove Border)
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preferred Date & Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _preferredDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  color: const Color(0xFFF8F9FA),
                  child: Text(
                    _preferredDateTime == null
                        ? 'Select date and time'
                        : '${_preferredDateTime!.day}/${_preferredDateTime!.month}/${_preferredDateTime!.year} at ${TimeOfDay.fromDateTime(_preferredDateTime!).format(context)}',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Urgency
        _buildFlatField(
          child: DropdownButtonFormField<String>(
            value: _selectedUrgency,
            decoration: const InputDecoration(
              labelText: 'Urgency',
            ),
            items: _urgencyLevels.map((urgency) {
              return DropdownMenuItem<String>(
                value: urgency,
                child: Text(urgency),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedUrgency = value!;
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        // Budget
        _buildFlatField(
          child: TextFormField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: CurrencyHelper.instance.getBudgetLabel(),
              hintText: 'Enter your budget range',
              prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Photo/Video
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo/Video (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload a photo or short video to better explain the issue',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ImageUploadWidget(
                initialImages: _imageUrls,
                uploadPath: 'request_images/services',
                onImagesChanged: (urls) {
                  setState(() {
                    _imageUrls = urls;
                  });
                },
                maxImages: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Module/Subcategory-specific dynamic fields (edit)
        _buildServiceDynamicFields(),
      ],
    );
  }

  void _resetServiceDynamicFields() {
    _peopleCountController.clear();
    _durationDaysController.clear();
    _guestsCountController.clear();
    _areaSizeController.clear();
    _sessionsPerWeekController.clear();
    _experienceYearsController.clear();
    _needsGuide = false;
    _pickupRequiredForTour = false;
    _educationLevel = 'Beginner';
    _positionType = 'Full-time';
  }

  Widget _buildServiceDynamicFields() {
    if (_selectedType != RequestType.service || _selectedModule == null) {
      return const SizedBox.shrink();
    }
    final module = _selectedModule!.toLowerCase();
    switch (module) {
      case 'tours':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlatField(
              child: TextFormField(
                controller: _peopleCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of People',
                  hintText: 'Enter headcount for the tour',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFlatField(
              child: TextFormField(
                controller: _durationDaysController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (days)',
                  hintText: 'e.g., 3',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFlatField(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Need a tour guide?'),
                    value: _needsGuide,
                    onChanged: (v) => setState(() => _needsGuide = v ?? false),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pickup required'),
                    value: _pickupRequiredForTour,
                    onChanged: (v) =>
                        setState(() => _pickupRequiredForTour = v ?? false),
                  ),
                ],
              ),
            ),
          ],
        );
      case 'events':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlatField(
              child: TextFormField(
                controller: _guestsCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Guests Count',
                  hintText: 'How many people will attend?',
                ),
              ),
            ),
          ],
        );
      case 'construction':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlatField(
              child: TextFormField(
                controller: _areaSizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Area Size (sqft)',
                  hintText: 'Approximate area size',
                ),
              ),
            ),
          ],
        );
      case 'education':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlatField(
              child: DropdownButtonFormField<String>(
                value: _educationLevel,
                decoration: const InputDecoration(labelText: 'Level'),
                items: const [
                  DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                  DropdownMenuItem(
                      value: 'Intermediate', child: Text('Intermediate')),
                  DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                ],
                onChanged: (v) =>
                    setState(() => _educationLevel = v ?? 'Beginner'),
              ),
            ),
            const SizedBox(height: 16),
            _buildFlatField(
              child: TextFormField(
                controller: _sessionsPerWeekController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sessions per week',
                  hintText: 'e.g., 2',
                ),
              ),
            ),
          ],
        );
      case 'hiring':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFlatField(
              child: DropdownButtonFormField<String>(
                value: _positionType,
                decoration: const InputDecoration(labelText: 'Position Type'),
                items: const [
                  DropdownMenuItem(
                      value: 'Full-time', child: Text('Full-time')),
                  DropdownMenuItem(
                      value: 'Part-time', child: Text('Part-time')),
                  DropdownMenuItem(value: 'Contract', child: Text('Contract')),
                ],
                onChanged: (v) =>
                    setState(() => _positionType = v ?? 'Full-time'),
              ),
            ),
            const SizedBox(height: 16),
            _buildFlatField(
              child: TextFormField(
                controller: _experienceYearsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Experience (years)',
                  hintText: 'e.g., 3',
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Map<String, dynamic> _buildModuleFieldsPayload() {
    final module = _selectedModule?.toLowerCase();
    switch (module) {
      case 'tours':
        return {
          'peopleCount': _peopleCountController.text.trim().isNotEmpty
              ? int.tryParse(_peopleCountController.text.trim())
              : null,
          'durationDays': _durationDaysController.text.trim().isNotEmpty
              ? int.tryParse(_durationDaysController.text.trim())
              : null,
          'needsGuide': _needsGuide,
          'pickupRequired': _pickupRequiredForTour,
        }..removeWhere((k, v) => v == null);
      case 'events':
        return {
          'guestsCount': _guestsCountController.text.trim().isNotEmpty
              ? int.tryParse(_guestsCountController.text.trim())
              : null,
        }..removeWhere((k, v) => v == null);
      case 'construction':
        return {
          'areaSizeSqft': _areaSizeController.text.trim().isNotEmpty
              ? double.tryParse(_areaSizeController.text.trim())
              : null,
        }..removeWhere((k, v) => v == null);
      case 'education':
        return {
          'level': _educationLevel,
          'sessionsPerWeek': _sessionsPerWeekController.text.trim().isNotEmpty
              ? int.tryParse(_sessionsPerWeekController.text.trim())
              : null,
        }..removeWhere((k, v) => v == null);
      case 'hiring':
        return {
          'positionType': _positionType,
          'experienceYears': _experienceYearsController.text.trim().isNotEmpty
              ? int.tryParse(_experienceYearsController.text.trim())
              : null,
        }..removeWhere((k, v) => v == null);
      default:
        return {};
    }
  }

  Widget _buildRentalFields() {
    return Column(
      children: [
        // Request Title
        _buildFlatField(
          child: TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Request Title',
              hintText: 'Enter a short, descriptive title',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Description
        _buildFlatField(
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText:
                  'Provide detailed information about the rental needed...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Item to Rent (Use Category Picker)
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Item to Rent',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final result =
                      await showModalBottomSheet<Map<String, String>>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: CategoryPicker(
                        requestType: 'rent',
                        scrollController: ScrollController(),
                      ),
                    ),
                  );

                  if (result != null && result['category'] != null) {
                    setState(() {
                      _selectedCategory = result['category']!;
                      _selectedSubcategory = result['subcategory'];
                      _selectedCategoryId =
                          result['category']!; // Use category name as ID
                      _selectedSubCategoryId = result['subcategory'];
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (_selectedSubcategory != null &&
                                _selectedSubcategory!.isNotEmpty)
                            ? _selectedSubcategory!
                            : (_selectedCategory.isNotEmpty
                                ? _selectedCategory
                                : 'Select item to rent'),
                        style: TextStyle(
                          color: (_selectedSubcategory != null &&
                                      _selectedSubcategory!.isNotEmpty) ||
                                  _selectedCategory.isNotEmpty
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Start Date & Time
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Start Date & Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _startDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  color: const Color(0xFFF8F9FA),
                  child: Text(
                    _startDateTime == null
                        ? 'Select start date and time'
                        : '${_startDateTime!.day}/${_startDateTime!.month}/${_startDateTime!.year} at ${TimeOfDay.fromDateTime(_startDateTime!).format(context)}',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // End Date & Time
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'End Date & Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDateTime ?? DateTime.now(),
                    firstDate: _startDateTime ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _endDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  color: const Color(0xFFF8F9FA),
                  child: Text(
                    _endDateTime == null
                        ? 'Select end date and time'
                        : '${_endDateTime!.day}/${_endDateTime!.month}/${_endDateTime!.year} at ${TimeOfDay.fromDateTime(_endDateTime!).format(context)}',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Location (Use Location Picker)
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              AccurateLocationPickerWidget(
                controller: _locationController,
                labelText: '',
                hintText: 'Enter rental pickup location',
                isRequired: true,
                prefixIcon: Icons.location_on,
                onLocationSelected: (address, lat, lng) {
                  setState(() {
                    _locationController.text = address;
                    _selectedLatitude = lat;
                    _selectedLongitude = lng;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Budget
        _buildFlatField(
          child: TextFormField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Budget (per day/hour)',
              hintText: 'Enter your budget',
              prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pickup / Dropoff
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pickup/Dropoff Preference',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _pickupDropoffPreference,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(
                      value: 'pickup', child: Text('I will pickup')),
                  DropdownMenuItem(
                      value: 'delivery', child: Text('Please deliver')),
                  DropdownMenuItem(
                      value: 'flexible', child: Text('Either option works')),
                ],
                onChanged: (value) {
                  setState(() {
                    _pickupDropoffPreference = value!;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Photo/Link
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo/Link (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload photo or share link of similar item you want to rent',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ImageUploadWidget(
                initialImages: _imageUrls,
                uploadPath: 'request_images/rentals',
                onImagesChanged: (urls) {
                  setState(() {
                    _imageUrls = urls;
                  });
                },
                maxImages: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryFields() {
    return Column(
      children: [
        // Request Title
        _buildFlatField(
          child: TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Request Title',
              hintText: 'Enter a short, descriptive title',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Pickup Location
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pickup Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              AccurateLocationPickerWidget(
                controller: _pickupLocationController,
                labelText: '',
                hintText: 'Enter pickup location',
                isRequired: true,
                prefixIcon: Icons.location_on,
                onLocationSelected: (address, lat, lng) {
                  setState(() {
                    _pickupLocationController.text = address;
                    _pickupLatitude = lat;
                    _pickupLongitude = lng;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Drop-off Location
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Drop-off Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              AccurateLocationPickerWidget(
                controller: _dropoffLocationController,
                labelText: '',
                hintText: 'Enter dropoff location',
                isRequired: true,
                prefixIcon: Icons.location_on,
                onLocationSelected: (address, lat, lng) {
                  setState(() {
                    _dropoffLocationController.text = address;
                    _dropoffLatitude = lat;
                    _dropoffLongitude = lng;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Item Categories (Use Category Picker)
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Item Category',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final result =
                      await showModalBottomSheet<Map<String, String>>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.8,
                      child: CategoryPicker(
                        requestType: 'delivery',
                        scrollController: ScrollController(),
                      ),
                    ),
                  );

                  if (result != null && result['category'] != null) {
                    setState(() {
                      _selectedCategory = result['category']!;
                      _selectedSubcategory = result['subcategory'];
                      _selectedCategoryId = result['category']!;
                      _selectedSubCategoryId = result['subcategory'];
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (_selectedSubcategory != null &&
                                _selectedSubcategory!.isNotEmpty)
                            ? _selectedSubcategory!
                            : (_selectedCategory.isNotEmpty
                                ? _selectedCategory
                                : 'Select item category'),
                        style: TextStyle(
                          color: (_selectedSubcategory != null &&
                                      _selectedSubcategory!.isNotEmpty) ||
                                  _selectedCategory.isNotEmpty
                              ? Colors.black
                              : Colors.grey.shade600,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Item Description
        _buildFlatField(
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Item Description',
              hintText: 'Describe what needs to be delivered...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please describe the item(s)';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),

        // Weight & Dimensions
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weight & Dimensions (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Weight (kg)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _dimensionsController,
                      decoration: const InputDecoration(
                        hintText: 'Dimensions (L x W x H)',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Preferred Delivery Time
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preferred Delivery Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(() {
                        _preferredDeliveryTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  color: const Color(0xFFF8F9FA),
                  child: Text(
                    _preferredDeliveryTime == null
                        ? 'Select preferred delivery time'
                        : '${_preferredDeliveryTime!.day}/${_preferredDeliveryTime!.month}/${_preferredDeliveryTime!.year} at ${TimeOfDay.fromDateTime(_preferredDeliveryTime!).format(context)}',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Special Instructions
        _buildFlatField(
          child: TextFormField(
            controller: _specialInstructionsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Special Instructions (Optional)',
              hintText: 'Any special handling requirements, access codes, etc.',
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Photo Upload
        _buildFlatField(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photo Upload (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              const Text(
                'Upload photos of items to be delivered',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ImageUploadWidget(
                initialImages: _imageUrls,
                uploadPath: 'request_images/deliveries',
                onImagesChanged: (urls) {
                  setState(() {
                    _imageUrls = urls;
                  });
                },
                maxImages: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for category selection based on request type
    if ((_selectedType == RequestType.service ||
            _selectedType == RequestType.delivery ||
            _selectedType == RequestType.rental) &&
        (_selectedCategory.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a ${_selectedType.name} category'),
          backgroundColor: Colors.red,
        ),
      );
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

      // Update the request using the service method
      LocationInfo? locationInfo;
      if (_locationController.text.trim().isNotEmpty) {
        if (_selectedLatitude != null && _selectedLongitude != null) {
          locationInfo = LocationInfo(
            address: _locationController.text.trim(),
            latitude: _selectedLatitude!,
            longitude: _selectedLongitude!,
          );
          print('=== EDIT SCREEN LOCATION DEBUG ===');
          print('Using coordinates - address: "${locationInfo.address}"');
          print('latitude: ${locationInfo.latitude}');
          print('longitude: ${locationInfo.longitude}');
          print('===================================');
        } else {
          // Create location with just address if coordinates are not available
          locationInfo = LocationInfo(
            address: _locationController.text.trim(),
            latitude: 0.0, // Default coordinates
            longitude: 0.0,
          );
          print('=== EDIT SCREEN LOCATION WARNING ===');
          print(
              'No coordinates available for address: "${_locationController.text.trim()}"');
          print('Using fallback coordinates: 0.0, 0.0');
          print('====================================');
        }
      }

      // Prepare update data for REST API
      final Map<String, dynamic> updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'budget': _budgetController.text.trim().isNotEmpty
            ? double.tryParse(_budgetController.text.trim())
            : null,
        'image_urls': _imageUrls.isNotEmpty ? _imageUrls : null,
        'metadata': _getTypeSpecificData(),
      };

      // Add location data if available
      if (locationInfo != null) {
        updateData['location_address'] = locationInfo.address;
        updateData['location_latitude'] = locationInfo.latitude;
        updateData['location_longitude'] = locationInfo.longitude;
      }

      // Include pickup/dropoff coordinates for delivery when available
      if (_selectedType == RequestType.delivery) {
        if (_pickupLatitude != null && _pickupLongitude != null) {
          updateData['pickup_latitude'] = _pickupLatitude;
          updateData['pickup_longitude'] = _pickupLongitude;
        }
        if (_dropoffLatitude != null && _dropoffLongitude != null) {
          updateData['dropoff_latitude'] = _dropoffLatitude;
          updateData['dropoff_longitude'] = _dropoffLongitude;
        }
      }

      // Use REST service to update the request
      final updatedRequest = await _restService.updateRequest(
        widget.request.id,
        updateData,
      );

      if (updatedRequest != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${_getTypeDisplayName(_selectedType)} updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
              context, true); // Return true to indicate successful update
        }
      } else {
        throw Exception('Failed to update request');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, dynamic> _getTypeSpecificData() {
    switch (_selectedType) {
      case RequestType.item:
        return {
          'itemName': _itemNameController.text.trim(),
          'category': _selectedCategory,
          'categoryId': _selectedCategoryId ?? '',
          'subCategoryId': _selectedSubCategoryId ?? '',
          'subcategory': _selectedSubcategory ?? '',
          'quantity': int.tryParse(_quantityController.text.trim()),
          'condition': _selectedCondition,
        };
      case RequestType.service:
        return {
          'serviceType': (_selectedSubcategory?.isNotEmpty == true)
              ? _selectedSubcategory
              : _selectedCategory,
          'module': _selectedModule,
          'categoryId': _selectedCategoryId ?? '',
          'subCategoryId': _selectedSubCategoryId ?? '',
          'category': _selectedCategory,
          'subcategory': _selectedSubcategory,
          'preferredDateTime': _preferredDateTime?.millisecondsSinceEpoch,
          'urgency': _selectedUrgency,
          'moduleFields': _buildModuleFieldsPayload(),
        };
      case RequestType.delivery:
        return {
          'pickupLocation': _pickupLocationController.text.trim(),
          'dropoffLocation': _dropoffLocationController.text.trim(),
          'itemCategory': _selectedCategory.trim(),
          'category': _selectedCategory
              .trim(), // Store in both fields for compatibility
          'categoryId': _selectedCategoryId?.trim() ?? '',
          'subcategory': _selectedSubcategory?.trim(),
          'subcategoryId': _selectedSubCategoryId?.trim() ?? '',
          'itemDescription': _descriptionController.text.trim(),
          'weight': _weightController.text.trim().isNotEmpty
              ? double.tryParse(_weightController.text.trim())
              : null,
          'dimensions': _dimensionsController.text.trim(),
          'preferredDeliveryTime':
              _preferredDeliveryTime?.millisecondsSinceEpoch,
          'specialInstructions': _specialInstructionsController.text.trim(),
        };
      case RequestType.rental:
        return {
          'itemToRent': _itemToRentController.text.trim(),
          'category': _selectedCategory,
          'categoryId': _selectedCategoryId ?? '',
          'subcategory': _selectedSubcategory,
          'subcategoryId': _selectedSubCategoryId ?? '',
          'startDate': _startDateTime?.millisecondsSinceEpoch,
          'endDate': _endDateTime?.millisecondsSinceEpoch,
          'pickupDropoffPreference': _pickupDropoffPreference,
        };
      default:
        return {};
    }
  }
}
