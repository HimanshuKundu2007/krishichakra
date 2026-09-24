import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_env.dart';
import 'api_endpoints.dart';

// ─── Storage provider ─────────────────────────────────────────────────────────
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

// ─── Dio / API client provider ────────────────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage: storage);
});

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.isTimeout = false,
    this.isNetworkError = false,
    this.isServerError = false,
    this.isBackendUnavailable = false,
    this.isValidationError = false,
    this.isAuthError = false,
  });

  final String message;
  final int? statusCode;
  final bool isTimeout;
  final bool isNetworkError;
  final bool isServerError;
  final bool isBackendUnavailable;
  final bool isValidationError;
  final bool isAuthError;

  String get userMessage => message;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          message: 'Connection timed out. Please check your network and retry.',
          isTimeout: true,
          isNetworkError: true,
          isBackendUnavailable: true,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          message:
              'Unable to connect to KrishiChakra server. Please ensure the backend is running.',
          isNetworkError: true,
          isBackendUnavailable: true,
        );
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        String message = 'Server error occurred ($status)';
        if (data is Map && data['detail'] != null) {
          message = data['detail'].toString();
        } else if (data is String && data.isNotEmpty) {
          message = data;
        }

        final is5xx = status != null && status >= 500;
        final isUnavailable =
            status != null && (status == 502 || status == 503 || status == 504);
        final isValidation =
            status != null && (status == 400 || status == 422);
        final isAuth = status != null && (status == 401 || status == 403);

        if (isUnavailable) {
          message =
              'Server temporarily unavailable ($status). Please try again shortly.';
        }

        return ApiException(
          message: message,
          statusCode: status,
          isServerError: is5xx,
          isBackendUnavailable: isUnavailable,
          isValidationError: isValidation,
          isAuthError: isAuth,
        );
      case DioExceptionType.cancel:
        return const ApiException(message: 'Request was cancelled.');
      default:
        return ApiException(
          message: e.message ?? 'An unexpected network error occurred.',
          isNetworkError: true,
        );
    }
  }

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required FlutterSecureStorage storage}) : _storage = storage {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.backendBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    )
      ..interceptors.add(_authInterceptor())
      ..interceptors.add(_retryInterceptor())
      ..interceptors.add(LogInterceptor(
        request: AppEnv.isDevelopment,
        responseBody: AppEnv.isDevelopment,
        requestBody: AppEnv.isDevelopment,
        error: true,
      ));
  }

  final FlutterSecureStorage _storage;
  late final Dio _dio;

  Dio get rawDio => _dio;

  // ── Auth interceptor: attach JWT if available ─────────────────────────────
  Interceptor _authInterceptor() => InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            _storage.delete(key: 'jwt_token');
          }
          handler.next(error);
        },
      );

  // ── Retry interceptor for transient network & gateway failures ────────────
  Interceptor _retryInterceptor() => InterceptorsWrapper(
        onError: (error, handler) async {
          final requestOptions = error.requestOptions;
          // Only automatically retry idempotent GET requests or explicitly retryable requests
          final isGet = requestOptions.method.toUpperCase() == 'GET';
          final retryCount = (requestOptions.extra['retry_count'] as int?) ?? 0;
          const maxRetries = 2;

          final isTransient = error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              (error.response?.statusCode != null &&
                  [502, 503, 504].contains(error.response!.statusCode));

          if (isGet && isTransient && retryCount < maxRetries) {
            requestOptions.extra['retry_count'] = retryCount + 1;
            final delayMs = 300 * (retryCount + 1);
            await Future.delayed(Duration(milliseconds: delayMs));
            try {
              final response = await _dio.fetch(requestOptions);
              return handler.resolve(response);
            } on DioException catch (retryErr) {
              return handler.next(retryErr);
            }
          }
          return handler.next(error);
        },
      );

  // ── Token management ──────────────────────────────────────────────────────
  Future<void> saveToken(String token) =>
      _storage.write(key: 'jwt_token', value: token);

  Future<void> clearToken() => _storage.delete(key: 'jwt_token');

  Future<String?> getToken() => _storage.read(key: 'jwt_token');

  // ── Generic request helpers with ApiException wrapping ────────────────────
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw wrapDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw wrapDioError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw wrapDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(path, options: options);
    } on DioException catch (e) {
      throw wrapDioError(e);
    }
  }

  ApiException wrapDioError(DioException e) => ApiException.fromDio(e);
}

