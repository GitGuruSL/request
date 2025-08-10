import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/phone_number_service.dart';
import '../../profile/screens/phone_verification_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addPhoneController = TextEditingController(); // New controller for adding additional phones
  final _addressController = TextEditingController();
  final _phoneService = PhoneNumberService();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isVerifyingPhone = false;
  File? _selectedImage;
  String? _currentImageUrl;
  List<dynamic> _phoneNumbers = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _addPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Reload phone numbers when app resumes
      _loadPhoneNumbers();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user document
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          
          setState(() {
            _nameController.text = userData['displayName'] ?? '';
            _emailController.text = user.email ?? '';
            _bioController.text = userData['bio'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _currentImageUrl = userData['photoURL'];
            _phoneNumbers = userData['phoneNumbers'] ?? [];
          });
        } else {
          setState(() {
            _emailController.text = user.email ?? '';
          });
        }
        
        // Load phone numbers
        await _loadPhoneNumbers();
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPhoneNumbers() async {
    try {
      print('🔄 Loading phone numbers...');
      final phoneNumbers = await _phoneService.getUserPhoneNumbers();
      print('📱 Loaded ${phoneNumbers.length} phone numbers');
      
      setState(() {
        _phoneNumbers = phoneNumbers;
        // Only set main phone field if there are NO verified phone numbers
        // This prevents showing the same number in multiple places
        final hasVerifiedPhones = phoneNumbers.any((phone) => phone.isVerified == true);
        
        if (!hasVerifiedPhones && phoneNumbers.isNotEmpty) {
          // If no verified phones exist, show the first phone in the main field
          final firstPhone = phoneNumbers.first;
          print('📱 Setting main phone field to: ${firstPhone.number}');
          _phoneController.text = firstPhone.number;
        } else if (!hasVerifiedPhones) {
          // Clear the phone field if no phone numbers exist
          print('📱 No phone numbers found, clearing main field');
          _phoneController.text = '';
        } else {
          // Clear main phone field when there are verified phones (they're shown separately)
          print('📱 Verified phones exist, clearing main field');
          _phoneController.text = '';
        }
        
        // Always keep the add phone field empty
        _addPhoneController.text = '';
      });
    } catch (e) {
      print('❌ Error loading phone numbers: $e');
      // Clear phone fields on error
      setState(() {
        _phoneController.text = '';
        _addPhoneController.text = '';
        _phoneNumbers = [];
      });
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load from Firebase Auth
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
        _currentImageUrl = user.photoURL;

        // Try to load additional profile data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _nameController.text = data['name'] ?? data['displayName'] ?? user.displayName ?? '';
          _bioController.text = data['bio'] ?? '';
          if (data['profileImageUrl'] != null) {
            _currentImageUrl = data['profileImageUrl'];
          }
        }
        
        // Load phone numbers
        await _loadPhoneNumbers();
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update Firebase Auth profile
      await user.updateDisplayName(_nameController.text.trim());

      // Update Firestore user document
      final userData = {
        'name': _nameController.text.trim(),
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // TODO: Upload image to Firebase Storage if selected
      // For now, we'll skip image upload

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(userData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1D1B20),
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF1D1B20),
          elevation: 0,
          centerTitle: false,
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1B20),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Section
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Profile Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  
                  // Profile Picture
                  _buildProfileItem(
                    icon: Icons.camera_alt_outlined,
                    title: 'Profile Picture',
                    subtitle: _selectedImage != null ? 'New image selected' : 
                             _currentImageUrl != null ? 'Current image' : 'No image',
                    hasChevron: true,
                    onTap: _pickImage,
                    trailing: _selectedImage != null || _currentImageUrl != null
                        ? Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                              image: _selectedImage != null
                                  ? DecorationImage(
                                      image: FileImage(_selectedImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : _currentImageUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(_currentImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                            ),
                            child: _selectedImage == null && _currentImageUrl == null
                                ? const Icon(Icons.person, color: Color(0xFF666666))
                                : null,
                          )
                        : null,
                  ),
                  
                  // Full Name
                  _buildTextFieldItem(
                    icon: Icons.person_outline,
                    title: 'Full Name',
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  
                  // Email
                  _buildTextFieldItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    controller: _emailController,
                    enabled: false, // Email usually shouldn't be editable
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  // Bio
                  _buildTextFieldItem(
                    icon: Icons.info_outline,
                    title: 'Bio',
                    controller: _bioController,
                    maxLines: 3,
                    hintText: 'Tell us about yourself...',
                  ),
                ],
              ),
            ),
            
            // Contact Information Section
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  
                  // Phone
                  _buildPhoneFieldItem(
                    icon: Icons.phone_outlined,
                    title: 'Phone Number',
                    controller: _phoneController,
                    onVerify: _addPhoneNumber,
                    phoneNumbers: _phoneNumbers,
                  ),
                  
                  // Address
                  _buildTextFieldItem(
                    icon: Icons.location_on_outlined,
                    title: 'Address',
                    controller: _addressController,
                    maxLines: 2,
                    hintText: 'Your address...',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool hasChevron = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF666666),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 16),
                  trailing,
                ] else if (hasChevron) ...[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF666666),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldItem({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF666666),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controller,
                      validator: validator,
                      maxLines: maxLines,
                      enabled: enabled,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addPhoneNumber() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingPhone = true;
    });

    try {
      // Send OTP
      final result = await _phoneService.addPhoneNumber(phoneNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to verification screen
        final verificationResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PhoneVerificationScreen(
              phoneNumber: phoneNumber,
              onVerificationSuccess: () async {
                print('📱 Verification success callback triggered');
                await _loadPhoneNumbers(); // Reload phone numbers after verification
              },
            ),
          ),
        );

        print('📱 Verification result: $verificationResult');
        if (verificationResult == true) {
          print('📱 Reloading phone numbers after successful verification');
          await _loadPhoneNumbers(); // Reload to show verified phone
        } else {
          print('📱 Verification not successful, still reloading to refresh state');
          await _loadPhoneNumbers(); // Reload anyway to refresh state
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
      }
    }
  }

  Future<void> _addAdditionalPhoneNumber() async {
    final phoneNumber = _addPhoneController.text.trim();
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifyingPhone = true;
    });

    try {
      // Send OTP
      final result = await _phoneService.addPhoneNumber(phoneNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to verification screen
        final verificationResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PhoneVerificationScreen(
              phoneNumber: phoneNumber,
              onVerificationSuccess: () async {
                print('📱 Additional phone verification success callback triggered');
                await _loadPhoneNumbers(); // Reload phone numbers after verification
                _addPhoneController.clear(); // Clear the add phone field
              },
            ),
          ),
        );

        print('📱 Additional phone verification result: $verificationResult');
        if (verificationResult == true) {
          print('📱 Reloading phone numbers after successful additional verification');
          await _loadPhoneNumbers(); // Reload to show verified phone
          _addPhoneController.clear(); // Clear the add phone field
        } else {
          print('📱 Additional verification not successful, still reloading to refresh state');
          await _loadPhoneNumbers(); // Reload anyway to refresh state
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
      }
    }
  }

  void _showDeletePhoneDialog(String phoneNumber) {
    // Check if this is the primary phone number
    final phoneToDelete = _phoneNumbers.firstWhere(
      (phone) => phone.number == phoneNumber,
      orElse: () => null,
    );
    
    final isPrimary = phoneToDelete?.isPrimary ?? false;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPrimary) ...[
                const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Primary Phone Number',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('You cannot delete your primary phone number. To delete this number, first set another phone number as primary.'),
              ] else ...[
                const Text('Are you sure you want to delete this phone number?'),
              ],
              const SizedBox(height: 8),
              Text(
                phoneNumber,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.orange : Colors.red,
                ),
              ),
              if (!isPrimary) ...[
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            if (!isPrimary)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deletePhoneNumber(phoneNumber);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
          ],
        );
      },
    );
  }

  Future<void> _deletePhoneNumber(String phoneNumber) async {
    setState(() {
      _isVerifyingPhone = true; // Reuse this loading state
    });

    try {
      await _phoneService.removePhoneNumber(phoneNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload phone numbers to update the UI
        await _loadPhoneNumbers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting phone number: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
      }
    }
  }

  Future<void> _setPrimaryPhone(String phoneNumber) async {
    setState(() {
      _isVerifyingPhone = true; // Reuse this loading state
    });

    try {
      await _phoneService.setPrimaryPhoneNumber(phoneNumber);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primary phone number updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Reload phone numbers to update the UI
        await _loadPhoneNumbers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting primary phone: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
      }
    }
  }

  Widget _buildPhoneFieldItem({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required VoidCallback onVerify,
    required List<dynamic> phoneNumbers,
  }) {
    final hasVerifiedPhone = phoneNumbers.any((phone) => phone.isVerified == true);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF666666),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (hasVerifiedPhone)
                          // Show verified phone numbers
                          Column(
                            children: phoneNumbers
                                .where((phone) => phone.isVerified)
                                .map((phone) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.verified,
                                            color: Color(0xFF4CAF50),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              phone.number,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF1D1B20),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          if (phone.isPrimary)
                                            Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Primary',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          // Action buttons
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!phone.isPrimary)
                                                Tooltip(
                                                  message: 'Set as primary phone',
                                                  child: GestureDetector(
                                                    onTap: () => _setPrimaryPhone(phone.number),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      margin: const EdgeInsets.only(right: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Icon(
                                                        Icons.star_outline,
                                                        color: Colors.blue,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              // Delete button
                                              Tooltip(
                                                message: phone.isPrimary ? 'Cannot delete primary phone' : 'Delete phone number',
                                                child: GestureDetector(
                                                  onTap: () => _showDeletePhoneDialog(phone.number),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(4),
                                                    decoration: BoxDecoration(
                                                      color: phone.isPrimary 
                                                          ? Colors.grey.withOpacity(0.1)
                                                          : Colors.red.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Icon(
                                                      Icons.delete_outline,
                                                      color: phone.isPrimary ? Colors.grey : Colors.red,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          )
                        else
                          // Show input field for new phone number
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: controller,
                                  decoration: const InputDecoration(
                                    hintText: '+94 70 123 4567',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF999999),
                                      fontSize: 14,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1D1B20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isVerifyingPhone ? null : onVerify,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isVerifyingPhone
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Verify',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        
                        // Add phone button for verified users
                        if (hasVerifiedPhone)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _addPhoneController,
                                    decoration: const InputDecoration(
                                      hintText: 'Add another phone number',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1D1B20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: _isVerifyingPhone ? null : _addAdditionalPhoneNumber,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isVerifyingPhone
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Add',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF666666),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF666666),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleListTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: textColor == Colors.red ? Colors.red : const Color(0xFF666666),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? const Color(0xFF1D1B20),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF666666),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion will be implemented soon'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
