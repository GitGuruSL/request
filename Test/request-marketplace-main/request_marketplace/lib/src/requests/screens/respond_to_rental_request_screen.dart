import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/request_model.dart';
import '../../core/services/phone_verification_helper.dart';
import '../../profile/screens/phone_number_management_screen.dart';

class RespondToRentalRequestScreen extends StatefulWidget {
  final RequestModel request;

  const RespondToRentalRequestScreen({super.key, required this.request});

  @override
  State<RespondToRentalRequestScreen> createState() => _RespondToRentalRequestScreenState();
}

class _RespondToRentalRequestScreenState extends State<RespondToRentalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitResponse() async {
    // Validate phone verification first
    final phoneVerified = await PhoneVerificationHelper.validatePhoneVerification(context);
    if (!phoneVerified) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get verified phone numbers automatically
      final phoneNumbers = await PhoneVerificationHelper.getVerifiedPhoneNumbers();
      
      // Create response data
      final responseData = {
        'requestId': widget.request.id,
        'responderId': FirebaseAuth.instance.currentUser?.uid ?? '',
        'message': _messageController.text.trim(),
        'price': _priceController.text.trim(),
        'phoneNumbers': phoneNumbers,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'active',
      };

      print('Submitting response: $responseData');
      
      // In a real app, submit to Firebase/backend here
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error submitting response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit response. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respond to Rental Request'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request: ${widget.request.title}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.request.description),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Phone Verification Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Phone Number Sharing',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your verified phone numbers from your profile will be automatically shared with the requester. Go to Settings > Profile to manage your phone numbers.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Response Message
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Response Message',
                  hintText: 'Describe your rental offer...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a response message';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Rental Price',
                  hintText: 'Enter your price',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit Response',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
