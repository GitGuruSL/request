import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessDebugScreen extends StatefulWidget {
  const BusinessDebugScreen({super.key});

  @override
  State<BusinessDebugScreen> createState() => _BusinessDebugScreenState();
}

class _BusinessDebugScreenState extends State<BusinessDebugScreen> {
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _businessesFromCollection = [];
  Map<String, dynamic>? _businessFromUserDoc;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _debugBusinessData();
  }

  Future<void> _debugBusinessData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Check businesses collection
      final businessesQuery = await FirebaseFirestore.instance
          .collection('businesses')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final businessesData = businessesQuery.docs.map((doc) {
        final data = doc.data();
        data['_documentId'] = doc.id;
        return data;
      }).toList();

      // Check user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      Map<String, dynamic>? userBusinessProfile;
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        userBusinessProfile = userData['businessProfile'] as Map<String, dynamic>?;
      }

      setState(() {
        _businessesFromCollection = businessesData;
        _businessFromUserDoc = userBusinessProfile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error debugging business data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Debug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Businesses Collection:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._businessesFromCollection.map((business) => Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${business['_documentId']}'),
                    Text('Name: ${business['basicInfo']?['name'] ?? business['businessName'] ?? 'N/A'}'),
                    Text('Email: ${business['basicInfo']?['email'] ?? business['email'] ?? 'N/A'}'),
                    const SizedBox(height: 4),
                    Text('Data Structure: ${business['basicInfo'] != null ? 'Structured' : 'Flat'}'),
                  ],
                ),
              ),
            )).toList(),
            
            if (_businessesFromCollection.isEmpty) 
              const Text('No businesses found in collection'),

            const SizedBox(height: 24),
            const Text(
              'Business from User Document:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            if (_businessFromUserDoc != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${_businessFromUserDoc!['businessName'] ?? 'N/A'}'),
                      Text('Email: ${_businessFromUserDoc!['email'] ?? 'N/A'}'),
                      Text('Type: ${_businessFromUserDoc!['businessType'] ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      const Text('Data Structure: User Profile Embedded'),
                    ],
                  ),
                ),
              )
            else
              const Text('No business profile found in user document'),
          ],
        ),
      ),
    );
  }
}
