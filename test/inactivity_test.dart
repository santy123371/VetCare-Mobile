import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vetcare_mobile/core/auth/auth_provider.dart';
import 'package:vetcare_mobile/core/auth/inactivity_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('InactivityDetector triggers expireSessionDueToInactivity after timeout duration', (tester) async {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => MockAuthNotifier()),
      ],
    );

    // Initial state: authenticated
    expect(container.read(authProvider).isAuthenticated, isTrue);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: InactivityDetector(
            timeoutDuration: Duration(seconds: 2),
            child: Scaffold(body: Text('Active Dashboard')),
          ),
        ),
      ),
    );

    expect(find.text('Active Dashboard'), findsOneWidget);

    // Advance 1 second -> should still be authenticated
    await tester.pump(const Duration(seconds: 1));
    expect(container.read(authProvider).isAuthenticated, isTrue);

    // Advance past timeout (2 seconds total)
    await tester.pump(const Duration(seconds: 2));
    expect(container.read(authProvider).isAuthenticated, isFalse);
    expect(container.read(authProvider).error, contains('inactividad'));
  });
}

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier()
      : super(const AuthState(isAuthenticated: true, role: 'CLIENTE', userId: '1'));

  @override
  Future<void> expireSessionDueToInactivity() async {
    state = const AuthState(
      isAuthenticated: false,
      error: 'Tu sesión ha expirado por 5 minutos de inactividad.',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
