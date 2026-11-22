import 'package:flutter_test/flutter_test.dart';
import 'package:lingo_gold/main.dart';

void main() {
  testWidgets('clean app opens', (tester) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.byType(Shell), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(BottomNav), findsOneWidget);
  });
}
