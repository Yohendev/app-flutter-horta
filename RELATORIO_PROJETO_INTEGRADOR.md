# Relatório do Projeto Integrador: Aplicativo Horta em Casa (Horta)

**Data de Entrega / Apresentação:** Quarta-feira, 04/11  
**Tecnologia Principal:** Flutter / Dart (Multiplataforma: Android e Desktop/Windows)  
**Tema Integrador:** Agricultura Urbana, Sustentabilidade Doméstica e Monitoramento Inteligente de Cultivo  

---

## 1. Visão Geral e Contexto Acadêmico

O projeto **Horta** é um aplicativo mobile desenvolvido em Flutter que tem como objetivo auxiliar pessoas a cultivar hortaliças e plantas em ambientes domésticos, mesmo sem experiência prévia. O aplicativo aborda as principais dores do cultivo caseiro: esquecimento da rotina de rega, dúvidas sobre luminosidade e temperatura, e a dificuldade em identificar carências nutricionais ou pragas que afetam as folhas.

No contexto do **Projeto Integrador**, o aplicativo unifica competências de múltiplas disciplinas do curso:

| Disciplina Envolvida | Aplicação Prática no Projeto Horta |
| :--- | :--- |
| **Engenharia de Requisitos & Modelagem de Software** | Levantamento de atores, especificação de casos de uso (UC-01 a UC-10), detalhamento do caso de uso crítico (UC-07) e diagramas UML (PlantUML). |
| **Arquitetura de Software** | Adoção do estilo arquitetural em camadas (*Layered Architecture*), justificado pelos atributos de manutenibilidade, testabilidade e baixo acoplamento. |
| **Desenvolvimento Mobile & Multiplataforma** | Construção da interface com Flutter 3 e Material 3, gerenciamento de estado reativo, suporte para compilação Android (APK) e Windows. |
| **Design de Interação e Experiência do Usuário (UI/UX)** | Criação de um *Design System* próprio com paleta botânica suave, micro-interações, ilustrações vetoriais procedurais e navegação ergonômica com *BottomAppBar* e botão central (*FloatingActionButton*). |
| **Testes e Qualidade de Software** | Testes automatizados de widgets em Flutter, validação de integridade estática (`flutter analyze`) e higienização de versionamento (`.gitignore`). |
| **Sustentabilidade e Inovação** | Fomento à segurança alimentar urbana, redução de desperdício e auxílio no diagnóstico precoce de deficiências de solo e nutrientes. |

---

## 2. Identidade Visual e Design System

O design do aplicativo foi cuidadosamente projetado para transmitir calma, contato com a natureza e acolhimento ao usuário iniciante, mantendo alto contraste e legibilidade.

### 2.1. Paleta de Cores Oficial

| Amostra | Código Hex | Constante | Finalidade / Aplicação |
| :---: | :--- | :--- | :--- |
| 🟨 | `#FFE04E` | `_yellow` | Cor secundária / Destaques de ação, retícula de escaneamento, botão de captura e tags solares. |
| 🟩 | `#97BA7F` | `_sage` | Cor primária botânica, barra de navegação, botão flutuante de scanner (FAB), botões de confirmação e pílulas de saúde. |
| 🪸 | `#F9998D` | `_coral` | Destaque quente para alertas, métricas de clima/temperatura e ilustrações secundárias. |
| 🍑 | `#F6A882` | `_peach` | Tons terrosos / acolhedores para avatares, vasos de plantas e elementos de suporte. |
| 🌲 | `#23352B` | `_ink` | Cor de tinta/texto de alto contraste sobre superfícies claras, garantindo excelente leitura. |
| 📄 | `#F8F8F3` | `_canvas` | Fundo principal da aplicação (*off-white* suave), evitando cansaço visual. |
| ⚪ | `#FFFFFF` | `Colors.white` | Superfície de cartões, fundos de listas e elementos de navegação inferior. |

