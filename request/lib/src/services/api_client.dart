import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Base API client for REST API communication
class ApiClient {
  late final Dio _dio;
  // Use 10.0.2.2 for Android emulator to connect to host localhost
  static const String _baseUrl =
      'http://10.0.2.2:3001'; // Development URL for Android emulator
  static const String _tokenKey = 'jwt_token';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._internal();

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Request interceptor - Add auth token to headers
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (kDebugMode) {
          print('🚀 API Request: ${options.method} ${options.path}');
          if (options.data != null) {
            print('📤 Request Data: ${options.data}');
          }
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          print(
              '✅ API Response: ${response.statusCode} ${response.requestOptions.path}');
          print('📥 Response Data: ${response.data}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        if (kDebugMode) {
          print(
              '❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          print('🔥 Error Data: ${error.response?.data}');
        }

        // Handle 401 Unauthorized - token expired
        if (error.response?.statusCode == 401) {
          _handleTokenExpired();
        }

        handler.next(error);
      },
    ));
  }

  /// Store JWT token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieve stored JWT token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Clear stored token (logout)
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Handle token expiration
  void _handleTokenExpired() {
    clearToken();
    // Navigate to login screen - implement based on your navigation
    // NavigationService.instance.navigateToLogin();
  }

  /// Generic GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final response =
          await _dio.delete(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJson);
    } on DioException catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Handle successful responses
  ApiResponse<T> _handleResponse<T>(
    Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final success = data['success'] ?? false;
      final message = data['message'] ?? '';

      if (success) {
        T? parsedData;
        // If a transformer is provided AND a nested 'data' object exists, parse that.
        if (fromJson != null && data['data'] is Map<String, dynamic>) {
          parsedData = fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // Otherwise, if caller expects a Map (common for simple endpoints), return full map.
          try {
            // If caller didn't supply a fromJson parser, assume they want the raw map.
            if (fromJson == null) {
              parsedData = data as T; // includes fields like otpToken
            }
          } catch (_) {
            // Ignore cast issues; parsedData stays null.
          }
        }

        return ApiResponse<T>(
          success: true,
          data: parsedData,
          message: message,
        );
      } else {
        return ApiResponse<T>(
          success: false,
          error: message,
        );
      }
    }

    return ApiResponse<T>(
      success: false,
      error: 'Invalid response format',
    );
  }

  /// Handle error responses
  ApiResponse<T> _handleError<T>(DioException error) {
    String errorMessage = 'An error occurred';

    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response!.data as Map<String, dynamic>;
      errorMessage = data['message'] ?? data['error'] ?? errorMessage;
    } else if (error.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Connection timeout';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Request timeout';
    } else if (error.type == DioExceptionType.connectionError) {
      errorMessage = 'No internet connection';
    }

    return ApiResponse<T>(
      success: false,
      error: errorMessage,
      statusCode: error.response?.statusCode,
    );
  }
}

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
    this.statusCode,
  });

  bool get isSuccess => success;
  bool get isError => !success;

  @override
  String toString() {
    return 'ApiResponse(success: $success, data: $data, error: $error)';
  }
}

/// Pagination response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final data = json['data'] as Map<String, dynamic>;
    final itemsJson = data['requests'] ?? data['items'] ?? [];
    final pagination = data['pagination'] as Map<String, dynamic>;

    return PaginatedResponse<T>(
      items: (itemsJson as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] ?? 1,
      limit: pagination['limit'] ?? 20,
      total: pagination['total'] ?? 0,
      totalPages: pagination['totalPages'] ?? 1,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}
