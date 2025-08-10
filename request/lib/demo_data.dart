// Demo script to test country-based functionality
// This file demonstrates how to create sample data for testing

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> createSampleRequests() async {
  final firestore = FirebaseFirestore.instance;
  
  // Sample requests for different countries
  final sampleRequests = [
    // United States requests
    {
      'id': 'req_001',
      'title': 'Need iPhone 15 Pro',
      'description': 'Looking for brand new iPhone 15 Pro in blue color',
      'type': 'item',
      'status': 'open',
      'userId': 'user_001',
      'country': 'United States',
      'budget': 1200.0,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'req_002',
      'title': 'Plumbing Service Needed',
      'description': 'Need a plumber to fix kitchen sink leak',
      'type': 'service',
      'status': 'open',
      'userId': 'user_002',
      'country': 'United States',
      'budget': 150.0,
      'createdAt': FieldValue.serverTimestamp(),
    },
    
    // United Kingdom requests
    {
      'id': 'req_003',
      'title': 'Gaming Laptop Required',
      'description': 'Need high-end gaming laptop for development work',
      'type': 'item',
      'status': 'open',
      'userId': 'user_003',
      'country': 'United Kingdom',
      'budget': 800.0, // Will show as £800
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'id': 'req_004',
      'title': 'Taxi to Airport',
      'description': 'Need ride to Heathrow Airport tomorrow morning',
      'type': 'ride',
      'status': 'open',
      'userId': 'user_004',
      'country': 'United Kingdom',
      'budget': 45.0, // Will show as £45
      'createdAt': FieldValue.serverTimestamp(),
    },
    
    // Canada requests
    {
      'id': 'req_005',
      'title': 'Moving Help',
      'description': 'Need help moving to new apartment this weekend',
      'type': 'service',
      'status': 'open',
      'userId': 'user_005',
      'country': 'Canada',
      'budget': 200.0, // Will show as C$200
      'createdAt': FieldValue.serverTimestamp(),
    },
    
    // Australia requests
    {
      'id': 'req_006',
      'title': 'Food Delivery',
      'description': 'Need food delivery from local restaurant',
      'type': 'delivery',
      'status': 'open',
      'userId': 'user_006',
      'country': 'Australia',
      'budget': 25.0, // Will show as A$25
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];
  
  // Add requests to Firestore
  for (final request in sampleRequests) {
    await firestore.collection('requests').doc(request['id'] as String).set(request);
    print('Created request: ${request['title']} in ${request['country']}');
  }
  
  print('All sample requests created successfully!');
}

// How to use this script:
// 1. Run this function after user authentication
// 2. The CountryService will automatically filter requests based on user's country
// 3. Currency will be displayed according to country (USD, GBP, CAD, AUD, etc.)
// 4. Only requests from user's selected country will be shown

void main() {
  // This is just a demo - in real app, call this function after Firebase initialization
  print('Demo script ready - call createSampleRequests() after Firebase init');
}
