# Diagrama de casos de uso - Horta

> O app Flutter atual possui navegação, planta inicial, registro visual de rega, guia e diagnóstico demonstrativo. Câmera real, persistência, notificações e IA são integrações previstas para transformar esse fluxo em funcionalidade completa.

## Atores identificados

| Ator | Responsabilidade |
| --- | --- |
| Jardineiro | Acompanha a própria horta e toma decisões de cuidado. |
| Câmera do dispositivo | Fornece a imagem da folha durante o escaneamento. |
| Serviço externo de IA | Identifica a planta e analisa possíveis deficiências na imagem. |
| Serviço de notificações | Entrega lembretes de cuidado agendados pelo sistema. |

```plantuml
@startuml
left to right direction
skinparam actorStyle awesome

actor "Jardineiro" as J
actor "Câmera do dispositivo" as C
actor "Serviço externo de IA" as IA
actor "Serviço de notificações" as N

rectangle "Aplicativo Horta" {
  usecase "Consultar painel da horta" as UC1
  usecase "Gerenciar plantas" as UC2
  usecase "Consultar detalhes da planta" as UC3
  usecase "Registrar cuidado realizado" as UC4
  usecase "Consultar guia de cuidados" as UC5
  usecase "Escanear folha" as UC6
  usecase "Diagnosticar saúde da planta" as UC7
  usecase "Salvar diagnóstico" as UC8
  usecase "Configurar lembretes" as UC9
  usecase "Receber lembrete de cuidado" as UC10
}

J -- UC1
J -- UC2
J -- UC3
J -- UC4
J -- UC5
J -- UC6
J -- UC8
J -- UC9
J -- UC10
C -- UC6
IA -- UC7
N -- UC10

UC6 .> UC7 : <<include>>
UC7 .> UC8 : <<include>>
@enduml
```
