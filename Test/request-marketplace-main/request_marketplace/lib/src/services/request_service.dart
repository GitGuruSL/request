import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:request_marketplace/src/models/request_model.dart';
import 'package:request_marketplace/src/models/user_model.dart';
import 'package:request_marketplace/src/services/activity_service.dart';

class RequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityService _activityService = ActivityService();

  // Check if Firebase Storage is properly configured
  Future<bool> isStorageAvailable() async {
    try {
      print('🔍 Testing Firebase Storage availability...');
      print('Storage instance: $_storage');
      
      // Try to list files in the root to check if storage is accessible
      final result = await _storage.ref().listAll().timeout(Duration(seconds: 3));
      print('✅ Storage test successful. Found ${result.items.length} items and ${result.prefixes.length} prefixes');
      return true;
    } catch (e) {
      print('❌ Storage availability check failed: $e');
      print('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }

  Future<String> _uploadImage(File imageFile, String requestId, int index) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    print('Uploading image to Firebase Storage...');
    print('User authenticated: ${user.uid}');
    
    final String fileName = 'request_${requestId}_image_$index.jpg';
    final Reference storageRef =
        _storage.ref().child('request_photos').child(fileName);

    print('Storage reference created: ${storageRef.fullPath}');

    try {
      // Create metadata to avoid null pointer exception
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );
      
      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Firebase Storage upload failed: $e');
      rethrow;
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<XFile> images, String requestId) async {
    List<String> imageUrls = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        print('Uploading image ${i + 1}/${images.length}...');
        final file = File(images[i].path);
        
        // Check file size (limit to 5MB)
        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception('Image ${i + 1} is too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Maximum size is 5MB.');
        }
        
        final url = await _uploadImage(file, requestId, i).timeout(Duration(seconds: 30));
        imageUrls.add(url);
        print('Image ${i + 1} uploaded successfully');
      } catch (e) {
        print('Failed to upload image ${i + 1}: $e');
        print('Error type: ${e.runtimeType}');
        // Don't throw here, just skip this image and continue
        print('Skipping image ${i + 1} and continuing with remaining images...');
      }
    }
    
    return imageUrls;
  }

  Future<String> createRequest({
    required String title,
    required String description,
    required RequestType type,
    required String condition,
    required double budget,
    required String location,
    required String category,
    required String subcategory,
    List<XFile> images = const [],
    List<String> additionalPhones = const [],
    Timestamp? deadline,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      print('Creating request for user: ${user.uid}');
      
      // 1. Create a document reference first to get an ID
      final requestRef = _firestore.collection('requests').doc();
      final requestId = requestRef.id;
      
      // 2. Upload images if any
      List<String> imageUrls = [];
      if (images.isNotEmpty) {
        print('Uploading ${images.length} images...');
        imageUrls = await uploadImages(images, requestId);
        print('Finished uploading images. Got ${imageUrls.length} URLs.');
      }

      // 3. Create the request model
      final newRequest = RequestModel(
        id: requestId,
        userId: user.uid,
        title: title,
        description: description,
        type: type,
        condition: ItemCondition.fromString(condition),
        budget: budget,
        location: location,
        category: category,
        subcategory: subcategory,
        imageUrls: imageUrls,
        additionalPhones: additionalPhones,
        status: 'open',
        deadline: deadline,
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );

      // 4. Save the request to Firestore
      await requestRef.set(newRequest.toMap());
      print('Request created successfully with ID: $requestId');

      // 5. Log the activity
      await _activityService.logActivity(
        'create_request',
        details: {
          'requestId': requestId,
          'title': title,
        },
      );
      print('Activity logged for request creation.');

      return requestId;
    } catch (e) {
      print('Error creating request: $e');
      // Consider more specific error handling or re-throwing
      throw Exception('Failed to create request: $e');
    }
  }

  // Get all requests with optional filters
  Future<List<RequestModel>> getAllRequests({
    RequestType? type,
    String? category,
    String? subcategory,
    double? maxBudget,
  }) async {
    print('🔍 RequestService: Getting all requests with filters - type: $type, category: $category, subcategory: $subcategory, maxBudget: $maxBudget');
    try {
      // Start with a simple query to avoid index requirements
      Query query = _firestore.collection('requests')
          .where('status', isEqualTo: 'open');

      // Add type filter if specified
      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      // Add category filter if specified
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Add subcategory filter if specified
      if (subcategory != null && subcategory.isNotEmpty) {
        query = query.where('subcategory', isEqualTo: subcategory);
      }

      print('📊 RequestService: Executing Firestore query...');
      final snapshot = await query.get();
      print('✅ RequestService: Got ${snapshot.docs.length} documents.');

      if (snapshot.docs.isEmpty) {
        return [];
      }

      // Fetch user data for each request
      final userIds = snapshot.docs.map((doc) => doc['userId'] as String).toSet().toList();
      
      Map<String, UserModel> usersMap = {};
      try {
        // Fetch user data one by one to avoid permission issues with bulk queries
        for (String userId in userIds) {
          try {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              usersMap[userId] = UserModel.fromFirestore(userDoc);
            }
          } catch (e) {
            print('⚠️  RequestService: Failed to fetch user profile for $userId: $e');
            // Continue with the next user
          }
        }
        print('✅ RequestService: Successfully fetched ${usersMap.length} user profiles out of ${userIds.length}');
      } catch (e) {
        print('⚠️  RequestService: Failed to fetch user profiles: $e');
        print('⚠️  RequestService: Continuing without user profile data');
        // Continue without user data - requests will still work but won't have user info
      }

      // Convert documents to RequestModel objects
      var results = snapshot.docs.map((doc) {
        final requestData = doc.data() as Map<String, dynamic>;
        final userId = requestData['userId'];
        final user = usersMap[userId];
        
        // Create RequestModel with user data
        return RequestModel(
          id: doc.id,
          userId: requestData['userId'] ?? '',
          title: requestData['title'] ?? '',
          description: requestData['description'] ?? '',
          type: RequestType.values.firstWhere(
            (e) => e.toString().split('.').last == requestData['type'],
            orElse: () => RequestType.item,
          ),
          condition: ItemCondition.fromString(requestData['condition'] ?? 'any'),
          budget: (requestData['budget'] ?? 0).toDouble(),
          location: requestData['location'] ?? '',
          category: requestData['category'] ?? '',
          subcategory: requestData['subcategory'] ?? '',
          imageUrls: List<String>.from(requestData['imageUrls'] ?? []),
          additionalPhones: List<String>.from(requestData['additionalPhones'] ?? []),
          status: requestData['status'] ?? 'open',
          deadline: requestData['deadline'],
          createdAt: requestData['createdAt'] ?? Timestamp.now(),
          updatedAt: requestData['updatedAt'] ?? Timestamp.now(),
          user: user, // Add the fetched user data directly
        );
      }).toList();

      // Apply client-side filtering for budget (since we removed it from the query)
      if (maxBudget != null && maxBudget > 0) {
        results = results.where((request) => request.budget <= maxBudget).toList();
      }

      // Sort by creation date in memory (since we removed orderBy from the query)
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return results;

    } catch (e) {
      print('❌ RequestService: Failed to get all requests: $e');
      throw Exception('Failed to get requests: $e');
    }
  }

  // Get requests for the current user
  Future<List<RequestModel>> getUserRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final querySnapshot = await _firestore
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final requests = querySnapshot.docs
          .map((doc) => RequestModel.fromFirestore(doc))
          .toList();
      
      print('✅ Retrieved ${requests.length} requests for user ${user.uid}');
      return requests;
    } catch (e) {
      print('❌ Failed to get user requests: $e');
      throw Exception('Failed to get user requests: $e');
    }
  }

  // Update request
  Future<void> updateRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('requests').doc(requestId).update(updates);
    } catch (e) {
      throw Exception('Failed to update request: $e');
    }
  }

  // Delete request
  Future<void> deleteRequest(String requestId) async {
    try {
      // First get the request to delete associated images
      final doc = await _firestore.collection('requests').doc(requestId).get();
      if (doc.exists) {
        final request = RequestModel.fromFirestore(doc);
        
        // Delete images from storage
        for (String imageUrl in request.imageUrls) {
          try {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Warning: Could not delete image: $e');
          }
        }
      }
      
      // Delete the document
      await _firestore.collection('requests').doc(requestId).delete();
    } catch (e) {
      throw Exception('Failed to delete request: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getRequestsStream() {
    return _firestore
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get requests stream with filters
  Stream<QuerySnapshot<Map<String, dynamic>>> getFilteredRequestsStream({
    String? category,
    String? subcategory,
    RequestType? type,
    double? maxBudget,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('requests').where('status', isEqualTo: 'open');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (subcategory != null) {
      query = query.where('subcategory', isEqualTo: subcategory);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.toString().split('.').last);
    }
    if (maxBudget != null) {
      query = query.where('budget', isLessThanOrEqualTo: maxBudget);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  // Get a single request by ID
  Future<RequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      
      if (!doc.exists) {
        return null;
      }

      return RequestModel.fromFirestore(doc);
    } catch (e) {
      print('❌ Error getting request by ID: $e');
      return null;
    }
  }

  // Get all requests (for dashboard)
  Future<List<Map<String, dynamic>>> getRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection('requests')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error getting requests: $e');
      return [];
    }
  }

  // Get responses by user
  Future<List<Map<String, dynamic>>> getResponsesByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('responses')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> responses = [];
      
      for (var doc in querySnapshot.docs) {
        final responseData = doc.data();
        responseData['id'] = doc.id;
        
        // Get request title
        if (responseData['requestId'] != null) {
          final requestDoc = await _firestore
              .collection('requests')
              .doc(responseData['requestId'])
              .get();
          
          if (requestDoc.exists) {
            final requestData = requestDoc.data()!;
            responseData['request_title'] = requestData['title'] ?? 'Ride Request';
          }
        }
        
        responses.add(responseData);
      }

      return responses;
    } catch (e) {
      print('❌ Error getting responses by user: $e');
      return [];
    }
  }
}
