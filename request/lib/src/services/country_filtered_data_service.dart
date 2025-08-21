import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/request_model.dart' as models;
import '../models/enhanced_user_model.dart' as enhanced;
import 'rest_request_service.dart'
    show RestRequestService, RequestModel, RequestsResponse;
import 'country_service.dart';

/// Provides country-scoped data streams for all app content
/// Ensures users only see content from their selected country
class CountryFilteredDataService {
  CountryFilteredDataService._();
  static final CountryFilteredDataService instance =
      CountryFilteredDataService._();

  final RestRequestService _requests = RestRequestService.instance;

  /// Get the current user's country filter
  String? get currentCountry => CountryService.instance.countryCode;

  /// Get country-filtered requests with pagination (direct method for compatibility)
  Future<RequestsResponse?> getRequests({
    int page = 1,
    int limit = 20,
    String? categoryId,
    String? status,
  }) async {
    if (currentCountry == null) {
      if (kDebugMode) print('⚠️ No country selected, returning empty requests');
      return null;
    }

    try {
      final result = await _requests.getRequests(
        page: page,
        limit: limit,
        categoryId: categoryId,
        hasAccepted: false,
        // country: currentCountry, // Add when backend implements this
      );

      if (result == null) return null;

      // Client-side filtering by country until backend implements it
      final countryFiltered = result.requests
          .where((r) => r.countryCode == currentCountry)
          .toList();

      // Return modified response with filtered data
      return RequestsResponse(
        requests: countryFiltered,
        pagination: result.pagination,
      );
    } catch (e) {
      if (kDebugMode) print('❌ Error loading country requests: $e');
      return null;
    }
  }

  /// Get country-filtered requests stream
  Stream<List<models.RequestModel>> getCountryRequestsStream({
    String? status,
    String? type,
    String? category,
    String? subcategory,
    int limit = 50,
    String? searchQuery,
  }) async* {
    if (currentCountry == null) {
      if (kDebugMode) print('⚠️ No country selected, returning empty requests');
      yield <models.RequestModel>[];
      return;
    }

    try {
      // TODO: Add country parameter to REST request service when backend supports it
      final result = await _requests.getRequests(
        page: 1,
        limit: limit,
        hasAccepted: false,
        // country: currentCountry, // Add when backend implements this
      );

      if (result == null) {
        yield <models.RequestModel>[];
      } else {
        // Client-side filtering by country until backend implements it
        final countryFiltered = result.requests
            .where((r) => r.countryCode == currentCountry)
            .toList();

        // Apply additional filters
        var filtered = countryFiltered;
        // Note: type filtering removed because REST RequestModel doesn't have type property
        if (status != null) {
          filtered = filtered
              .where((r) => r.status.toLowerCase() == status.toLowerCase())
              .toList();
        }
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final query = searchQuery.toLowerCase();
          filtered = filtered
              .where((r) =>
                  r.title.toLowerCase().contains(query) ||
                  r.description.toLowerCase().contains(query))
              .toList();
        }

        final converted = filtered.map(_convertToRequestModel).toList();
        if (kDebugMode)
          print(
              '🌍 Returning ${converted.length} requests for country: $currentCountry');
        yield converted;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error loading country requests: $e');
      yield <models.RequestModel>[];
    }
  }

  /// Get country-filtered businesses stream
  Stream<List<Map<String, dynamic>>> getCountryBusinessesStream({
    bool verifiedOnly = false,
    String? category,
  }) async* {
    if (currentCountry == null) {
      if (kDebugMode)
        print('⚠️ No country selected, returning empty businesses');
      yield <Map<String, dynamic>>[];
      return;
    }

    // TODO: Implement when business REST endpoint is available
    // For now, return empty stream
    if (kDebugMode) print('🏢 Business filtering not yet implemented');
    yield <Map<String, dynamic>>[];
  }

  /// Get country-filtered price listings stream
  Stream<List<Map<String, dynamic>>> getCountryPriceListingsStream({
    String? category,
    String? subcategory,
    double? minPrice,
    double? maxPrice,
  }) async* {
    if (currentCountry == null) {
      if (kDebugMode)
        print('⚠️ No country selected, returning empty price listings');
      yield <Map<String, dynamic>>[];
      return;
    }

    // TODO: Implement when price listings REST endpoint is available
    // For now, return empty stream
    if (kDebugMode) print('💰 Price listings filtering not yet implemented');
    yield <Map<String, dynamic>>[];
  }

  /// Get country-filtered categories
  Future<List<Map<String, dynamic>>> getCountryCategories() async {
    if (currentCountry == null) {
      if (kDebugMode)
        print('⚠️ No country selected, returning empty categories');
      return [];
    }

    try {
      // TODO: Implement REST call to /api/categories with country filter
      // For now, return default categories
      if (kDebugMode)
        print(
            '📂 Categories filtering not yet implemented for country: $currentCountry');
      return [];
    } catch (e) {
      if (kDebugMode) print('❌ Error loading country categories: $e');
      return [];
    }
  }

