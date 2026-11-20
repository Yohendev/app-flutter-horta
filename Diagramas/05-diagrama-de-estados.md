# Diagrama de estados - Planta

`Horta.plantar` cadastra e inclui a planta no cultivo na mesma operação. O
estado `Cadastrada` é transitório. Tarefas pendentes contam como vencidas a
partir do horário previsto, na consulta ao estado.

O UML de referência retorna a `Saudavel` após um resultado inconclusivo.
A implementação mantém o resultado como inconclusivo e aplica a regra de
cuidados vencidos também após uma análise sem deficiência. Se houver pendências,
o destino é `PrecisaDeCuidado`. A mesma verificação vale após uma recuperação
confirmada. Falhas de processamento encerram a análise sem aplicar um resultado
de saúde. Uma reavaliação inconclusiva ou com falha mantém `EmRecuperacao`.
Reabrir uma tarefa vencida produz o mesmo efeito que seu vencimento.

O arquivamento preserva os objetos na horta durante a sessão e os retira do
cultivo ativo. Os dados usam o armazenamento em memória do aplicativo.

```plantuml
@startuml
[*] --> Cadastrada
Cadastrada --> Saudavel : planta adicionada ao cultivo
Saudavel --> PrecisaDeCuidado : tarefa pendente vence ou é reaberta já vencida
PrecisaDeCuidado --> Saudavel : última tarefa vencida concluída

Saudavel --> EmDiagnostico : escaneamento iniciado
PrecisaDeCuidado --> EmDiagnostico : escaneamento iniciado
EmDiagnostico --> Saudavel : sem deficiência, inconclusivo ou falha [sem cuidado vencido]
EmDiagnostico --> PrecisaDeCuidado : sem deficiência, inconclusivo ou falha [com cuidado vencido]
EmDiagnostico --> ComDeficiencia : deficiência identificada

ComDeficiencia --> EmRecuperacao : tratamento registrado
EmRecuperacao --> Saudavel : reavaliação sem deficiência [sem cuidado vencido]
EmRecuperacao --> PrecisaDeCuidado : reavaliação sem deficiência [com cuidado vencido]
EmRecuperacao --> ComDeficiencia : deficiência persiste
note right of EmRecuperacao
  Reavaliação em curso, inconclusiva ou com falha
  mantém o estado.
end note

Saudavel --> Arquivada : planta removida do cultivo
PrecisaDeCuidado --> Arquivada : planta removida do cultivo
ComDeficiencia --> Arquivada : planta removida do cultivo
EmRecuperacao --> Arquivada : planta removida do cultivo
Arquivada --> [*]
@enduml
```
