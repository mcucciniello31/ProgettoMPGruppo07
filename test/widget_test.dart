import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:say_my_travel/main.dart';
import 'package:say_my_travel/providers/travel_provider.dart';

void main() {
  testWidgets('Smoke test - Verify Say My Travel main screen loads', (
    WidgetTester tester,
  ) async {
    // Costruisce la nostra app e avvia un frame, avvolgendolo in MultiProvider.
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => TravelProvider())],
        child: const MyApp(),
      ),
    );

    // Verifica che il titolo "Say My Travel" sia presente sullo schermo.
    expect(find.text('Say My Travel'), findsOneWidget);
    expect(find.text('Organizza le tue prossime avventure!'), findsOneWidget);
  });
}
