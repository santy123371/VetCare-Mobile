import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vetcare_mobile/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_BASE_URL=https://test.example.com/api/v1\n',
    );
  });

  testWidgets('VetCareApp pumps and displays LoginScreen without crashing', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VetCareApp()));
    await tester.pumpAndSettle();
    expect(find.text('VetCare'), findsWidgets);
    expect(find.text('Ingresar al Sistema'), findsOneWidget);
  });
}