### 2.2. Diretrizes de UI e Ergonomia (Regra de Ouro para Próximos Desenvolvimentos)
- **Bordas Arredondadas Orgânicas:** Cards com raios entre `16px` e `31px`, reforçando a sensação de suavidade e modernidade.
- **Micro-interações Intuitivas:** Alternância rápida entre status pendente e concluído (ex: interruptor de rega na tela inicial e botão de toque na tela de detalhes).
- **Ilustrações Vetoriais Nativas (`CustomPainter`):** Toda a arte botânica (`_PlantPainter`) e o plano de fundo do scanner (`_CameraBackdropPainter`) foram desenvolvidos em código puro Dart/Canvas, sem dependência de imagens externas ou arquivos pesados, garantindo leveza, escalabilidade em qualquer resolução e funcionamento offline imediato.
- **Navegação com Entalhe Circular (*Docked FloatingActionButton*):** Barra inferior com recorte anatômico para abrigar o botão de scanner com elevação equilibrada.
- **Diagrama Estrutural do Código:** Mapeamento completo da árvore de widgets, navegação e herança documentado em [`Diagramas/06-diagrama-de-componentes-codigo.md`](Diagramas/06-diagrama-de-componentes-codigo.md).

---

## 3. Estrutura do Código e Funcionalidades Implementadas

