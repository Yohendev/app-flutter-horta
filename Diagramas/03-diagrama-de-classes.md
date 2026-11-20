# Diagrama de classes - Horta

Os modelos estão em [modelos_horta.dart](../lib/modelos_horta.dart). O app mantém os objetos em memória durante a sessão. Os identificadores são UUID v4 armazenados como `String`, e `dataPlantio` guarda uma data civil em `DateTime` à meia-noite local. A confiança é uma proporção entre 0 e 1. O scanner de demonstração usa uma URI simbólica e valores fictícios de confiança e severidade.

```plantuml
@startuml
skinparam classAttributeIconSize 0

class Jardineiro {
  +id: String {UUID v4}
  +nome: String
  +email: String
}
class Horta {
  +id: String {UUID v4}
  +nome: String
  +plantasAtivas: Iterable<Planta>
}
class Planta {
  +id: String {UUID v4}
  +apelido: String
  +dataPlantio: DateTime
  +statusSaude: StatusSaude {derivado}
  +estado: EstadoPlanta {derivado}
  +iniciarDiagnostico(): Diagnostico
  +registrarTratamento(diagnostico, descricao): Tratamento
  +arquivar(): void
}
class EspeciePlanta {
  +id: String {UUID v4}
  +nomePopular: String
  +nomeCientifico: String
}
class TarefaCuidado {
  +id: String {UUID v4}
  +tipo: TipoCuidado
  +previstaPara: DateTime
  +status: StatusTarefa
  +concluidaEm: DateTime?
}
class GuiaCuidado {
  +id: String {UUID v4}
  +titulo: String
  +conteudo: String
  +categoria: TipoCuidado
}
class Diagnostico {
  +id: String {UUID v4}
  +realizadoEm: DateTime
  +status: StatusDiagnostico
  +observacao: String
  +finalizar(resultado, observacao): void
}
class Tratamento {
  +id: String {UUID v4}
  +descricao: String
  +registradoEm: DateTime
}
class ImagemEscaneada {
  +id: String {UUID v4}
  +uri: String
  +capturadaEm: DateTime
}
class AchadoDiagnostico {
  +id: String {UUID v4}
  +confianca: double
  +severidade: Severidade
  +recomendacao: String
}
class Deficiencia {
  +id: String {UUID v4}
  +nome: String
  +sintomas: String
}

enum StatusSaude {
  saudavel
  precisaDeCuidado
  comDeficiencia
  emRecuperacao
}
enum EstadoPlanta {
  cadastrada
  saudavel
  precisaDeCuidado
  emDiagnostico
  comDeficiencia
  emRecuperacao
  arquivada
}
enum TipoCuidado {
  rega
  luz
  nutricao
}
enum StatusTarefa {
  pendente
  concluida
}
enum StatusDiagnostico {
  emAnalise
  concluido
  inconclusivo
  falhou
}
enum Severidade {
  leve
  moderada
  grave
}

Jardineiro "1" -- "0..*" Horta : mantém
Horta "1" *-- "0..*" Planta : contém
Planta "0..*" -- "1" EspeciePlanta : pertence à espécie
Planta "1" *-- "0..*" TarefaCuidado : possui
Planta "1" *-- "0..*" Diagnostico : histórico
Planta "1" *-- "0..*" Tratamento : histórico
Tratamento "0..*" --> "1" Diagnostico : trata
Diagnostico "1" *-- "1" ImagemEscaneada : usa como origem
Diagnostico "1" *-- "0..*" AchadoDiagnostico : produz
AchadoDiagnostico "0..*" -- "1" Deficiencia : aponta para
EspeciePlanta "0..*" -- "0..*" GuiaCuidado : recomenda

Planta ..> StatusSaude
Planta ..> EstadoPlanta
TarefaCuidado ..> TipoCuidado
TarefaCuidado ..> StatusTarefa
GuiaCuidado ..> TipoCuidado
Diagnostico ..> StatusDiagnostico
AchadoDiagnostico ..> Severidade
@enduml
```
