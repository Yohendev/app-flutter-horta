import 'package:flutter/material.dart';

import 'modelos_horta.dart';

void main() => runApp(const HortaApp());
// =====================================================================
// PALETA DE CORES OFICIAL - HORTA APP
// =====================================================================
const _yellow = Color(0xFFFFE04E); // Cor de fundo de "Sua Horta está crescendo"
const _sage = Color(0xFF97BA7F);   // Cor primária (verde da vegetação), símbolos (ao clicar), Scanner e texto 
const _coral = Color(0xFFF9998D);  // Cor de destaque/alerta (ex: scanner, wishlist)
const _peach = Color(0xFFF6A882);  // Tom complementar quente para detalhes e avatares/vasos
const _ink = Color(0xFF23352B);    // Cor principal para tipografia (alto contraste e suavidade)
const _canvas = Color(0xFFF8F8F3); // Cor de fundo padrão das telas (Canvas/Scaffold)


/// Widget raiz do aplicativo HortaApp.
/// Configura o tema global, paleta de cores Material 3 e tipografia padrão.
class HortaApp extends StatelessWidget {
  const HortaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horta',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _sage,
          primary: _sage,
          secondary: _yellow,
          surface: Colors.white,
        ),
        textTheme: Theme.of(context).textTheme
            .apply(fontFamily: 'Arial', bodyColor: _ink, displayColor: _ink),
      ),
      home: const GardenShell(),
    );
  }
}


/// Tela principal contendo a barra de navegação inferior (BottomNavigationBar)
/// e o gerenciamento de troca de abas (Início, Plantas, Guia, Perfil).
class GardenShell extends StatefulWidget {
  const GardenShell({super.key});

  @override
  State<GardenShell> createState() => _GardenShellState();
}

class _GardenShellState extends State<GardenShell> {
  int _currentIndex = 0;
  late final _jardineiro = Jardineiro(
    nome: 'Júlia Martins',
    email: 'julia@example.com',
  );
  late final _horta = _jardineiro.criarHorta('Sua horta');
  late final EspeciePlanta _especieGuia;
  Planta? _plantaEmDestaque;
  final _deficiencia = Deficiencia(
    nome: 'Possível falta de nitrogênio',
    sintomas: 'As folhas inferiores parecem mais claras que o normal.',
  );

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    final alface = EspeciePlanta(
      nomePopular: 'Alface crespa',
      nomeCientifico: 'Lactuca sativa',
    );
    _especieGuia = alface;
    alface
      ..recomendarGuia(GuiaCuidado(
        titulo: 'Como regar sem exagerar',
        conteudo: 'O solo conta quando está na hora de molhar.',
        categoria: TipoCuidado.rega,
      ))
      ..recomendarGuia(GuiaCuidado(
        titulo: 'A luz certa para crescer',
        conteudo: 'Sol suave pela manhã deixa as folhas felizes.',
        categoria: TipoCuidado.luz,
      ))
      ..recomendarGuia(GuiaCuidado(
        titulo: 'Folhas bonitas e verdes',
        conteudo: 'Identifique carências antes que elas avancem.',
        categoria: TipoCuidado.nutricao,
      ));
    _plantar(
      dataPlantio: DateTime(agora.year, agora.month, agora.day - 12),
      especie: alface,
    );
  }

  void _plantar({required DateTime dataPlantio, required EspeciePlanta especie}) {
    final agora = DateTime.now();
    _plantaEmDestaque = _horta.plantar(
      apelido: especie.nomePopular,
      dataPlantio: dataPlantio,
      especie: especie,
    )
      ..agendarCuidado(TipoCuidado.rega, agora)
      ..agendarCuidado(TipoCuidado.luz, agora);
  }

  Future<void> _adicionarPlanta() async {
    final especie = await showDialog<EspeciePlanta>(
      context: context,
      builder: (_) => const _CadastroPlantaDialog(),
    );
    if (!mounted || especie == null) return;
    setState(() => _plantar(dataPlantio: DateTime.now(), especie: especie));
  }

  void _atualizarCuidado(TarefaCuidado tarefa, bool concluida) {
    setState(() {
      if (concluida) {
        tarefa.concluir(DateTime.now());
      } else {
        tarefa.reabrir();
      }
    });
  }

