import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'dart:convert';

import 'src/app.dart';
import 'src/demo_data.dart' as campus;
import 'src/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data =
      jsonDecode(await rootBundle.loadString('assets/maps/campus.json')) as Map;
  campus.campusLocations = (data['places'] as List)
      .map(
        (item) =>
            CampusLocation.fromJson(Map<String, dynamic>.from(item as Map)),
      )
      .toList();
  campus.campusCatalog = {
    for (final item in data['places'] as List)
      item['id'] as int: Map<String, dynamic>.from(item as Map),
  };
  campus.campusMapLabels = (data['labels'] as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  campus.campusRouting = Map<String, dynamic>.from(data['routing'] as Map);
  runApp(const ProviderScope(child: SduCampusApp()));
}
