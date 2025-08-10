import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/ride_tracking_model.dart';
import '../../models/driver_model.dart';
import '../../services/ride_tracking_service.dart';
import '../../services/driver_service.dart';
import '../../widgets/driver_profile_card.dart';
import '../../drivers/screens/enhanced_driver_profile_detail_screen.dart';
import 'driver_review_screen.dart';

class RideTrackingScreen extends StatefulWidget {
  final String rideTrackingId;
  final bool isDriver; // true if current user is driver, false if requester

  const RideTrackingScreen({
    super.key,
    required this.rideTrackingId,
    required this.isDriver,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final RideTrackingService _rideTrackingService = RideTrackingService();
  final DriverService _driverService = DriverService();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  RideTracking? _rideTracking;
  DriverModel? _driver;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRideData();
  }

  @override
  void dispose() {
    _verificationCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRideData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final rideTracking =
          await _rideTrackingService.getRideTracking(widget.rideTrackingId);
      if (rideTracking != null) {
        final driver = await _driverService.getDriverProfile();

        setState(() {
          _rideTracking = rideTracking;
          _driver = driver;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Ride not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading ride data: $e');
      setState(() {
        _error = 'Failed to load ride data';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDriver ? 'Current Ride' : 'Track Your Ride'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRideData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('ride_tracking')
                      .doc(widget.rideTrackingId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final updatedRideTracking =
                          RideTracking.fromFirestore(snapshot.data!);
                      _rideTracking = updatedRideTracking;
                    }

                    return _buildRideContent();
                  },
                ),
    );
  }

  Widget _buildRideContent() {
    if (_rideTracking == null || _driver == null) {
      return const Center(child: Text('No ride data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status indicator
          _buildStatusIndicator(),

          const SizedBox(height: 24),

          // Driver information (for requester) or ride details (for driver)
          if (!widget.isDriver) ...[
            _buildDriverInfo(),
            const SizedBox(height: 24),
          ],

          // Ride progress
          _buildRideProgress(),

          const SizedBox(height: 24),

          // Action buttons based on current status
          _buildActionButtons(),

          const SizedBox(height: 24),

          // Ride details
          _buildRideDetails(),

          // Show review option if ride is completed and not reviewed yet
          if (_rideTracking!.status == RideStatus.completed &&
              !widget.isDriver &&
              !_rideTracking!.isDriverReviewed) ...[
            const SizedBox(height: 24),
            _buildReviewSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final status = _rideTracking!.status;
    final color = _rideTracking!.getStatusColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(status),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rideTracking!.getStatusDisplayText(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  _getStatusDescription(status),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Driver',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        DriverProfileCard(
          driver: _driver!,
          showSensitiveInfo: true, // Always show vehicle number for safety
          onViewProfile: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DriverProfileDetailScreen(driver: _driver!),
              ),
            );
          },
        ),

        // Safety reminder
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verify vehicle number plate: ${_driver!.vehicleNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideProgress() {
    final steps = [
      RideStatus.accepted,
      RideStatus.driverArriving,
      RideStatus.pickupVerified,
      RideStatus.inProgress,
      RideStatus.dropoffVerified,
      RideStatus.completed,
    ];

    final currentIndex = steps.indexOf(_rideTracking!.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ride Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          itemBuilder: (context, index) {
            final step = steps[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return _buildProgressStep(
              _getStepTitle(step),
              _getStepDescription(step),
              isCompleted,
              isCurrent,
              index < steps.length - 1,
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressStep(
    String title,
    String description,
    bool isCompleted,
    bool isCurrent,
    bool hasNextStep,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.green : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                color: Colors.white,
                size: 16,
              ),
            ),
            if (hasNextStep)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCurrent
                        ? Colors.blue
                        : (isCompleted ? Colors.green : Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final status = _rideTracking!.status;

    if (!widget.isDriver) {
      // Requester actions
      switch (status) {
        case RideStatus.completed:
          if (!_rideTracking!.isDriverReviewed) {
            return _buildReviewButton();
          }
          break;
        default:
          return Container(); // No actions for requester during ride
      }
    } else {
      // Driver actions
      switch (status) {
        case RideStatus.accepted:
          return _buildDriverArrivingButton();
        case RideStatus.driverArriving:
          return _buildPickupVerificationButton();
        case RideStatus.pickupVerified:
          return _buildStartTripButton();
        case RideStatus.inProgress:
          return _buildDropoffVerificationButton();
        case RideStatus.dropoffVerified:
          return _buildCompleteRideButton();
        default:
          break;
      }
    }

    return Container();
  }

  Widget _buildDriverArrivingButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await _rideTrackingService.updateRideStatus(
              rideTrackingId: widget.rideTrackingId,
              status: RideStatus.driverArriving,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Passenger notified - you are arriving!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(Icons.directions_car),
        label: const Text('I\'m Arriving'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPickupVerificationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showVerificationDialog(VerificationType.pickup),
        icon: const Icon(Icons.person_pin_circle),
        label: const Text('Verify Pickup'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildStartTripButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          try {
            await _rideTrackingService.updateRideStatus(
              rideTrackingId: widget.rideTrackingId,
              status: RideStatus.inProgress,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip started! Drive safely.'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        icon: const Icon(Icons.navigation),
        label: const Text('Start Trip'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropoffVerificationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showVerificationDialog(VerificationType.dropoff),
        icon: const Icon(Icons.location_on),
        label: const Text('Verify Dropoff'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildCompleteRideButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showPaymentDialog(),
        icon: const Icon(Icons.payment),
        label: const Text('Complete & Process Payment'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildReviewButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriverReviewScreen(
                rideTrackingId: widget.rideTrackingId,
                driver: _driver!,
              ),
            ),
          );
        },
        icon: const Icon(Icons.star),
        label: const Text('Rate Your Driver'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade600),
              const SizedBox(width: 8),
              const Text(
                'How was your ride?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Help other passengers by rating your driver',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _buildReviewButton(),
        ],
      ),
    );
  }

  Widget _buildRideDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ride Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Ride ID', _rideTracking!.id),
          _buildDetailRow('Started', _formatDateTime(_rideTracking!.createdAt)),
          if (_rideTracking!.pickupVerifiedAt != null)
            _buildDetailRow('Pickup Time',
                _formatDateTime(_rideTracking!.pickupVerifiedAt!)),
          if (_rideTracking!.dropoffVerifiedAt != null)
            _buildDetailRow('Dropoff Time',
                _formatDateTime(_rideTracking!.dropoffVerifiedAt!)),
          if (_rideTracking!.finalAmount != null)
            _buildDetailRow('Amount',
                '\$${_rideTracking!.finalAmount!.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog(VerificationType type) {
    _verificationCodeController.clear();
    _notesController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Verify ${type == VerificationType.pickup ? 'Pickup' : 'Dropoff'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the verification code provided by the ${type == VerificationType.pickup ? 'passenger' : 'passenger'}:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _verificationCodeController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _processVerification(type),
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the final amount for this ride:'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Final Amount (\$)',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                Navigator.pop(context);
                await _processPayment(amount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Complete Ride'),
          ),
        ],
      ),
    );
  }

  Future<void> _processVerification(VerificationType type) async {
    final code = _verificationCodeController.text.trim();
    final notes = _notesController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      Navigator.pop(context);

      if (type == VerificationType.pickup) {
        await _rideTrackingService.verifyPickup(
          rideTrackingId: widget.rideTrackingId,
          verificationCode: code,
          notes: notes.isNotEmpty ? notes : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await _rideTrackingService.verifyDropoff(
          rideTrackingId: widget.rideTrackingId,
          verificationCode: code,
          notes: notes.isNotEmpty ? notes : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dropoff verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processPayment(double amount) async {
    try {
      await _rideTrackingService.completeRide(
        rideTrackingId: widget.rideTrackingId,
        finalAmount: amount,
      );

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      await _rideTrackingService.markPaymentCompleted(
        rideTrackingId: widget.rideTrackingId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride completed and payment processed!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getStatusIcon(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
        return Icons.check_circle;
      case RideStatus.driverArriving:
        return Icons.directions_car;
      case RideStatus.pickupVerified:
        return Icons.person_pin_circle;
      case RideStatus.inProgress:
        return Icons.navigation;
      case RideStatus.dropoffVerified:
        return Icons.location_on;
      case RideStatus.completed:
        return Icons.flag;
      default:
        return Icons.info;
    }
  }

  String _getStatusDescription(RideStatus status) {
    switch (status) {
      case RideStatus.accepted:
        return 'Driver has accepted your ride request';
      case RideStatus.driverArriving:
        return 'Driver is on the way to pick you up';
      case RideStatus.pickupVerified:
        return 'Driver has confirmed pickup';
      case RideStatus.inProgress:
        return 'You are on your way to destination';
      case RideStatus.dropoffVerified:
        return 'You have arrived at your destination';
      case RideStatus.completed:
        return 'Ride completed successfully';
      default:
        return '';
    }
  }

  String _getStepTitle(RideStatus step) {
    switch (step) {
      case RideStatus.accepted:
        return 'Ride Accepted';
      case RideStatus.driverArriving:
        return 'Driver Arriving';
      case RideStatus.pickupVerified:
        return 'Pickup Confirmed';
      case RideStatus.inProgress:
        return 'Trip In Progress';
      case RideStatus.dropoffVerified:
        return 'Dropoff Confirmed';
      case RideStatus.completed:
        return 'Trip Completed';
      default:
        return '';
    }
  }

  String _getStepDescription(RideStatus step) {
    switch (step) {
      case RideStatus.accepted:
        return 'Driver accepts your ride request';
      case RideStatus.driverArriving:
        return 'Driver is coming to pick you up';
      case RideStatus.pickupVerified:
        return 'Driver confirms passenger pickup';
      case RideStatus.inProgress:
        return 'Trip is in progress';
      case RideStatus.dropoffVerified:
        return 'Arrived at destination';
      case RideStatus.completed:
        return 'Payment processed and trip complete';
      default:
        return '';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