// Navega para a página de escaneamento de folhas/plantas
  Future<void> _openScanner(Planta planta) async {
    if (!planta.podeEscanear) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registre o tratamento antes de reavaliar.'),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScannerPage(
          planta: planta,
          deficiencia: _deficiencia,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

// Navega para os detalhes da planta com callback para atualizar o estado de rega
  Future<void> _openPlant(Planta planta) async {
    _plantaEmDestaque = planta;
    final rega = planta.tarefas.firstWhere(
      (tarefa) => tarefa.tipo == TipoCuidado.rega,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlantDetailPage(
          planta: planta,
          rega: rega,
          onWaterChanged: (concluida) => _atualizarCuidado(rega, concluida),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _inicioComPlanta(Planta planta) {
    final rega = planta.tarefas.firstWhere((t) => t.tipo == TipoCuidado.rega);
    final luz = planta.tarefas.firstWhere((t) => t.tipo == TipoCuidado.luz);
    return HomePage(
      planta: planta,
      watered: rega.status == StatusTarefa.concluida,
      onOpenPlant: () => _openPlant(planta),
      onOpenPlants: () => setState(() => _currentIndex = 1),
      onScan: () => _openScanner(planta),
      onWater: () => _atualizarCuidado(rega, rega.status == StatusTarefa.pendente),
      luzConcluida: luz.status == StatusTarefa.concluida,
      onLight: () => _atualizarCuidado(luz, luz.status == StatusTarefa.pendente),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plantas = _horta.plantasAtivas.toList();
    final planta = plantas.contains(_plantaEmDestaque)
        ? _plantaEmDestaque
        : plantas.lastOrNull;
    final pages = [
      if (planta != null)
        _inicioComPlanta(planta)
      else
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Nenhuma planta no cultivo ativo.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _adicionarPlanta,
                child: const Text('Adicionar planta'),
              ),
            ],
          ),
        ),
      PlantsPage(
        plantas: plantas,
        onOpenPlant: _openPlant,
        onAddPlant: _adicionarPlanta,
      ),
      CareGuidePage(especie: _especieGuia),
      ProfilePage(jardineiro: _jardineiro, plantasAtivas: plantas.length),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_currentIndex]),
      // Botão flutuante centralizado na barra de navegação (Scanner)
      floatingActionButton: planta != null
          ? FloatingActionButton(
              heroTag: 'scanner',
              onPressed: () => _openScanner(planta),
              elevation: 1,
              backgroundColor: _sage,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.document_scanner_outlined, size: 25),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _GardenNavigation(
        selectedIndex: _currentIndex,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}


/// Barra de navegação inferior customizada com entalhe (notch) para o botão flutuante.
class _GardenNavigation extends StatelessWidget {
  const _GardenNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      // NOMES DA BARRA INFERIOR
      (Icons.home_rounded, 'Início'),
      (Icons.local_florist_outlined, 'Plantas'),
      (Icons.menu_book_outlined, 'Guia'),
      (Icons.person_outline_rounded, 'Perfil'),
    ];
    return BottomAppBar(
      height: 76,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 5),
      child: Row(
        children: [
          _NavItem(
            icon: items[0].$1,
            label: items[0].$2,
            active: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _NavItem(
            icon: items[1].$1,
            label: items[1].$2,
            active: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),

          // Espaço reservado para o FAB central
          const SizedBox(width: 62),
          _NavItem(
            icon: items[2].$1,
            label: items[2].$2,
            active: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
          _NavItem(
            icon: items[3].$1,
            label: items[3].$2,
            active: selectedIndex == 3,
            onTap: () => onSelected(3),
          ),
        ],
      ),
    );
  }
}

