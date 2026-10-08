import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdu_campus_assistant/src/app_state.dart';
import 'package:sdu_campus_assistant/src/demo_data.dart' as catalog;
import 'package:sdu_campus_assistant/src/models.dart';
import 'package:sdu_campus_assistant/src/screens/map_screen.dart';

class MapController extends AppController {
  MapController(this.places, this.role, {this.initialFavorites = const {}});
  final List<CampusLocation> places;
  final UserRole role;
  final Set<int> initialFavorites;
  @override
  AppState build() => AppState(
    locations: places,
    favorites: initialFavorites,
    user: AppUser(name: 'Test', email: '240103049', role: role),
  );
}

void main() {
  test('map background inherits the app theme', () {
    final svg = File('assets/maps/floor-1-background.svg').readAsStringSync();
    expect(svg.contains('<rect width="765" height="1280" fill="white"'), false);
  });
  final data =
      jsonDecode(File('assets/maps/campus.json').readAsStringSync()) as Map;
  final places = (data['places'] as List)
      .map((p) => CampusLocation.fromJson(Map<String, dynamic>.from(p as Map)))
      .toList();
  setUp(
    () => catalog.campusRouting = Map<String, dynamic>.from(
      data['routing'] as Map,
    ),
  );
  test(
    'sixth favorite is rejected locally without changing saved places',
    () async {
      final saved = places.take(5).map((p) => p.id).toSet();
      final container = ProviderContainer(
        overrides: [
          appProvider.overrideWith(
            () => MapController(
              places,
              UserRole.student,
              initialFavorites: saved,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final error = await container
          .read(appProvider.notifier)
          .toggleFavorite(places[5].id);
      expect(error, contains('up to 5'));
      expect(container.read(appProvider).favorites, saved);
    },
  );
  test(
    'catalogues agree, floor constraints and unknown positions are preserved',
    () {
      expect(
        File('backend/app/data/campus.json').readAsStringSync(),
        File('assets/maps/campus.json').readAsStringSync(),
      );
      expect(places.length, 53);
      for (final block in ['d', 'f', 'h']) {
        final lift = places.singleWhere((p) => p.mapKey == 'lift_block_$block');
        expect(lift.category, 'Lift');
        expect(lift.hasPosition, true);
        expect(lift.mapFloor, 1);
        expect(lift.floors, [-1, 1, 2, 3]);
      }
      final stair = places.singleWhere((p) => p.mapKey == 'stair_main_06');
      expect(stair.floors, [1, 3]);
      expect(stair.skipsFloors, [2]);
      expect(
        places.singleWhere((p) => p.mapKey == 'library_lift').hasPosition,
        false,
      );
      final rooms = [
        'D101',
        'D102',
        'D103',
        'D104',
      ].map((name) => places.singleWhere((p) => p.name == name)).toList();
      expect(rooms.every((p) => p.roomBounds != null), true);
      expect(
        rooms.first.roomBounds!.left,
        greaterThan(rooms.last.roomBounds!.left),
      );
    },
  );

  for (final role in [UserRole.student, UserRole.guest]) {
    testWidgets('search opens real D101 details for ${role.name}', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appProvider.overrideWith(() => MapController(places, role)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CampusMapScreen(
                onOpenAssistant: () {},
                locationToOpen: null,
                onLocationOpened: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'D101');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'D101'));
      await tester.pumpAndSettle();
      expect(find.text('Schematic routing available'), findsOneWidget);
      expect(
        find.byTooltip('Save place'),
        role == UserRole.guest ? findsNothing : findsOneWidget,
      );
      await tester.tap(find.text('Plan draft route'));
      await tester.pumpAndSettle();
      expect(find.text('Plan a draft route'), findsOneWidget);
      expect(find.text('Avoid stairs'), findsNothing);
      expect(find.byType(SwitchListTile), findsNothing);
      expect(find.text('Show draft route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
