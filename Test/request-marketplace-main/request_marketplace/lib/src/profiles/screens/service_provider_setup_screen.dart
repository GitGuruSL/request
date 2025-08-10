import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/user_profile_service.dart';

class ServiceProviderSetupScreen extends StatefulWidget {
  final String userId;
  
  const ServiceProviderSetupScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ServiceProviderSetupScreen> createState() => _ServiceProviderSetupScreenState();
}

class _ServiceProviderSetupScreenState extends State<ServiceProviderSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _userProfileService = UserProfileService();
  final Location _location = Location();
  final _imagePicker = ImagePicker();

  final List<String> _selectedCategories = [];
  final List<String> _skills = [];
  final List<File> _portfolioImages = [];
  final Map<String, String> _availability = {
    'Monday': 'Available',
    'Tuesday': 'Available',
    'Wednesday': 'Available',
    'Thursday': 'Available',
    'Friday': 'Available',
    'Saturday': 'Available',
    'Sunday': 'Not Available',
  };
  
  double _serviceRadius = 10.0; // km
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLoading = false;
  bool _hasExperience = false;
  bool _hasPortfolio = false;

  final List<String> _serviceCategories = [
    'Home Cleaning', 'Plumbing', 'Electrical', 'Carpentry',
    'Painting', 'Gardening', 'Moving', 'Pet Care',
    'Tutoring', 'Photography', 'Graphic Design', 'Web Development',
    'Mobile Repair', 'Appliance Repair', 'Beauty Services', 'Fitness Training',
    'Legal Services', 'Accounting', 'Consulting', 'Translation',
    'Music Lessons', 'Cooking', 'Event Planning', 'Interior Design'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Provider Setup'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.handyman, color: Colors.white, size: 32),
                    SizedBox(height: 16),
                    Text(
                      'Become a Service Provider',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Set up your professional profile and start offering services to customers in your area.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Professional Info
              const Text(
                'Professional Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Professional Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Professional Title *',
                  hintText: 'e.g., Licensed Plumber, House Cleaner',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your professional title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Service Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Service Description *',
                  hintText: 'Describe the services you offer...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your services';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Experience
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _experienceController,
                      decoration: const InputDecoration(
                        labelText: 'Years of Experience',
                        hintText: '5',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.star),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final years = int.tryParse(value);
                          if (years == null || years < 0) {
                            return 'Enter valid years';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _hourlyRateController,
                      decoration: const InputDecoration(
                        labelText: 'Hourly Rate (\$)',
                        hintText: '25',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final rate = double.tryParse(value);
                          if (rate == null || rate <= 0) {
                            return 'Enter valid rate';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Service Categories
              const Text(
                'Service Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the services you provide (up to 5)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _serviceCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: _selectedCategories.length < 5 || isSelected
                        ? (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          }
                        : null,
                    selectedColor: const Color(0xFF1976D2).withOpacity(0.3),
                    checkmarkColor: const Color(0xFF1976D2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Skills
              const Text(
                'Skills & Specializations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Add a skill (e.g., Kitchen Renovation)',
                              border: InputBorder.none,
                            ),
                            onFieldSubmitted: _addSkill,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _showSkillDialog(),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    if (_skills.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () {
                              setState(() {
                                _skills.remove(skill);
                              });
                            },
                            backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Service Area
              const Text(
                'Service Area',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Service Radius', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${_serviceRadius.round()} km'),
                      Slider(
                        value: _serviceRadius,
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        label: '${_serviceRadius.round()} km',
                        onChanged: (value) {
                          setState(() {
                            _serviceRadius = value;
                          });
                        },
                        activeColor: const Color(0xFF1976D2),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Set Current Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
                          foregroundColor: const Color(0xFF1976D2),
                        ),
                      ),
                      if (_latitude != 0.0 && _longitude != 0.0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Location set: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Availability
              const Text(
                'Availability',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: _availability.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: entry.value,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              items: [
                                'Not Available',
                                'Available',
                                'Morning Only',
                                'Afternoon Only',
                                'Evening Only',
                                'By Appointment'
                              ].map((availability) => DropdownMenuItem(
                                value: availability,
                                child: Text(availability),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _availability[entry.key] = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Portfolio Images
              const Text(
                'Portfolio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Show examples of your work (up to 8 images)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              if (_portfolioImages.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _portfolioImages.length + (_portfolioImages.length < 8 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _portfolioImages.length) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_portfolioImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text('Add More', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ] else ...[
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text('Add Portfolio Images', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Professional Verification
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Professional Verification',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Boost your credibility by verifying your professional credentials.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('I have professional certifications'),
                        subtitle: const Text('Upload certificates, licenses, or qualifications'),
                        value: _hasExperience,
                        onChanged: (value) {
                          setState(() {
                            _hasExperience = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('I have work references'),
                        subtitle: const Text('Contact information for previous clients'),
                        value: _hasPortfolio,
                        onChanged: (value) {
                          setState(() {
                            _hasPortfolio = value ?? false;
                          });
                        },
                      ),
                      if (_hasExperience || _hasPortfolio)
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement verification upload
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Verification upload coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Verification Documents'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitServiceProviderSetup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF1976D2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Complete Setup'),
                ),
              ),
              const SizedBox(height: 16),

              // Skip Option
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text(
                    'Skip for now - I\'ll complete this later',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _addSkill(String skill) {
    if (skill.trim().isNotEmpty && !_skills.contains(skill.trim())) {
      setState(() {
        _skills.add(skill.trim());
      });
    }
  }

  void _showSkillDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Skill'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Skill or Specialization',
            hintText: 'e.g., Bathroom Renovation',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addSkill(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      LocationData locationData = await _location.getLocation();
      
      if (mounted) {
        setState(() {
          _latitude = locationData.latitude!;
          _longitude = locationData.longitude!;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    if (_portfolioImages.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 8 images allowed')),
      );
      return;
    }

    final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        final remainingSlots = 8 - _portfolioImages.length;
        final imagesToAdd = pickedFiles.take(remainingSlots);
        _portfolioImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _portfolioImages.removeAt(index);
    });
  }

  Future<void> _submitServiceProviderSetup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service category')),
      );
      return;
    }

    if (_latitude == 0.0 || _longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your service location')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create service provider profile
      final serviceProviderProfile = ServiceProviderProfile(
        description: _descriptionController.text.trim(),
        skills: _skills,
        experience: _experienceController.text.trim().isNotEmpty 
            ? _experienceController.text.trim() : 'No experience specified',
        hourlyRates: _hourlyRateController.text.trim().isNotEmpty 
            ? {'general': double.parse(_hourlyRateController.text.trim())} : {},
        portfolioImages: [], // TODO: Upload images to storage first
        serviceAreas: _selectedCategories, // Using categories as service areas for now
        availability: _availability.map((key, value) => MapEntry(key, value != 'Not Available')),
        verificationStatus: VerificationStatus.pending,
        isAvailable: true,
      );

      // Add service provider profile to user
      await _userProfileService.addServiceProviderProfile(widget.userId, serviceProviderProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service provider profile created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating profile: $e')),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }
}
