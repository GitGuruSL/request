import 'dart:async';

class PricingService {
  Future<List<dynamic>> searchProducts(
          [String query = '', int limit = 25]) async =>
      [];
  Future<bool> isBusinessEligibleForPricing(String? businessUserId) async =>
      true;
  Stream<List<dynamic>> getPriceListingsForProduct(
      String masterProductId) async* {
    yield const [];
  }

  Future<List<Map<String, dynamic>>> getActiveVariableTypes() async => [];
  Future<void> trackProductClick(
      {String? listingId, String? masterProductId, String? businessId}) async {}
  Stream<List<dynamic>> getBusinessPriceListings(String? businessId) async* {
    yield const [];
  }

  Future<bool> deletePriceListing(
          String listingId, String masterProductId) async =>
      true;
  Stream<List<dynamic>> getMasterProducts(
      {String? category,
      String? searchQuery,
      String? businessId,
      int limit = 50}) async* {
    yield const [];
  }

  Future<Map<String, dynamic>?> getBusinessProfile(String? userId) async =>
      userId == null ? null : {'businessId': userId, 'name': 'Stub Business'};
  Future<bool> addOrUpdatePriceListing(dynamic listing) async => true;
  Future<bool> createOrUpdateListing(Map<String, dynamic> data) async => true;
}
