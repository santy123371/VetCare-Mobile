import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../api/api_client.dart';
import '../storage/secure_storage.dart';

class AuthState {
  final bool isLoading;
  final String? role;
  final String? userId;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.role,
    this.userId,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? role,
    String? userId,
    String? error,
    bool? isAuthenticated,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        role: role ?? this.role,
        userId: userId ?? this.userId,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._dio, this._storage) : super(const AuthState()) {
    _init();
  }

  final Dio _dio;
  final SecureStorage _storage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> _init() async {
    // La sesión se cierra al cerrar la app (similar a la web al cerrar el navegador).
    // Borramos cualquier token de acceso activo anterior para exigir autenticación fresca.
    await _storage.deleteAccessToken();
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> login(String email, String password, {bool enableBiometrics = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data['data'] ?? res.data;
      await _storage.saveTokens(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
      );
      final user = data['user'] as Map<String, dynamic>;
      final role = (user['nombre_rol'] ?? user['rol'] ?? 'CLIENTE').toString();
      final userId = (user['id'] ?? '').toString();
      await _storage.saveUserMeta(role: role, userId: userId);

      await _storage.setBiometricsEnabled(enableBiometrics);
      if (enableBiometrics) {
        await _storage.saveEmail(email);
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: role,
        userId: userId,
      );
      return true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message']?.toString() ??
            'No fue posible iniciar sesión. Verifica tu correo y contraseña.',
      );
      return false;
    }
  }

  Future<bool> loginWithBiometrics() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final canBio = await canCheckBiometrics();
      if (!canBio) {
        state = state.copyWith(
          isLoading: false,
          error: 'Tu dispositivo no cuenta con biometría configurada.',
        );
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Escanea tu huella digital para ingresar a VetCare',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Inicia sesión primero con tu contraseña para habilitar la huella.',
        );
        return false;
      }

      // Renovar tokens con el refresh token almacenado identificando origen biométrico
      final res = await _dio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
        options: Options(headers: {
          'X-Auth-Method': 'biometric',
        }),
      );
      final data = res.data['data'] ?? res.data;
      final accessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String;
      await _storage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );

      // 1. Obtener rol y userId desde la respuesta del servidor
      final user = data['user'] as Map<String, dynamic>?;
      String? role;
      String? userId;
      if (user != null) {
        role = (user['nombre_rol'] ?? user['rol'])?.toString();
        userId = (user['id'])?.toString();
      }

      // 2. Si no vino en el payload del refresh, leer del almacenamiento seguro preservado
      if (role == null || role.isEmpty) {
        role = await _storage.getUserRole();
      }
      if (userId == null || userId.isEmpty) {
        userId = await _storage.getUserId();
      }

      // 3. Fallback infalible: decodificar claims del access_token JWT
      if (role == null || role.isEmpty || userId == null || userId.isEmpty) {
        final claims = _decodeJwt(accessToken);
        if (claims != null) {
          role ??= claims['role']?.toString();
          userId ??= claims['sub']?.toString();
        }
      }

      // Guardar metadatos normalizados en almacenamiento seguro
      if (role != null && userId != null) {
        await _storage.saveUserMeta(role: role, userId: userId);
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        role: role ?? 'CLIENTE',
        userId: userId,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo autenticar con huella. Ingresa con tu contraseña.',
      );
      return false;
    }
  }

  Map<String, dynamic>? _decodeJwt(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> expireSessionDueToInactivity() async {
    try {
      await _dio.post(
        '/auth/logout',
        options: Options(headers: {
          'X-Logout-Reason': 'inactivity',
        }),
      );
    } catch (_) {}
    await _storage.deleteAccessToken();
    state = const AuthState(
      isAuthenticated: false,
      error: 'Tu sesión ha expirado por 5 minutos de inactividad.',
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    final isBio = await _storage.isBiometricsEnabled();
    if (isBio) {
      await _storage.deleteAccessToken();
      await _storage.clear(keepBiometrics: true);
    } else {
      await _storage.clear(keepBiometrics: false);
    }
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(dioProvider), ref.watch(secureStorageProvider));
});
