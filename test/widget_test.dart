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
    expect(find.text('Rega concluída'), findsOneWidget);

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

  testWidgets('reflete cuidados, tratamento, reavaliação e arquivamento', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const HortaApp());

    Future<void> tocar(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tocar(find.byType(Switch));
    await tocar(find.text('Alface crespa'));
    expect(find.text('Precisa de cuidado'), findsOneWidget);
    await tocar(find.byIcon(Icons.arrow_back_rounded));
    await tocar(find.byTooltip('Concluir cuidado de luz'));
    await tocar(find.text('Alface crespa'));
    expect(find.text('Saudável'), findsOneWidget);
    await tocar(find.byIcon(Icons.arrow_back_rounded));

    final scanner = find.byType(FloatingActionButton);
    final disparador = find.byKey(const ValueKey('scan-leaf'));
    await tocar(scanner);
    await tocar(disparador);
    await tocar(find.text('Concluir'));
    await tocar(find.text('Alface crespa'));
    expect(find.text('Com deficiência'), findsOneWidget);
    await tocar(find.text('Registrar tratamento'));
    await tester.enterText(find.byType(TextField), 'Composto aplicado');
    await tocar(find.text('Registrar'));
    expect(find.text('Em recuperação'), findsOneWidget);
    await tocar(find.byIcon(Icons.arrow_back_rounded));

    await tocar(scanner);
    await tocar(disparador);
    await tocar(find.text('Sem deficiência'));
    await tocar(find.text('Sem deficiência na reavaliação simulada'));
    await tocar(find.text('Alface crespa'));
    expect(find.text('Saudável'), findsOneWidget);
    await tocar(find.byTooltip('Opções da planta'));
    await tocar(find.text('Arquivar planta'));
    await tocar(find.text('Arquivar'));
    expect(find.text('Nenhuma planta no cultivo ativo.'), findsOneWidget);
    expect(scanner, findsNothing);
    await tocar(find.text('Adicionar planta'));
    await tester.enterText(find.byType(TextFormField).first, 'Hortelã');
    await tocar(find.text('Adicionar'));
    expect(find.text('Hortelã'), findsOneWidget);
    expect(scanner, findsOneWidget);
    await tocar(find.text('Plantas'));
    expect(find.text('Hortelã'), findsOneWidget);
    expect(find.text('Alface crespa'), findsNothing);
  });

  testWidgets('cadastra na lista e preserva as demais plantas do cultivo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const HortaApp());

    Future<void> tocar(String texto) async {
      await tester.tap(find.text(texto));
      await tester.pumpAndSettle();
    }

    await tocar('Ver tudo');
    await tocar('Adicionar outra planta');
    await tocar('Adicionar');
    expect(find.text('Informe o nome da planta.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Manjericão');
    await tester.enterText(find.byType(TextFormField).last, 'Ocimum basilicum');
    await tocar('Adicionar');
    expect(find.text('Alface crespa'), findsOneWidget);
    await tocar('Início');
    expect(find.text('Manjericão'), findsOneWidget);
    await tocar('Plantas');
    await tocar('Alface crespa');
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    await tocar('Início');
    expect(find.text('Alface crespa'), findsOneWidget);
    await tocar('Plantas');
    await tocar('Manjericão');
    expect(find.text('Ocimum basilicum'), findsOneWidget);
    await tester.tap(find.byTooltip('Opções da planta'));
    await tester.pumpAndSettle();
    await tocar('Arquivar planta');
    await tocar('Arquivar');
    expect(find.text('Manjericão'), findsNothing);
    await tocar('Início');
    expect(find.text('Alface crespa'), findsOneWidget);
  });
}
