import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile_relay/main.dart';
import 'package:mobile_relay/providers/app_provider.dart';

void main() {
  testWidgets('Splash screen renders app name', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MobileRelayApp(),
      ),
    );

    expect(find.text('MobileRelay'), findsOneWidget);
  });
}
