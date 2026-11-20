import 'dart:math';

enum StatusSaude { saudavel, precisaDeCuidado, comDeficiencia, emRecuperacao }

enum EstadoPlanta {
  cadastrada,
  saudavel,
  precisaDeCuidado,
  emDiagnostico,
  comDeficiencia,
  emRecuperacao,
  arquivada,
}

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

  Horta criarHorta(String nome, {DateTime Function()? relogio}) {
    final horta = Horta._(this, nome, relogio ?? DateTime.now);
    _hortas.add(horta);
    return horta;
  }
}

class Horta {
  Horta._(this.jardineiro, this.nome, this._relogio);

  final String id = _uuid();
  final Jardineiro jardineiro;
  final String nome;
  final DateTime Function() _relogio;
  final _plantas = <Planta>[];
  List<Planta> get plantas => List.unmodifiable(_plantas);
  Iterable<Planta> get plantasAtivas =>
      _plantas.where((planta) => planta.estado != EstadoPlanta.arquivada);

  Planta plantar({
    required String apelido,
    required DateTime dataPlantio,
    required EspeciePlanta especie,
  }) {
    final planta = Planta._(this, apelido, dataPlantio, especie);
    _plantas.add(planta);
    especie._plantas.add(planta);
    planta._noCultivo = true;
    return planta;
  }
}

class Planta {
  Planta._(this.horta, this.apelido, DateTime plantio, this.especie)
    : dataPlantio = DateTime(plantio.year, plantio.month, plantio.day);

  final String id = _uuid();
  final Horta horta;
  final String apelido;
  final DateTime dataPlantio;
  final EspeciePlanta especie;
  bool _noCultivo = false;
  StatusSaude? _saudeAoArquivar;
  Diagnostico? _analise;
  Diagnostico? _deficienciaAtiva;
  final _tratamentos = <Tratamento>[];
  final _tarefas = <TarefaCuidado>[];
  final _diagnosticos = <Diagnostico>[];
  List<TarefaCuidado> get tarefas => List.unmodifiable(_tarefas);
  List<Diagnostico> get diagnosticos => List.unmodifiable(_diagnosticos);
  List<Tratamento> get tratamentos => List.unmodifiable(_tratamentos);
  Diagnostico? get deficienciaAtiva => _deficienciaAtiva;

  StatusSaude get statusSaude {
    if (_saudeAoArquivar case final status?) return status;
    if (_deficienciaAtiva case final diagnostico?) {
      return _tratamentos.isNotEmpty &&
              _tratamentos.last.diagnostico == diagnostico
          ? StatusSaude.emRecuperacao
          : StatusSaude.comDeficiencia;
    }
    final agora = horta._relogio();
    return _tarefas.any((tarefa) => tarefa.estaVencida(agora))
        ? StatusSaude.precisaDeCuidado
        : StatusSaude.saudavel;
  }

  EstadoPlanta get estado {
    if (_saudeAoArquivar != null) return EstadoPlanta.arquivada;
    if (!_noCultivo) return EstadoPlanta.cadastrada;
    if (_analise != null && _deficienciaAtiva == null) {
      return EstadoPlanta.emDiagnostico;
    }
    return switch (statusSaude) {
      StatusSaude.saudavel => EstadoPlanta.saudavel,
      StatusSaude.precisaDeCuidado => EstadoPlanta.precisaDeCuidado,
      StatusSaude.comDeficiencia => EstadoPlanta.comDeficiencia,
      StatusSaude.emRecuperacao => EstadoPlanta.emRecuperacao,
    };
  }

  bool get podeEscanear =>
      _analise == null &&
      (estado == EstadoPlanta.saudavel ||
          estado == EstadoPlanta.precisaDeCuidado ||
          estado == EstadoPlanta.emRecuperacao);

  bool get podeArquivar => switch (estado) {
    EstadoPlanta.saudavel ||
    EstadoPlanta.precisaDeCuidado ||
    EstadoPlanta.comDeficiencia ||
    EstadoPlanta.emRecuperacao => true,
    _ => false,
  };