/// Item individual da barra de navegação inferior.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? _sage : const Color(0xFF9BA49D),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: active ? _sage : const Color(0xFF9BA49D),
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PÁGINA INICIAL (HOME): Exibe saudações, banner de status, resumo do cultivo e tarefas do dia.
class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.planta,
    required this.watered,
    required this.onOpenPlant,
    required this.onOpenPlants,
    required this.onScan,
    required this.onWater,
    required this.luzConcluida,
    required this.onLight,
  });

  final Planta planta;
  final bool watered;
  final VoidCallback onOpenPlant;
  final VoidCallback onOpenPlants;
  final VoidCallback onScan;
  final VoidCallback onWater;
  final bool luzConcluida;
  final VoidCallback onLight;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([

              // CABEÇALHO COM PERFIL DO USUÁRIO E NOTIFICAÇÕES
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: _peach,
                    child: Icon(Icons.person_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bom dia, ${planta.horta.jardineiro.nome.split(' ').first}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF627168),
                          ),
                        ),
                        Text(
                          planta.horta.nome,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoundIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const _WelcomeCard(), // Banner amarelo de boas-vindas
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Meu cultivo',
                action: 'Ver tudo',
                onAction: onOpenPlants,
              ),
              const SizedBox(height: 14),
              _PlantOverviewCard(planta: planta, onTap: onOpenPlant),
              const SizedBox(height: 25),
              _SectionHeader(
                title: 'Cuidados de hoje',
                action: 'Calendário',
                onAction: () {},
              ),

              // TAREFA INTERATIVA DE REGAR, A BOLINHA DE ATIVAR E DESATIVAR
              const SizedBox(height: 13),
              _CareTask(
                done: watered,
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF5BA9D8),
                title: watered ? 'Rega concluída' : 'Regar ${planta.apelido}',
                subtitle: watered
                    ? 'Tudo certo por hoje'
                    : 'Solo levemente seco',
                trailing: Switch.adaptive(
                  value: watered,
                  activeThumbColor: _sage,
                  onChanged: (_) => onWater(),
                ),
              ),

              const SizedBox(height: 10),
              _CareTask(
                done: luzConcluida,
                icon: Icons.wb_sunny_outlined,
                iconColor: Color(0xFFE8AC31),
                title: 'Checar a luz',
                subtitle: 'Deixe receber sol da manhã',
                trailing: IconButton(
                  tooltip: luzConcluida
                      ? 'Reabrir cuidado de luz'
                      : 'Concluir cuidado de luz',
                  onPressed: onLight,
                  icon: Icon(
                    luzConcluida ? Icons.check_circle : Icons.circle_outlined,
                  ),
                ),
              ),

              // ATALHO PARA ESCANEAMENTO
              const SizedBox(height: 25),
              _ScanCallout(onTap: onScan),
            ]),
          ),
        ),
      ],
    );
  }
}


