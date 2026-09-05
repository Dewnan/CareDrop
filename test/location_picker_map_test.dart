import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:caredrop/components/location_picker_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'GEOAPIFY_API_KEY=test_key');
  });

  testWidgets('LocationPickerMap builds and renders My Location button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LocationPickerMap(
          title: 'Select Location',
          initialLocation: LatLng(6.9271, 79.8612),
        ),
      ),
    );

    expect(find.text('Select Location'), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.text('Confirm Location'), findsOneWidget);
  });
}
