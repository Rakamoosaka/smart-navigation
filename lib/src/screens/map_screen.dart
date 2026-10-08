import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_state.dart';
import '../api_client.dart';
import '../demo_data.dart' as catalog;
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
  final _transform = TransformationController();
  final _search = TextEditingController();
  String _category = 'All';
  Size _viewport = Size.zero;
  bool _fitted = false;
  Map<String, dynamic>? _route;
  bool _routeable(CampusLocation place) =>
      (catalog.campusRouting['attachments'] as Map? ?? {}).containsKey(
        place.mapKey,
      );

  Future<void> _planRoute(CampusLocation destination) async {
    final starts = ref.read(appProvider).locations.where(_routeable).toList();
    if (starts.isEmpty) return;
    var start =
        starts.where((p) => p.id == 1 && p.id != destination.id).firstOrNull ??
        starts.where((p) => p.id != destination.id).firstOrNull ??
        starts.first;
    final avoidStairs = ref.read(appProvider).accessibleRoutes;
    var busy = false;
    String? error;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan a draft route',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('To: ${destination.name} · Floor 1'),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: start.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Start location (selected manually)',
                  ),
                  items: starts
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (id) => update(
                          () => start = starts.singleWhere((p) => p.id == id),
                        ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Traced from the schematic. Dashed ends indicate approximate doorways. Other floors, distance and walking time are not available.',
                  style: TextStyle(color: AppColors.muted),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          update(() {
                            busy = true;
                            error = null;
                          });
                          try {
                            final route = await ApiClient().draftRoute(
                              start.id,
                              destination.id,
                              avoidStairs,
                            );
                            if (!sheetContext.mounted) return;
                            if (route['status'] != 'schematic_draft') {
                              update(() {
                                busy = false;
                                error =
                                    route['message']?.toString() ??
                                    'No draft route found.';
                              });
                              return;
                            }
                            Navigator.pop(sheetContext, route);
                          } catch (_) {
                            if (sheetContext.mounted) {
                              update(() {
                                busy = false;
                                error = 'Cannot reach the route service. Start the backend and try again.';
                              });
                            }
                          }
                        },
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.route),
                  label: Text(busy ? 'Calculating…' : 'Show draft route'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _route = result;
      _search.clear();
      _category = 'All';
    });
    _fitRoute(result);
  }

  void _fitRoute(Map<String, dynamic> route) {
    final points = (route['points'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    if (points.isEmpty) return;
    final left = points.map((p) => p.dx).reduce(math.min);
    final right = points.map((p) => p.dx).reduce(math.max);
    final top = points.map((p) => p.dy).reduce(math.min);
    final bottom = points.map((p) => p.dy).reduce(math.max);
    // Keep both ends above the directions banner, including on a Mac simulator.
    final height = math.max(120.0, _viewport.height - 145);
    final scale = math
        .min(
          (_viewport.width - 48) / (right - left + 90),
          height / (bottom - top + 90),
        )
        .clamp(.25, 2.2);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        _viewport.width / 2 - (left + right) / 2 * scale,
        height / 2 - (top + bottom) / 2 * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _showRouteSteps() {
    final route = _route;
    if (route == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Draft directions · Floor 1',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(route['message'] as String),
              for (final (index, step) in (route['steps'] as List).indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 14,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(step.toString()),
                ),
              const Text(
                'Blue: traced corridor · Gold dashed: approximate connection. No live position, distance or walking time.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CampusMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final place = widget.locationToOpen;
    if (place == null || oldWidget.locationToOpen?.id == place.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _open(place);
      widget.onLocationOpened();
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    _search.dispose();
    super.dispose();
  }

  void _fit() {
    final scale = math
        .min(_viewport.width / 765, (_viewport.height - 40) / 1280)
        .clamp(.25, 1.0);
    _transform.value = Matrix4.identity()
      ..translateByDouble((_viewport.width - 765 * scale) / 2, 12, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _open(CampusLocation place) {
    ref.read(appProvider.notifier).selectLocation(place);
    setState(() {
      _search.clear();
      _category = 'All';
    });
    if (place.hasPosition && place.mapFloor == 1) {
      const scale = 1.25;
      _transform.value = Matrix4.identity()
        ..translateByDouble(
          _viewport.width / 2 - place.x * 765 * scale,
          _viewport.height / 2 - place.y * 1280 * scale,
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1);
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PlaceDetails(
        place,
        onPlanRoute: _routeable(place)
            ? () {
                Navigator.pop(context);
                _planRoute(place);
              }
            : null,
      ),
    );
  }

  void _floorInformation() {
    final places = ref.read(appProvider).locations;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .65,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            const Text(
              'Floors & connections',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Floor 1 has a schematic plan. Other floors have connection information only; their layouts are not mapped.',
            ),
            for (final floor in [-1, 1, 2, 3]) ...[
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 8),
                child: Text(
                  'Floor $floor${floor == 1 ? ' · current map' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (final place in places.where(
                (p) =>
                    (p.category == 'Stairs' || p.category == 'Lift') &&
                    p.floors.contains(floor),
              ))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(place.icon),
                  title: Text(place.name),
                  subtitle: Text(
                    'Serves ${place.floors.join(', ')}${place.skipsFloors.isEmpty ? '' : ' · skips ${place.skipsFloors.join(', ')}'}',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _open(place);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final names = state.locations.map((p) => p.category).toSet().toList()
      ..sort();
    final matches = state.locations
        .where(
          (p) =>
              (_category == 'All' || p.category == _category) &&
              p.matches(_search.text),
        )
        .toList();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explore SDU',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        'Current role: ${state.user?.role.label ?? 'Guest'}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onOpenAssistant,
                  tooltip: 'Campus assistant',
                  icon: const Icon(Icons.auto_awesome),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search D101, library, stairs…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(_search.clear),
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', ...names]
                  .map(
                    (name) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(name),
                        selected: name == _category,
                        onSelected: (_) => setState(() => _category = name),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _viewport = constraints.biggest;
                if (!_fitted) {
                  _fitted = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _fit();
                  });
                }
                return Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: _transform,
                        constrained: false,
                        minScale: .25,
                        maxScale: 4,
                        boundaryMargin: const EdgeInsets.all(900),
                        child: SizedBox(
                          width: 765,
                          height: 1280,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: SvgPicture.asset(
                                  'assets/maps/floor-1-background.svg',
                                ),
                              ),
                              for (final label in catalog.campusMapLabels)
                                _MapLabel(label),
                              if (_route != null)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _DraftRoutePainter(_route!),
                                    ),
                                  ),
                                ),
                              for (final place in matches.where(
                                (p) => p.hasPosition && p.mapFloor == 1,
                              ))
                                _PlaceOverlay(
                                  place: place,
                                  selected:
                                      state.selectedLocation?.id == place.id,
                                  saved: state.favorites.contains(place.id),
                                  onTap: () => _open(place),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: 6,
                      child: ActionChip(
                        avatar: const Icon(Icons.layers, size: 18),
                        label: const Text('Floor 1'),
                        onPressed: _floorInformation,
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 38,
                      child: FloatingActionButton.small(
                        heroTag: 'fit-map',
                        tooltip: 'Fit map',
                        onPressed: _fit,
                        child: const Icon(Icons.center_focus_strong),
                      ),
                    ),
                    const Positioned(
                      left: 12,
                      right: 64,
                      bottom: 8,
                      child: Text(
                        'Schematic · positions approximate · pinch to zoom',
                        style: TextStyle(fontSize: 11, color: AppColors.muted),
                      ),
                    ),
                    if (_route != null)
                      Positioned(
                        left: 12,
                        right: 76,
                        bottom: 30,
                        child: Material(
                          color: Colors.white,
                          elevation: 4,
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            onTap: _showRouteSteps,
                            title: const Text(
                              'Schematic route · not verified',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${_route!['start']} → ${_route!['destination']}\nTap for draft directions',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              tooltip: 'Clear route',
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _route = null),
                            ),
                          ),
                        ),
                      ),
                    if (_search.text.isNotEmpty || _category != 'All')
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 54,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: _viewport.height * .55,
                          ),
                          child: Material(
                            elevation: 5,
                            borderRadius: BorderRadius.circular(18),
                            clipBehavior: Clip.antiAlias,
                            child: matches.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Text(
                                      'No mapped places match. Try D101, library or stairs.',
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: matches.length,
                                    itemBuilder: (_, index) {
                                      final place = matches[index];
                                      return ListTile(
                                        leading: Icon(place.icon),
                                        title: Text(place.name),
                                        subtitle: Text(
                                          '${place.floor} · ${place.hasPosition ? place.block : 'Position not mapped'}',
                                        ),
                                        onTap: () => _open(place),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLabel extends StatelessWidget {
  const _MapLabel(this.label);
  final Map<String, dynamic> label;
  @override
  Widget build(BuildContext context) {
    final end = label['align'] == 'end';
    return Positioned(
      left: (label['x'] as num).toDouble() - (end ? 160 : 0),
      top: (label['y'] as num).toDouble() - (label['size'] as num).toDouble(),
      width: 160,
      child: IgnorePointer(
        child: Text(
          label['text'] as String,
          textAlign: end ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: (label['size'] as num).toDouble(),
            height: 1,
            color: Color(
              int.parse(
                (label['color'] as String).replaceFirst('#', 'ff'),
                radix: 16,
              ),
            ),
            fontWeight: label['bold'] == true
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _PlaceOverlay extends StatelessWidget {
  const _PlaceOverlay({
    required this.place,
    required this.selected,
    required this.saved,
    required this.onTap,
  });
  final CampusLocation place;
  final bool selected, saved;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final room = place.roomBounds;
    final color = selected
        ? AppColors.blue
        : saved
        ? const Color(0xffb78c45)
        : AppColors.navy;
    return Positioned(
      left: room?.left ?? place.x * 765 - 19,
      top: room?.top ?? place.y * 1280 - 19,
      width: room?.width ?? 38,
      height: room?.height ?? 38,
      child: Semantics(
        button: true,
        label: place.name,
        child: Tooltip(
          message: place.name,
          child: Material(
            color: room != null ? const Color(0xff833282) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(room != null ? 3 : 19),
              side: BorderSide(
                color: color,
                width: selected || saved ? 3 : 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: room != null
                    ? Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : place.mapKey.startsWith('stair_main_')
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(place.icon, size: 16, color: color),
                          Text(
                            int.parse(place.mapKey.split('_').last).toString(),
                            style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Icon(place.icon, size: 22, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftRoutePainter extends CustomPainter {
  _DraftRoutePainter(this.route);
  final Map<String, dynamic> route;
  Offset _point(dynamic value) =>
      Offset((value[0] as num).toDouble(), (value[1] as num).toDouble());
  @override
  void paint(Canvas canvas, Size size) {
    final segments = route['segments'] as List;
    final white = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final blue = Paint()
      ..color = AppColors.blue
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final gold = Paint()
      ..color = const Color(0xffbd7a19)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (final segment in segments) {
      final a = _point(segment['from']), b = _point(segment['to']);
      canvas.drawLine(a, b, white);
      if (segment['approximate_door'] == true) {
        final length = (b - a).distance;
        for (double d = 0; d < length; d += 13) {
          canvas.drawLine(
            Offset.lerp(a, b, d / length)!,
            Offset.lerp(a, b, math.min(d + 7, length) / length)!,
            gold,
          );
        }
      } else {
        canvas.drawLine(a, b, blue);
      }
    }
    final points = route['points'] as List;
    if (points.isNotEmpty) {
      for (final point in [points.first, points.last]) {
        canvas.drawCircle(_point(point), 8, Paint()..color = Colors.white);
        canvas.drawCircle(_point(point), 5, Paint()..color = AppColors.blue);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DraftRoutePainter oldDelegate) =>
      oldDelegate.route != route;
}

class _PlaceDetails extends ConsumerWidget {
  const _PlaceDetails(this.place, {this.onPlanRoute});
  final CampusLocation place;
  final VoidCallback? onPlanRoute;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final guest = state.user?.role == UserRole.guest;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(place.icon, color: AppColors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!guest)
                  IconButton(
                    tooltip: 'Save place',
                    onPressed: () async {
                      final error = await ref
                          .read(appProvider.notifier)
                          .toggleFavorite(place.id);
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
                    icon: Icon(
                      state.favorites.contains(place.id)
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                    ),
                  ),
              ],
            ),
            Text(
              '${place.block} · ${place.floor}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            if (!guest &&
                !state.favorites.contains(place.id) &&
                state.favorites.length >= 5)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  '5/5 places saved. Remove a saved place in Profile before saving another.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            if (!place.hasPosition)
              _info(
                Icons.location_off,
                'Exact position is not mapped. No pin is shown.',
              ),
            if (place.hasPosition)
              _info(
                Icons.info_outline,
                'Approximate position on the schematic; not surveyed.',
              ),
            if (place.access != 'public')
              _info(Icons.lock_outline, '${place.access} access'),
            if (place.floors.length > 1)
              _info(Icons.layers, 'Serves floors ${place.floors.join(', ')}'),
            if (place.skipsFloors.isNotEmpty)
              _info(
                Icons.warning_amber,
                'Skips floor ${place.skipsFloors.join(', ')}. Leads to the floor-3 canteen, not the general corridor.',
              ),
            if (place.entrancesFromFloors.isNotEmpty)
              _info(
                Icons.door_front_door,
                'Entrances on floors ${place.entrancesFromFloors.join(', ')}',
              ),
            if (place.category == 'Stairs')
              _info(Icons.accessible, 'Stairs are not a step-free option.'),
            if (place.category == 'Lift')
              _info(
                Icons.accessible,
                place.floors.isEmpty
                    ? 'Lift location recorded; served floors and step-free approaches are not yet confirmed.'
                    : 'Lift connection recorded; approaches and landings are not verified.',
              ),
            if (place.hours != 'Not confirmed')
              _info(Icons.schedule, place.hours),
            if (place.contact != 'Not confirmed')
              _info(Icons.contact_phone, place.contact),
            if (place.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(place.notes),
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      onPlanRoute != null
                          ? 'Schematic routing available'
                          : 'Approach not mapped yet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      onPlanRoute != null
                          ? 'A draft floor-1 path can be traced to this place. Doorways and accessibility are approximate, not surveyed. No walking distance or time is estimated.'
                          : 'This location has no traced floor-1 approach. Other floor layouts are not mapped. No route can be drawn to it yet.',
                    ),
                  ],
                ),
              ),
            ),
            if (onPlanRoute != null)
              FilledButton.icon(
                onPressed: onPlanRoute,
                icon: const Icon(Icons.route),
                label: const Text('Plan draft route'),
              ),
            if (!guest)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Use Profile → Report outdated information to submit a correction.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report outdated information'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