/// Card de destaque principal na Home com fundo _yellow.
class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      decoration: BoxDecoration(
        color: _yellow,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -13,
            child: Opacity(
              opacity: .88,
              child: _PlantArtwork(
                size: 175,
                potColor: const Color(0xFFCD745B),
              ),
            ),
          ),
          const Positioned(
            left: 22,
            top: 23,
            right: 105,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sua horta está\nflorescendo!',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Um pouco de cuidado todos os dias.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de resumo da planta ativa na Home.
class _PlantOverviewCard extends StatelessWidget {
  const _PlantOverviewCard({required this.planta, required this.onTap});
  final Planta planta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 87,
                height: 94,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0E0),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const _PlantArtwork(size: 82, potColor: _peach),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planta.apelido,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Plantada há ${_diasDeCultivo(planta)} dias',
                      style: TextStyle(color: Color(0xFF77847B), fontSize: 12),
                    ),
                    SizedBox(height: 13),
                    Row(
                      children: [
                        _TinyTag(
                          icon: Icons.water_drop_outlined,
                          text: 'Bem regada',
                        ),
                        SizedBox(width: 7),
                        _TinyTag(icon: Icons.wb_sunny_outlined, text: 'Sol'),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _sage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etiqueta compacta utilizada para tags informativas (ex: status de rega/sol).
class _TinyTag extends StatelessWidget {
  const _TinyTag({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _sage),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontSize: 9,
              color: _ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Componente de tarefa diária (permite concluir ou interagir com o cuidado).
class _CareTask extends StatelessWidget {
  const _CareTask({
    required this.done,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final bool done;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              color: done ? _sage : iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF78847C),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Callout (Banner) de destaque para incentivar o uso do scanner de diagnóstico.
class _ScanCallout extends StatelessWidget {
  const _ScanCallout({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(23),
      color: _coral,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_outlined,
                  color: _coral,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Não sabe o que ela tem?',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Escaneie uma folha e descubra.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

int _diasDeCultivo(Planta planta) {
  final hoje = DateTime.now();
  final plantio = planta.dataPlantio;
  return DateTime.utc(hoje.year, hoje.month, hoje.day)
      .difference(DateTime.utc(plantio.year, plantio.month, plantio.day))
      .inDays;
}

/// Página de listagem de plantas do usuário e itens salvos na lista de desejos.
class PlantsPage extends StatelessWidget {
  const PlantsPage({
    super.key,
    required this.plantas,
    required this.onOpenPlant,
    required this.onAddPlant,
  });
  final List<Planta> plantas;
  final ValueChanged<Planta> onOpenPlant;
  final VoidCallback onAddPlant;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
      children: [
        const Text(
          'Minhas plantas',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Acompanhe a saúde da sua horta.',
          style: TextStyle(color: Color(0xFF718078)),
        ),
        const SizedBox(height: 23),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Buscar uma planta',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(17),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 25),
        if (plantas.isEmpty) ...[
          const Text('Nenhuma planta no cultivo ativo.'),
          const SizedBox(height: 13),
        ],
        for (final planta in plantas) ...[
          _PlantGridCard(planta: planta, onTap: () => onOpenPlant(planta)),
          const SizedBox(height: 13),
        ],
        _AddPlantCard(onTap: onAddPlant),
        const SizedBox(height: 28),
        const Text(
          'Na sua lista de desejos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 13),
        const _WishlistRow(),
      ],
    );
  }
}

/// Card de exibição da planta cadastrada na listagem.
class _PlantGridCard extends StatelessWidget {
  const _PlantGridCard({required this.planta, required this.onTap});
  final Planta planta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 186,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EFE0),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: _PlantArtwork(size: 172, potColor: _peach),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      planta.apelido,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _HealthPill(estado: planta.estado),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_diasDeCultivo(planta)} dias de cultivo',
                style: TextStyle(color: Color(0xFF78847C), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador em formato de pílula para o estado de saúde da planta.
class _HealthPill extends StatelessWidget {
  const _HealthPill({required this.estado});
  final EstadoPlanta estado;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3E5),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      switch (estado) {
        EstadoPlanta.cadastrada => 'Cadastrada',
        EstadoPlanta.saudavel => 'Saudável',
        EstadoPlanta.precisaDeCuidado => 'Precisa de cuidado',
        EstadoPlanta.emDiagnostico => 'Em diagnóstico',
        EstadoPlanta.comDeficiencia => 'Com deficiência',
        EstadoPlanta.emRecuperacao => 'Em recuperação',
        EstadoPlanta.arquivada => 'Arquivada',
      },
      style: TextStyle(
        color: Color(0xFF56834B),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _CadastroPlantaDialog extends StatefulWidget {
  const _CadastroPlantaDialog();

  @override
  State<_CadastroPlantaDialog> createState() => _CadastroPlantaDialogState();
}

class _CadastroPlantaDialogState extends State<_CadastroPlantaDialog> {
  final _formulario = GlobalKey<FormState>();
  String _nome = '';
  String _nomeCientifico = '';

  void _salvar() {
    final formulario = _formulario.currentState!;
    if (!formulario.validate()) return;
    formulario.save();
    Navigator.pop(
      context,
      EspeciePlanta(nomePopular: _nome, nomeCientifico: _nomeCientifico),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Adicionar planta'),
    scrollable: true,
    content: Form(
      key: _formulario,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome da planta'),
            validator: (valor) => (valor ?? '').trim().isEmpty
                ? 'Informe o nome da planta.'
                : null,
            onSaved: (valor) => _nome = valor!.trim(),
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Nome científico (opcional)',
            ),
            onSaved: (valor) => _nomeCientifico = (valor ?? '').trim(),
            onFieldSubmitted: (_) => _salvar(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _salvar, child: const Text('Adicionar')),
    ],
  );
}

/// Botão em formato de card tracejado para adicionar novas plantas.
class _AddPlantCard extends StatelessWidget {
  const _AddPlantCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          border: Border.all(color: _sage.withValues(alpha: .45), width: 1.5),
          borderRadius: BorderRadius.circular(21),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, color: _sage),
            SizedBox(width: 8),
            Text(
              'Adicionar outra planta',
              style: TextStyle(fontWeight: FontWeight.w700, color: _sage),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Item da lista de desejos (Wishlist) para futuras plantas
class _WishlistRow extends StatelessWidget {
  const _WishlistRow();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF2EB),
      borderRadius: BorderRadius.circular(19),
    ),
    child: const Row(
      children: [
        SizedBox(
          width: 63,
          height: 63,
          child: _PlantArtwork(size: 62, potColor: _coral),
        ),
        SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tomate-cereja',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text(
                'Boa escolha para começar',
                style: TextStyle(fontSize: 12, color: Color(0xFF7C7772)),
              ),
            ],
          ),
        ),
        Icon(Icons.bookmark_border_rounded, color: _coral),
      ],
    ),
  );
}

/// Página de Guia de Cuidados com dicas e boas práticas de jardinagem.
class CareGuidePage extends StatelessWidget {
  const CareGuidePage({super.key, required this.especie});
  final EspeciePlanta especie;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
      children: [
        const Text(
          'Guia de cuidados',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'Aprenda a cultivar com confiança.',
          style: TextStyle(color: Color(0xFF718078)),
        ),
        const SizedBox(height: 23),
        const _TipHero(), // Dica em destaque da semana
        const SizedBox(height: 26),
        const Text(
          'Guias de cuidado',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 13),
        for (final (index, guia) in especie.guias.indexed) ...[
          if (index > 0) const SizedBox(height: 11),
          _GuideTile(
            number: '${index + 1}'.padLeft(2, '0'),
            color: switch (guia.categoria) {
              TipoCuidado.rega => _yellow,
              TipoCuidado.luz => _peach,
              TipoCuidado.nutricao => _sage,
            },
            icon: switch (guia.categoria) {
              TipoCuidado.rega => Icons.water_drop_outlined,
              TipoCuidado.luz => Icons.wb_sunny_outlined,
              TipoCuidado.nutricao => Icons.eco_outlined,
            },
            title: guia.titulo,
            subtitle: guia.conteudo,
          ),
        ],
      ],
    );
  }
}

/// Card principal com gradiente para a Dica da Semana.
class _TipHero extends StatelessWidget {
  const _TipHero();
  @override
  Widget build(BuildContext context) => Container(
    height: 185,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(27),
      gradient: const LinearGradient(
        colors: [Color(0xFF54754F), Color(0xFF8FBA78)],
      ),
    ),
    child: Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dica da semana',
                style: TextStyle(
                  color: Color(0xFFE9F3E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Colha as folhas externas primeiro.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  height: 1.12,
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          right: -5,
          bottom: -7,
          child: _PlantArtwork(size: 136, potColor: Color(0xFFDD926A)),
        ),
        Positioned(
          left: 0,
          bottom: 0,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            onPressed: () {},
            icon: const Icon(Icons.play_circle_outline_rounded, size: 19),
            label: const Text(
              'Ver vídeo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Bloco de guia numerado para tutoriais rápidos.
class _GuideTile extends StatelessWidget {
  const _GuideTile({
    required this.number,
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final String number;
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(19),
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 57,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .35),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: color == _sage ? const Color(0xFF548744) : _ink,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF77847C),
                ),
              ),
            ],
          ),
        ),
        Text(
          number,
          style: TextStyle(
            color: color == _yellow ? const Color(0xFFE4B810) : color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

// PÁGINA DE PERFIL DO USUÁRIO com estatísticas de cultivo e opções de ajuste.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.jardineiro,
    required this.plantasAtivas,
  });
  final Jardineiro jardineiro;
  final int plantasAtivas;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 25, 22, 110),
    children: [
      const Center(
        child: CircleAvatar(
          radius: 43,
          backgroundColor: _peach,
          child: Icon(Icons.person_rounded, color: Colors.white, size: 45),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: Text(
          jardineiro.nome,
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 4),
      const Center(
        child: Text(
          'Jardineira iniciante',
          style: TextStyle(color: Color(0xFF718078)),
        ),
      ),
      const SizedBox(height: 31),
      _ProfileStatRow(plantasAtivas: plantasAtivas),
      const SizedBox(height: 28),
      const Text(
        'Preferências',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 10),
      const _ProfileOption(
        icon: Icons.notifications_none_rounded,
        label: 'Lembretes de cuidado',
      ),
      const _ProfileOption(
        icon: Icons.calendar_month_outlined,
        label: 'Meu calendário',
      ),
      const _ProfileOption(
        icon: Icons.settings_outlined,
        label: 'Configurações',
      ),
    ],
  );
}

