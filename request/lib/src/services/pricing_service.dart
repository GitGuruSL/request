import 'dart:async';

class PricingService {
  Future<List<dynamic>> searchProducts(
          {String query = '', String? brand, int limit = 25}) async =>
      [];
  Future<bool> isBusinessEligibleForPricing(String? businessUserId) async =>
      true;
  Stream<List<dynamic>> getPriceListingsForProduct(
      String masterProductId) async* {
    yield const [];
  }

  Future<List<Map<String, dynamic>>> getActiveVariableTypes() async => [];
  Future<void> trackProductClick(
      {String? listingId,
      String? masterProductId,
      String? businessId,
      String? userId}) async {}
  Stream<List<dynamic>> getBusinessPriceListings(String? businessId) async* {
    yield const [];
  }

  Future<bool> deletePriceListing(
          String listingId, String masterProductId) async =>
      true;
  Stream<List<dynamic>> getMasterProducts(
      {String? category,
      String? query,
      String? searchQuery,
      String? businessId,
      int limit = 50}) async* {
    // accept either query or searchQuery (legacy param name)
    final effectiveQuery = query ?? searchQuery;
    yield const [];
  }

  Future<Map<String, dynamic>?> getBusinessProfile(String? userId) async =>
      userId == null ? null : {'businessId': userId, 'name': 'Stub Business'};
  Future<bool> addOrUpdatePriceListing(dynamic listing) async => true;
  Future<bool> createOrUpdateListing(Map<String, dynamic> data) async => true;
}
