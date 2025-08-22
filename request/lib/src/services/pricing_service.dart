import 'dart:async';
import '../models/price_listing.dart';
import '../models/master_product.dart';
import 'api_client.dart';

class PricingService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<MasterProduct>> searchProducts(
      {String query = '', String? brand, int limit = 25}) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/price-listings/search',
        queryParameters: {
          'q': query,
          'country': 'LK',
          'limit': limit.toString(),
          if (brand != null) 'brand': brand,
        },
      );

      if (response.isSuccess && response.data != null) {
        return response.data!
            .map((data) => MasterProduct.fromJson(data))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  Future<bool> isBusinessEligibleForPricing(String? businessUserId) async {
    if (businessUserId == null) return false;

    try {
      // Check if business is verified
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/business-verifications/status/$businessUserId',
      );

      return response.isSuccess && response.data?['isVerified'] == true;
    } catch (e) {
      print('Error checking business eligibility: $e');
      return false;
    }
  }

  Stream<List<PriceListing>> getPriceListingsForProduct(
      String masterProductId) async* {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/price-listings',
        queryParameters: {
          'masterProductId': masterProductId,
          'country': 'LK',
          'sortBy': 'price_asc',
        },
      );

      if (response.isSuccess && response.data?['data'] != null) {
        final List<dynamic> listingsData = response.data!['data'];
        final listings =
            listingsData.map((data) => PriceListing.fromJson(data)).toList();
        yield listings;
      } else {
        yield [];
      }
    } catch (e) {
      print('Error loading price listings: $e');
      yield [];
    }
  }

  Future<List<Map<String, dynamic>>> getActiveVariableTypes() async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/variable-types',
        queryParameters: {'country': 'LK', 'active': 'true'},
      );

      if (response.isSuccess && response.data != null) {
        return response.data!.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error loading variable types: $e');
      return [];
    }
  }

  Future<void> trackProductClick({
    String? listingId,
    String? masterProductId,
    String? businessId,
    String? userId,
  }) async {
    if (listingId == null) return;

    try {
      await _apiClient.post(
        '/api/price-listings/$listingId/contact',
        data: {
          'userId': userId,
          'masterProductId': masterProductId,
          'businessId': businessId,
        },
      );
    } catch (e) {
      print('Error tracking product click: $e');
    }
  }

  Stream<List<PriceListing>> getBusinessPriceListings(
      String? businessId) async* {
    if (businessId == null) {
      yield [];
      return;
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/price-listings',
        queryParameters: {
          'businessId': businessId,
          'country': 'LK',
        },
      );

      if (response.isSuccess && response.data?['data'] != null) {
        final List<dynamic> listingsData = response.data!['data'];
        final listings =
            listingsData.map((data) => PriceListing.fromJson(data)).toList();
        yield listings;
      } else {
        yield [];
      }
    } catch (e) {
      print('Error loading business price listings: $e');
      yield [];
    }
  }

  Future<bool> deletePriceListing(
      String listingId, String masterProductId) async {
    try {
      final response =
          await _apiClient.delete('/api/price-listings/$listingId');
      return response.isSuccess;
    } catch (e) {
      print('Error deleting price listing: $e');
      return false;
    }
  }

  Stream<List<dynamic>> getMasterProducts({
    String? category,
    String? query,
    String? searchQuery,
    String? businessId,
    String? brand,
    int limit = 50,
  }) async* {
    try {
      final effectiveQuery = query ?? searchQuery ?? '';
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/price-listings/search',
        queryParameters: {
          'q': effectiveQuery,
          'country': 'LK',
          'limit': limit.toString(),
          if (category != null) 'category': category,
          if (brand != null) 'brand': brand,
        },
      );

      if (response.isSuccess && response.data?['data'] != null) {
        yield response.data!['data'];
      } else {
        yield [];
      }
    } catch (e) {
      print('Error loading master products: $e');
      yield [];
    }
  }

  Future<Map<String, dynamic>?> getBusinessProfile(String? userId) async {
    if (userId == null) return null;

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/business-verifications/profile/$userId',
      );

      if (response.isSuccess && response.data != null) {
        return response.data;
      }
      return {'businessId': userId, 'name': 'Business User'};
    } catch (e) {
      print('Error loading business profile: $e');
      return {'businessId': userId, 'name': 'Business User'};
    }
  }

  Future<bool> addOrUpdatePriceListing(dynamic listing) async {
    try {
      Map<String, dynamic> data;
      if (listing is Map<String, dynamic>) {
        data = listing;
      } else {
        // Convert object to map if needed
        data = listing.toJson();
      }

      final response = await _apiClient.post(
        '/api/price-listings',
        data: data,
      );

      return response.isSuccess;
    } catch (e) {
      print('Error adding/updating price listing: $e');
      return false;
    }
  }

  Future<bool> createOrUpdateListing(Map<String, dynamic> data) async {
    return await addOrUpdatePriceListing(data);
  }
}