  /// Get country-filtered subcategories for a category
  Future<List<Map<String, dynamic>>> getCountrySubcategories(
      String categoryId) async {
    if (currentCountry == null) {
      if (kDebugMode)
        print('⚠️ No country selected, returning empty subcategories');
      return [];
    }

    try {
      // TODO: Implement REST call to /api/subcategories with country filter
      if (kDebugMode)
        print(
            '📁 Subcategories filtering not yet implemented for country: $currentCountry');
      return [];
    } catch (e) {
      if (kDebugMode) print('❌ Error loading country subcategories: $e');
      return [];
    }
  }

  /// Check if country filtering is properly set up
  bool get isCountryFilteringActive => currentCountry != null;

  /// Get country display info
  Map<String, String> getCountryInfo() {
    final service = CountryService.instance;
    return {
      'countryCode': service.countryCode ?? 'unknown',
      'countryName':
          service.countryName.isNotEmpty ? service.countryName : 'Unknown',
      'currency': service.currency.isNotEmpty ? service.currency : 'LKR',
      'phoneCode': service.phoneCode.isNotEmpty ? service.phoneCode : '+94',
    };
  }

  /// Convert REST RequestModel to UI RequestModel
  models.RequestModel _convertToRequestModel(RequestModel r) {
    return models.RequestModel(
      id: r.id,
      requesterId: r.userId,
      title: r.title,
      description: r.description,
      type: _convertRequestType(
          r.categoryName), // Use category name for type mapping
      status: _convertRequestStatus(r.status),
      priority: models.Priority.medium,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      images: r.imageUrls ?? const [],
      typeSpecificData: r.metadata ?? const {},
      budget: r.budget,
      currency: r.currency ?? CountryService.instance.currency,
      country: r.countryCode,
      countryName: CountryService.instance.countryName,
      isPublic: true,
      responses: const [],
      tags: const [],
      contactMethod: null,
      location: null,
      destinationLocation: null,
    );
  }

  enhanced.RequestType _convertRequestType(String? type) {
    switch (type?.toLowerCase()) {
      case 'item':
        return enhanced.RequestType.item;
      case 'service':
        return enhanced.RequestType.service;
      case 'rental':
      case 'rent':
        return enhanced.RequestType.rental;
      case 'delivery':
        return enhanced.RequestType.delivery;
      case 'ride':
        return enhanced.RequestType.ride;
      case 'price':
        return enhanced.RequestType.price;
      default:
        return enhanced.RequestType.item;
    }
  }

  models.RequestStatus _convertRequestStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return models.RequestStatus.active;
      case 'completed':
        return models.RequestStatus.completed;
      case 'cancelled':
        return models.RequestStatus.cancelled;
      default:
        return models.RequestStatus.active;
    }
  }

  /// Get active variable types for the current country
  Future<List<Map<String, dynamic>>> getActiveVariableTypes() async {
    if (currentCountry == null) {
      if (kDebugMode)
        print('⚠️ No country selected, returning empty variable types');
      return <Map<String, dynamic>>[];
    }

    try {
      // Get base URL from platform configuration
      String baseUrl;
      if (kIsWeb) {
        baseUrl = 'http://localhost:3001';
      } else if (Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:3001';
      } else if (Platform.isIOS) {
        baseUrl = 'http://localhost:3001';
      } else {
        baseUrl = 'http://localhost:3001';
      }

      final url = Uri.parse('$baseUrl/api/country-variable-types');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final allVariableTypes = data['data'] as List;

          // Filter by current country and active status
          final filteredTypes = allVariableTypes
              .where((vt) =>
                  vt['country_code'] == currentCountry &&
                  (vt['is_active'] == true || vt['is_active'] == 1))
              .map((vt) => {
                    'id': vt['variable_id']?.toString() ??
                        vt['id']?.toString() ??
                        '',
                    'name': vt['variable_name'] ?? vt['name'] ?? '',
                    'type': vt['variable_type'] ?? vt['type'] ?? 'select',
                    'required': vt['is_required'] ?? false,
                    'custom_settings': vt['custom_settings'] ?? {},
                  })
              .toList();

          if (kDebugMode)
            print(
                '✅ Loaded ${filteredTypes.length} active variable types for country $currentCountry');
          return filteredTypes;
        }
      }

      if (kDebugMode)
        print('❌ Failed to load variable types: ${response.statusCode}');
      return <Map<String, dynamic>>[];
    } catch (e) {
      if (kDebugMode) print('❌ Error loading variable types: $e');
      return <Map<String, dynamic>>[];
    }
  }
}
