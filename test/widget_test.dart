import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sdu_campus_assistant/src/app.dart';

void main() {
  testWidgets('shows anniversary splash branding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SduCampusApp()));
    expect(find.text('SDU'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
  });
}
