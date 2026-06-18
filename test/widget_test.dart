import 'package:flutter_test/flutter_test.dart';
import 'package:random_select/main.dart';

void main() {
  testWidgets('shows selector screen', (tester) async {
    await tester.pumpWidget(const RandomSelectApp());

    expect(find.text('Random Select'), findsOneWidget);
    expect(find.text('Список'), findsOneWidget);
  });
}
