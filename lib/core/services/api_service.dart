import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Exceptions ────────────────────────────────────────────────────────────────

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Tidak ada koneksi internet.']);
  @override
  String toString() => 'NetworkException: $message';
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException(this.message, {this.statusCode});
  @override
  String toString() => 'ServerException($statusCode): $message';
}

class UnauthorizedException implements Exception {
  const UnauthorizedException();
  @override
  String toString() => 'UnauthorizedException';
}

// ── Constants ─────────────────────────────────────────────────────────────────

const _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://digitalpmo-production.up.railway.app',
);
const _tokenKey = 'access_token';
const _maxRetries = 3;

String normalizePhoneNumber(String phone) {
  var cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (cleaned.startsWith('62') && cleaned.length > 10) {
    cleaned = '0${cleaned.substring(2)}';
  }
  return cleaned;
}

// ── Dio client factory ────────────────────────────────────────────────────────

Dio _buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(_AuthInterceptor());
  dio.interceptors.add(_RetryInterceptor(dio));
  return dio;
}

class _AuthInterceptor extends Interceptor {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _RetryInterceptor extends Interceptor {
  final Dio dio;
  _RetryInterceptor(this.dio);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra['_attempt'] as int? ?? 0;
    final isTimeout =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;

    if (isTimeout && attempt < _maxRetries) {
      await Future<void>.delayed(Duration(seconds: attempt + 1));
      final opts = err.requestOptions..extra['_attempt'] = attempt + 1;
      try {
        final response = await dio.fetch<dynamic>(opts);
        handler.resolve(response);
        return;
      } catch (e) {
        // fall through to next handler
      }
    }
    handler.next(err);
  }
}

// ── Typed error mapper ────────────────────────────────────────────────────────

String? _extractErrorDetail(dynamic data) {
  if (data == null) return null;
  if (data is String && data.trim().isNotEmpty) return data;
  if (data is Map<String, dynamic>) {
    final detail = data['detail'] ?? data['message'] ?? data['error'];
    return _extractErrorDetail(detail);
  }
  if (data is List) {
    final messages = data
        .map((item) {
          if (item is Map<String, dynamic>) {
            final msg = item['msg'] ?? item['message'] ?? item['detail'];
            final loc = item['loc'];
            if (msg == null) return null;
            if (loc is List && loc.isNotEmpty) {
              return '${loc.join('.')}: $msg';
            }
            return msg.toString();
          }
          return item?.toString();
        })
        .whereType<String>()
        .where((message) => message.trim().isNotEmpty)
        .toList();
    if (messages.isNotEmpty) return messages.join('\n');
  }
  final fallback = data.toString();
  return fallback.trim().isEmpty ? null : fallback;
}

Never _mapDioError(DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.error is SocketException) {
    throw const NetworkException();
  }
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    throw const NetworkException('Koneksi timeout. Coba lagi.');
  }
  final status = e.response?.statusCode;
  if (status == 401) throw const UnauthorizedException();
  final detail =
      _extractErrorDetail(e.response?.data) ?? 'Server tidak mengirim detail.';
  throw ServerException(detail, statusCode: status);
}

// ── User-facing error messages (Bahasa Indonesia) ─────────────────────────────

String apiErrorMessage(Object error) {
  if (error is NetworkException) {
    return error.message.contains('timeout')
        ? 'Koneksi lambat, coba lagi'
        : 'Tidak ada internet';
  }
  if (error is UnauthorizedException) return 'Sesi habis, silakan login ulang';
  if (error is ServerException) {
    if (error.statusCode == 500) {
      return error.message.isNotEmpty
          ? 'Server sedang bermasalah: ${error.message}'
          : 'Server sedang bermasalah';
    }
    return error.message.isNotEmpty
        ? error.message
        : 'Terjadi kesalahan server';
  }
  return 'Terjadi kesalahan, coba lagi';
}

// ── ApiService ────────────────────────────────────────────────────────────────

class ApiService {
  ApiService._() : _dio = _buildDio();
  static final ApiService instance = ApiService._();

