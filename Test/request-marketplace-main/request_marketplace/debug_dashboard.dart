import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with your config
  await Firebase.initializeApp();
  
  print('🔍 Testing Dashboard Query Issue');
  
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  
  print('Current user: ${auth.currentUser?.uid ?? "Not logged in"}');
  
  if (auth.currentUser == null) {
    print('❌ No user logged in. Please log in first.');
    return;
  }
  
  try {
    print('\n🔍 Testing StreamBuilder query equivalent...');
    
    // Test the exact same query as the dashboard
    final stream = firestore
        .collection('requests')
        .where('userId', isEqualTo: auth.currentUser!.uid)
        .limit(10)
        .snapshots();
    
    print('✅ Stream created successfully');
    
    // Listen to first result
    final snapshot = await stream.first;
    print('✅ Got first snapshot');
    print('📊 Documents found: ${snapshot.docs.length}');
    
    if (snapshot.docs.isEmpty) {
      print('❌ No documents found for user ${auth.currentUser!.uid}');
      
      // Check if any requests exist at all
      final allRequests = await firestore.collection('requests').get();
      print('📊 Total requests in DB: ${allRequests.docs.length}');
      
      if (allRequests.docs.isNotEmpty) {
        print('🔍 Sample request user IDs:');
        for (int i = 0; i < allRequests.docs.length && i < 5; i++) {
          final doc = allRequests.docs[i];
          final data = doc.data();
          print('  ${doc.id}: userId = "${data['userId']}"');
        }
        
        print('🔍 Current user ID: "${auth.currentUser!.uid}"');
        print('🔍 Looking for exact match...');
        
        final exactMatch = allRequests.docs.where((doc) {
          final data = doc.data();
          return data['userId'] == auth.currentUser!.uid;
        }).toList();
        
        print('📊 Exact matches found: ${exactMatch.length}');
      }
    } else {
      print('✅ Found ${snapshot.docs.length} requests for current user');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('  - ${data['title']} (${doc.id})');
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}
