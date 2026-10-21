import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:srimca_ai/campus_map_bubble.dart';

void main() {
  testWidgets('CampusMapBubble renders interactive map and OSM attribution when coordinates are valid',
      (WidgetTester tester) async {
    final locationData = {
      'name': 'Library',
      'latitude': 21.06785,
      'longitude': 73.13145,
      'description': 'SRIMCA Central Library with textbooks and reading room.',
      'building': 'SRIMCA Main Academic Building',
      'floor': 'Ground Floor',
      'room': 'L-101',
      'coordinates_verified': true,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusMapBubble(location: locationData),
        ),
      ),
    );

    // Verify location title and building info
    expect(find.text('Library'), findsWidgets);
    expect(find.text('SRIMCA Main Academic Building • Ground Floor • L-101'), findsOneWidget);

    // Verify FlutterMap is rendered
    expect(find.byType(FlutterMap), findsOneWidget);

    // Verify OpenStreetMap attribution is visible
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

    // Verify zoom buttons are present
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
  });

  testWidgets('CampusMapBubble shows pending notice when coordinates are unverified or zero',
      (WidgetTester tester) async {
    final locationData = {
      'name': 'Research Innovation Cell',
      'latitude': 0.0,
      'longitude': 0.0,
      'description': 'Research lab',
      'coordinates_verified': false,
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusMapBubble(location: locationData),
        ),
      ),
    );

    // Verify FlutterMap is NOT rendered for missing coordinates
    expect(find.byType(FlutterMap), findsNothing);

    // Verify informational warning is displayed
    expect(
      find.textContaining('pending official field survey'),
      findsOneWidget,
    );
  });
}
