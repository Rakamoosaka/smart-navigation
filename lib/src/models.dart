import 'package:flutter/material.dart';

enum UserRole { guest, student, teacher, admin }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.guest => 'Guest',
    UserRole.student => 'Student',
    UserRole.teacher => 'Teacher',
    UserRole.admin => 'Administrator',
  };
}

class AppUser {
  const AppUser({required this.name, required this.email, required this.role});
  final String name;
  final String email;
  final UserRole role;
}

class CampusLocation {
  const CampusLocation({
    required this.id,
    required this.name,
    required this.category,
    required this.block,
    required this.floor,
    required this.x,
    required this.y,
    required this.icon,
    this.hours = '08:00–18:00',
    this.contact = '+7 727 307 95 65',
    this.accessible = true,
    this.aliases = const [],
  });

  final int id;
  final String name;
  final String category;
  final String block;
  final String floor;
  final double x;
  final double y;
  final IconData icon;
  final String hours;
  final String contact;
  final bool accessible;
  final List<String> aliases;

  factory CampusLocation.fromJson(Map<String, dynamic> json) {
    final category = json['category']?.toString() ?? 'Service';
    return CampusLocation(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Campus location',
      category: category,
      block: json['block']?.toString() ?? 'SDU Campus',
      floor: json['floor']?.toString() ?? 'Ground floor',
      x: (json['x'] as num?)?.toDouble() ?? .5,
      y: (json['y'] as num?)?.toDouble() ?? .5,
      icon: iconForCategory(category),
      hours: json['opening_hours']?.toString() ?? '08:00–18:00',
      contact: json['contact']?.toString() ?? '+7 727 307 95 65',
      accessible: json['accessible'] as bool? ?? true,
      aliases: (json['aliases']?.toString() ?? '')
          .split(',')
          .where((value) => value.trim().isNotEmpty)
          .map((value) => value.trim())
          .toList(),
    );
  }

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return [
      name,
      category,
      block,
      floor,
      ...aliases,
    ].any((value) => value.toLowerCase().contains(q));
  }
}

class CampusAnnouncement {
  const CampusAnnouncement(this.title, this.body, this.when, this.locationId);
  final String title;
  final String body;
  final String when;
  final int? locationId;

  factory CampusAnnouncement.fromJson(Map<String, dynamic> json) =>
      CampusAnnouncement(
        json['title']?.toString() ?? 'Campus update',
        json['body']?.toString() ?? '',
        _formatPublishedAt(json['published_at']?.toString()),
        json['location_id'] as int?,
      );
}

String _formatPublishedAt(String? raw) {
  if (raw == null) return 'Recently';
  final value = DateTime.tryParse(raw)?.toLocal();
  if (value == null) return 'Recently';
  final now = DateTime.now();
  if (value.year == now.year &&
      value.month == now.month &&
      value.day == now.day) {
    return 'Today · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
  return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}

IconData iconForCategory(String category) => switch (category.toLowerCase()) {
  'entrance' => Icons.login,
  'study' => Icons.local_library_outlined,
  'food' => Icons.restaurant_outlined,
  'classroom' => Icons.meeting_room_outlined,
  'office' => Icons.badge_outlined,
  'health' => Icons.medical_services_outlined,
  'printer' => Icons.print_outlined,
  'restroom' => Icons.accessible,
  'finance' => Icons.account_balance_outlined,
  'parking' => Icons.local_parking,
  _ => Icons.place_outlined,
};

class RouteStep {
  const RouteStep(this.instruction, this.minutes);
  final String instruction;
  final int minutes;
}