/// Linha de estatísticas do perfil (Plantas, Dias cultivando, Guias lidos).
class _ProfileStatRow extends StatelessWidget {
  const _ProfileStatRow({required this.plantasAtivas});
  final int plantasAtivas;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Stat(value: '$plantasAtivas', label: 'Plantas ativas'),
        const _Stat(value: '12', label: 'Dias cultivando'),
        const _Stat(value: '3', label: 'Guias lidos'),
      ],
    ),
  );
}

/// Widget auxiliar para exibir uma estatística individual no perfil.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: _sage,
        ),
      ),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF718078)),
      ),
    ],
  );
}

/// Opção individual de menu nas configurações de perfil.
class _ProfileOption extends StatelessWidget {
  const _ProfileOption({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Row(
      children: [
        Icon(icon, color: _sage),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFF9BA49D)),
      ],
    ),
  );
}

/// Página de Detalhes da Planta selecionada.
class PlantDetailPage extends StatefulWidget {
  const PlantDetailPage({
    super.key,
    required this.planta,
    required this.rega,
    required this.onWaterChanged,
  });
  final Planta planta;
  final TarefaCuidado rega;
  final ValueChanged<bool> onWaterChanged;
  @override
  State<PlantDetailPage> createState() => _PlantDetailPageState();
}

