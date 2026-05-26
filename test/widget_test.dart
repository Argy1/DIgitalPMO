import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:digitalpmo/main.dart';
import 'package:digitalpmo/core/utils/connectivity_manager.dart';

void main() {
  testWidgets('App initializes without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStreamProvider.overrideWith(
            (ref) => Stream.value([ConnectivityResult.wifi]),
          ),
        ],
        child: const DigitalPMOApp(),
      ),
    );

    // Just verify the app initializes and the router is set up
    expect(find.byType(DigitalPMOApp), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
