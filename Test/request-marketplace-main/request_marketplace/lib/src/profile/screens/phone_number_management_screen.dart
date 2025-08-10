import 'package:flutter/material.dart';
import '../../services/phone_number_service.dart';
import '../../models/user_model.dart';
import 'phone_verification_screen.dart';

class PhoneNumberManagementScreen extends StatefulWidget {
  const PhoneNumberManagementScreen({super.key});

  @override
  State<PhoneNumberManagementScreen> createState() => _PhoneNumberManagementScreenState();
}

class _PhoneNumberManagementScreenState extends State<PhoneNumberManagementScreen> {
  final PhoneNumberService _phoneService = PhoneNumberService();
  
  List<PhoneNumber> _phoneNumbers = [];
  bool _isLoading = false;
  String? _pendingPhoneNumber;

  @override
  void initState() {
    super.initState();
    _loadPhoneNumbers();
  }

  Future<void> _loadPhoneNumbers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumbers = await _phoneService.getUserPhoneNumbers();
      setState(() {
        _phoneNumbers = phoneNumbers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading phone numbers: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addPhoneNumber() async {
    final phoneController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Phone Number'),
        content: TextField(
          controller: phoneController,
          decoration: const InputDecoration(
            hintText: '+1234567890',
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, phoneController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        setState(() {
          _pendingPhoneNumber = result;
        });
        
        // Send OTP using custom service
        await _phoneService.addPhoneNumber(result);
        
        // Navigate to verification screen
        final verificationResult = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PhoneVerificationScreen(
              phoneNumber: result,
              onVerificationSuccess: _loadPhoneNumbers,
            ),
          ),
        );
        
        setState(() {
          _pendingPhoneNumber = null;
        });
        
        if (verificationResult == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Phone number added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPhoneNumbers();
        }
        
      } catch (e) {
        setState(() {
          _pendingPhoneNumber = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removePhoneNumber(String phoneNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Phone Number'),
        content: Text('Are you sure you want to remove $phoneNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _phoneService.removePhoneNumber(phoneNumber);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number removed')),
        );
        _loadPhoneNumbers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _setPrimaryPhoneNumber(String phoneNumber) async {
    try {
      await _phoneService.setPrimaryPhoneNumber(phoneNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary phone number updated')),
      );
      _loadPhoneNumbers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phone Numbers'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Your Phone Numbers',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add and verify phone numbers to share with others when responding to requests.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // Add Phone Number Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pendingPhoneNumber == null ? _addPhoneNumber : null,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Phone Number'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Phone Numbers List
                  if (_phoneNumbers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No phone numbers added yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _phoneNumbers.length,
                        itemBuilder: (context, index) {
                          final phone = _phoneNumbers[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: phone.isVerified 
                                    ? Colors.green[100] 
                                    : Colors.orange[100],
                                child: Icon(
                                  phone.isVerified 
                                      ? Icons.verified 
                                      : Icons.pending,
                                  color: phone.isVerified 
                                      ? Colors.green 
                                      : Colors.orange,
                                ),
                              ),
                              title: Text(phone.number),
                              subtitle: Row(
                                children: [
                                  Text(
                                    phone.isVerified ? 'Verified' : 'Pending',
                                    style: TextStyle(
                                      color: phone.isVerified 
                                          ? Colors.green 
                                          : Colors.orange,
                                    ),
                                  ),
                                  if (phone.isPrimary) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'PRIMARY',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'primary':
                                      _setPrimaryPhoneNumber(phone.number);
                                      break;
                                    case 'remove':
                                      _removePhoneNumber(phone.number);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (!phone.isPrimary && phone.isVerified)
                                    const PopupMenuItem(
                                      value: 'primary',
                                      child: Text('Set as Primary'),
                                    ),
                                  if (!phone.isPrimary)
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Text('Remove'),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Pending Phone Number
                  if (_pendingPhoneNumber != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pending, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Verifying $_pendingPhoneNumber',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const Text(
                                  'Check your SMS for the verification code',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
