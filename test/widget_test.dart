import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sdu_campus_assistant/src/app.dart';
import 'package:sdu_campus_assistant/src/screens/entry_screens.dart';

void main() {
  testWidgets('shows anniversary splash branding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SduCampusApp()));
    expect(find.byType(AnniversaryMark), findsOneWidget);
  });
}
