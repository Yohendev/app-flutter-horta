import 'dart:math';

enum StatusSaude { saudavel, precisaDeCuidado, comDeficiencia, emRecuperacao }

enum TipoCuidado { rega, luz, nutricao }

enum StatusTarefa { pendente, concluida }

enum StatusDiagnostico { emAnalise, concluido, inconclusivo, falhou }

enum Severidade { leve, moderada, grave }

final _random = Random.secure();

String _uuid() {
  final bytes = List.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class Jardineiro {
  Jardineiro({required this.nome, required this.email});

  final String id = _uuid();
  final String nome;
  final String email;
  final _hortas = <Horta>[];
  List<Horta> get hortas => List.unmodifiable(_hortas);

  Horta criarHorta(String nome) {
    final horta = Horta._(this, nome);
    _hortas.add(horta);
    return horta;
  }
}

class Horta {
  Horta._(this.jardineiro, this.nome);

  final String id = _uuid();
  final Jardineiro jardineiro;
  final String nome;
  final _plantas = <Planta>[];
  List<Planta> get plantas => List.unmodifiable(_plantas);

  Planta plantar({
    required String apelido,
    required DateTime dataPlantio,
    required EspeciePlanta especie,
    required StatusSaude statusSaude,
  }) {
    final planta = Planta._(this, apelido, dataPlantio, especie, statusSaude);
    _plantas.add(planta);
    especie._plantas.add(planta);
    return planta;
  }
}

class Planta {
  Planta._(
    this.horta,
    this.apelido,
    DateTime plantio,
    this.especie,
    this.statusSaude,
  ) : dataPlantio = DateTime(plantio.year, plantio.month, plantio.day);

  final String id = _uuid();
  final Horta horta;
  final String apelido;
  final DateTime dataPlantio;
  final EspeciePlanta especie;
  StatusSaude statusSaude;
  final _tarefas = <TarefaCuidado>[];
  final _diagnosticos = <Diagnostico>[];
  List<TarefaCuidado> get tarefas => List.unmodifiable(_tarefas);
  List<Diagnostico> get diagnosticos => List.unmodifiable(_diagnosticos);

  TarefaCuidado agendarCuidado(TipoCuidado tipo, DateTime previstaPara) {
    final tarefa = TarefaCuidado._(this, tipo, previstaPara);
    _tarefas.add(tarefa);
    return tarefa;
  }

  Diagnostico registrarDiagnostico({
    required DateTime realizadoEm,
    required StatusDiagnostico status,
    required String observacao,
    required String uri,
    required DateTime capturadaEm,
  }) {
    final diagnostico = Diagnostico._(
      this,
      realizadoEm,
      status,
      observacao,
      uri,
      capturadaEm,
    );
    _diagnosticos.add(diagnostico);
    return diagnostico;
  }
}

class EspeciePlanta {
  EspeciePlanta({required this.nomePopular, required this.nomeCientifico});

  final String id = _uuid();
  final String nomePopular;
  final String nomeCientifico;
  final _plantas = <Planta>[];
  final _guias = <GuiaCuidado>{};
  List<Planta> get plantas => List.unmodifiable(_plantas);
  Set<GuiaCuidado> get guias => Set.unmodifiable(_guias);

  void recomendarGuia(GuiaCuidado guia) {
    _guias.add(guia);
    guia._especies.add(this);
  }
}

class TarefaCuidado {
  TarefaCuidado._(this.planta, this.tipo, this.previstaPara);

  final String id = _uuid();
  final Planta planta;
  final TipoCuidado tipo;
  final DateTime previstaPara;
  DateTime? _concluidaEm;
  DateTime? get concluidaEm => _concluidaEm;
  StatusTarefa get status =>
      _concluidaEm == null ? StatusTarefa.pendente : StatusTarefa.concluida;

  void concluir(DateTime em) => _concluidaEm ??= em;

  void reabrir() => _concluidaEm = null;
}

class GuiaCuidado {
  GuiaCuidado({
    required this.titulo,
    required this.conteudo,
    required this.categoria,
  });

  final String id = _uuid();
  final String titulo;
  final String conteudo;
  final TipoCuidado categoria;
  final _especies = <EspeciePlanta>{};
  Set<EspeciePlanta> get especies => Set.unmodifiable(_especies);
}

class Diagnostico {
  Diagnostico._(
    this.planta,
    this.realizadoEm,
    this.status,
    this.observacao,
    String uri,
    DateTime capturadaEm,
  ) {
    _imagem = ImagemEscaneada._(this, uri, capturadaEm);
  }

  final String id = _uuid();
  final Planta planta;
  final DateTime realizadoEm;
  final StatusDiagnostico status;
  final String observacao;
  late final ImagemEscaneada _imagem;
  ImagemEscaneada get imagem => _imagem;
  final _achados = <AchadoDiagnostico>[];
  List<AchadoDiagnostico> get achados => List.unmodifiable(_achados);

  AchadoDiagnostico adicionarAchado({
    required double confianca,
    required Severidade severidade,
    required String recomendacao,
    required Deficiencia deficiencia,
  }) {
    if (!confianca.isFinite || confianca < 0 || confianca > 1) {
      throw RangeError.value(
        confianca,
        'confianca',
        'Use um valor entre 0 e 1',
      );
    }
    final achado = AchadoDiagnostico._(
      this,
      confianca,
      severidade,
      recomendacao,
      deficiencia,
    );
    _achados.add(achado);
    deficiencia._achados.add(achado);
    return achado;
  }
}

class ImagemEscaneada {
  ImagemEscaneada._(this.diagnostico, this.uri, this.capturadaEm);

  final String id = _uuid();
  final Diagnostico diagnostico;
  final String uri;
  final DateTime capturadaEm;
}

class AchadoDiagnostico {
  AchadoDiagnostico._(
    this.diagnostico,
    this.confianca,
    this.severidade,
    this.recomendacao,
    this.deficiencia,
  );

  final String id = _uuid();
  final Diagnostico diagnostico;
  final double confianca;
  final Severidade severidade;
  final String recomendacao;
  final Deficiencia deficiencia;
}

class Deficiencia {
  Deficiencia({required this.nome, required this.sintomas});

  final String id = _uuid();
  final String nome;
  final String sintomas;
  final _achados = <AchadoDiagnostico>[];
  List<AchadoDiagnostico> get achados => List.unmodifiable(_achados);
}
