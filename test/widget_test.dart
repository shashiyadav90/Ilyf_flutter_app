
import 'package:flutter_test/flutter_test.dart';
import 'package:ilyf_connect_flutter/app.dart';

void main() {
  testWidgets('ILYF Connect app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const IlyfConnectApp());

    expect(find.text('ILYF Connect'), findsOneWidget);
  });
}
