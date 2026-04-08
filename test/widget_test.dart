import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bible_app/main.dart';

void main() {
  testWidgets('App boots to welcome screen on first run', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: BibleApp()));
    await tester.pump();

    // First-run shows welcome with mode picker.
    expect(find.text('Start reading'), findsOneWidget);
    expect(find.text('Kids mode'), findsOneWidget);
  });
}
