import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:say_my_travel/main.dart';
import 'package:say_my_travel/providers/travel_provider.dart';

void main() {
  testWidgets('Smoke test - Verify Say My Travel main screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame, wrapping in MultiProvider.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TravelProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the title "Say My Travel" is found on screen.
    expect(find.text('Say My Travel'), findsOneWidget);
    expect(find.text('Organizza le tue prossime avventure!'), findsOneWidget);
  });
}
