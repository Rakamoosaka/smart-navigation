import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'demo_data.dart' as demo;
import 'models.dart';

class AppState {
  const AppState({
    this.user,
    this.selectedLocation,
    this.searchQuery = '',
    this.favorites = const {2, 4},
    this.accessibleRoutes = false,
    this.routeActive = false,
    this.busy = false,
    this.locations = const [],
    this.announcements = const [],
    this.apiConnected = false,
  });

  final AppUser? user;
  final CampusLocation? selectedLocation;
  final String searchQuery;
  final Set<int> favorites;
  final bool accessibleRoutes;
  final bool routeActive;
  final bool busy;
  final List<CampusLocation> locations;
  final List<CampusAnnouncement> announcements;
  final bool apiConnected;

  AppState copyWith({
    AppUser? user,
    bool clearUser = false,
    CampusLocation? selectedLocation,
    bool clearLocation = false,
    String? searchQuery,
    Set<int>? favorites,
    bool? accessibleRoutes,
    bool? routeActive,
    bool? busy,
    List<CampusLocation>? locations,
    List<CampusAnnouncement>? announcements,
    bool? apiConnected,
  }) => AppState(
    user: clearUser ? null : user ?? this.user,
    selectedLocation: clearLocation
        ? null
        : selectedLocation ?? this.selectedLocation,
    searchQuery: searchQuery ?? this.searchQuery,
    favorites: favorites ?? this.favorites,
    accessibleRoutes: accessibleRoutes ?? this.accessibleRoutes,
    routeActive: routeActive ?? this.routeActive,
    busy: busy ?? this.busy,
    locations: locations ?? this.locations,
    announcements: announcements ?? this.announcements,
    apiConnected: apiConnected ?? this.apiConnected,
  );
}

class AppController extends Notifier<AppState> {
  final ApiClient _api = ApiClient();

  @override
  AppState build() => const AppState(
    locations: demo.campusLocations,
    announcements: demo.announcements,
  );

  Future<bool> restoreSession() async {
    final result = await _api.restoreUser();
    if (result == null) return false;
    final role = _roleFromString(result['role']?.toString());
    final email = result['email']?.toString() ?? 'Guest session';
    final name =
        result['full_name']?.toString() ??
        result['name']?.toString() ??
        (role == UserRole.guest ? 'Campus Visitor' : _demoName(email));
    state = state.copyWith(
      user: AppUser(name: name, email: email, role: role),
    );
    await _syncRemote();
    return true;
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(busy: true);
    try {
      await _api.guest();
    } catch (_) {
      // The seeded map remains available when the classroom API is stopped.
    }
    state = state.copyWith(
      busy: false,
      user: const AppUser(
        name: 'Campus Visitor',
        email: 'Guest session',
        role: UserRole.guest,
      ),
    );
    await _syncRemote();
  }

  Future<String?> login(String email) async {
    final normalized = email.trim().toLowerCase();
    if (!RegExp(r'^\d{9}@sdu\.edu\.kz$').hasMatch(normalized)) {
      return 'Use a 9-digit SDU email, for example 240103049@sdu.edu.kz';
    }
    state = state.copyWith(busy: true);
    var role = UserRole.student;
    var name = _demoName(normalized);
    try {
      final result = await _api.login(normalized);
      role = _roleFromString(result['role']?.toString());
      name = result['name']?.toString() ?? name;
    } catch (_) {
      role = normalized.startsWith('240000002')
          ? UserRole.admin
          : normalized.startsWith('240000001')
          ? UserRole.teacher
          : UserRole.student;
    }
    state = state.copyWith(
      busy: false,
      user: AppUser(name: name, email: normalized, role: role),
    );
    await _syncRemote();
    return null;
  }

  Future<void> _syncRemote() async {
    try {
      final remoteLocations = (await _api.locations())
          .map(CampusLocation.fromJson)
          .toList();
      final remoteAnnouncements = (await _api.announcements())
          .map(CampusAnnouncement.fromJson)
          .toList();
      var remoteFavorites = state.favorites;
      var accessible = state.accessibleRoutes;
      if (state.user?.role != UserRole.guest) {
        remoteFavorites = (await _api.favorites())
            .map((item) => item['id'] as int)
            .toSet();
        accessible =
            (await _api.preference())['accessible_routes'] as bool? ?? false;
      }
      state = state.copyWith(
        locations: remoteLocations,
        announcements: remoteAnnouncements,
        favorites: remoteFavorites,
        accessibleRoutes: accessible,
        apiConnected: true,
      );
    } catch (_) {
      state = state.copyWith(apiConnected: false);
    }
  }

  void selectLocation(CampusLocation location) =>
      state = state.copyWith(selectedLocation: location, routeActive: false);
  void clearLocation() =>
      state = state.copyWith(clearLocation: true, routeActive: false);
  void search(String value) => state = state.copyWith(searchQuery: value);
  void startRoute(CampusLocation location) =>
      state = state.copyWith(selectedLocation: location, routeActive: true);
  void setAccessible(bool value) {
    state = state.copyWith(accessibleRoutes: value);
    if (state.user?.role != UserRole.guest) {
      unawaited(_api.updatePreference(value));
    }
  }

  void toggleFavorite(int id) {
    final next = {...state.favorites};
    final removing = next.contains(id);
    removing ? next.remove(id) : next.add(id);
    state = state.copyWith(favorites: next);
    if (state.user?.role != UserRole.guest) {
      unawaited(removing ? _api.removeFavorite(id) : _api.addFavorite(id));
    }
  }

  Future<void> logout() async {
    await _api.logout();
    state = const AppState(
      locations: demo.campusLocations,
      announcements: demo.announcements,
    );
  }

  Future<bool> submitReport(String message, int? locationId) async {
    try {
      await _api.submitReport(message, locationId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static UserRole _roleFromString(String? value) => switch (value) {
    'admin' => UserRole.admin,
    'teacher' => UserRole.teacher,
    'guest' => UserRole.guest,
    _ => UserRole.student,
  };

  static String _demoName(String email) =>
      const {
        '240103049@sdu.edu.kz': 'Yerassyl',
        '240103050@sdu.edu.kz': 'Daulet',
        '240103051@sdu.edu.kz': 'Omar',
        '240103052@sdu.edu.kz': 'Aitore',
        '240103053@sdu.edu.kz': 'Aidyn',
        '240000001@sdu.edu.kz': 'Dr. Ayan',
        '240000002@sdu.edu.kz': 'Campus Admin',
      }[email] ??
      'SDU Student';
}

final appProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);
