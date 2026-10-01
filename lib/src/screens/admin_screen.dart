import 'package:flutter/material.dart';

import '../theme.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Administration')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      children: [
        const Row(
          children: [
            Expanded(
              child: _Metric(
                '12',
                'Locations',
                Icons.place_outlined,
                Color(0xFFE4EEFF),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _Metric(
                '3',
                'Open reports',
                Icons.flag_outlined,
                Color(0xFFFFE5E5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: _Metric(
                '247',
                'Searches',
                Icons.search,
                Color(0xFFE4F6EE),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _Metric(
                '3',
                'Updates',
                Icons.campaign_outlined,
                Color(0xFFFFF0D9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Manage campus',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _AdminTile(
                Icons.map_outlined,
                'Locations and map markers',
                'Add rooms, services, pins, and map zones',
                () => _showManagement(context, 'Locations and map markers'),
              ),
              const Divider(height: 1),
              _AdminTile(
                Icons.route_outlined,
                'Routes',
                'Edit normal and accessible route steps',
                () => _showManagement(context, 'Routes'),
              ),
              const Divider(height: 1),
              _AdminTile(
                Icons.people_outline,
                'Users and roles',
                'Assign student, teacher, and administrator roles',
                () => _showManagement(context, 'Users and roles'),
              ),
              const Divider(height: 1),
              _AdminTile(
                Icons.campaign_outlined,
                'Announcements',
                'Publish hours, notices, and events',
                () => _showManagement(context, 'Announcements'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Inaccuracy reports',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        const _ReportCard(
          'Library closing time is wrong',
          'Library · submitted by Yerassyl',
          'NEW',
        ),
        const _ReportCard(
          'Printer moved to second floor',
          'Block F · submitted by Daulet',
          'UNDER REVIEW',
        ),
        const SizedBox(height: 22),
        const Text(
          'Popular searches',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        const _SearchBar('Room 317', 86, 1),
        const _SearchBar('Library', 71, .83),
        const _SearchBar('Food court', 54, .63),
        const _SearchBar('Printer', 38, .44),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showManagement(context, 'Add campus location'),
      icon: const Icon(Icons.add_location_alt_outlined),
      label: const Text('Add location'),
    ),
  );

  void _showManagement(BuildContext context, String title) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Details',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('$title saved')));
                  },
                  child: const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.icon, this.color);
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: AppColors.navy),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    ),
  );
}

class _AdminTile extends StatelessWidget {
  const _AdminTile(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
    leading: Icon(icon, color: AppColors.blue),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard(this.title, this.subtitle, this.status);
  final String title;
  final String subtitle;
  final String status;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFFFE5E5),
        child: Icon(Icons.flag_outlined, color: Colors.redAccent),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: Chip(
        label: Text(status, style: const TextStyle(fontSize: 10)),
        visualDensity: VisualDensity.compact,
        side: BorderSide.none,
      ),
    ),
  );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar(this.label, this.count, this.fraction);
  final String label;
  final int count;
  final double fraction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(
      children: [
        SizedBox(width: 92, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: const Color(0xFFE4E8F2),
              color: AppColors.blue,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
