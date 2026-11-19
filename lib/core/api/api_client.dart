import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final baseUrl = (dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null) ??
      const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2/veterinaria_php/api/v1');

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Accept': 'application/json',
      'X-Client': 'movil',
      'X-Source': 'movil',
      'User-Agent': 'VetCare-Mobile/1.0.0 (Android; Flutter)',
    },
  ));

  // SSL Certificate Pinning configurable para producción
  final pinSha256 = (dotenv.isInitialized ? dotenv.env['SSL_PIN_SHA256'] : null)
      ?.trim()
      .toLowerCase()
      .replaceAll(':', '');
  if (pinSha256 != null && pinSha256.isNotEmpty) {
    (dio.httpClientAdapter as IOHttpClientAdapter).validateCertificate =
        (X509Certificate? cert, String host, int port) {
      if (cert == null) return false;
      final digest = sha256.convert(cert.der).toString().toLowerCase();
      return digest == pinSha256;
    };
  }

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refreshToken = await storage.getRefreshToken();
        if (refreshToken != null) {
          try {
            final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
            final res = await refreshDio.post('/auth/refresh', data: {
              'refresh_token': refreshToken,
            });
            final data = res.data['data'] ?? res.data;
            final newAccess = data['access_token'] as String;
            final newRefresh = data['refresh_token'] as String;
            await storage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);

            // Reintentar request original
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            final retry = await dio.fetch(opts);
            handler.resolve(retry);
            return;
          } catch (_) {
            await storage.clear();
          }
        }
      }
      handler.next(error);
    },
  ));

  return dio;
});