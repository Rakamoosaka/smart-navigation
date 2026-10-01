import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';

class CampusAssistantScreen extends ConsumerStatefulWidget {
  const CampusAssistantScreen({super.key, required this.onShowMap});
  final VoidCallback onShowMap;

  @override
  ConsumerState<CampusAssistantScreen> createState() =>
      _CampusAssistantScreenState();
}

class _Message {
  const _Message(this.text, this.user, [this.location]);
  final String text;
  final bool user;
  final CampusLocation? location;
}

class _CampusAssistantScreenState extends ConsumerState<CampusAssistantScreen> {
  final _controller = TextEditingController();
  final _messages = <_Message>[
    const _Message(
      'Hi! Ask me where a room or service is. I can also recommend food, study spaces, parking, printers, or an accessible route.',
      false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send([String? suggested]) {
    final query = (suggested ?? _controller.text).trim();
    if (query.isEmpty) return;
    _controller.clear();
    final answer = _answer(query);
    setState(() {
      _messages.add(_Message(query, true));
      _messages.add(answer);
    });
  }

  _Message _answer(String query) {
    final q = query.toLowerCase();
    final locations = ref.read(appProvider).locations;
    CampusLocation? location;
    if (q.contains('next class') || q.contains('317')) {
      location = locations.firstWhere((e) => e.id == 4);
      return _Message(
        'Your next class is Project Management at 10:30 in Room 317, Block F, 3rd floor. It is about 6 minutes away.',
        false,
        location,
      );
    }
    if (q.contains('park')) {
      location = locations.firstWhere((e) => e.id == 10);
    }
    if (q.contains('print')) {
      location = locations.firstWhere((e) => e.id == 7);
    }
    if (q.contains('eat') || q.contains('food') || q.contains('coffee')) {
      location = locations.firstWhere((e) => e.id == 3);
    }
    if (q.contains('library') || q.contains('study')) {
      location = locations.firstWhere((e) => e.id == 2);
    }
    if (q.contains('medical') || q.contains('doctor')) {
      location = locations.firstWhere((e) => e.id == 6);
    }
    if (q.contains('toilet') || q.contains('restroom')) {
      location = locations.firstWhere((e) => e.id == 8);
    }
    if (location != null) {
      return _Message(
        'I found ${location.name} in ${location.block}, ${location.floor}. Tap below to show it on the map and start directions.',
        false,
        location,
      );
    }
    return const _Message(
      'I found a few possible matches. Do you mean a classroom, office, food service, or another campus facility?',
      false,
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.navy,
                child: Icon(Icons.auto_awesome, color: Colors.white),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus Assistant',
                    style: TextStyle(
                      fontSize: 21,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Online · uses live campus data',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children:
                [
                      'Where is my next class?',
                      'Find a printer',
                      'Where can I eat?',
                      'Library hours',
                    ]
                    .map(
                      (text) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(text),
                          onPressed: () => _send(text),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (_, index) {
              final message = _messages[index];
              return Align(
                alignment: message.user
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: message.user ? AppColors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: message.user ? Colors.white : AppColors.ink,
                          height: 1.35,
                        ),
                      ),
                      if (message.location != null) ...[
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () {
                            ref
                                .read(appProvider.notifier)
                                .selectLocation(message.location!);
                            widget.onShowMap();
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Show on map'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: 'Ask about campus…',
              prefixIcon: const Icon(Icons.auto_awesome),
              suffixIcon: IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send, color: AppColors.blue),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
