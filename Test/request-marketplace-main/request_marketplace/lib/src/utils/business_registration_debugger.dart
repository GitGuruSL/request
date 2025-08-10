// Business Registration Debug Test
// This file helps debug business registration issues

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessRegistrationDebugger {
  static Future<void> testBusinessRegistration() async {
    print('🔍 Testing Business Registration...');
    
    try {
      // Test 1: Check Firestore connection
      print('📡 Testing Firestore connection...');
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').doc('connection').set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'connection_test'
      });
      print('✅ Firestore connection successful');
      
      // Test 2: Check user document creation/update
      print('👤 Testing user document update...');
      final testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      await firestore.collection('users').doc(testUserId).set({
        'email': 'test@example.com',
        'displayName': 'Test User',
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ User document creation successful');
      
      // Test 3: Test business profile addition
      print('🏢 Testing business profile addition...');
      await firestore.collection('users').doc(testUserId).update({
        'businessProfile': {
          'businessName': 'Test Business',
          'businessType': 'retail',
          'description': 'Test description',
          'businessCategories': ['Electronics'],
          'businessHours': {},
          'businessImages': [],
          'businessAddress': 'Test Address',
          'latitude': 0.0,
          'longitude': 0.0,
          'verificationStatus': 'pending',
          'averageRating': 0.0,
          'totalReviews': 0,
          'isActive': true,
        },
        'roles': FieldValue.arrayUnion(['business']),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Business profile addition successful');
      
      // Clean up test data
      await firestore.collection('users').doc(testUserId).delete();
      await firestore.collection('test').doc('connection').delete();
      
      print('🎉 All tests passed! Business registration should work.');
      
    } catch (e, stackTrace) {
      print('❌ Business registration test failed:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
    }
  }
  
  static Future<void> debugUserDocument(String userId) async {
    try {
      print('🔍 Debugging user document for: $userId');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        print('📄 User document exists');
        print('Data: ${doc.data()}');
      } else {
        print('❌ User document does not exist');
      }
    } catch (e) {
      print('❌ Error accessing user document: $e');
    }
  }
}

// Widget to add debug functionality to the registration screen
class BusinessRegistrationDebugWidget extends StatelessWidget {
  final String userId;
  
  const BusinessRegistrationDebugWidget({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        border: Border.all(color: Colors.orange),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Tools',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => BusinessRegistrationDebugger.testBusinessRegistration(),
            child: const Text('Run Registration Test'),
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: () => BusinessRegistrationDebugger.debugUserDocument(userId),
            child: const Text('Check User Document'),
          ),
        ],
      ),
    );
  }
}
