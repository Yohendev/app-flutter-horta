import 'package:flutter_test/flutter_test.dart';
import 'package:horta/modelos_horta.dart';

void main() {
  late Jardineiro jardineiro;
  late EspeciePlanta especie;
  late DateTime agora;

  setUp(() {
    jardineiro = Jardineiro(nome: 'Júlia', email: 'julia@example.com');
    especie = EspeciePlanta(
      nomePopular: 'Alface',
      nomeCientifico: 'Lactuca sativa',
    );
    agora = DateTime(2026, 11, 20, 8);
  });

  test(
    'consulta os vínculos de cultivo e mantém o estado da tarefa coerente',
    () {
      expect(jardineiro.hortas, isEmpty);
      final horta = jardineiro.criarHorta('Horta');
      expect(horta.plantas, isEmpty);
      final planta = horta.plantar(
        apelido: 'Alface crespa',
        dataPlantio: agora,
        especie: especie,
        statusSaude: StatusSaude.saudavel,
      );

      expect(jardineiro.hortas.single, same(horta));
      expect(horta.jardineiro, same(jardineiro));
      expect(horta.plantas.single, same(planta));
      expect(planta.horta, same(horta));
      expect(planta.especie, same(especie));
      expect(especie.plantas.single, same(planta));
      expect(planta.dataPlantio, DateTime(2026, 11, 20));
      expect(planta.tarefas, isEmpty);
      expect(planta.diagnosticos, isEmpty);
      expect(() => horta.plantas.clear(), throwsUnsupportedError);

      final tarefa = planta.agendarCuidado(TipoCuidado.rega, agora);
      expect(planta.tarefas.single, same(tarefa));
      expect(tarefa.planta, same(planta));
      expect(tarefa.previstaPara, agora);
      expect(tarefa.status, StatusTarefa.pendente);
      expect(tarefa.concluidaEm, isNull);

      tarefa.concluir(agora);
      tarefa.concluir(agora.add(const Duration(minutes: 1)));
      expect(tarefa.status, StatusTarefa.concluida);
      expect(tarefa.concluidaEm, agora);
      tarefa.reabrir();
      expect(tarefa.status, StatusTarefa.pendente);
      expect(tarefa.concluidaEm, isNull);
    },
  );

  test('compartilha guias entre espécies sem repetir o vínculo', () {
    final outra = EspeciePlanta(
      nomePopular: 'Couve',
      nomeCientifico: 'Brassica oleracea',
    );
    final guia = GuiaCuidado(
      titulo: 'Rega',
      conteudo: 'Verifique a umidade do solo.',
      categoria: TipoCuidado.rega,
    );
    final guiaDeLuz = GuiaCuidado(
      titulo: 'Luz',
      conteudo: 'Observe a luz da manhã.',
      categoria: TipoCuidado.luz,
    );

    especie
      ..recomendarGuia(guia)
      ..recomendarGuia(guia)
      ..recomendarGuia(guiaDeLuz);
    outra.recomendarGuia(guia);

    expect(especie.guias, {guia, guiaDeLuz});
    expect(outra.guias.single, same(guia));
    expect(guia.especies, {especie, outra});
    expect(() => guia.especies.clear(), throwsUnsupportedError);
  });

  test('vincula imagens e achados aos diagnósticos com confiança válida', () {
    final horta = jardineiro.criarHorta('Horta');
    final planta = horta.plantar(
      apelido: 'Alface crespa',
      dataPlantio: agora,
      especie: especie,
      statusSaude: StatusSaude.saudavel,
    );
    Diagnostico diagnosticar() => planta.registrarDiagnostico(
      realizadoEm: agora,
      status: StatusDiagnostico.concluido,
      observacao: 'Resultado demonstrativo',
      uri: 'horta-demo:/folha',
      capturadaEm: agora,
    );

    final primeiro = diagnosticar();
    final segundo = diagnosticar();
    expect(planta.diagnosticos, [primeiro, segundo]);
    expect(primeiro.planta, same(planta));
    expect(primeiro.imagem.diagnostico, same(primeiro));
    expect(segundo.imagem.diagnostico, same(segundo));
    expect(primeiro.imagem, isNot(same(segundo.imagem)));
    expect(primeiro.imagem.capturadaEm, agora);
    expect(primeiro.achados, isEmpty);

    final deficiencia = Deficiencia(
      nome: 'Nitrogênio',
      sintomas: 'Folhas claras',
    );
    AchadoDiagnostico adicionar(Diagnostico diagnostico, double confianca) =>
        diagnostico.adicionarAchado(
          confianca: confianca,
          severidade: Severidade.leve,
          recomendacao: 'Adicionar composto.',
          deficiencia: deficiencia,
        );

    for (final invalida in [-0.1, 1.1, double.nan, double.infinity]) {
      expect(() => adicionar(primeiro, invalida), throwsRangeError);
    }
    expect(primeiro.achados, isEmpty);
    expect(deficiencia.achados, isEmpty);
    final achado = adicionar(primeiro, 0);
    final outroAchado = adicionar(primeiro, 1);
    final achadoDoSegundo = adicionar(segundo, 0.7);
    expect(primeiro.achados, [achado, outroAchado]);
    expect(achado.diagnostico, same(primeiro));
    expect(achado.deficiencia, same(deficiencia));
    expect(deficiencia.achados, [achado, outroAchado, achadoDoSegundo]);

    final ids = {
      jardineiro.id,
      horta.id,
      planta.id,
      especie.id,
      primeiro.id,
      segundo.id,
      primeiro.imagem.id,
      segundo.imagem.id,
      deficiencia.id,
      achado.id,
      outroAchado.id,
      achadoDoSegundo.id,
    };
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    expect(ids, hasLength(12));
    expect(ids, everyElement(matches(uuidV4)));
  });
}
