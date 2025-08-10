import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_models.dart';

class ApprovedProductsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all approved master products
  Stream<List<MasterProduct>> getApprovedMasterProducts() {
    return _firestore
        .collection('master_products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MasterProduct.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get product categories
  Stream<List<ProductCategory>> getProductCategories() {
    return _firestore
        .collection('product_categories')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductCategory.fromMap(doc.data(), doc.id))
            .where((category) => category.isActive == true) // Filter on client side
            .toList());
  }

  // Submit business product for approval
  Future<void> submitBusinessProduct(BusinessProduct businessProduct) async {
    await _firestore.collection('business_products').add(businessProduct.toMap());
  }

  // Submit business product with individual parameters
  Future<void> submitBusinessProductWithParams({
    required String masterProductId,
    required String businessId,
    required double price,
    required int stock,
    required bool available,
    String? businessNotes,
    String? businessName,
  }) async {
    final businessProduct = BusinessProduct(
      id: '', // Will be set by Firestore
      businessId: businessId,
      masterProductId: masterProductId,
      businessName: businessName,
      price: price,
      stock: stock,
      available: available,
      businessNotes: businessNotes,
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await submitBusinessProduct(businessProduct);
  }

  // Update business product
  Future<void> updateBusinessProduct(String productId, Map<String, dynamic> updates) async {
    await _firestore.collection('business_products').doc(productId).update(updates);
  }

  // Get business products by business ID
  Stream<List<BusinessProduct>> getBusinessProducts(String businessId) {
    return _firestore
        .collection('business_products')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusinessProduct.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Check if business already has a product for a master product
  Future<bool> hasBusinessProduct(String businessId, String masterProductId) async {
    final query = await _firestore
        .collection('business_products')
        .where('businessId', isEqualTo: businessId)
        .where('masterProductId', isEqualTo: masterProductId)
        .get();
    
    return query.docs.isNotEmpty;
  }
}
