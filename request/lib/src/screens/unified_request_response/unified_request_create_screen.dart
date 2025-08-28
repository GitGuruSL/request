import 'package:flutter/material.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_page.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/centralized_request_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../widgets/image_upload_widget.dart';
import '../../services/country_service.dart';
import '../../widgets/accurate_location_picker_widget.dart';
import '../../widgets/category_picker.dart';
import '../../utils/currency_helper.dart';

class UnifiedRequestCreateScreen extends StatefulWidget {
  final RequestType? initialType;
  final String?
      initialModule; // e.g., item, rent, delivery, ride, tours, events, construction, education, hiring, other

  const UnifiedRequestCreateScreen(
      {super.key, this.initialType, this.initialModule});

  @override
  State<UnifiedRequestCreateScreen> createState() =>
      _UnifiedRequestCreateScreenState();
}

class _UnifiedRequestCreateScreenState
    extends State<UnifiedRequestCreateScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  final CentralizedRequestService _requestService = CentralizedRequestService();

  // Common form controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();

  // Item-specific controllers
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();

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
  final _specialInstructionsController = TextEditingController();
  // Service module dynamic controllers/fields
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

  // Tours module – general and category-specific state
  DateTime? _tourStartDate; // date-only
  DateTime? _tourEndDate; // date-only
  int _adults = 2;
  int _children = 0;

  // Tours & Experiences
  String _tourType = 'Cultural & Heritage';
  String _preferredLanguage = 'English';
  final _otherLanguageController = TextEditingController();
  final Set<String> _timeOfDayPrefs =
      <String>{}; // Morning, Afternoon, Evening, Full Day
  bool _jeepIncluded = false;
  String _skillLevel = 'Beginner';

  // Transportation (within tours)
  String _transportType = 'Hire Driver for Tour';
  final _tourPickupController = TextEditingController();
  final _tourDropoffController = TextEditingController();
  final Set<String> _vehicleTypes =
      <String>{}; // Car (Sedan), Van (AC), Tuk-Tuk, Motorbike/Scooter, Luxury Vehicle
  String _luggageOption = 'Small Bags Only';
  final _itineraryController = TextEditingController();
  final _flightNumberController = TextEditingController();
  final _flightTimeController = TextEditingController();
  bool _licenseConfirmed = false;

  // Accommodation (within tours)
  String _accommodationType = 'Hotel';
  int _unitsCount = 1; // rooms or beds
  String _unitsType = 'rooms'; // 'rooms' or 'beds'
  final Set<String> _amenities =
      <String>{}; // AC, Hot Water, Wi-Fi, Kitchen, Pool, Parking
  String _boardBasis = 'Room Only';
  bool _cookStaffRequired = false;
  bool _mealsWithHostFamily = false;
  String _hostelRoomType = 'Dormitory';

  RequestType _selectedType = RequestType.item;
  String? _selectedModule; // service subtype/module context
  String _selectedCondition = 'New';
  String _selectedUrgency = 'Flexible';
  // kept for parity with other flows if needed later

  String _selectedCategory = 'Electronics';
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedSubcategory;
  String _pickupDropoffPreference = 'pickup';
  // legacy placeholders removed; using *_DateTime specific fields
  DateTime? _preferredDateTime;
  DateTime? _startDateTime;
  DateTime? _endDateTime;
  DateTime? _preferredDeliveryTime;
  List<String> _imageUrls = [];
  bool _isLoading = false;
  double? _selectedLatitude;
  double? _selectedLongitude;

  final List<String> _conditions = [
    'New',
    'Used',
    'For Parts',
    'Any Condition'
  ];
  final List<String> _urgencyLevels = ['Flexible', 'ASAP', 'Specific Date'];
  // delivery time options are derived inline in UI where needed

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? RequestType.item;
    _selectedModule = widget.initialModule;
    // If opened for a specific service module, reflect it in the visible label
    if (_selectedType == RequestType.service && _selectedModule != null) {
      final m = _selectedModule!;
      // Use module as a temporary visible category label until user picks from CategoryPicker
      _selectedCategory = m.isNotEmpty
          ? m[0].toUpperCase() + (m.length > 1 ? m.substring(1) : '')
          : _selectedCategory;
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
    _itemToRentController.dispose();
    _rentalItemController.dispose();
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    _itemCategoryController.dispose();
    _itemDescriptionController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _specialInstructionsController.dispose();
    // dispose dynamic controllers
    _peopleCountController.dispose();
    _durationDaysController.dispose();
    _guestsCountController.dispose();
    _areaSizeController.dispose();
    _sessionsPerWeekController.dispose();
    _experienceYearsController.dispose();
    _otherLanguageController.dispose();
    _tourPickupController.dispose();
    _tourDropoffController.dispose();
    _itineraryController.dispose();
    _flightNumberController.dispose();
    _flightTimeController.dispose();
    super.dispose();
  }

  // Derive which module banner to show based on selected type and module.
  String? _effectiveBannerModule() {
    // If a specific module is set, use it (normalize aliases)
    if (_selectedModule != null && _selectedModule!.isNotEmpty) {
      final m = _selectedModule!.toLowerCase();
      if (m == 'rental') return 'rent';
      if (m == 'jobs') return 'hiring';
      return m;
    }
    // Otherwise, map the high-level request type
    switch (_selectedType) {
      case RequestType.item:
        return 'item';
      case RequestType.rental:
        return 'rent';
      case RequestType.delivery:
        return 'delivery';
      case RequestType.ride:
        return 'ride';
      case RequestType.service:
        return null; // no specific module chosen yet
      case RequestType.price:
        return null;
    }
  }

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

  // Color mapping now handled by GlassTheme buttons

  String _getRequestTypeString(RequestType type) {
    switch (type) {
      case RequestType.item:
        return 'item';
      case RequestType.service:
        return 'service';
      case RequestType.delivery:
        return 'delivery';
      case RequestType.rental:
        return 'rental';
      case RequestType.ride:
        return 'ride';
      case RequestType.price:
        return 'price';
    }
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
          requestType: _getRequestTypeString(_selectedType),
          module: _selectedType == RequestType.service ? _selectedModule : null,
          scrollController: scrollController,
        ),
      ),
    );

    if (result != null && result.containsKey('category')) {
      setState(() {
        _selectedCategory = result['category'] ?? 'Electronics';
        _selectedSubcategory = result['subcategory'];
        _selectedCategoryId = result['categoryId'] ?? _selectedCategoryId;
        _selectedSubCategoryId =
            result['subcategoryId'] ?? _selectedSubcategory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'Create ${_getTypeDisplayNameWithModule()}',
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
              // Show banner for all modules/types: item, rent, delivery, ride, tours, events, construction, education, hiring, other
              if (_effectiveBannerModule() != null)
                _buildModuleBanner(_effectiveBannerModule()!),
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
                  : Text('Create ${_getTypeDisplayNameWithModule()}'),
            ),
          ),
        ),
      ),
    );
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

  Widget _buildModuleBanner(String module) {
    final info = _moduleTheme(module);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: info.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Icon(info.icon, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    )),
                if (info.subtitle != null)
                  Text(info.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ModuleTheme _moduleTheme(String module) {
    switch (module.toLowerCase()) {
      case 'item':
        return _ModuleTheme(
          title: 'Item Request',
          subtitle: 'Buy or request items',
          icon: Icons.shopping_bag,
          gradient: const [Color(0xFF2563EB), Color(0xFF60A5FA)],
        );
      case 'rent':
      case 'rental':
        return _ModuleTheme(
          title: 'Rental',
          subtitle: 'Rent items and equipment',
          icon: Icons.business_center,
          gradient: const [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
        );
      case 'delivery':
        return _ModuleTheme(
          title: 'Delivery',
          subtitle: 'Pickup and drop-off made easy',
          icon: Icons.local_shipping,
          gradient: const [Color(0xFFF97316), Color(0xFFF59E0B)],
        );
      case 'ride':
        return _ModuleTheme(
          title: 'Ride',
          subtitle: 'Get a driver quickly',
          icon: Icons.directions_car,
          gradient: const [Color(0xFF06B6D4), Color(0xFF22C55E)],
        );
      case 'tours':
        return _ModuleTheme(
          title: 'Tours & Travel',
          subtitle: 'Trips, packages, and activities',
          icon: Icons.flight_takeoff,
          gradient: const [Color(0xFF9333EA), Color(0xFF6366F1)],
        );
      case 'events':
        return _ModuleTheme(
          title: 'Events',
          subtitle: 'Weddings, parties, and more',
          icon: Icons.celebration,
          gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
        );
      case 'construction':
        return _ModuleTheme(
          title: 'Construction',
          subtitle: 'Builders, repairs, and renovations',
          icon: Icons.construction,
          gradient: const [Color(0xFF0EA5E9), Color(0xFF10B981)],
        );
      case 'education':
        return _ModuleTheme(
          title: 'Education',
          subtitle: 'Tutoring and training',
          icon: Icons.school,
          gradient: const [Color(0xFF22C55E), Color(0xFF06B6D4)],
        );
      case 'hiring':
        return _ModuleTheme(
          title: 'Hiring',
          subtitle: 'Find talent or gigs',
          icon: Icons.work,
          gradient: const [Color(0xFF3B82F6), Color(0xFF10B981)],
        );
      case 'other':
      default:
        return _ModuleTheme(
          title: 'Other Service',
          subtitle: 'Tell us what you need',
          icon: Icons.more_horiz,
          gradient: const [Color(0xFF64748B), Color(0xFF94A3B8)],
        );
    }
  }

  Widget _buildFlatField({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: GlassTheme.glassContainerSubtle,
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
                  print('=== ITEM LOCATION CALLBACK RECEIVED ===');
                  print('Address: "$address"');
                  print('Latitude: $lat');
                  print('Longitude: $lng');
                  print('========================================');

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
                  requestType: _getRequestTypeString(_selectedType),
                  module: _selectedType == RequestType.service
                      ? _selectedModule
                      : null,
                  scrollController: scrollController,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _selectedCategory = result['category'] ?? _selectedCategory;
                _selectedSubcategory =
                    result['subcategory'] ?? _selectedSubcategory;
                _selectedCategoryId =
                    result['categoryId'] ?? _selectedCategoryId;
                _selectedSubCategoryId =
                    result['subcategoryId'] ?? _selectedSubCategoryId;
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

        // Tours module: General fields at the top
        if (_selectedType == RequestType.service &&
            (_selectedModule?.toLowerCase() == 'tours')) ...[
          // Location / Destination
          _buildFlatField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location / Destination',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                AccurateLocationPickerWidget(
                  controller: _locationController,
                  countryCode: CountryService.instance.countryCode,
                  labelText: '',
                  hintText: 'Enter destination (e.g., Kandy, Ella, Yala)',
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

          // Start/End Dates (date-only)
          _buildFlatField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dates',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _tourStartDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null)
                            setState(() => _tourStartDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFFF8F9FA),
                          child: Text(
                            _tourStartDate == null
                                ? 'Start Date'
                                : _formatDate(_tourStartDate!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final initial =
                              _tourEndDate ?? _tourStartDate ?? DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: _tourStartDate ?? DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _tourEndDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFFF8F9FA),
                          child: Text(
                            _tourEndDate == null
                                ? 'End Date'
                                : _formatDate(_tourEndDate!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Number of People (Adults / Children)
          _buildFlatField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Number of People',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                _buildCounterRow(
                    'Adults (12+)', _adults, (v) => setState(() => _adults = v),
                    min: 1),
                const SizedBox(height: 8),
                _buildCounterRow('Children (2-11)', _children,
                    (v) => setState(() => _children = v),
                    min: 0),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

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

        // Description (Tours: Special Requirements / Description)
        _buildFlatField(
          child: TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: (_selectedModule?.toLowerCase() == 'tours')
                  ? 'Special Requirements / Description'
                  : 'Description',
              hintText: (_selectedModule?.toLowerCase() == 'tours')
                  ? 'Any extra details (e.g., wheelchair access, child-friendly)'
                  : 'Provide detailed information about the service needed...',
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

        // Location for non-Tours services (Tours handled above)
        if (!(_selectedType == RequestType.service &&
            (_selectedModule?.toLowerCase() == 'tours')))
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
        if (!(_selectedType == RequestType.service &&
            (_selectedModule?.toLowerCase() == 'tours')))
          const SizedBox(height: 16),

        // Preferred Date & Time for non-Tours (Tours uses Start/End)
        if (!(_selectedType == RequestType.service &&
            (_selectedModule?.toLowerCase() == 'tours'))) ...[
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
        ],

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

        // Module/Subcategory-specific dynamic fields
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
        return _buildToursModuleFields();
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
          // General (for all tours module requests)
          'startDate': _tourStartDate?.millisecondsSinceEpoch,
          'endDate': _tourEndDate?.millisecondsSinceEpoch,
          'adults': _adults,
          'children': _children,
          // Tours & Experiences specific
          if (_selectedCategory.toLowerCase() == 'tours & experiences') ...{
            'tourType': _tourType,
            'preferredLanguage': _preferredLanguage,
            'otherLanguage': _preferredLanguage == 'Other'
                ? _otherLanguageController.text.trim()
                : null,
            'timeOfDayPrefs':
                _timeOfDayPrefs.isNotEmpty ? _timeOfDayPrefs.toList() : null,
            'jeepIncluded':
                _tourType == 'Wildlife & Safari' ? _jeepIncluded : null,
            'skillLevel':
                _tourType == 'Adventure & Water Sports' ? _skillLevel : null,
          },
          // Transportation specific
          if (_selectedCategory.toLowerCase() == 'transportation') ...{
            'transportType': _transportType,
            'transportPickup': _tourPickupController.text.trim().isNotEmpty
                ? _tourPickupController.text.trim()
                : null,
            'transportDropoff': _tourDropoffController.text.trim().isNotEmpty
                ? _tourDropoffController.text.trim()
                : null,
            'vehicleTypes':
                _vehicleTypes.isNotEmpty ? _vehicleTypes.toList() : null,
            'luggage': _transportType == 'Vehicle Rental (Self-Drive)'
                ? null
                : _luggageOption,
            'itinerary': _transportType == 'Hire Driver for Tour'
                ? _itineraryController.text.trim()
                : null,
            'flightNumber': _transportType == 'Airport Transfer'
                ? _flightNumberController.text.trim()
                : null,
            'flightTime': _transportType == 'Airport Transfer'
                ? _flightTimeController.text.trim()
                : null,
            'licenseConfirmed': _transportType == 'Vehicle Rental (Self-Drive)'
                ? _licenseConfirmed
                : null,
          },
          // Accommodation specific
          if (_selectedCategory.toLowerCase() == 'accommodation') ...{
            'accommodationType': _accommodationType,
            'unitsCount': _unitsCount,
            'unitsType': _unitsType,
            'amenities': _amenities.isNotEmpty ? _amenities.toList() : null,
            'boardBasis': _boardBasis,
            'cookStaffRequired': _accommodationType == 'Villa/Bungalow'
                ? _cookStaffRequired
                : null,
            'mealsWithHostFamily': _accommodationType == 'Guesthouse/Homestay'
                ? _mealsWithHostFamily
                : null,
            'hostelRoomType':
                _accommodationType == 'Hostel' ? _hostelRoomType : null,
          },
          // Legacy simple fields kept (optional)
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

  // Tours module UI builder
  Widget _buildToursModuleFields() {
    final cat = _selectedCategory.toLowerCase();
    if (cat == 'tours & experiences') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type of Tour
          _buildFlatField(
            child: DropdownButtonFormField<String>(
              value: _tourType,
              decoration: const InputDecoration(labelText: 'Type of Tour'),
              items: const [
                DropdownMenuItem(
                    value: 'Cultural & Heritage',
                    child: Text('Cultural & Heritage')),
                DropdownMenuItem(
                    value: 'Wildlife & Safari',
                    child: Text('Wildlife & Safari')),
                DropdownMenuItem(
                    value: 'Nature & Hiking', child: Text('Nature & Hiking')),
                DropdownMenuItem(
                    value: 'Local Experience', child: Text('Local Experience')),
                DropdownMenuItem(
                    value: 'Adventure & Water Sports',
                    child: Text('Adventure & Water Sports')),
              ],
              onChanged: (v) => setState(() => _tourType = v ?? _tourType),
            ),
          ),
          const SizedBox(height: 16),
          // Preferred Language
          _buildFlatField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  value: _preferredLanguage,
                  decoration:
                      const InputDecoration(labelText: 'Preferred Language'),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Sinhala', child: Text('Sinhala')),
                    DropdownMenuItem(value: 'Tamil', child: Text('Tamil')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) =>
                      setState(() => _preferredLanguage = v ?? 'English'),
                ),
                if (_preferredLanguage == 'Other')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextFormField(
                      controller: _otherLanguageController,
                      decoration:
                          const InputDecoration(labelText: 'Specify Language'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Preferred Time of Day (multi-select)
          _buildFlatField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preferred Time of Day',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ...['Morning', 'Afternoon', 'Evening', 'Full Day'].map((t) {
                  final selected = _timeOfDayPrefs.contains(t);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t),
                    value: selected,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _timeOfDayPrefs.add(t);
                      } else {
                        _timeOfDayPrefs.remove(t);
                      }
                    }),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sub-type specific
          if (_tourType == 'Wildlife & Safari')
            _buildFlatField(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jeep Included?'),
                value: _jeepIncluded,
                onChanged: (v) => setState(() => _jeepIncluded = v ?? false),
              ),
            ),
          if (_tourType == 'Adventure & Water Sports')
            _buildFlatField(
              child: DropdownButtonFormField<String>(
                value: _skillLevel,
                decoration: const InputDecoration(labelText: 'Skill Level'),
                items: const [
                  DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                  DropdownMenuItem(
                      value: 'Intermediate', child: Text('Intermediate')),
                  DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
                ],
                onChanged: (v) => setState(() => _skillLevel = v ?? 'Beginner'),
              ),
            ),
        ],
      );
    } else if (cat == 'transportation') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type of Transport
          _buildFlatField(
            child: DropdownButtonFormField<String>(
              value: _transportType,
              decoration: const InputDecoration(labelText: 'Type of Transport'),
              items: const [
                DropdownMenuItem(
                    value: 'Hire Driver for Tour',
                    child: Text('Hire Driver for Tour')),
                DropdownMenuItem(
                    value: 'Airport Transfer', child: Text('Airport Transfer')),
                DropdownMenuItem(
                    value: 'Vehicle Rental (Self-Drive)',
                    child: Text('Vehicle Rental (Self-Drive)')),
                DropdownMenuItem(
                    value: 'Inter-city Taxi', child: Text('Inter-city Taxi')),
              ],
              onChanged: (v) =>
                  setState(() => _transportType = v ?? _transportType),
            ),
          ),
          const SizedBox(height: 16),
          // Pickup/Dropoff Locations
          _buildFlatField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pickup Location'),
                const SizedBox(height: 6),
                AccurateLocationPickerWidget(
                  controller: _tourPickupController,
                  countryCode: CountryService.instance.countryCode,
                  labelText: '',
                  hintText: 'Enter pickup location',
                  isRequired: true,
                  prefixIcon: Icons.my_location,
                  onLocationSelected: (address, lat, lng) {
                    _tourPickupController.text = address;
                  },
                ),
                const SizedBox(height: 12),
                const Text('Drop-off Location'),
                const SizedBox(height: 6),
                AccurateLocationPickerWidget(
                  controller: _tourDropoffController,
                  countryCode: CountryService.instance.countryCode,
                  labelText: '',
                  hintText: 'Enter drop-off location',
                  isRequired: true,
                  prefixIcon: Icons.location_on,
                  onLocationSelected: (address, lat, lng) {
                    _tourDropoffController.text = address;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Vehicle Type Preference (multi-select)
          _buildFlatField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vehicle Type Preference'),
                ...[
                  'Car (Sedan)',
                  'Van (AC)',
                  'Tuk-Tuk',
                  'Motorbike/Scooter',
                  'Luxury Vehicle'
                ].map((vtype) {
                  final selected = _vehicleTypes.contains(vtype);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(vtype),
                    value: selected,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _vehicleTypes.add(vtype);
                      } else {
                        _vehicleTypes.remove(vtype);
                      }
                    }),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Luggage (hidden for self-drive)
          if (_transportType != 'Vehicle Rental (Self-Drive)')
            _buildFlatField(
              child: DropdownButtonFormField<String>(
                value: _luggageOption,
                decoration: const InputDecoration(labelText: 'Luggage'),
                items: const [
                  DropdownMenuItem(
                      value: 'Small Bags Only', child: Text('Small Bags Only')),
                  DropdownMenuItem(
                      value: 'Medium Suitcases',
                      child: Text('Medium Suitcases')),
                  DropdownMenuItem(
                      value: 'Large Suitcases', child: Text('Large Suitcases')),
                ],
                onChanged: (v) =>
                    setState(() => _luggageOption = v ?? _luggageOption),
              ),
            ),
          // Sub-type specifics
          if (_transportType == 'Hire Driver for Tour') ...[
            const SizedBox(height: 16),
            _buildFlatField(
              child: TextFormField(
                controller: _itineraryController,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Itinerary / Key Stops'),
              ),
            ),
          ],
          if (_transportType == 'Airport Transfer') ...[
            const SizedBox(height: 16),
            _buildFlatField(
              child: TextFormField(
                controller: _flightNumberController,
                decoration: const InputDecoration(labelText: 'Flight Number'),
              ),
            ),
            const SizedBox(height: 16),
            _buildFlatField(
              child: TextFormField(
                controller: _flightTimeController,
                decoration:
                    const InputDecoration(labelText: 'Arrival/Departure Time'),
              ),
            ),
          ],
          if (_transportType == 'Vehicle Rental (Self-Drive)') ...[
            const SizedBox(height: 16),
            _buildFlatField(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Valid International/Local License?'),
                value: _licenseConfirmed,
                onChanged: (v) =>
                    setState(() => _licenseConfirmed = v ?? false),
              ),
            ),
          ],
        ],
      );
    } else if (cat == 'accommodation') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type of Accommodation
          _buildFlatField(
            child: DropdownButtonFormField<String>(
              value: _accommodationType,
              decoration:
                  const InputDecoration(labelText: 'Type of Accommodation'),
              items: const [
                DropdownMenuItem(value: 'Hotel', child: Text('Hotel')),
                DropdownMenuItem(
                    value: 'Villa/Bungalow', child: Text('Villa/Bungalow')),
                DropdownMenuItem(
                    value: 'Guesthouse/Homestay',
                    child: Text('Guesthouse/Homestay')),
                DropdownMenuItem(value: 'Eco-Lodge', child: Text('Eco-Lodge')),
                DropdownMenuItem(value: 'Hostel', child: Text('Hostel')),
              ],
              onChanged: (v) => setState(() {
                _accommodationType = v ?? _accommodationType;
                if (_accommodationType == 'Hostel') {
                  _unitsType = 'beds';
                } else {
                  _unitsType = 'rooms';
                }
              }),
            ),
          ),
          const SizedBox(height: 16),
          // Rooms/Beds counter
          _buildFlatField(
            child: _buildCounterRow(
              _unitsType == 'beds' ? 'Number of Beds' : 'Number of Rooms',
              _unitsCount,
              (v) => setState(() => _unitsCount = v),
              min: 1,
            ),
          ),
          const SizedBox(height: 16),
          // Amenities (multi-select)
          _buildFlatField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Required Amenities'),
                ...[
                  'Air Conditioning (AC)',
                  'Hot Water',
                  'Wi-Fi',
                  'Kitchen Facilities',
                  'Swimming Pool',
                  'Parking',
                ].map((a) {
                  final selected = _amenities.contains(a);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(a),
                    value: selected,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _amenities.add(a);
                      } else {
                        _amenities.remove(a);
                      }
                    }),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Board Basis
          _buildFlatField(
            child: DropdownButtonFormField<String>(
              value: _boardBasis,
              decoration: const InputDecoration(labelText: 'Board Basis'),
              items: const [
                DropdownMenuItem(value: 'Room Only', child: Text('Room Only')),
                DropdownMenuItem(
                    value: 'Bed & Breakfast', child: Text('Bed & Breakfast')),
                DropdownMenuItem(
                    value: 'Half Board', child: Text('Half Board')),
                DropdownMenuItem(
                    value: 'Full Board', child: Text('Full Board')),
              ],
              onChanged: (v) => setState(() => _boardBasis = v ?? _boardBasis),
            ),
          ),
          const SizedBox(height: 16),
          // Sub-type specifics
          if (_accommodationType == 'Villa/Bungalow')
            _buildFlatField(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cook / Staff Required?'),
                value: _cookStaffRequired,
                onChanged: (v) =>
                    setState(() => _cookStaffRequired = v ?? false),
              ),
            ),
          if (_accommodationType == 'Hostel') ...[
            _buildFlatField(
              child: DropdownButtonFormField<String>(
                value: _hostelRoomType,
                decoration: const InputDecoration(labelText: 'Room Type'),
                items: const [
                  DropdownMenuItem(
                      value: 'Dormitory', child: Text('Dormitory')),
                  DropdownMenuItem(
                      value: 'Private Room', child: Text('Private Room')),
                ],
                onChanged: (v) =>
                    setState(() => _hostelRoomType = v ?? _hostelRoomType),
              ),
            ),
          ],
          if (_accommodationType == 'Guesthouse/Homestay')
            _buildFlatField(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Meals with Host Family?'),
                value: _mealsWithHostFamily,
                onChanged: (v) =>
                    setState(() => _mealsWithHostFamily = v ?? false),
              ),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // Helpers
  String _formatDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}';
  }

  Widget _buildCounterRow(String label, int value, void Function(int) onChanged,
      {int min = 0, int max = 99}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
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
                        requestType: _getRequestTypeString(_selectedType),
                        module: _selectedType == RequestType.service
                            ? _selectedModule
                            : null,
                        scrollController: ScrollController(),
                      ),
                    ),
                  );

                  if (result != null && result['category'] != null) {
                    setState(() {
                      _selectedCategory = result['category']!;
                      _selectedSubcategory = result['subcategory'];
                      _selectedCategoryId =
                          result['categoryId'] ?? _selectedCategoryId;
                      _selectedSubCategoryId =
                          result['subcategoryId'] ?? _selectedSubCategoryId;
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
                        _selectedSubcategory ?? 'Select item to rent',
                        style: TextStyle(
                          color: _selectedSubcategory != null
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
                prefixIcon: Icons.my_location,
                onLocationSelected: (address, lat, lng) {
                  setState(() {
                    _pickupLocationController.text = address;
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
                hintText: 'Enter drop-off location',
                isRequired: true,
                prefixIcon: Icons.location_on,
                onLocationSelected: (address, lat, lng) {
                  setState(() {
                    _dropoffLocationController.text = address;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Item Categories (Use Category Picker)
        _buildFlatField(
          child: GestureDetector(
            onTap: () async {
              final result = await showModalBottomSheet<Map<String, String>>(
                context: context,
                isScrollControlled: true,
                builder: (context) => DraggableScrollableSheet(
                  expand: false,
                  builder: (context, scrollController) => CategoryPicker(
                    requestType: _getRequestTypeString(_selectedType),
                    module: _selectedType == RequestType.service
                        ? _selectedModule
                        : null,
                    scrollController: scrollController,
                  ),
                ),
              );

              if (result != null) {
                setState(() {
                  _selectedCategory = result['category'] ?? _selectedCategory;
                  _selectedSubcategory =
                      result['subcategory'] ?? _selectedSubcategory;
                  _selectedCategoryId =
                      result['categoryId'] ?? _selectedCategoryId;
                  _selectedSubCategoryId =
                      result['subcategoryId'] ?? _selectedSubCategoryId;
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
                    _selectedSubcategory ?? 'Select item category',
                    style: TextStyle(
                      color: _selectedSubcategory != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
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
        (_selectedCategoryId == null || _selectedCategoryId!.isEmpty)) {
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

      // Debug log location data before creating request
      print('=== LOCATION DEBUG BEFORE CREATE ===');
      print('_locationController.text: "${_locationController.text}"');
      print('_selectedLatitude: $_selectedLatitude');
      print('_selectedLongitude: $_selectedLongitude');
      print('=====================================');

      // Create request using the service method
      LocationInfo? locationInfo;
      if (_locationController.text.trim().isNotEmpty) {
        if (_selectedLatitude != null && _selectedLongitude != null) {
          locationInfo = LocationInfo(
            address: _locationController.text.trim(),
            latitude: _selectedLatitude!,
            longitude: _selectedLongitude!,
          );
        } else {
          // Create location with just address if coordinates are not available
          locationInfo = LocationInfo(
            address: _locationController.text.trim(),
            latitude: 0.0, // Default coordinates
            longitude: 0.0,
          );
        }
      }

      print('=== FINAL LOCATION INFO ===');
      print('locationInfo: $locationInfo');
      if (locationInfo != null) {
        print('locationInfo.address: "${locationInfo.address}"');
        print('locationInfo.latitude: ${locationInfo.latitude}');
        print('locationInfo.longitude: ${locationInfo.longitude}');
      }
      print('===========================');

      await _requestService.createRequestCompat(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        location: locationInfo,
        budget: _budgetController.text.trim().isNotEmpty
            ? double.tryParse(_budgetController.text.trim())
            : null,
        images: _imageUrls,
        typeSpecificData: _getTypeSpecificData(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_getTypeDisplayNameWithModule()} created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating request: $e'),
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
          // module/subtype hint for backend routing/analytics
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
          'category': _selectedCategory.trim(),
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
          'itemToRent': _rentalItemController.text.trim(),
          'category': _selectedCategory,
          'categoryId': _selectedCategoryId ?? '',
          'subCategoryId': _selectedSubCategoryId ?? '',
          'subcategory': _selectedSubcategory ?? '',
          'startDate': _startDateTime?.millisecondsSinceEpoch,
          'endDate': _endDateTime?.millisecondsSinceEpoch,
          'pickupDropoffPreference': _pickupDropoffPreference,
        };
      default:
        return {};
    }
  }
}

class _ModuleTheme {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Color> gradient;
  const _ModuleTheme({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.gradient,
  });
}