// É a tela de detalhes completos de uma planta específica (neste caso, demonstrando a Alface crespa / Lactuca sativa).
class _PlantDetailPageState extends State<PlantDetailPage> {
  bool get _watered => widget.rega.status == StatusTarefa.concluida;

  void _setWatered() {
    setState(() => widget.onWaterChanged(!_watered));
  }

  Future<void> _arquivar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arquivar planta?'),
        content: const Text('A planta será removida do cultivo ativo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Arquivar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmar != true || !widget.planta.podeArquivar) return;
    widget.planta.arquivar();
    Navigator.pop(context);
  }

  Future<void> _registrarTratamento() async {
    final diagnostico = widget.planta.deficienciaAtiva;
    if (diagnostico == null) return;
    String descricao = '';
    final tratamento = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar tratamento'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tratamento aplicado'),
          onChanged: (valor) => descricao = valor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (descricao.trim().isNotEmpty) Navigator.pop(context, descricao);
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    if (!mounted || tratamento == null) return;
    setState(() => widget.planta.registrarTratamento(diagnostico, tratamento));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _canvas,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
        children: [
          Row(
            children: [
              _RoundIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              if (widget.planta.podeArquivar)
                PopupMenuButton<VoidCallback>(
                  tooltip: 'Opções da planta',
                  onSelected: (acao) => acao(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _arquivar,
                      child: const Text('Arquivar planta'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 276,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EFE0),
              borderRadius: BorderRadius.circular(29),
            ),
            child: const Center(
              child: _PlantArtwork(size: 245, potColor: _peach),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.planta.apelido,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.planta.especie.nomeCientifico.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.planta.especie.nomeCientifico,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF718078),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _HealthPill(estado: widget.planta.estado),
            ],
          ),
          if (widget.planta.estado == EstadoPlanta.comDeficiencia)
            TextButton(
              onPressed: _registrarTratamento,
              child: const Text('Registrar tratamento'),
            ),
          const SizedBox(height: 21),
          const Row(
            children: [
              _PlantMetric(
                icon: Icons.water_drop_outlined,
                label: 'Água',
                value: 'A cada 2 dias',
                color: Color(0xFF60A9D3),
              ),
              SizedBox(width: 9),
              _PlantMetric(
                icon: Icons.wb_sunny_outlined,
                label: 'Luz',
                value: 'Sol suave',
                color: Color(0xFFE6AF2B),
              ),
              SizedBox(width: 9),
              _PlantMetric(
                icon: Icons.thermostat_outlined,
                label: 'Clima',
                value: '15°–25°',
                color: _coral,
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'Próximo cuidado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F2F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFF60A9D3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _watered ? 'Regada por hoje' : 'Hora de regar',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _watered
                            ? 'O solo está recebendo água suficiente.'
                            : 'Toque o solo: ele está quase seco.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF77847C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _setWatered,
            style: FilledButton.styleFrom(
              backgroundColor: _sage,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: Icon(
              _watered ? Icons.check_rounded : Icons.water_drop_outlined,
            ),
            label: Text(
              _watered ? 'Cuidado concluído' : 'Marcar como regada',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

// É a tela de detalhes completos de uma planta específica (neste caso, demonstrando a Alface crespa / Lactuca sativa).
class _PlantMetric extends StatelessWidget {
  const _PlantMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF738078), fontSize: 10),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

/// Placeholder temporário para a tela de Scanner/Diagnóstico.
class ScannerPage extends StatefulWidget {
  const ScannerPage({
    super.key,
    required this.planta,
    required this.deficiencia,
  });

  final Planta planta;
  final Deficiencia deficiencia;
  @override
  State<ScannerPage> createState() => _ScannerPageState();
}
// Controla a tela de escaneamento de folhas (simulando a câmera do celular).
class _ScannerPageState extends State<ScannerPage> {
  Diagnostico? _diagnostico;
  bool _selecionandoResultado = false;

  Future<void> _scan() async {
    if (_diagnostico != null ||
        _selecionandoResultado ||
        !widget.planta.podeEscanear) {
      return;
    }
    _selecionandoResultado = true;
    final reavaliacao = widget.planta.estado == EstadoPlanta.emRecuperacao;
    final resultado = reavaliacao
        ? await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Resultado da reavaliação simulada'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Sem deficiência'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Deficiência persiste'),
                ),
              ],
            ),
          )
        : true;
    _selecionandoResultado = false;
    if (!mounted || resultado == null || !widget.planta.podeEscanear) return;
    final agora = DateTime.now();
    final diagnostico = widget.planta.iniciarDiagnostico(
      realizadoEm: agora,
      uri: 'horta-demo:/folha',
      capturadaEm: agora,
    );
    final deficiencia = widget.deficiencia;
    setState(() => _diagnostico = diagnostico);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      diagnostico.finalizar(
        StatusDiagnostico.falhou,
        'Escaneamento interrompido',
      );
      return;
    }
    if (resultado) {
      diagnostico.adicionarAchado(
        confianca: 0.7,
        severidade: Severidade.leve,
        recomendacao: 'Adicione composto orgânico ao solo.\n'
            'Regue sem encharcar e acompanhe por 7 dias.',
        deficiencia: deficiencia,
      );
    }
    diagnostico.finalizar(
      StatusDiagnostico.concluido,
      resultado
          ? 'Análise concluída agora'
          : 'Sem deficiência na reavaliação simulada',
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF163125),
    body: SafeArea(
      child: switch (_diagnostico) {
        final diagnostico?
            when diagnostico.status == StatusDiagnostico.emAnalise =>
          const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Analisando folha'),
          ),
        final diagnostico? when diagnostico.achados.isEmpty => Center(
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(diagnostico.observacao),
          ),
        ),
        final diagnostico? => _DiagnosisResult(
          diagnostico: diagnostico,
          onClose: () => Navigator.pop(context),
        ),
        null => _ScannerView(onScan: _scan),
      },
    ),
  );
}
// Controla a tela de escaneamento de folhas (simulando a câmera do celular).
class _ScannerView extends StatelessWidget {
  const _ScannerView({required this.onScan});
  final VoidCallback onScan;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: _CameraBackdropPainter())),
      Positioned(
        top: 12,
        left: 18,
        child: _ScannerCircle(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.pop(context),
        ),
      ),
      const Positioned(
        top: 21,
        left: 0,
        right: 0,
        child: Text(
          'Diagnóstico da planta',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
      ),
      Positioned(
        top: 12,
        right: 18,
        child: _ScannerCircle(icon: Icons.flash_on_outlined, onTap: () {}),
      ),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 272,
              height: 344,
              decoration: BoxDecoration(
                border: Border.all(color: _yellow, width: 2.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: _PlantArtwork(size: 235, potColor: Color(0xFFB16E4F)),
              ),
            ),
            const SizedBox(height: 17),
            const Text(
              'Enquadre uma folha para analisar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 30,
        child: Column(
          children: [
            const Text(
              'Aponte para uma folha com boa iluminação',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 17),
            GestureDetector(
              key: const ValueKey('scan-leaf'),
              onTap: onScan,
              child: Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  shape: BoxShape.circle,
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: _yellow,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
// Controla a tela de escaneamento de folhas (simulando a câmera do celular).
class _ScannerCircle extends StatelessWidget {
  const _ScannerCircle({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        color: Color(0x66000000),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
    ),
  );
}

// Exibe o resultado do diagnóstico após o escaneamento da folha.
class _DiagnosisResult extends StatelessWidget {
  const _DiagnosisResult({
    required this.diagnostico,
    required this.onClose,
  });
  final Diagnostico diagnostico;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: _CameraBackdropPainter())),
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.fromLTRB(23, 15, 23, 30),
          decoration: const BoxDecoration(
            color: _canvas,
            borderRadius: BorderRadius.vertical(top: Radius.circular(31)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 43,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5DAD4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 21),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5F0DF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF528747),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${diagnostico.planta.especie.nomePopular.split(' ').first} identificada',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          diagnostico.observacao,
                          style: TextStyle(
                            color: Color(0xFF77847C),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 19),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0DC),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFD68B24)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            diagnostico.achados.single.deficiencia.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            diagnostico.achados.single.deficiencia.sintomas,
                            style: TextStyle(fontSize: 12, height: 1.28),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'O que fazer agora',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              for (final (index, passo)
                  in diagnostico.achados.single.recomendacao.split('\n').indexed)
                _ResultStep(number: '${index + 1}', text: passo),
              const SizedBox(height: 17),
              FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                  backgroundColor: _sage,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Concluir',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({required this.number, required this.text});
  final String number;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: _sage, shape: BoxShape.circle),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text, style: const TextStyle(fontSize: 12.5)),
          ),
        ),
      ],
    ),
  );
}


