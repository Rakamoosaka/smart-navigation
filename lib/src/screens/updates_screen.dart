import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class UpdatesScreen extends ConsumerWidget {
  const UpdatesScreen({super.key, required this.onShowMap});
  final ValueChanged<CampusLocation> onShowMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          const Text(
            'Campus updates',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Announcements and events around SDU',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          ...state.announcements.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0D9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.campaign_outlined,
                            color: AppColors.gold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.when,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                    if (state.locations.any((e) => e.id == item.locationId))
                      TextButton.icon(
                        onPressed: () {
                          ref
                              .read(appProvider.notifier)
                              .selectLocation(
                                state.locations.firstWhere(
                                  (e) => e.id == item.locationId,
                                ),
                              );
                          onShowMap(
                            state.locations.firstWhere(
                              (e) => e.id == item.locationId,
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on_outlined),
                        label: const Text('View location'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
