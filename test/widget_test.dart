import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bible_app/main.dart';

void main() {
  testWidgets('App boots and shows bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BibleApp()));
    await tester.pump();

    // Bottom nav destinations should be present.
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Listen'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Bookmarks'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
