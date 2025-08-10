import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/request_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../utils/currency_helper.dart';

class CreateResponseScreen extends StatefulWidget {
  final RequestModel request;
  final String requestType;

  const CreateResponseScreen({
    super.key,
    required this.request,
    required this.requestType,
  });

  @override
  State<CreateResponseScreen> createState() => _CreateResponseScreenState();
}

class _CreateResponseScreenState extends State<CreateResponseScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final _formKey = GlobalKey<FormState>();
  
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  bool _isLoading = false;
  
  // Type-specific fields
  Map<String, dynamic> _typeSpecificData = {};

  @override
  void initState() {
    super.initState();
    _initializeTypeSpecificFields();
  }

  void _initializeTypeSpecificFields() {
    switch (widget.request.type) {
      case RequestType.service:
        _typeSpecificData = {
          'experienceYears': 0,
          'certifications': <String>[],
          'portfolioImages': <String>[],
        };
        break;
      case RequestType.delivery:
        _typeSpecificData = {
          'vehicleType': '',
          'maxWeight': 0.0,
          'hasInsurance': false,
          'deliveryTime': '',
        };
        break;
      case RequestType.ride:
        _typeSpecificData = {
          'vehicleModel': '',
          'vehicleYear': DateTime.now().year,
          'seatCount': 4,
          'hasAC': true,
          'licenseNumber': '',
        };
        break;
      case RequestType.rental:
        _typeSpecificData = {
          'condition': 'good',
          'includesDelivery': false,
          'securityDeposit': 0.0,
          'minimumRentalPeriod': 1,
        };
        break;
      default:
        _typeSpecificData = {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Response'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequestSummary(),
              const SizedBox(height: 20),
              _buildResponseForm(),
              const SizedBox(height: 20),
              _buildTypeSpecificFields(),
              const SizedBox(height: 20),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Responding to:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.request.title,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              widget.request.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (widget.request.budget != null) ...[
              const SizedBox(height: 8),
              Text(
                'Budget: ${CurrencyHelper.formatPrice(widget.request.budget!, widget.request.currency)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponseForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Response',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message *',
                hintText: 'Explain how you can help...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Your Price',
                      hintText: 'Enter amount',
                      border: const OutlineInputBorder(),
                      prefixText: CurrencyHelper.getCurrencySymbol(widget.request.currency),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter a valid price';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Available From'),
                    subtitle: Text(
                      _availableFrom?.toString().split(' ')[0] ?? 'Not set',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(isStartDate: true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Available Until'),
                    subtitle: Text(
                      _availableUntil?.toString().split(' ')[0] ?? 'Not set',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(isStartDate: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _additionalInfoController,
              decoration: const InputDecoration(
                labelText: 'Additional Information',
                hintText: 'Any other details...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificFields() {
    switch (widget.request.type) {
      case RequestType.service:
        return _buildServiceFields();
      case RequestType.delivery:
        return _buildDeliveryFields();
      case RequestType.ride:
        return _buildRideFields();
      case RequestType.rental:
        return _buildRentalFields();
      default:
        return const SizedBox();
    }
  }

  Widget _buildServiceFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Service Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Years of Experience',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _typeSpecificData['experienceYears'] = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Certifications (comma separated)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _typeSpecificData['certifications'] = 
                    value.split(',').map((e) => e.trim()).toList();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Vehicle Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'bike', child: Text('Bike')),
                DropdownMenuItem(value: 'car', child: Text('Car')),
                DropdownMenuItem(value: 'van', child: Text('Van')),
                DropdownMenuItem(value: 'truck', child: Text('Truck')),
              ],
              onChanged: (value) {
                _typeSpecificData['vehicleType'] = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Maximum Weight (kg)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _typeSpecificData['maxWeight'] = double.tryParse(value) ?? 0.0;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Have Insurance Coverage'),
              value: _typeSpecificData['hasInsurance'] ?? false,
              onChanged: (value) {
                setState(() {
                  _typeSpecificData['hasInsurance'] = value ?? false;
                });
              },
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Estimated Delivery Time',
                hintText: 'e.g., 2-3 hours, Same day',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _typeSpecificData['deliveryTime'] = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Vehicle Model',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _typeSpecificData['vehicleModel'] = value;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _typeSpecificData['vehicleYear'] = int.tryParse(value) ?? DateTime.now().year;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Seat Count',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _typeSpecificData['seatCount'] = int.tryParse(value) ?? 4;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Air Conditioning'),
              value: _typeSpecificData['hasAC'] ?? true,
              onChanged: (value) {
                setState(() {
                  _typeSpecificData['hasAC'] = value ?? true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rental Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Item Condition',
                border: OutlineInputBorder(),
              ),
              value: _typeSpecificData['condition'] ?? 'good',
              items: const [
                DropdownMenuItem(value: 'excellent', child: Text('Excellent')),
                DropdownMenuItem(value: 'good', child: Text('Good')),
                DropdownMenuItem(value: 'fair', child: Text('Fair')),
              ],
              onChanged: (value) {
                setState(() {
                  _typeSpecificData['condition'] = value ?? 'good';
                });
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Includes Delivery'),
              value: _typeSpecificData['includesDelivery'] ?? false,
              onChanged: (value) {
                setState(() {
                  _typeSpecificData['includesDelivery'] = value ?? false;
                });
              },
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Security Deposit',
                border: const OutlineInputBorder(),
                prefixText: CurrencyHelper.getCurrencySymbol(widget.request.currency),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _typeSpecificData['securityDeposit'] = double.tryParse(value) ?? 0.0;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitResponse,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Submit Response',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _availableFrom = date;
        } else {
          _availableUntil = date;
        }
      });
    }
  }

  void _submitResponse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final price = _priceController.text.isNotEmpty
          ? double.tryParse(_priceController.text)
          : null;

      final additionalInfo = Map<String, dynamic>.from(_typeSpecificData);
      if (_additionalInfoController.text.isNotEmpty) {
        additionalInfo['notes'] = _additionalInfoController.text;
      }

      await _requestService.createResponse(
        requestId: widget.request.id,
        message: _messageController.text.trim(),
        price: price,
        currency: widget.request.currency,
        availableFrom: _availableFrom,
        availableUntil: _availableUntil,
        additionalInfo: additionalInfo,
      );

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Response submitted successfully!'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit response: $e'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
