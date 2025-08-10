import 'package:flutter/material.dart';
import '../models/driver_model.dart';

class DriverProfileCard extends StatelessWidget {
  final DriverModel driver;
  final bool showSensitiveInfo;
  final VoidCallback? onViewProfile;

  const DriverProfileCard({
    super.key,
    required this.driver,
    this.showSensitiveInfo = false,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with driver photo and basic info
            Row(
              children: [
                // Driver photo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: driver.driverImageUrls.isNotEmpty
                        ? Image.network(
                            driver.driverImageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderAvatar(),
                          )
                        : _buildPlaceholderAvatar(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            driver.rating > 0
                                ? driver.rating.toStringAsFixed(1)
                                : 'New',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${driver.totalRides} rides',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Verification badge
                      if (driver.status == DriverStatus.approved &&
                          driver.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 12,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Driver',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
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

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Vehicle information
            Row(
              children: [
                Icon(
                  _getVehicleIcon(driver.vehicleType),
                  size: 20,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${driver.vehicleColor} ${driver.vehicleModel}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Always show vehicle number for safety - requester needs to identify driver
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          'Vehicle: ${driver.vehicleNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        _getVehicleDisplayName(driver.vehicleType),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Vehicle images (only show front view for privacy)
            if (driver.vehicleImageUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Vehicle',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    driver.vehicleImageUrls.first, // Show only first image
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Icon(
                          Icons.directions_car,
                          size: 32,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Action button
            if (onViewProfile != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewProfile,
                  icon: const Icon(Icons.person, size: 18),
                  label: const Text('View Driver Profile'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        Icons.person,
        size: 30,
        color: Colors.grey.shade400,
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'bike':
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'threewheeler':
      case 'auto':
        return Icons.electric_rickshaw;
      case 'car':
        return Icons.directions_car;
      case 'van':
        return Icons.airport_shuttle;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  String _getVehicleDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'bike':
        return 'Motorcycle';
      case 'threewheeler':
        return 'Three Wheeler';
      case 'car':
        return 'Car';
      case 'van':
        return 'Van';
      case 'truck':
        return 'Truck';
      default:
        return type;
    }
  }
}
