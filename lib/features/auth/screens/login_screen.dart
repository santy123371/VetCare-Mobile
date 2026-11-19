import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _canUseBiometrics = false;
  bool _enableBiometrics = false;
  bool _hasSavedSession = false;
  bool _hasAutoPromptedBiometrics = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  Future<void> _checkBiometrics() async {
    final storage = ref.read(secureStorageProvider);
    final canBio = await ref.read(authProvider.notifier).canCheckBiometrics();
    final isBioEnabled = await storage.isBiometricsEnabled();
    final savedEmail = await storage.getSavedEmail();
    final refreshToken = await storage.getRefreshToken();

    if (savedEmail != null && savedEmail.isNotEmpty && _email.text.isEmpty) {
      _email.text = savedEmail;
    }

    final hasSession = isBioEnabled && refreshToken != null && refreshToken.isNotEmpty;

    if (mounted) {
      setState(() {
        _canUseBiometrics = canBio;
        _enableBiometrics = isBioEnabled;
        _hasSavedSession = hasSession;
      });

      // Si tiene huella configurada, abrir automáticamente el sensor biométrico
      if (!_hasAutoPromptedBiometrics && canBio && hasSession) {
        _hasAutoPromptedBiometrics = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !ref.read(authProvider).isAuthenticated) {
            _submitBiometrics();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final ok = await ref.read(authProvider.notifier).login(
          _email.text.trim(),
          _password.text,
          enableBiometrics: _enableBiometrics,
        );
    if (ok && mounted) context.go('/dashboard');
  }

  Future<void> _submitBiometrics() async {
    final ok = await ref.read(authProvider.notifier).loginWithBiometrics();
    if (ok && mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background subtle gradient glow
          Positioned(
            top: -80,
            left: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: isDark ? 0.25 : 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.secondary.withValues(alpha: isDark ? 0.2 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Logo & Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primary, Color(0xFF6366F1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.pets_rounded, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'VetCare',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Cuidado y bienestar integral para mascotas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Card Container for Form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ingresa tus credenciales para continuar',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Email
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Ingresa tu correo electrónico';
                                if (!v.contains('@')) return 'Correo no válido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextFormField(
                              controller: _password,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                                if (v.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),

                            // Biometrics Checkbox / Switch
                            if (_canUseBiometrics) ...[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () => setState(() => _enableBiometrics = !_enableBiometrics),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _enableBiometrics,
                                          activeColor: AppTheme.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                          onChanged: (val) => setState(() => _enableBiometrics = val ?? false),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.fingerprint_rounded, size: 20, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Ingresar con huella digital la próxima vez',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Error Card
                            if (auth.error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.rose.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.rose.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppTheme.rose, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        auth.error!,
                                        style: const TextStyle(
                                          color: AppTheme.rose,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Submit Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primary, Color(0xFF6366F1)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: FilledButton(
                                onPressed: auth.isLoading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text('Ingresar al Sistema'),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded, size: 18),
                                        ],
                                      ),
                              ),
                            ),

                            // Biometric Shortcut Button (si ya hay sesión guardada)
                            if (_hasSavedSession) ...[
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: auth.isLoading ? null : _submitBiometrics,
                                  icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.primary, size: 22),
                                  label: const Text('Ingresar con Huella'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