  void _exigirAtiva() {
    if (_saudeAoArquivar != null) {
      throw StateError('A planta está arquivada.');
    }
  }

  void arquivar() {
    if (!podeArquivar) {
      throw StateError('O estado atual da planta não permite arquivamento.');
    }
    // Uma reavaliação ainda aberta não pode receber resultados após a remoção.
    _analise?.finalizar(StatusDiagnostico.falhou, 'Cultivo arquivado.');
    _saudeAoArquivar = statusSaude;
  }

  TarefaCuidado agendarCuidado(TipoCuidado tipo, DateTime previstaPara) {
    _exigirAtiva();
    final tarefa = TarefaCuidado._(this, tipo, previstaPara);
    _tarefas.add(tarefa);
    return tarefa;
  }

  Diagnostico iniciarDiagnostico({
    required DateTime realizadoEm,
    required String uri,
    required DateTime capturadaEm,
  }) {
    if (!podeEscanear) {
      throw StateError('O estado atual da planta não permite escaneamento.');
    }
    final diagnostico = Diagnostico._(this, realizadoEm, uri, capturadaEm);
    _diagnosticos.add(diagnostico);
    _analise = diagnostico;
    return diagnostico;
  }

  Tratamento registrarTratamento(Diagnostico diagnostico, String descricao) {
    if (estado != EstadoPlanta.comDeficiencia ||
        !identical(diagnostico, _deficienciaAtiva)) {
      throw StateError(
        'O tratamento exige o diagnóstico da deficiência atual.',
      );
    }
    if (descricao.trim().isEmpty) {
      throw ArgumentError.value(
        descricao,
        'descricao',
        'Descreva o tratamento',
      );
    }
    final tratamento = Tratamento._(
      diagnostico,
      descricao.trim(),
      horta._relogio(),
    );
    _tratamentos.add(tratamento);
    return tratamento;
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

  bool estaVencida(DateTime em) =>
      _concluidaEm == null && !previstaPara.isAfter(em);

  void concluir(DateTime em) {
    planta._exigirAtiva();
    _concluidaEm ??= em;
  }

  void reabrir() {
    planta._exigirAtiva();
    _concluidaEm = null;
  }
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
    String uri,
    DateTime capturadaEm,
  ) {
    _imagem = ImagemEscaneada._(this, uri, capturadaEm);
  }

  final String id = _uuid();
  final Planta planta;
  final DateTime realizadoEm;
  StatusDiagnostico _status = StatusDiagnostico.emAnalise;
  StatusDiagnostico get status => _status;
  String _observacao = '';
  String get observacao => _observacao;
  late final ImagemEscaneada _imagem;
  ImagemEscaneada get imagem => _imagem;
  final _achados = <AchadoDiagnostico>[];
  List<AchadoDiagnostico> get achados => List.unmodifiable(_achados);

  void _exigirEmAnalise() {
    planta._exigirAtiva();
    if (!identical(planta._analise, this)) {
      throw StateError('O diagnóstico não está em análise.');
    }
  }

  void finalizar(StatusDiagnostico resultado, String observacao) {
    _exigirEmAnalise();
    if (resultado == StatusDiagnostico.emAnalise) {
      throw StateError('Informe um resultado final para o diagnóstico.');
    }
    _status = resultado;
    _observacao = observacao;
    if (resultado == StatusDiagnostico.concluido) {
      planta._deficienciaAtiva = _achados.isEmpty ? null : this;
    }
    planta._analise = null;
  }

  AchadoDiagnostico adicionarAchado({
    required double confianca,
    required Severidade severidade,
    required String recomendacao,
    required Deficiencia deficiencia,
  }) {
    _exigirEmAnalise();
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

class Tratamento {
  Tratamento._(this.diagnostico, this.descricao, this.registradoEm);

  final String id = _uuid();
  final Diagnostico diagnostico;
  final String descricao;
  final DateTime registradoEm;
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
