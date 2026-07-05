import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_fee_manager/main.dart';

void main() {
  testWidgets('App renders splash screen without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolFeeManagerApp(),
      ),
    );
    // Verify the app renders without throwing.
    expect(find.byType(SchoolFeeManagerApp), findsOneWidget);
  });
}
