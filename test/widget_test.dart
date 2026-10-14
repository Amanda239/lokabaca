
import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';

void main() {
  testWidgets('LokaBaca menampilkan splash screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LokaBacaApp());

    expect(find.byType(LokaBacaApp), findsOneWidget);
  });
}
