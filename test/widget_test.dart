import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app_supabase/main.dart';

void main() {
  testWidgets('App renders splash title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Police Prep App'), findsOneWidget);
  });
}
