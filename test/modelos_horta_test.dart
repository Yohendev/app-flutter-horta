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
    );
    Diagnostico diagnosticar() => planta.iniciarDiagnostico(
      realizadoEm: agora,
      uri: 'horta-demo:/folha',
      capturadaEm: agora,
    );

    final primeiro = diagnosticar();
    expect(primeiro.planta, same(planta));
    expect(primeiro.imagem.diagnostico, same(primeiro));
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
    primeiro.finalizar(StatusDiagnostico.concluido, 'Resultado demonstrativo');
    planta.registrarTratamento(primeiro, 'Composto aplicado');
    final segundo = diagnosticar();
    final achadoDoSegundo = adicionar(segundo, 0.7);
    segundo.finalizar(StatusDiagnostico.concluido, 'Deficiência persiste');
    expect(planta.diagnosticos, [primeiro, segundo]);
    expect(segundo.imagem.diagnostico, same(segundo));
    expect(primeiro.imagem, isNot(same(segundo.imagem)));
    expect(planta.estado, EstadoPlanta.comDeficiencia);
    expect(planta.tratamentos.single.diagnostico, same(primeiro));
    expect(
      () => planta.registrarTratamento(primeiro, 'Antigo'),
      throwsStateError,
    );
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

  Planta plantar() => jardineiro
      .criarHorta('Horta', relogio: () => agora)
      .plantar(apelido: 'Alface', dataPlantio: agora, especie: especie);

  Diagnostico escanear(Planta planta) => planta.iniciarDiagnostico(
    realizadoEm: agora,
    uri: 'horta-demo:/folha',
    capturadaEm: agora,
  );

  test('considera o vencimento e todas as tarefas pendentes de uma planta', () {
    final planta = plantar();
    expect(planta.estado, EstadoPlanta.saudavel);
    final prazo = agora.add(const Duration(hours: 1));
    final rega = planta.agendarCuidado(TipoCuidado.rega, prazo);
    final luz = planta.agendarCuidado(TipoCuidado.luz, prazo);
    planta.agendarCuidado(
      TipoCuidado.nutricao,
      prazo.add(const Duration(days: 1)),
    );
    expect(planta.estado, EstadoPlanta.saudavel);
    agora = prazo;
    expect(planta.estado, EstadoPlanta.precisaDeCuidado);
    rega.concluir(agora);
    expect(planta.estado, EstadoPlanta.precisaDeCuidado);
    luz.concluir(agora);
    expect(planta.estado, EstadoPlanta.saudavel);
    rega.reabrir();
    expect(planta.estado, EstadoPlanta.precisaDeCuidado);
  });

  test(
    'encerra a análise de acordo com o resultado e os cuidados pendentes',
    () {
      final planta = plantar();
      final primeiro = escanear(planta);
      expect(planta.estado, EstadoPlanta.emDiagnostico);
      expect(planta.statusSaude, StatusSaude.saudavel);
      expect(() => escanear(planta), throwsStateError);
      expect(planta.arquivar, throwsStateError);
      expect(
        () => primeiro.finalizar(StatusDiagnostico.emAnalise, ''),
        throwsStateError,
      );
      primeiro.finalizar(StatusDiagnostico.inconclusivo, 'Imagem pouco nítida');
      expect(planta.estado, EstadoPlanta.saudavel);
      expect(primeiro.status, StatusDiagnostico.inconclusivo);
      expect(
        () => primeiro.finalizar(StatusDiagnostico.concluido, ''),
        throwsStateError,
      );

      final tarefa = planta.agendarCuidado(TipoCuidado.rega, agora);
      escanear(planta).finalizar(StatusDiagnostico.inconclusivo, 'Pouca luz');
      expect(planta.estado, EstadoPlanta.precisaDeCuidado);
      escanear(planta)
          .finalizar(StatusDiagnostico.concluido, 'Sem deficiência');
      expect(planta.estado, EstadoPlanta.precisaDeCuidado);
      final falhou = escanear(planta);
      tarefa.concluir(agora);
      falhou.finalizar(StatusDiagnostico.falhou, 'Erro de processamento');
      expect(planta.estado, EstadoPlanta.saudavel);
    },
  );

  test(
    'exige tratamento vinculado e mantém o histórico ao recuperar e arquivar',
    () {
      final planta = plantar();
      final primeiro = escanear(planta);
      primeiro.adicionarAchado(
        confianca: 0.8,
        severidade: Severidade.leve,
        recomendacao: 'Aplicar composto',
        deficiencia: Deficiencia(nome: 'Nitrogênio', sintomas: 'Folhas claras'),
      );
      primeiro.finalizar(
        StatusDiagnostico.concluido,
        'Deficiência identificada',
      );
      expect(planta.estado, EstadoPlanta.comDeficiencia);
      expect(planta.tratamentos, isEmpty);
      expect(() => escanear(planta), throwsStateError);
      final outro = escanear(plantar());
      outro.finalizar(StatusDiagnostico.concluido, 'Sem deficiência');
      expect(
        () => planta.registrarTratamento(outro, 'Adubo'),
        throwsStateError,
      );
      expect(
        () => planta.registrarTratamento(primeiro, '  '),
        throwsArgumentError,
      );
      final tratamento = planta.registrarTratamento(
        primeiro,
        'Aplicado composto',
      );
      final reavaliacao = escanear(planta);
      expect(planta.estado, EstadoPlanta.emRecuperacao);
      reavaliacao.finalizar(
        StatusDiagnostico.inconclusivo,
        'Imagem pouco nítida',
      );
      expect(planta.estado, EstadoPlanta.emRecuperacao);
      final resultado = escanear(planta)
        ..finalizar(StatusDiagnostico.concluido, 'Sem deficiência');
      expect(planta.estado, EstadoPlanta.saudavel);
      final tarefa = planta.agendarCuidado(TipoCuidado.rega, agora);
      planta.arquivar();
      expect(planta.estado, EstadoPlanta.arquivada);
      expect(planta.horta.plantasAtivas, isEmpty);
      expect(planta.horta.plantas.single, same(planta));
      expect(planta.diagnosticos, [primeiro, reavaliacao, resultado]);
      expect(primeiro.achados, hasLength(1));
      expect(planta.tratamentos.single, same(tratamento));
      expect(() => escanear(planta), throwsStateError);
      expect(() => tarefa.concluir(agora), throwsStateError);
      expect(tarefa.reabrir, throwsStateError);
      expect(
        () => planta.agendarCuidado(TipoCuidado.luz, agora),
        throwsStateError,
      );
      expect(planta.arquivar, throwsStateError);
    },
  );
}
