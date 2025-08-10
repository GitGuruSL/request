// Admin Phone Management Panel
// Comprehensive view for admins to manage phone verifications and handle duplicates

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/phone_verification_service.dart';

class AdminPhoneManagementScreen extends StatefulWidget {
  const AdminPhoneManagementScreen({super.key});

  @override
  State<AdminPhoneManagementScreen> createState() => _AdminPhoneManagementScreenState();
}

class _AdminPhoneManagementScreenState extends State<AdminPhoneManagementScreen> {
  final _phoneService = PhoneVerificationService();
  final _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _phoneRecords = [];
  List<Map<String, dynamic>> _otpRecords = [];
  bool _isLoading = false;
  String _selectedTab = 'phones';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Management'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search by phone number',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => _filterRecords(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Search'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Tab Selection
                Row(
                  children: [
                    _buildTabButton('phones', 'Phone Records'),
                    const SizedBox(width: 8),
                    _buildTabButton('otps', 'OTP Records'),
                  ],
                ),
              ],
            ),
          ),

          // Data Display
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'phones'
                    ? _buildPhoneRecordsView()
                    : _buildOTPRecordsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabKey, String label) {
    final isSelected = _selectedTab == tabKey;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedTab = tabKey;
        });
        _loadData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildPhoneRecordsView() {
    if (_phoneRecords.isEmpty) {
      return const Center(
        child: Text('No phone records found'),
      );
    }

    return ListView.builder(
      itemCount: _phoneRecords.length,
      itemBuilder: (context, index) {
        final record = _phoneRecords[index];
        return _buildPhoneRecordCard(record);
      },
    );
  }

  Widget _buildOTPRecordsView() {
    if (_otpRecords.isEmpty) {
      return const Center(
        child: Text('No OTP records found'),
      );
    }

    return ListView.builder(
      itemCount: _otpRecords.length,
      itemBuilder: (context, index) {
        final record = _otpRecords[index];
        return _buildOTPRecordCard(record);
      },
    );
  }

  Widget _buildPhoneRecordCard(Map<String, dynamic> record) {
    final phoneNumber = record['phoneNumber'] ?? 'Unknown';
    final collection = record['collection'] ?? 'Unknown';
    final userId = record['userId'] ?? 'Unknown';
    final userType = record['userType'] ?? 'Unknown';
    final isVerified = record['verified'] ?? false;
    final isActive = record['active'] ?? true;
    final createdAt = record['createdAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    phoneNumber,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(isVerified ? 'Verified' : 'Unverified', 
                    isVerified ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                _buildStatusChip(isActive ? 'Active' : 'Disabled', 
                    isActive ? Colors.blue : Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            
            _buildInfoRow('Collection', collection),
            _buildInfoRow('User Type', userType),
            _buildInfoRow('User ID', userId),
            if (createdAt != null)
              _buildInfoRow('Created', createdAt.toDate().toString()),
            
            const SizedBox(height: 12),
            
            // Action Buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _searchPhoneDuplicates(phoneNumber),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Find Duplicates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (!isActive)
                  ElevatedButton.icon(
                    onPressed: () => _reactivatePhone(record),
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Reactivate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (isActive && !isVerified)
                  ElevatedButton.icon(
                    onPressed: () => _disablePhone(record),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Disable'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOTPRecordCard(Map<String, dynamic> record) {
    final phoneNumber = record['phoneNumber'] ?? 'Unknown';
    final otp = record['otp'] ?? 'Unknown';
    final userType = record['userType'] ?? 'Unknown';
    final isVerified = record['verified'] ?? false;
    final createdAt = record['createdAt'] as Timestamp?;
    final context = record['context'] as Map<String, dynamic>? ?? {};

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    phoneNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'OTP: $otp',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            _buildInfoRow('User Type', userType),
            _buildInfoRow('Status', isVerified ? 'Verified' : 'Pending'),
            if (createdAt != null)
              _buildInfoRow('Created', createdAt.toDate().toString()),
            
            if (context.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Context:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              ...context.entries.map((entry) => 
                _buildInfoRow(entry.key, entry.value.toString())),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedTab == 'phones') {
        await _loadPhoneRecords();
      } else {
        await _loadOTPRecords();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPhoneRecords() async {
    final records = <Map<String, dynamic>>[];
    
    // Search across all collections
    final collections = ['users', 'businesses', 'drivers'];
    
    for (final collection in collections) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .get();
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['phoneNumber'] != null) {
          records.add({
            ...data,
            'collection': collection,
            'documentId': doc.id,
          });
        }
      }
    }

    setState(() {
      _phoneRecords = records;
    });
  }

  Future<void> _loadOTPRecords() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('phone_otps')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final records = querySnapshot.docs.map((doc) {
      return {
        ...doc.data(),
        'documentId': doc.id,
      };
    }).toList();

    setState(() {
      _otpRecords = records;
    });
  }

  void _filterRecords() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      _loadData();
      return;
    }

    setState(() {
      if (_selectedTab == 'phones') {
        _phoneRecords = _phoneRecords.where((record) {
          final phoneNumber = (record['phoneNumber'] ?? '').toString().toLowerCase();
          return phoneNumber.contains(query);
        }).toList();
      } else {
        _otpRecords = _otpRecords.where((record) {
          final phoneNumber = (record['phoneNumber'] ?? '').toString().toLowerCase();
          return phoneNumber.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _searchPhoneDuplicates(String phoneNumber) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Searching for duplicates...'),
          ],
        ),
      ),
    );

    try {
      final duplicates = <Map<String, dynamic>>[];
      final collections = ['users', 'businesses', 'drivers'];
      
      for (final collection in collections) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('phoneNumber', isEqualTo: phoneNumber)
            .get();
        
        for (final doc in querySnapshot.docs) {
          duplicates.add({
            ...doc.data(),
            'collection': collection,
            'documentId': doc.id,
          });
        }
      }

      Navigator.of(context).pop(); // Close loading dialog

      _showDuplicatesDialog(phoneNumber, duplicates);
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error searching duplicates: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDuplicatesDialog(String phoneNumber, List<Map<String, dynamic>> duplicates) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Duplicates for $phoneNumber'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: duplicates.isEmpty
              ? const Text('No duplicates found')
              : ListView.builder(
                  itemCount: duplicates.length,
                  itemBuilder: (context, index) {
                    final duplicate = duplicates[index];
                    return Card(
                      child: ListTile(
                        title: Text(duplicate['collection']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User ID: ${duplicate['userId'] ?? 'Unknown'}'),
                            Text('Verified: ${duplicate['verified'] ?? false}'),
                            Text('Active: ${duplicate['active'] ?? true}'),
                          ],
                        ),
                        trailing: duplicate['verified'] == false
                            ? ElevatedButton(
                                onPressed: () => _disablePhone(duplicate),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Disable', style: TextStyle(color: Colors.white)),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _disablePhone(Map<String, dynamic> record) async {
    try {
      await FirebaseFirestore.instance
          .collection(record['collection'])
          .doc(record['documentId'])
          .update({
        'active': false,
        'disabledAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone record disabled successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error disabling phone: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reactivatePhone(Map<String, dynamic> record) async {
    try {
      await FirebaseFirestore.instance
          .collection(record['collection'])
          .doc(record['documentId'])
          .update({
        'active': true,
        'reactivatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone record reactivated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error reactivating phone: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
