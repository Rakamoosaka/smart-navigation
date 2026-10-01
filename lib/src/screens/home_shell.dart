import 'package:flutter/material.dart';

import '../models.dart';
import 'assistant_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'updates_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  CampusLocation? _locationToOpen;

  void _openLocation(CampusLocation location) {
    setState(() {
      _locationToOpen = location;
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _index,
      children: [
        CampusMapScreen(
          onOpenAssistant: () => setState(() => _index = 1),
          locationToOpen: _locationToOpen,
          onLocationOpened: () => setState(() => _locationToOpen = null),
        ),
        CampusAssistantScreen(onShowMap: () => setState(() => _index = 0)),
        UpdatesScreen(onShowMap: () => setState(() => _index = 0)),
        ProfileScreen(onOpenLocation: _openLocation),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Map',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(Icons.auto_awesome),
          label: 'Assistant',
        ),
        NavigationDestination(
          icon: Icon(Icons.campaign_outlined),
          selectedIcon: Icon(Icons.campaign),
          label: 'Updates',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}
