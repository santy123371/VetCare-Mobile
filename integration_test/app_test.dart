import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vetcare_mobile/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://test.vetcare.local/api/v1\n',
    );
  });

  group('VetCare Mobile E2E Integration Suite', () {
    testWidgets('E2E: App boots, verifies brand layout, and renders login screen', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: VetCareApp()));
      await tester.pumpAndSettle();

      // Verificar elementos principales de identidad y marca
      expect(find.text('VetCare'), findsWidgets);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Ingresa tus credenciales para continuar'), findsOneWidget);

      // Verificar campos de formulario
      expect(find.widgetWithText(TextFormField, 'Correo electrónico'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Contraseña'), findsOneWidget);
      expect(find.text('Ingresar al Sistema'), findsOneWidget);
    });

    testWidgets('E2E: Form validation asserts required fields and email format', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: VetCareApp()));
      await tester.pumpAndSettle();

      // Intento de envío vacío
      final submitBtn = find.text('Ingresar al Sistema');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verificar mensajes de validación
      expect(find.text('Ingresa tu correo electrónico'), findsOneWidget);

      // Ingresar email sin formato válido
      final emailField = find.widgetWithText(TextFormField, 'Correo electrónico');
      await tester.enterText(emailField, 'usuarioinvalido');
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Correo no válido'), findsOneWidget);
    });

    testWidgets('E2E: Credential input, password mask toggle, and interaction flow', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: VetCareApp()));
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'Correo electrónico');
      final passField = find.widgetWithText(TextFormField, 'Contraseña');

      // Diligenciar credenciales válidas
      await tester.enterText(emailField, 'veterinario@vetcare.com');
      await tester.enterText(passField, 'VetCare2026*');
      await tester.pumpAndSettle();

      expect(find.text('veterinario@vetcare.com'), findsOneWidget);

      // Probar toggle de visibilidad de contraseña
      final toggleIcon = find.byIcon(Icons.visibility_outlined);
      if (toggleIcon.evaluate().isNotEmpty) {
        await tester.tap(toggleIcon);
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      }

      // Verificar que el botón de envío permanezca disponible
      final submitBtn = find.text('Ingresar al Sistema');
      expect(submitBtn, findsOneWidget);
    });
  });
}
