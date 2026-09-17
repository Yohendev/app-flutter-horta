import 'package:flutter_test/flutter_test.dart';

import 'package:horta/main.dart';

void main() {
  testWidgets('shows the garden dashboard', (tester) async {
    await tester.pumpWidget(const HortaApp());

    expect(find.text('Sua horta'), findsOneWidget);
    expect(find.text('Alface crespa'), findsOneWidget);
    expect(find.text('Cuidados de hoje'), findsOneWidget);
  });

  testWidgets('opens the plant detail', (tester) async {
    await tester.pumpWidget(const HortaApp());
    await tester.tap(find.text('Alface crespa').first);
    await tester.pumpAndSettle();

    expect(find.text('Próximo cuidado'), findsOneWidget);
    expect(find.text('Hora de regar'), findsOneWidget);
  });
}
