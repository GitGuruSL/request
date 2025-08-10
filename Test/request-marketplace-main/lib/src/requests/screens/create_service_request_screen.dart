import 'package:flutter/material.dart';
import 'package:request_marketplace/src/models/request.dart';
import 'package:request_marketplace/src/models/user.dart';
import 'package:request_marketplace/src/services/request_service.dart';
import 'package:request_marketplace/src/services/phone_number_service.dart';
import 'package:request_marketplace/src/requests/widgets/category_picker.dart';
import 'package:request_marketplace/src/profile/screens/phone_number_management_screen.dart';

enum ServiceUrgency { low, medium, high, urgent }

class CreateServiceRequestScreen extends StatefulWidget {
  const CreateServiceRequestScreen({super.key});

  @override
  State<CreateServiceRequestScreen> createState() => _CreateServiceRequestScreenState();
}

class _CreateServiceRequestScreenState extends State<CreateServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  final RequestService _requestService = RequestService();
  final PhoneNumberService _phoneNumberService = PhoneNumberService();
  
  String? _selectedCategory;
  ServiceUrgency _urgency = ServiceUrgency.medium;
  bool _isRemoteServiceRequired = false;
  bool _isLoading = false;
  User? _currentUser;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }
  
  Future<void> _loadCurrentUser() async {
    final user = await _requestService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Service Request'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Request Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Service Title',
                  hintText: 'Enter service title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a service title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the service you need',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              CategoryPicker(
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Enter service location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Budget (LKR)',
                  hintText: 'Enter your budget',
                  border: OutlineInputBorder(),
                  prefixText: 'LKR ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a budget';
                  }
                  final budget = double.tryParse(value);
                  if (budget == null || budget <= 0) {
                    return 'Please enter a valid budget amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              Text(
                'Service Urgency',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: ServiceUrgency.values.map((urgency) {
                    return RadioListTile<ServiceUrgency>(
                      title: Text(_getUrgencyLabel(urgency)),
                      subtitle: Text(_getUrgencyDescription(urgency)),
                      value: urgency,
                      groupValue: _urgency,
                      onChanged: (value) {
                        setState(() {
                          _urgency = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SwitchListTile(
                  title: const Text('Remote Service Required'),
                  subtitle: const Text('Can this service be provided remotely?'),
                  value: _isRemoteServiceRequired,
                  onChanged: (value) {
                    setState(() {
                      _isRemoteServiceRequired = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
              
              if (_currentUser != null) ...[
                if (!_phoneNumberService.hasVerifiedPhone(_currentUser!)) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Phone Verification Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You need to verify your phone number before creating service requests.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PhoneNumberManagementScreen(),
                              ),
                            );
                          },
                          child: const Text('Verify Phone Number'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || (_currentUser != null && !_phoneNumberService.hasVerifiedPhone(_currentUser!))
                      ? null
                      : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Service Request',
                          style: TextStyle(
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
    );
  }
  
  String _getUrgencyLabel(ServiceUrgency urgency) {
    switch (urgency) {
      case ServiceUrgency.low:
        return 'Low Priority';
      case ServiceUrgency.medium:
        return 'Medium Priority';
      case ServiceUrgency.high:
        return 'High Priority';
      case ServiceUrgency.urgent:
        return 'Urgent';
    }
  }
  
  String _getUrgencyDescription(ServiceUrgency urgency) {
    switch (urgency) {
      case ServiceUrgency.low:
        return 'Can wait a few days';
      case ServiceUrgency.medium:
        return 'Within 1-2 days';
      case ServiceUrgency.high:
        return 'Within hours';
      case ServiceUrgency.urgent:
        return 'Immediate attention required';
    }
  }
  
  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final request = Request(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        location: _locationController.text.trim(),
        budget: double.parse(_budgetController.text.trim()),
        urgency: _urgency.toString().split('.').last,
        isRemoteServiceRequired: _isRemoteServiceRequired,
        userId: _currentUser!.id,
        userName: _currentUser!.fullName,
        userPhoneNumber: _currentUser!.phoneNumber ?? '',
        createdAt: DateTime.now(),
        status: 'active',
        type: 'service',
      );
      
      await _requestService.createRequest(request);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service request created successfully!'),
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
