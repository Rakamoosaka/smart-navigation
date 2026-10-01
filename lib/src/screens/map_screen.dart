import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../demo_data.dart';
import '../models.dart';
import '../theme.dart';

class CampusMapScreen extends ConsumerStatefulWidget {
  const CampusMapScreen({
    super.key,
    required this.onOpenAssistant,
    required this.locationToOpen,
    required this.onLocationOpened,
  });
  final VoidCallback onOpenAssistant;
  final CampusLocation? locationToOpen;
  final VoidCallback onLocationOpened;

  @override
  ConsumerState<CampusMapScreen> createState() => _CampusMapScreenState();
}

class _CampusMapScreenState extends ConsumerState<CampusMapScreen> {
  String _category = 'All';
  final _search = TextEditingController();

  @override
  void didUpdateWidget(covariant CampusMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final location = widget.locationToOpen;
    if (location == null || oldWidget.locationToOpen?.id == location.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showLocation(location);
      widget.onLocationOpened();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final user = state.user;
    final matches = state.locations.where((location) {
      final categoryMatch =
          _category == 'All' || location.category == _category;
      return categoryMatch && location.matches(state.searchQuery);
    }).toList();

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: .72,
              maxScale: 4,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(260),
              child: SizedBox(
                width: 520,
                height: 1160,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/campus_map.jpg',
                        fit: BoxFit.fill,
                      ),
                    ),
                    if (state.routeActive && state.selectedLocation != null)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _RoutePainter(
                              destination: state.selectedLocation!,
                            ),
                          ),
                        ),
                      ),
                    ...matches.map(
                      (location) => _MapPin(
                        location: location,
                        selected: state.selectedLocation?.id == location.id,
                        saved: state.favorites.contains(location.id),
                        onTap: () => _showLocation(location),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 10,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x220B153E),
                              blurRadius: 20,
                              offset: Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user?.name.characters.first.toUpperCase() ??
                                    'S',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Hi, ${user?.name ?? 'Explorer'}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${user?.role.label ?? 'Guest'} · SDU Campus',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: widget.onOpenAssistant,
                              icon: const Icon(
                                Icons.auto_awesome,
                                color: AppColors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  onChanged: ref.read(appProvider.notifier).search,
                  decoration: InputDecoration(
                    hintText: 'Search rooms, offices, services…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: state.searchQuery.isEmpty
                        ? const Icon(Icons.tune)
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              ref.read(appProvider.notifier).search('');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children:
                        [
                              'All',
                              'Classroom',
                              'Food',
                              'Study',
                              'Office',
                              'Printer',
                              'Restroom',
                              'Parking',
                            ]
                            .map(
                              (category) => Padding(
                                padding: const EdgeInsets.only(right: 7),
                                child: FilterChip(
                                  selected: _category == category,
                                  label: Text(category),
                                  backgroundColor: Colors.white,
                                  selectedColor: const Color(0xFFDDE9FF),
                                  onSelected: (_) =>
                                      setState(() => _category = category),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
          if (state.searchQuery.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 160,
              child: _SearchResults(
                locations: matches.take(4).toList(),
                onTap: _showLocation,
              ),
            ),
          if (user?.role == UserRole.student &&
              state.searchQuery.isEmpty &&
              !state.routeActive)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: _NextClassCard(
                onRoute: () =>
                    _showLocation(state.locations.firstWhere((e) => e.id == 4)),
              ),
            ),
          if (state.routeActive && state.selectedLocation != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: _RouteSummary(
                location: state.selectedLocation!,
                onDetails: () => _showRouteSteps(state.selectedLocation!),
                onClose: ref.read(appProvider.notifier).clearLocation,
              ),
            ),
          Positioned(
            right: 14,
            bottom: state.routeActive || user?.role == UserRole.student
                ? 132
                : 18,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'layers',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy,
                  onPressed: () => _showLegend(context),
                  child: const Icon(Icons.layers_outlined),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'locate',
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  onPressed: () => _showLocation(state.locations.first),
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocation(CampusLocation location) {
    ref.read(appProvider.notifier).selectLocation(location);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LocationSheet(
        location: location,
        onRoute: () {
          Navigator.pop(context);
          ref.read(appProvider.notifier).startRoute(location);
        },
      ),
    );
  }

  void _showRouteSteps(CampusLocation location) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RouteStepsSheet(location: location),
  );

  void _showLegend(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Map layers',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.meeting_room_outlined),
            title: Text('Rooms and offices'),
            trailing: Switch(value: true, onChanged: null),
          ),
          ListTile(
            leading: Icon(Icons.restaurant_outlined),
            title: Text('Campus services'),
            trailing: Switch(value: true, onChanged: null),
          ),
          ListTile(
            leading: Icon(Icons.accessible),
            title: Text('Accessible facilities'),
            trailing: Switch(value: true, onChanged: null),
          ),
        ],
      ),
    ),
  );
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.location,
    required this.selected,
    required this.saved,
    required this.onTap,
  });
  final CampusLocation location;
  final bool selected;
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    left: location.x * 520 - 24,
    top: location.y * 1160 - 24,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: selected ? 56 : 48,
        height: selected ? 56 : 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: saved ? AppColors.gold : AppColors.navy,
            width: saved ? 3 : 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          location.icon,
          size: 23,
          color: selected ? Colors.white : AppColors.navy,
        ),
      ),
    ),
  );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({required this.destination});
  final CampusLocation destination;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final start = Offset(.72 * size.width, .76 * size.height);
    final end = Offset(destination.x * size.width, destination.y * size.height);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(.58 * size.width, .70 * size.height)
      ..lineTo(.57 * size.width, .50 * size.height)
      ..lineTo(end.dx, end.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.destination.id != destination.id;
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.locations, required this.onTap});
  final List<CampusLocation> locations;
  final ValueChanged<CampusLocation> onTap;

  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    borderRadius: BorderRadius.circular(18),
    child: locations.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No exact match. Try a room code, block, or service.'),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: locations
                .map(
                  (location) => ListTile(
                    leading: Icon(location.icon, color: AppColors.blue),
                    title: Text(location.name),
                    subtitle: Text('${location.block} · ${location.floor}'),
                    onTap: () => onTap(location),
                  ),
                )
                .toList(),
          ),
  );
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.onRoute});
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.navy,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onRoute,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFF314079),
              child: Icon(Icons.schedule, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NEXT CLASS · 10:30',
                    style: TextStyle(
                      color: Color(0xFFB9C5EA),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Project Management · Room 317',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}

class _LocationSheet extends ConsumerWidget {
  const _LocationSheet({required this.location, required this.onRoute});
  final CampusLocation location;
  final VoidCallback onRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(
      appProvider.select((s) => s.user?.role == UserRole.guest),
    );
    final saved = ref.watch(
      appProvider.select((s) => s.favorites.contains(location.id)),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE4EEFF),
                child: Icon(location.icon, color: AppColors.blue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.category.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      location.name,
                      style: const TextStyle(
                        fontSize: 24,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGuest)
                IconButton(
                  onPressed: () => ref
                      .read(appProvider.notifier)
                      .toggleFavorite(location.id),
                  icon: Icon(
                    saved ? Icons.bookmark : Icons.bookmark_border,
                    color: saved ? AppColors.gold : AppColors.navy,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _InfoRow(
            Icons.location_on_outlined,
            '${location.block} · ${location.floor}',
          ),
          _InfoRow(Icons.schedule, location.hours),
          _InfoRow(Icons.call_outlined, location.contact),
          _InfoRow(
            Icons.accessible,
            location.accessible
                ? 'Accessible entrance and elevator available'
                : 'Limited accessibility information',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (!isGuest) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _report(context, location),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Report info'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRoute,
                  icon: const Icon(Icons.directions),
                  label: const Text('Route'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _report(BuildContext context, CampusLocation location) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Report started for ${location.name}. Open Profile → Reports to submit.',
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 21, color: AppColors.muted),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
      ],
    ),
  );
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.location,
    required this.onDetails,
    required this.onClose,
  });
  final CampusLocation location;
  final VoidCallback onDetails;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.blue,
            child: Icon(Icons.directions_walk, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  location.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const Text(
                  '6 min · 420 m · via central atrium',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onDetails, child: const Text('Steps')),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
    ),
  );
}

class _RouteStepsSheet extends ConsumerWidget {
  const _RouteStepsSheet({required this.location});
  final CampusLocation location;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessible = ref.watch(appProvider.select((s) => s.accessibleRoutes));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .67,
      maxChildSize: .9,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        children: [
          Text(
            'Route to ${location.name}',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '6 min · 420 metres',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Accessible route',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Avoid stairs and use elevators'),
            value: accessible,
            onChanged: ref.read(appProvider.notifier).setAccessible,
          ),
          const Divider(),
          ...routeSteps.indexed.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE4EEFF),
                child: Text(
                  '${entry.$1 + 1}',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(entry.$2.instruction),
              subtitle: entry.$2.minutes == 0
                  ? const Text('Destination')
                  : Text('${entry.$2.minutes} min'),
            ),
          ),
        ],
      ),
    );
  }
}
