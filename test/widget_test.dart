import 'package:flutter_test/flutter_test.dart';
import 'package:caredrop/main.dart';

void main() {
  testWidgets('CareDrop app initial launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CareDropApp());

    // Verify that CareDrop landing title and Get Started button exist.
    expect(find.text('CareDrop'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
