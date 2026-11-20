import 'package:flutter/material.dart';
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

  testWidgets('shows the same watering state on both screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const HortaApp());
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Alface regada'), findsOneWidget);

    await tester.tap(find.text('Alface crespa'));
    await tester.pumpAndSettle();
    expect(find.text('Regada por hoje'), findsOneWidget);

    await tester.tap(find.text('Cuidado concluído'));
    await tester.pumpAndSettle();
    expect(find.text('Hora de regar'), findsOneWidget);
  });

  testWidgets('renders the simulated scan result', (tester) async {
    await tester.pumpWidget(const HortaApp());
    await tester.tap(find.byIcon(Icons.document_scanner_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('scan-leaf')));
    await tester.pumpAndSettle();

    expect(find.text('Alface identificada'), findsOneWidget);
    expect(find.text('Possível falta de nitrogênio'), findsOneWidget);
    expect(find.text('Adicione composto orgânico ao solo.'), findsOneWidget);
  });
}