O código-fonte principal reside em [`lib/main.dart`](file:///C:/Users/Yu/Desktop/Antigravity/horta/lib/main.dart) (1.775 linhas), estruturado com widgets modulares e reutilizáveis:

### 3.1. Telas do Aplicativo

#### A. Painel Inicial (`HomePage`)
- **Cabeçalho personalizado:** Saudação contextualizada ("Bom dia, Júlia"), avatar do usuário e atalho para notificações.
- **Card de Inspiração (`_WelcomeCard`):** Mensagem de boas-vindas com gradiente suave e ícones de clima.
- **Cultivo em Foco (`_PlantOverviewCard`):** Card em destaque da "Alface crespa", acompanhado de tags informativas ("Hortaliça", "Fácil"), tempo de cultivo e indicador de saúde.
- **Rotina de Cuidados (`_CareTask`):** Seção de tarefas diárias com controle interativo:
  - Rega com switch funcional: alternar para "Alface regada" atualiza o estado imediatamente na UI.
  - Verificação de luz solar matinal.
- **Chamada de Ação do Scanner (`_ScanCallout`):** Banner convidativo para diagnóstico rápido da horta.

#### B. Catálogo e Minhas Plantas (`PlantsPage`)
- Visualização em lista/grid das espécies em cultivo ativo.
- Card de detalhamento rápido com badge de status ("Saudável").
- Ação interativa para adicionar novas plantas (`_AddPlantCard`), já integrada com feedback visual de *SnackBar*.
- Seção "Lista de Desejos" (`_WishlistRow`), introduzindo próximas espécies sugeridas para cultivo (ex: Tomate-cereja).

#### C. Guia de Cuidados (`CareGuidePage`)
- **Destaque da Semana (`_TipHero`):** Dica especial ("Colha as folhas externas primeiro") com gradiente verde vivo e ilustração de planta.
- **Trilhas de Aprendizado (`_GuideTile`):** Módulos práticos numerados (01: Rega sem excesso, 02: Luz ideal, 03: Identificação de folhas bonitas e saudáveis).

#### D. Perfil do Jardineiro (`ProfilePage`)
- Resumo do usuário com nível ("Jardineira iniciante").
- **Métricas de Engajamento (`_ProfileStatRow`):** Contadores de plantas ativas, dias cultivando e guias concluídos.
- Opções e preferências: Lembretes de cuidado, calendário de plantio e configurações do app.

#### E. Detalhe da Planta (`PlantDetailPage`)
- Exibição destacada da planta com arte vetorial em escala ampliada.
- Nomenclatura botânica completa: Nome popular e nome científico (*Lactuca sativa*).
- **Métricas de Manejo (`_PlantMetric`):**
  - Frequência de irrigação ("A cada 2 dias").
  - Exposição solar recomendada ("Sol suave").
  - Faixa térmica ideal ("15°–25°C").
- **Ação de Manejo:** Botão de ação direta "Marcar como regada" / "Cuidado concluído", sincronizado bidirecionalmente com o painel inicial.

#### F. Scanner & Diagnóstico de Deficiências Foliar (`ScannerPage`)
- **Interface do Scanner (`_ScannerView`):**
  - Retícula retangular dourada centralizada com instruções de enquadramento da folha.
  - Controles de lanterna/flash e botão circular central de captura.
  - Backdrop vetorial estilizado simulando folhagens em campo de visão.
- **Painel de Diagnóstico (`_DiagnosisResult`):**
  - Identificação botânica confirmada ("Alface identificada").
  - Identificação de carência nutricional: **"Possível falta de nitrogênio"**, explicando que folhas inferiores amareladas indicam baixa disponibilidade de N.
  - Plano de ação em etapas ("O que fazer agora"):
    1. Adição de composto orgânico ao solo.
    2. Ajuste na frequência de rega e monitoramento por 7 dias.
  - Botão de encerramento para salvar o diagnóstico no histórico.

---

## 4. Engenharia de Software e Modelagem UML

O projeto foi totalmente documentado de acordo com a modelagem orientada a objetos na pasta [`Diagramas/`](file:///C:/Users/Yu/Desktop/Antigravity/horta/Diagramas/):

### 4.1. Atores do Sistema
1. **Jardineiro (Ator Primário):** Usuário humano responsável pela horta e pelas ações de manejo.
2. **Câmera do Dispositivo (Ator Secundário/Hardware):** Dispositivo responsável pela aquisição da foto foliar.
3. **Serviço Externo de IA (Ator Secundário/Sistema):** Responsável pelo processamento visual e inferência fitossanitária.
4. **Serviço de Notificações (Ator Secundário/Sistema):** Emissor de alertas e lembretes periódicos de rega e colheita.

### 4.2. Casos de Uso Identificados
- **UC-01:** Consultar painel da horta
- **UC-02:** Gerenciar plantas
- **UC-03:** Consultar detalhes da planta
- **UC-04:** Registrar cuidado realizado
- **UC-05:** Consultar guia de cuidados
- **UC-06:** Escanear folha (`<<include>>` UC-07)
- **UC-07:** Diagnosticar saúde da planta por imagem (Caso de Uso Crítico, `<<include>>` UC-08)
- **UC-08:** Salvar diagnóstico
- **UC-09:** Configurar lembretes
- **UC-10:** Receber lembrete de cuidado

### 4.3. Detalhamento do Caso de Uso Crítico (UC-07)
- **Objetivo:** Fornecer diagnóstico orientativo seguro a partir de foto da folha.
- **Tratamento de Exceções:** Falta de permissão de câmera (A1), foto fora de foco/baixa luz (A2), indisponibilidade de internet/IA (A3), espécie não identificada (A4) e folha 100% sadia (A5).
- **Regras de Negócio:** Cada diagnóstico é uma ocorrência imutável no histórico; recomendações possuem caráter orientativo sem substituir laudos agronômicos profissionais.

### 4.4. Modelo de Domínio e Entidades
O diagrama de classes modela as 10 entidades essenciais:
- `Jardineiro` (1) $\rightarrow$ Mantém $\rightarrow$ (0..*) `Horta`
- `Horta` (1) $\rightarrow$ Contém [Composição] $\rightarrow$ (0..*) `Planta`
- `Planta` (0..*) $\rightarrow$ É da espécie $\rightarrow$ (1) `EspeciePlanta`
- `Planta` (1) $\rightarrow$ Possui [Composição] $\rightarrow$ (0..*) `TarefaCuidado`
- `Planta` (1) $\rightarrow$ Histórico [Composição] $\rightarrow$ (0..*) `Diagnostico`
- `Diagnostico` (1) $\rightarrow$ Origem [Composição] $\rightarrow$ (1) `ImagemEscaneada`
- `Diagnostico` (1) $\rightarrow$ Produz [Composição] $\rightarrow$ (0..*) `AchadoDiagnostico`
- `AchadoDiagnostico` (0..*) $\rightarrow$ Aponta para $\rightarrow$ (1) `Deficiencia`
- `EspeciePlanta` (0..*) $\rightarrow$ Recomenda $\rightarrow$ (0..*) `GuiaCuidado`

### 4.5. Diagrama de Sequência e Integração
Representa o ciclo de vida da requisição entre `Jardineiro`, `App Flutter`, `Câmera do dispositivo`, `Repositório de dados` e `Serviço externo de IA`, cobrindo os cenários de sucesso, análise inconclusiva e falha de comunicação com fallback gracioso.

### 4.6. Diagrama de Estados da Entidade `Planta`
Estados modelados: `Cadastrada` $\rightarrow$ `Saudavel` $\rightleftharpoons$ `PrecisaDeCuidado` $\rightarrow$ `EmDiagnostico` $\rightarrow$ `ComDeficiencia` $\rightarrow$ `EmRecuperacao` $\rightarrow$ `Arquivada`.

---

## 5. Arquitetura de Software Escolhida

Em consonância com as diretrizes da disciplina de **Arquitetura de Software** (Aula 07 — Arquitetura de Software e Atributos de Qualidade), foi selecionado o padrão **Arquitetura em Camadas** (*Layered Architecture*).

### 5.1. Separação de Responsabilidades por Camada
1. **Camada de Apresentação (*Presentation Layer*):**
   - Composta por widgets Flutter, navegação (*routing*), controladores de interface e feedback visual imediato.
2. **Camada de Aplicação (*Application Layer*):**
   - Casos de uso e serviços orquestradores (ex: `RegistrarCuidadoUseCase`, `EscanearFolhaUseCase`, `SalvarDiagnosticoUseCase`).
3. **Camada de Domínio (*Domain Layer*):**
   - Entidades puras, regras de negócio e interfaces de repositórios (independente de frameworks ou bibliotecas de terceiros).
4. **Camada de Infraestrutura (*Infrastructure Layer*):**
   - Acesso à câmera nativa do sistema operacional, banco de dados local (SQLite/Preferences), APIs de IA em nuvem e agendador de notificações do sistema operacional.

### 5.2. Justificativa Baseada em Atributos de Qualidade
- **Manutenibilidade:** A inclusão de novas espécies botânicas, novas regras de rega ou tipos de deficiências não exige refatoração das telas ou do design.
- **Testabilidade:** As regras de negócio do cultivo e a lógica de diagnóstico podem ser testadas por testes unitários sem necessidade de simular telas ou instanciar a câmera física.
- **Desacoplamento e Resiliência:** Isola serviços externos suscetíveis a falhas (ex: serviço de visão computacional na nuvem). Se a conexão cair, a aplicação mantém pleno funcionamento do catálogo, dos guias e das tarefas de rega.

---

## 6. Verificação, Testes e Qualidade

- **Análise Estática de Código:** Verificação via `flutter analyze --no-pub` sem nenhum erro ou pendência.
- **Testes Automatizados:** Implementados em [`test/widget_test.dart`](file:///C:/Users/Yu/Desktop/Antigravity/horta/test/widget_test.dart):
  - `shows the garden dashboard`: Garante a renderização dos títulos "Sua horta", "Alface crespa" e "Cuidados de hoje".
  - `opens the plant detail`: Simula o clique na planta e verifica a abertura da tela de detalhes com métricas de rega.
- **Versionamento Seguro:** Arquivo [`.gitignore`](file:///C:/Users/Yu/Desktop/Antigravity/horta/.gitignore) atualizado com exclusões de builds Gradle, pastas locais de Android SDK (`local.properties`), chaves de assinatura (`key.properties`) e caches transitórios do Flutter.

---

## 7. Estado Atual do Protótipo vs. Próximos Passos (Roadmap)

| Componente | Situação Atual (Entregue para 04/11) | Próxima Etapa de Evolução |
| :--- | :--- | :--- |
| **Interface e Design** | 100% implementada no padrão visual aprovado, responsiva e com interações de teste. | Expansão de telas para cadastro dinâmico de novas espécies. |
| **Scanner de Folha** | Protótipo visual completo e interativo com simulação de diagnóstico foliar. | Conexão do fluxo à câmera física do dispositivo via plugin `camera`. |
| **Diagnóstico de Deficiências** | Regras de deficiência de Nitrogênio simuladas com orientação real de manejo. | Integração com modelo de classificação por IA (ex: Gemini Vision API ou TensorFlow Lite). |
| **Persistência de Dados** | Estados em memória (reativos durante a sessão). | Persistência local com SQLite (`sqflite` ou `drift`) ou armazenamento chave-valor. |
| **Notificações** | Mock visual no perfil e na home. | Integração com `flutter_local_notifications` para alarmes de irrigação. |

---

## 8. Diretriz de Continuidade de Design

> **Compromisso de Design:** Quaisquer implementações ou ampliações de código solicitadas daqui para frente manterão estritamente o mesmo padrão estético já estabelecido no projeto:
> - Respeito integral à paleta de cores (`#FFE04E`, `#97BA7F`, `#F9998D`, `#F6A882`, `#23352B`, `#F8F8F3`, `#FFFFFF`);
> - Cartões arredondados com geometria orgânica;
> - Tipografia limpa com hierarquia bem marcada;
> - Desenhos e detalhes botânicos consistentes com a identidade já aprovada.
