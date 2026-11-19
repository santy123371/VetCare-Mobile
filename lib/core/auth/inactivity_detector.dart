import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';

/// Detector global de inactividad que cierra la sesión tras 5 minutos sin interacción
/// o tras 5 minutos con la aplicación en segundo plano.
class InactivityDetector extends ConsumerStatefulWidget {
  final Widget child;
  final Duration timeoutDuration;

  const InactivityDetector({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(minutes: 5),
  });

  @override
  ConsumerState<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends ConsumerState<InactivityDetector>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    FocusManager.instance.addListener(_onFocusChange);
    _resetTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    FocusManager.instance.removeListener(_onFocusChange);
    _timer?.cancel();
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    _resetTimer();
    return false;
  }

  void _onFocusChange() {
    _resetTimer();
  }

  void _resetTimer([Duration? duration]) {
    _timer?.cancel();
    final isAuth = ref.read(authProvider).isAuthenticated;
    if (!isAuth) return;

    _timer = Timer(duration ?? widget.timeoutDuration, _onTimeout);
  }

  void _onTimeout() {
    _timer?.cancel();
    final isAuth = ref.read(authProvider).isAuthenticated;
    if (isAuth) {
      ref.read(authProvider.notifier).expireSessionDueToInactivity();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pausedAt = DateTime.now();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final elapsed = DateTime.now().difference(_pausedAt!);
        if (elapsed >= widget.timeoutDuration) {
          _onTimeout();
        } else {
          final remaining = widget.timeoutDuration - elapsed;
          _resetTimer(remaining);
        }
        _pausedAt = null;
      } else {
        _resetTimer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated != true && next.isAuthenticated) {
        _resetTimer();
      } else if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        _timer?.cancel();
      }
    });

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
