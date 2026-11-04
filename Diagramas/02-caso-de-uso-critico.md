# Caso de uso crítico - Diagnosticar saúde da planta

| Campo | Descrição |
| --- | --- |
| Identificador | UC-07 |
| Nome | Diagnosticar saúde da planta por imagem |
| Objetivo | Identificar a planta e possíveis deficiências em uma folha fotografada, apresentando orientações seguras ao jardineiro. |
| Ator primário | Jardineiro |
| Atores de apoio | Câmera do dispositivo e Serviço externo de IA. |
| Gatilho | O jardineiro toca no botão de escaneamento no aplicativo. |
| Pré-condições | O aplicativo está aberto; há permissão para usar a câmera; há conexão com a internet para a análise real. |
| Pós-condições de sucesso | A imagem, o resultado e as recomendações são associados à planta e ficam disponíveis no histórico de diagnósticos. |
| Pós-condições de falha | Nenhum diagnóstico é salvo como concluído; o aplicativo informa o motivo e permite uma nova tentativa. |

## Fluxo principal de sucesso

1. O jardineiro escolhe **Escanear folha**.
2. O sistema abre a câmera e orienta o enquadramento da folha em boa iluminação.
3. O jardineiro captura a imagem e confirma o envio.
4. O sistema cria um diagnóstico com estado **Em análise** e associa a imagem capturada.
5. O sistema envia a imagem ao serviço externo de IA.
6. O serviço identifica a espécie ou confirma a espécie já selecionada e retorna as evidências encontradas.
7. O sistema registra cada deficiência identificada, incluindo grau de confiança, severidade e recomendação.
8. O sistema atualiza a situação de saúde da planta.
9. O sistema mostra o resultado, por exemplo, “possível falta de nitrogênio”, e os próximos passos de cuidado.
10. O jardineiro salva ou fecha o resultado; o diagnóstico permanece no histórico da planta.

## Fluxos alternativos e exceções

| Código | Situação | Resposta do sistema |
| --- | --- | --- |
| A1 | Permissão da câmera negada | Explica que a câmera é necessária e oferece abrir as configurações ou cancelar. |
| A2 | Foto sem qualidade suficiente | Solicita nova foto, indicando iluminação ou foco insuficientes; nada é enviado para análise. |
| A3 | Sem conexão ou serviço de IA indisponível | Mantém o diagnóstico como **Falhou**, informa que não foi possível analisar e permite tentar novamente. |
| A4 | Planta não identificada | Exibe o resultado como inconclusivo e permite que o jardineiro escolha a espécie manualmente ou recapture a foto. |
| A5 | Nenhuma deficiência detectada | Salva o diagnóstico como saudável e mantém a planta no estado **Saudável**. |

## Regras de negócio

- Uma imagem deve pertencer a exatamente um diagnóstico.
- Um diagnóstico concluído pertence a exatamente uma planta e pode possuir zero ou mais achados.
- Um achado aponta para uma deficiência cadastrada e deve registrar sua severidade e confiança.
- O resultado é uma orientação de cuidado; não substitui orientação agronômica profissional em caso de risco ou perda de cultivo.
- O histórico não deve ser apagado ao realizar um novo escaneamento; cada diagnóstico é uma ocorrência independente.
