class PaymentMethodsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get all payment methods for a specific country
  static Future<List<PaymentMethod>> getPaymentMethodsForCountry(String countryCode) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('payment_methods')
          .where('country', isEqualTo: countryCode)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      return snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching payment methods: $e');
      return [];
    }
  }
  
  /// Get payment methods by IDs (for user profiles)
  static Future<List<PaymentMethod>> getPaymentMethodsByIds(List<String> methodIds) async {
    if (methodIds.isEmpty) return [];
    
    try {
      final List<PaymentMethod> methods = [];
      
      // Firestore 'in' query has a limit of 10, so batch the requests
      for (int i = 0; i < methodIds.length; i += 10) {
        final batch = methodIds.skip(i).take(10).toList();
        
        final QuerySnapshot snapshot = await _firestore
            .collection('payment_methods')
            .where(FieldPath.documentId, whereIn: batch)
            .where('isActive', isEqualTo: true)
            .get();
        
        methods.addAll(
          snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList()
        );
      }
      
      return methods;
    } catch (e) {
      print('Error fetching payment methods by IDs: $e');
      return [];
    }
  }
  
  /// Search payment methods by name or category
  static Future<List<PaymentMethod>> searchPaymentMethods(
    String countryCode, 
    String searchQuery
  ) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('payment_methods')
          .where('country', isEqualTo: countryCode)
          .where('isActive', isEqualTo: true)
          .get();
      
      final methods = snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList();
      
      if (searchQuery.isEmpty) return methods;
      
      return methods.where((method) {
        return method.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               method.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
               method.category.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching payment methods: $e');
      return [];
    }
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String description;
  final String country;
  final String imageUrl;
  final String linkUrl;
  final bool isActive;
  final String category;
  final String fees;
  final String processingTime;
  final String minAmount;
  final String maxAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.country,
    required this.imageUrl,
    required this.linkUrl,
    required this.isActive,
    required this.category,
    required this.fees,
    required this.processingTime,
    required this.minAmount,
    required this.maxAmount,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PaymentMethod(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      country: data['country'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      linkUrl: data['linkUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      category: data['category'] ?? 'digital',
      fees: data['fees'] ?? '',
      processingTime: data['processingTime'] ?? '',
      minAmount: data['minAmount'] ?? '',
      maxAmount: data['maxAmount'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'country': country,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'isActive': isActive,
      'category': category,
      'fees': fees,
      'processingTime': processingTime,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
