import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_models.dart';

/// Service to handle approved products for businesses
class ApprovedProductsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all approved master products that businesses can add pricing to
  Future<List<MasterProduct>> getApprovedMasterProducts() async {
    try {
      final snapshot = await _firestore
          .collection('master_products')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => MasterProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching approved master products: $e');
      rethrow;
    }
  }

  /// Get master products by category
  Future<List<MasterProduct>> getMasterProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('master_products')
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => MasterProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching master products by category: $e');
      rethrow;
    }
  }

  /// Submit business product pricing for admin approval
  Future<String> submitBusinessProduct({
    required String masterProductId,
    required String businessId,
    required double price,
    required int stock,
    required bool available,
    String? businessNotes,
    Map<String, dynamic>? customAttributes,
    List<String>? businessImageUrls,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if business already has a listing for this master product
      final existingProduct = await _firestore
          .collection('business_products')
          .where('businessId', isEqualTo: businessId)
          .where('masterProductId', isEqualTo: masterProductId)
          .get();

      if (existingProduct.docs.isNotEmpty) {
        throw Exception('You already have a listing for this product');
      }

      // Create business product document
      final businessProduct = {
        'masterProductId': masterProductId,
        'businessId': businessId,
        'userId': currentUser.uid,
        'price': price,
        'stock': stock,
        'available': available,
        'businessNotes': businessNotes,
        'customAttributes': customAttributes ?? {},
        'businessImageUrls': businessImageUrls ?? [],
        'status': 'pending', // Admin needs to approve
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'submittedBy': currentUser.email ?? currentUser.uid,
      };

      final docRef = await _firestore
          .collection('business_products')
          .add(businessProduct);

      print('Business product submitted for approval: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error submitting business product: $e');
      rethrow;
    }
  }

  /// Update existing business product
  Future<void> updateBusinessProduct({
    required String businessProductId,
    required double price,
    required int stock,
    required bool available,
    String? businessNotes,
    Map<String, dynamic>? customAttributes,
    List<String>? businessImageUrls,
  }) async {
    try {
      final updates = {
        'price': price,
        'stock': stock,
        'available': available,
        'businessNotes': businessNotes,
        'customAttributes': customAttributes ?? {},
        'businessImageUrls': businessImageUrls ?? [],
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending', // Requires re-approval for changes
      };

      await _firestore
          .collection('business_products')
          .doc(businessProductId)
          .update(updates);

      print('Business product updated: $businessProductId');
    } catch (e) {
      print('Error updating business product: $e');
      rethrow;
    }
  }

  /// Get business products for a specific business
  Future<List<Map<String, dynamic>>> getBusinessProducts(String businessId) async {
    try {
      final snapshot = await _firestore
          .collection('business_products')
          .where('businessId', isEqualTo: businessId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      print('Error fetching business products: $e');
      rethrow;
    }
  }

  /// Get approved business products for marketplace display
  Future<List<Map<String, dynamic>>> getApprovedBusinessProducts() async {
    try {
      final snapshot = await _firestore
          .collection('business_products')
          .where('status', isEqualTo: 'approved')
          .where('available', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      // Fetch master product details for each business product
      List<Map<String, dynamic>> productsWithDetails = [];
      
      for (var doc in snapshot.docs) {
        final businessProduct = doc.data() as Map<String, dynamic>;
        final masterProductId = businessProduct['masterProductId'];
        
        if (masterProductId != null) {
          final masterProductDoc = await _firestore
              .collection('master_products')
              .doc(masterProductId)
              .get();
          
          if (masterProductDoc.exists) {
            productsWithDetails.add({
              'id': doc.id,
              'businessProduct': businessProduct,
              'masterProduct': masterProductDoc.data(),
            });
          }
        }
      }

      return productsWithDetails;
    } catch (e) {
      print('Error fetching approved business products: $e');
      rethrow;
    }
  }

  /// Check if business can add pricing to a master product
  Future<bool> canAddPricingToProduct(String businessId, String masterProductId) async {
    try {
      final existingProduct = await _firestore
          .collection('business_products')
          .where('businessId', isEqualTo: businessId)
          .where('masterProductId', isEqualTo: masterProductId)
          .get();

      return existingProduct.docs.isEmpty;
    } catch (e) {
      print('Error checking product availability: $e');
      return false;
    }
  }

  /// Get product categories for business selection
  Future<List<ProductCategory>> getProductCategories() async {
    try {
      final snapshot = await _firestore
          .collection('product_categories')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ProductCategory.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching product categories: $e');
      rethrow;
    }
  }

  /// Stream of business products for real-time updates
  Stream<List<Map<String, dynamic>>> streamBusinessProducts(String businessId) {
    return _firestore
        .collection('business_products')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }).toList());
  }
}
