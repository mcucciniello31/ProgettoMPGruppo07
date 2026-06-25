import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zefiro/main.dart';
import 'package:zefiro/providers/travel_provider.dart';

void main() {
  testWidgets('Smoke test - Verify Zefiro main screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame, wrapping in MultiProvider.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TravelProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the title "Zefiro" is found on screen.
    expect(find.text('Zefiro'), findsOneWidget);
    expect(find.text('Organizza le tue prossime avventure!'), findsOneWidget);
  });
}
