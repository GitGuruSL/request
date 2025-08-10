import 'package:flutter/material.dart';
import '../../models/ride_tracking_model.dart';
import '../../services/ride_tracking_service.dart';
import '../screens/ride_tracking_screen.dart';

class DriverRideManagementScreen extends StatefulWidget {
  const DriverRideManagementScreen({super.key});

  @override
  State<DriverRideManagementScreen> createState() =>
      _DriverRideManagementScreenState();
}

class _DriverRideManagementScreenState extends State<DriverRideManagementScreen>
    with SingleTickerProviderStateMixin {
  final RideTrackingService _rideTrackingService = RideTrackingService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rides'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(
              icon: Icon(Icons.directions_car),
              text: 'Active Rides',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Ride History',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveRides(),
          _buildRideHistory(),
        ],
      ),
    );
  }

  Widget _buildActiveRides() {
    return StreamBuilder<List<RideTracking>>(
      stream: _rideTrackingService.getActiveRides(asDriver: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading rides',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final activeRides = snapshot.data ?? [];

        if (activeRides.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No active rides',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When you accept ride requests, they will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: activeRides.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ride = activeRides[index];
            return _buildRideCard(ride, isActive: true);
          },
        );
      },
    );
  }

  Widget _buildRideHistory() {
    return StreamBuilder<List<RideTracking>>(
      stream: _rideTrackingService.getRideHistory(asDriver: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading ride history',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final rideHistory = snapshot.data ?? [];

        if (rideHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No ride history',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your completed rides will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: rideHistory.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final ride = rideHistory[index];
            return _buildRideCard(ride, isActive: false);
          },
        );
      },
    );
  }

  Widget _buildRideCard(RideTracking ride, {required bool isActive}) {
    final statusColor = ride.getStatusColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideTrackingScreen(
                rideTrackingId: ride.id,
                isDriver: true,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(ride.status),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ride.getStatusDisplayText(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Ride details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ride ID: #${ride.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Started: ${_formatDateTime(ride.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (ride.completedAt != null)
                          Text(
                            'Completed: ${_formatDateTime(ride.completedAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (ride.finalAmount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        '\$${ride.finalAmount!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons for active rides
              if (isActive) ...[
                const Divider(),
                const SizedBox(height: 8),
                _buildQuickActions(ride),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(RideTracking ride) {
    List<Widget> actions = [];

    switch (ride.status) {
      case RideStatus.accepted:
        actions.add(
          _buildActionButton(
            'I\'m Arriving',
            Icons.directions_car,
            Colors.blue,
            () => _updateRideStatus(ride.id, RideStatus.driverArriving),
          ),
        );
        break;
      case RideStatus.driverArriving:
        actions.add(
          _buildActionButton(
            'Verify Pickup',
            Icons.person_pin_circle,
            Colors.green,
            () => _showVerificationDialog(ride.id, VerificationType.pickup),
          ),
        );
        break;
      case RideStatus.pickupVerified:
        actions.add(
          _buildActionButton(
            'Start Trip',
            Icons.navigation,
            Colors.blue,
            () => _updateRideStatus(ride.id, RideStatus.inProgress),
          ),
        );
        break;
      case RideStatus.inProgress:
        actions.add(
          _buildActionButton(
            'Verify Dropoff',
            Icons.location_on,
            Colors.orange,
            () => _showVerificationDialog(ride.id, VerificationType.dropoff),
          ),
        );
        break;
      case RideStatus.dropoffVerified:
        actions.add(
          _buildActionButton(
            'Complete Ride',
            Icons.payment,
            Colors.green,
            () => _showPaymentDialog(ride.id),
          ),
        );
        break;
      default:
        break;
    }

    if (actions.isEmpty) {
      return Container();
    }

    return Row(
      children: actions.map((action) {
        return Expanded(child: action);
      }).toList(),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Future<void> _updateRideStatus(
      String rideTrackingId, RideStatus status) async {
    try {
      await _rideTrackingService.updateRideStatus(
        rideTrackingId: rideTrackingId,
        status: status,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showVerificationDialog(String rideTrackingId, VerificationType type) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Verify ${type == VerificationType.pickup ? 'Pickup' : 'Dropoff'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the verification code provided by the passenger:',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Verification Code',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
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
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                await _processVerification(rideTrackingId, type, code);
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(String rideTrackingId) {
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
                await _processPayment(rideTrackingId, amount);
              }
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  Future<void> _processVerification(
    String rideTrackingId,
    VerificationType type,
    String code,
  ) async {
    try {
      if (type == VerificationType.pickup) {
        await _rideTrackingService.verifyPickup(
          rideTrackingId: rideTrackingId,
          verificationCode: code,
        );
      } else {
        await _rideTrackingService.verifyDropoff(
          rideTrackingId: rideTrackingId,
          verificationCode: code,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${type == VerificationType.pickup ? 'Pickup' : 'Dropoff'} verified!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPayment(String rideTrackingId, double amount) async {
    try {
      await _rideTrackingService.completeRide(
        rideTrackingId: rideTrackingId,
        finalAmount: amount,
      );

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 1));

      await _rideTrackingService.markPaymentCompleted(
        rideTrackingId: rideTrackingId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride completed and payment processed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