  final Dio _dio;
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String password,
    String role = 'patient',
  }) async {
    try {
      // Clear any stale tokens before registering a new account.
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: 'refresh_token');

      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/register',
        data: {
          'name': name,
          'phone': normalizePhoneNumber(phone),
          'password': password,
          'role': role,
        },
      );
      final data = res.data!;
      // When OTP is skipped the backend returns tokens immediately — save them
      // so subsequent API calls (e.g. setup-profile) are authenticated.
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      if (data['skip_otp'] == true &&
          accessToken != null &&
          refreshToken != null) {
        await _storage.write(key: _tokenKey, value: accessToken as String);
        await _storage.write(key: 'refresh_token', value: refreshToken as String);
        // Verify write succeeded.
        final saved = await _storage.read(key: _tokenKey);
        assert(saved != null, 'Token write failed after register');
      }
      return data;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String phone,
    required String otp,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/verify-otp',
        data: {'phone': normalizePhoneNumber(phone), 'otp': otp},
      );
      final data = res.data!;
      await _storage.write(
        key: _tokenKey,
        value: data['access_token'] as String,
      );
      await _storage.write(
        key: 'refresh_token',
        value: data['refresh_token'] as String,
      );
      return data;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> setupPatientProfile({
    required String dateOfBirth,
    required String gender,
    required String faksesName,
    required String doctorName,
    required String tbCategory, // "SO" atau "RO"
    required String treatmentStartDate,
    String? tbSoType,
    String? tbRoType,
    int? treatmentDurationDays,
    String? medicationType, // "FDC" atau "Kombinasi"
    String? fdcType, // "FDC" atau "Kombipak"
    List<String>? customMedications,
    double? weightKg,
    String? address,
    bool? isPregnant,
  }) async {
    try {
      final body = <String, dynamic>{
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'faskes_name': faksesName,
        'doctor_name': doctorName,
        'tb_category': tbCategory,
        'treatment_start_date': treatmentStartDate,
      };
      if (tbSoType != null) body['tb_so_type'] = tbSoType;
      if (tbRoType != null) body['tb_ro_type'] = tbRoType;
      if (treatmentDurationDays != null) {
        body['treatment_duration_days'] = treatmentDurationDays;
      }
      if (medicationType != null) body['medication_type'] = medicationType;
      if (fdcType != null) body['fdc_type'] = fdcType;
      if (customMedications != null) {
        body['custom_medications'] = customMedications;
      }
      if (weightKg != null) body['weight_kg'] = weightKg;
      if (address != null) body['address'] = address;
      if (isPregnant != null) body['is_pregnant'] = isPregnant;
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/patients/setup-profile',
        data: body,
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<bool> hasValidToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
    String? fcmToken,
  }) async {
    try {
      final body = <String, dynamic>{
        'phone': normalizePhoneNumber(phone),
        'password': password,
      };
      if (fcmToken != null) body['fcm_token'] = fcmToken;
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: body,
      );
      final data = res.data!;
      await _storage.write(
        key: _tokenKey,
        value: data['access_token'] as String,
      );
      await _storage.write(
        key: 'refresh_token',
        value: data['refresh_token'] as String,
      );
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final detail =
            _extractErrorDetail(e.response?.data) ??
            'Nomor HP atau password salah.';
        throw ServerException(detail, statusCode: 401);
      }
      if (e.response?.statusCode == 429) {
        throw const ServerException(
          'Terlalu banyak percobaan login. Tunggu sekitar 1 menit lalu coba lagi.',
          statusCode: 429,
        );
      }
      _mapDioError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/api/v1/auth/logout');
    } catch (_) {
      // best effort
    } finally {
      await _storage.deleteAll();
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  // ── Patient / Profile ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyProfile() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/api/v1/patients/me');
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  // ── Medications ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getTodayMedication() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/medications/today',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> confirmMedication({
    required String scheduleId,
    required String photoBase64,
    String? deviceId,
    DateTime? photoTakenAt,
  }) async {
    try {
      final body = <String, dynamic>{
        'schedule_id': scheduleId,
        'photo_base64': photoBase64,
      };
      if (deviceId != null) body['device_id'] = deviceId;
      if (photoTakenAt != null) {
        body['photo_taken_at'] = photoTakenAt.toIso8601String();
      }
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/medications/confirm',
        data: body,
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMedicationHistory(String month) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/medications/history',
        queryParameters: {'month': month},
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  // ── Symptoms ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logSymptom(Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/symptoms/log',
        data: payload,
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> getTodaySymptom() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/symptoms/today',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> logSideEffect(
    Map<String, dynamic> payload,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/side-effects/log',
        data: payload,
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  // ── AI ────────────────────────────────────────────────────────────────────

  /// Streams AI chat response chunks via server-sent text.
  Stream<String> chatStream(
    String message,
    List<Map<String, dynamic>> history,
    Map<String, dynamic> patientContext,
  ) async* {
    final response = await _dio.post<ResponseBody>(
      '/api/v1/ai/chat',
      data: {
        'message': message,
        'conversation_history': history,
        'patient_context': patientContext,
      },
      options: Options(responseType: ResponseType.stream),
    );
    await for (final chunk in response.data!.stream) {
      yield String.fromCharCodes(chunk);
    }
  }

  Future<Map<String, dynamic>> analyzeRisk() async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/ai/analyze-risk',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/ai/monthly-summary/$year/$month',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<void> registerFcmToken(String token) async {
    try {
      await _dio.post<void>(
        '/api/v1/notifications/register-token',
        data: {'fcm_token': token},
      );
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<List<dynamic>> getNotificationHistory({
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    try {
      final params = <String, dynamic>{'page': page, 'limit': limit};
      if (type != null) params['type'] = type;
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/notifications/history',
        queryParameters: params,
      );
      return res.data as List<dynamic>? ?? [];
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  // ── User / Profile ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? email,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (email != null) body['email'] = email;
      final res = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/auth/me',
        data: body,
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> updatePatientProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/api/v1/patients/me',
        data: data,
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateHospitalized(bool isHospitalized) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/api/v1/patients/me/hospitalized',
        data: {'is_hospitalized': isHospitalized},
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post<void>(
        '/api/v1/auth/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  // ── Support ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> submitSupportTicket({
    required String category,
    required String subject,
    required String message,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/support/contact',
        data: {'category': category, 'subject': subject, 'message': message},
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  // ── Reports ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMonthlyReport(int year, int month) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/reports/monthly/$year/$month',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> generatePdf(int year, int month) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/reports/generate-pdf/$year/$month',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  // ── PMO ───────────────────────────────────────────────────────────────────

  /// Dashboard PMO: daftar pasien yang diawasi + ringkasan status harian.
  Future<Map<String, dynamic>> getPMODashboard() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/pmo/dashboard',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  /// Detail seorang pasien yang diawasi PMO.
  Future<Map<String, dynamic>> getPMOPatientDetail(String patientId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/pmo/patients/$patientId',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  /// Generate QR token untuk di-scan pasien (berlaku 24 jam).
  Future<Map<String, dynamic>> generatePMOQR() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/pmo/generate-qr',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  /// PMO meminta link ke pasien via nomor HP.
  Future<Map<String, dynamic>> requestPMOLink(String patientPhone) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/pmo/link/request',
        data: {'patient_phone': normalizePhoneNumber(patientPhone)},
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  /// Pasien menyetujui permintaan link dari PMO.
  Future<Map<String, dynamic>> approvePMOLink(String linkRequestId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/pmo/link/approve/$linkRequestId',
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  /// Pasien terhubung ke PMO via scan QR.
  Future<Map<String, dynamic>> linkPMOViaQR(String qrToken) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/pmo/link/qr',
        data: {'qr_token': qrToken},
      );
      return res.data!;
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }

  /// Putus hubungan PMO-pasien.
  Future<void> unlinkPMOPatient(String patientId) async {
    try {
      await _dio.delete<void>('/api/v1/pmo/unlink/$patientId');
    } on DioException catch (e) {
      _mapDioError(e);
    }
  }
}
