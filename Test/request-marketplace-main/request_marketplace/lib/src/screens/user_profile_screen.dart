import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? profileData;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.profileData,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _profileImageUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    if (widget.profileData != null) {
      _displayNameController.text = widget.profileData!['displayName'] ?? '';
      _emailController.text = widget.profileData!['email'] ?? '';
      _phoneController.text = widget.profileData!['phone'] ?? '';
      _addressController.text = widget.profileData!['address'] ?? '';
      _profileImageUrl = widget.profileData!['profileImage'];
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Profile', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (!_isUpdating)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save', style: TextStyle(fontFamily: 'Poppins')),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileImageSection(),
                    const SizedBox(height: 24),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    _buildContactInfoSection(),
                    const SizedBox(height: 32),
                    if (_isUpdating)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: _selectedImage != null
                  ? ClipOval(
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _profileImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[500],
                        ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Change Photo', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      'Personal Information',
      [
        _buildTextField(
          controller: _displayNameController,
          label: 'Full Name',
          icon: Icons.person,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return _buildSection(
      'Contact Information',
      [
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email,
          enabled: false, // Usually email shouldn't be editable
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Address',
          icon: Icons.location_on,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontFamily: 'Poppins'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: enabled ? Colors.black87 : Colors.grey,
        ),
        prefixIcon: Icon(icon, color: enabled ? Colors.blue : Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Save Changes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      String? imageUrl = _profileImageUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${widget.userId}.jpg');

        final uploadTask = storageRef.putFile(_selectedImage!);
        final snapshot = await uploadTask.whenComplete(() => null);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'displayName': _displayNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        if (imageUrl != null) 'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update Firebase Auth display name
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        _displayNameController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true); // Return true to indicate success

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}
