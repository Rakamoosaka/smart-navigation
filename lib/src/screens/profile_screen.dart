import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import 'admin_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.onOpenLocation});

  final ValueChanged<CampusLocation> onOpenLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final user = state.user!;
    if (user.role == UserRole.guest) {
      return const _GuestAccountScreen();
    }
    final favorites = state.locations
        .where((e) => state.favorites.contains(e.id))
        .toList();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.navy,
                child: Text(
                  user.name.characters.first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(user.role.label),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      backgroundColor: const Color(0xFFDDE9FF),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (user.role == UserRole.student)
            _StudentSummary(onSchedule: () => _showSchedule(context, false)),
          if (user.role == UserRole.teacher)
            _TeacherSummary(onSchedule: () => _showSchedule(context, true)),
          if (user.role == UserRole.admin)
            Card(
              color: AppColors.navy,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF314079),
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Colors.white,
                  ),
                ),
                title: const Text(
                  'Administration',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: const Text(
                  'Manage campus data and review analytics',
                  style: TextStyle(color: Color(0xFFBCC6E7)),
                ),
                trailing: const Icon(Icons.arrow_forward, color: Colors.white),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            'Saved places (${state.favorites.length}/5)',
            style: const TextStyle(
              fontSize: 19,
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (favorites.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No saved locations yet. Tap the bookmark on any map location.',
                ),
              ),
            ),
          ...favorites.map(
            (location) => Card(
              child: ListTile(
                onTap: () => onOpenLocation(location),
                leading: Icon(location.icon, color: AppColors.blue),
                title: Text(location.name),
                subtitle: Text('${location.block} · ${location.floor}'),
                trailing: IconButton(
                  onPressed: () async {
                    final error = await ref
                        .read(appProvider.notifier)
                        .toggleFavorite(location.id);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(error)));
                    }
                  },
                  icon: const Icon(Icons.bookmark, color: AppColors.gold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: state.accessibleRoutes,
                  onChanged: ref.read(appProvider.notifier).setAccessible,
                  secondary: const Icon(
                    Icons.accessible,
                    color: AppColors.blue,
                  ),
                  title: const Text(
                    'Accessibility preference',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Avoid staircase endpoints. Cross-floor and verified step-free routes are not available yet.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Report outdated information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReport(context, ref),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Language'),
                  subtitle: Text('English'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(appProvider.notifier).logout();
              if (context.mounted) context.go('/welcome');
            },
            icon: const Icon(Icons.logout),
            label: Text(
              user.role == UserRole.guest ? 'End guest session' : 'Log out',
            ),
          ),
        ],
      ),
    );
  }

  void _showSchedule(BuildContext context, bool teacher) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacher ? 'Teaching schedule' : 'Today’s timetable',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 14),
              const _ScheduleTile(
                '09:00',
                'Software Engineering',
                'Room 218 · Block F',
              ),
              const _ScheduleTile(
                '10:30',
                'Project Management',
                'Room 317 · Block F',
              ),
              const _ScheduleTile(
                '14:00',
                'Database Systems',
                'Room 402 · Block H',
              ),
            ],
          ),
        ),
      );

  void _showReport(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report outdated information'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'What information should be corrected?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final submitted = await ref
                  .read(appProvider.notifier)
                  .submitReport(controller.text.trim(), null);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    submitted
                        ? 'Report submitted · status: New'
                        : 'Report saved in demo mode · start the API to sync',
                  ),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _GuestAccountScreen extends ConsumerWidget {
  const _GuestAccountScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    bottom: false,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        const CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.navy,
          child: Icon(Icons.person_outline, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 14),
        const Text(
          'Browsing as Guest',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'You can use the campus map, search, floor connections, the assistant, and announcements.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log in to unlock',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const _GuestLockedFeature(
                  Icons.bookmark_border,
                  'Saved places',
                ),
                const _GuestLockedFeature(
                  Icons.tune,
                  'Saved accessibility preferences',
                ),
                const _GuestLockedFeature(
                  Icons.calendar_month_outlined,
                  'Personal schedules and next class',
                ),
                const _GuestLockedFeature(
                  Icons.flag_outlined,
                  'Information reports',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await ref.read(appProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Log in'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(appProvider.notifier).logout();
                      if (context.mounted) context.go('/register');
                    },
                    child: const Text('Create account'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(appProvider.notifier).logout();
            if (context.mounted) context.go('/welcome');
          },
          icon: const Icon(Icons.logout),
          label: const Text('End guest session'),
        ),
      ],
    ),
  );
}

class _GuestLockedFeature extends StatelessWidget {
  const _GuestLockedFeature(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
      ],
    ),
  );
}

class _StudentSummary extends StatelessWidget {
  const _StudentSummary({required this.onSchedule});
  final VoidCallback onSchedule;
  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.navy,
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF314079),
        child: Icon(Icons.school_outlined, color: Colors.white),
      ),
      title: const Text(
        'Next: Project Management',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      subtitle: const Text(
        '10:30 · Room 317 · Block F',
        style: TextStyle(color: Color(0xFFBCC6E7)),
      ),
      trailing: IconButton(
        onPressed: onSchedule,
        icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
      ),
    ),
  );
}

class _TeacherSummary extends StatelessWidget {
  const _TeacherSummary({required this.onSchedule});
  final VoidCallback onSchedule;
  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.navy,
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFF314079),
        child: Icon(Icons.badge_outlined, color: Colors.white),
      ),
      title: const Text(
        'Next lecture: 10:30',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      subtitle: const Text(
        'Project Management · Room 317',
        style: TextStyle(color: Color(0xFFBCC6E7)),
      ),
      trailing: IconButton(
        onPressed: onSchedule,
        icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
      ),
    ),
  );
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile(this.time, this.title, this.place);
  final String time;
  final String title;
  final String place;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE4EEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        time,
        style: const TextStyle(
          color: AppColors.blue,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(place),
    trailing: const Icon(Icons.directions_outlined),
  );
}
