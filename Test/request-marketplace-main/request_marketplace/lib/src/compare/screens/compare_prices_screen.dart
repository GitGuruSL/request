import 'package:flutter/material.dart';

class ComparePricesScreen extends StatefulWidget {
  const ComparePricesScreen({super.key});

  @override
  State<ComparePricesScreen> createState() => _ComparePricesScreenState();
}

class _ComparePricesScreenState extends State<ComparePricesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Prices'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.compare_arrows,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Compare Prices',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Compare prices across different requests',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