/// Cabeçalho padrão para seções com título e botão de ação à direita.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      TextButton(
        onPressed: onAction,
        style: TextButton.styleFrom(
          foregroundColor: _sage,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          action,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

/// Botão circular contendo um ícone (usado em barras de navegação superiores e voltar).
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(width: 43, height: 43, child: Icon(icon, size: 21)),
    ),
  );
}

/// Componente gráfico vetorizado customizado para ilustrar a plantinha e o vaso.
class _PlantArtwork extends StatelessWidget {
  const _PlantArtwork({required this.size, required this.potColor});
  final double size;
  final Color potColor;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _PlantPainter(potColor)),
  );
}

/// Desenha o vaso e as folhas usando o CustomPainter.
class _PlantPainter extends CustomPainter {
  _PlantPainter(this.potColor);
  final Color potColor;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stem = Paint()
      ..color = const Color(0xFF467243)
      ..strokeWidth = w * .035
      ..strokeCap = StrokeCap.round;
    final dark = Paint()..color = const Color(0xFF4F874A);
    final mid = Paint()..color = const Color(0xFF70A966);
    final light = Paint()..color = const Color(0xFF9FC88B);
    final pot = Paint()..color = potColor;
    final soil = Paint()..color = const Color(0xFF70503D);
    final baseY = h * .80;
    canvas.drawLine(Offset(w * .5, baseY), Offset(w * .50, h * .25), stem);
    final leaves = <(Offset, double, double, Paint)>[
      (Offset(w * .48, h * .40), -.92, .34, dark),
      (Offset(w * .51, h * .46), -.45, .38, mid),
      (Offset(w * .50, h * .35), .13, .38, light),
      (Offset(w * .52, h * .49), .55, .39, dark),
      (Offset(w * .49, h * .57), .92, .31, mid),
      (Offset(w * .49, h * .55), -1.28, .29, light),
      (Offset(w * .50, h * .27), -.20, .29, mid),
    ];
    for (final leaf in leaves) {
      canvas.save();
      canvas.translate(leaf.$1.dx, leaf.$1.dy);
      canvas.rotate(leaf.$2);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(w * leaf.$3, -h * .10, w * leaf.$3, -h * .26)
        ..quadraticBezierTo(w * .05, -h * .25, 0, 0);
      canvas.drawPath(path, leaf.$4);
      canvas.restore();
    }
    final potPath = Path()
      ..moveTo(w * .29, h * .76)
      ..lineTo(w * .71, h * .76)
      ..lineTo(w * .64, h * .94)
      ..quadraticBezierTo(w * .5, h, w * .36, h * .94)
      ..close();
    canvas.drawPath(potPath, pot);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .25, h * .72, w * .5, h * .09),
        Radius.circular(w * .03),
      ),
      pot,
    );
    canvas.drawOval(Rect.fromLTWH(w * .29, h * .735, w * .42, h * .035), soil);
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) =>
      oldDelegate.potColor != potColor;
}

class _CameraBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF142E22), Color(0xFF4F7851)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    final leafPaint = Paint()
      ..color = const Color(0xFF82AD70).withValues(alpha: .45);
    for (var i = 0; i < 8; i++) {
      final x = (i % 3) * size.width / 3 + 10;
      final y = (i ~/ 3) * size.height / 3 + 50;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i * .52);
      canvas.drawOval(Rect.fromLTWH(-18, -66, 44, 132), leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
