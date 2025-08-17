import 'dart:async';
import '../models/price_listing.dart';

class PricingService {
  Future<List<PriceListing>> searchProducts(
      {String query = '', String? brand, int limit = 25}) async {
    // Return empty typed list placeholder
    return <PriceListing>[];
  }

  Future<bool> isBusinessEligibleForPricing(String? businessUserId) async =>
      true;
  Stream<List<PriceListing>> getPriceListingsForProduct(
      String masterProductId) async* {
    yield <PriceListing>[];
  }

  Future<List<Map<String, dynamic>>> getActiveVariableTypes() async => [];
  Future<void> trackProductClick(
      {String? listingId,
      String? masterProductId,
      String? businessId,
      String? userId}) async {}
  Stream<List<PriceListing>> getBusinessPriceListings(
      String? businessId) async* {
    yield <PriceListing>[];
  }

  Future<bool> deletePriceListing(
          String listingId, String masterProductId) async =>
      true;
  Stream<List<dynamic>> getMasterProducts(
      {String? category,
      String? query,
      String? searchQuery,
      String? businessId,
      String? brand,
      int limit = 50}) async* {
    // accept either query or searchQuery (legacy param name)
    // ignore effective query in placeholder implementation
    yield const [];
  }

  Future<Map<String, dynamic>?> getBusinessProfile(String? userId) async =>
      userId == null ? null : {'businessId': userId, 'name': 'Stub Business'};
  Future<bool> addOrUpdatePriceListing(dynamic listing) async => true;
  Future<bool> createOrUpdateListing(Map<String, dynamic> data) async => true;
}
