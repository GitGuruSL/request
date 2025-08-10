import 'package:flutter/material.dart';

class BusinessManagementScreen extends StatelessWidget {
  final String businessId;

  const BusinessManagementScreen({
    super.key,
    required this.businessId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Management'),
      ),
      body: const Center(
        child: Text(
          'Business Management Screen\nComing Soon',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
