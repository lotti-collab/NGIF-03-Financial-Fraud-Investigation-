# NGIF-03 — Do CSV ao grafo: investigando redes de fraude financeira com Neo4j e Graph Intelligence

**Autor:** Alexandre Lotti  
**Framework:** Noxtron Graph Intelligence Framework (NGIF)  
**Projeto:** NGIF-03 — Financial Fraud Investigation  
**Tecnologias:** Python, pandas, Neo4j, Cypher e Neo4j Graph Data Science (GDS)

> **O grafo não acusa: ele organiza conexões para que a investigação faça as perguntas certas.**

---

## 1. Visão geral

Fraudes financeiras organizadas podem envolver múltiplas contas, transferências, dispositivos e diferentes padrões de relacionamento. Quando cada transação é analisada isoladamente, parte do contexto relacional pode passar despercebida.

O NGIF-03 explora como a modelagem em grafos pode contribuir para a investigação de transações financeiras, identificando concentrações de conexões, estruturas de relacionamento e padrões de distribuição de valores.

O projeto utiliza dados sintéticos do PaySim, preparados em Python e pandas, e uma representação em grafo no Neo4j. As análises combinam consultas Cypher e algoritmos do Neo4j Graph Data Science.

O objetivo não é declarar que uma conta ou comunidade é fraudulenta, mas demonstrar como a estrutura relacional pode gerar hipóteses investigativas verificáveis.

### Objetivos

- Modelar transações financeiras como um grafo.
- Identificar contas que concentram transferências.
- Explorar caminhos temporais entre transferências e saques.
- Detectar agrupamentos estruturais com Louvain.
- Comparar conectividade e relevância estrutural usando Degree e PageRank.
- Quantificar a concentração financeira por origem usando HHI e participação Top 3.
- Preparar indicadores que possam ser avaliados posteriormente em modelos de Machine Learning.

## 2. Dados e preparação

### Fonte dos dados

O projeto utiliza o **PaySim**, um conjunto de dados sintéticos que simula transações de dinheiro móvel.

A exploração inicial identificou:

| Indicador | Resultado |
|---|---:|
| Transações no conjunto original | 6.362.620 |
| Colunas | 11 |
| Valores ausentes | 0 |
| Linhas duplicadas | 0 |
| Transações rotuladas como fraude | 8.213 |
| Proporção de transações rotuladas como fraude | Aproximadamente 0,1291% |
| Horizonte temporal | 744 passos, equivalentes a aproximadamente 30 dias |

No PaySim, `step` representa intervalos de uma hora. As variáveis `nameOrig` e `nameDest` identificam a origem e o destino registrados para cada transação.

Os rótulos `isFraud` são simulados. Portanto, representam a classificação disponibilizada pelo conjunto de dados, não uma conclusão produzida pela investigação.

### Preparação e seleção

A exploração inicial foi realizada com Python e pandas. As colunas de saldo foram excluídas da análise antifraude principal, considerando as particularidades da simulação e os cancelamentos associados aos eventos fraudulentos.

A investigação relacional selecionou um subgrafo de 209 transações, armazenado no arquivo:

`NGIF03_subgrafo_contas.csv`

O arquivo contém:

- `tx_id`
- `step`
- `type`
- `source_account`
- `target_account`
- `amount`
- `isFraud`
- `isFlaggedFraud`

A seleção reduz o escopo da análise e permite concentrar a investigação em estruturas identificadas durante a exploração anterior.

**Limitação:** os resultados apresentados neste projeto referem-se ao subgrafo selecionado, não ao universo completo de transações do PaySim.

## 3. Modelagem no Neo4j

A estrutura de dados utiliza três elementos principais:

- `Account`: conta de origem ou destino registrado.
- `Transaction`: evento de transação financeira.
- `SENT`: relacionamento entre a conta de origem e a transação.
- `RECEIVED_BY`: relacionamento entre a transação e a conta de destino registrada.

Representação:

```text
(:Account)-[:SENT]->(:Transaction)-[:RECEIVED_BY]->(:Account)
```

Cada transação mantém atributos como identificador, horário lógico, tipo, valor e rótulos disponíveis.

### Restrições de unicidade

```cypher
CREATE CONSTRAINT account_id IF NOT EXISTS
FOR (a:Account)
REQUIRE a.id IS UNIQUE;

CREATE CONSTRAINT transaction_id IF NOT EXISTS
FOR (t:Transaction)
REQUIRE t.tx_id IS UNIQUE;
```

### Importação do CSV

O arquivo foi importado por meio de `LOAD CSV WITH HEADERS`, criando as contas e as transações e estabelecendo os relacionamentos correspondentes.

A estrutura resultante contém:

| Elemento | Quantidade |
|---|---:|
| Nós `Account` | 214 |
| Nós `Transaction` | 209 |
| Transações selecionadas | 209 |

O identificador da transação foi convertido para inteiro durante a importação. Os campos numéricos foram tipados explicitamente para possibilitar agregações e análises posteriores.

> A relação `RECEIVED_BY` representa o destino registrado no conjunto de dados. Sua presença não deve ser interpretada automaticamente como confirmação de recebimento econômico ou rastreamento integral dos recursos.

## 4. Identificação de intermediários

A exploração das transferências identificou cinco contas que concentram múltiplas origens distintas.

| Conta intermediária | Origens distintas | Transferências | Volume registrado |
|---|---:|---:|---:|
| C874023329 | 12 | 12 | R$ 20.869.851,39 |
| C418053001 | 9 | 9 | R$ 5.315.128,82 |
| C2097141675 | 7 | 7 | R$ 10.269.864,62 |
| C2088638273 | 6 | 6 | R$ 3.751.366,50 |
| C1598002267 | 5 | 5 | R$ 2.617.583,31 |
| **Total** | **39** | **39** | **R$ 42.823.794,64** |

Os valores correspondem à soma dos montantes das transferências selecionadas associadas a cada destino.

A concentração de origens e de valores foi utilizada como critério exploratório para priorizar estruturas que merecem análise contextual.

Esses indicadores não constituem, isoladamente, evidência de fraude.

## 5. Análise temporal de caminhos

Uma das consultas investigou caminhos com a seguinte estrutura:

```text
Conta de origem
    → TRANSFER
    → Conta intermediária
    → CASH_OUT
    → Destino registrado
```

A condição temporal exigiu que a transferência ocorresse antes do saque:

```cypher
WHERE tr.step < saque.step
```

### Resultados observados

| Intermediário | Caminhos encontrados | Transferências | Saques distintos | Intervalo médio entre transferência e saque |
|---|---:|---:|---:|---:|
| C874023329 | 9 | 9 | 1 | 31,67 horas |
| C418053001 | 6 | 6 | 1 | 138,67 horas |
| C2097141675 | 6 | 6 | 1 | 137,33 horas |
| C2088638273 | 6 | 6 | 1 | 447,50 horas |
| C1598002267 | 5 | 5 | 1 | 179,60 horas |
| **Total** | **32** | **32** | **5** | — |

A análise encontrou 32 caminhos temporais associados a cinco intermediários. Nenhuma das transferências ou dos saques desses caminhos estava rotulada como fraude.

O intervalo é calculado a partir dos passos temporais das transações. Ele não comprova que os mesmos recursos transferidos foram utilizados no saque posterior: dinheiro é fungível, e os saldos foram excluídos da análise principal.

Assim, os caminhos identificam sequências relacionais que podem orientar perguntas investigativas, sem demonstrar causalidade ou fluxo financeiro rastreado.

## 6. Neo4j Graph Data Science

A projeção `ngif03_transfer` foi construída com os nós `Account` e os relacionamentos correspondentes às transações do tipo `TRANSFER`.

| Indicador da projeção | Resultado |
|---|---:|
| Nós | 214 |
| Relacionamentos de transferência originais | 39 |
| Relacionamentos após conversão para duas direções | 78 |

A projeção foi utilizada para explorar conectividade, relevância estrutural e comunidades.

### 6.1. Degree

O Degree foi utilizado para medir a quantidade de conexões de entrada e saída na projeção.

Para os cinco intermediários, os graus de entrada foram:

| Conta | Degree de entrada |
|---|---:|
| C874023329 | 12 |
| C418053001 | 9 |
| C2097141675 | 7 |
| C2088638273 | 6 |
| C1598002267 | 5 |

Esses resultados coincidem com a quantidade de origens distintas identificadas nas transferências.

Na projeção exclusivamente de transferências, os cinco intermediários apresentam grau de saída igual a zero. Isso significa que não há transferências de saída desses nós na projeção selecionada; não significa que não tenham outras operações financeiras no grafo completo.

### 6.2. PageRank

O PageRank foi aplicado à projeção de transferências com 20 iterações máximas e fator de amortecimento de 0,85.

| Conta | PageRank |
|---|---:|
| C874023329 | 1,6800 |
| C418053001 | 1,2975 |
| C2097141675 | 1,0425 |
| C2088638273 | 0,9150 |
| C1598002267 | 0,7875 |

A ordenação reproduziu a ordem observada no Degree de entrada.

Isso é coerente com a estrutura da projeção: os intermediários concentram as conexões de entrada e não possuem transferências de saída nessa representação.

**Interpretação:** PageRank mede relevância estrutural na rede analisada. Não é um score de fraude e, neste caso, não demonstrou um sinal independente do padrão de conectividade.

### 6.3. Louvain

O Louvain foi executado sobre o tipo de relacionamento não direcionado criado na projeção em memória.

A saída do `gds.louvain.stream` identificou 175 comunidades distintas entre os 214 nós processados.

As cinco comunidades principais observadas foram:

| Comunidade | Número de nós | Intermediário presente |
|---|---:|---|
| 120 | 13 | C874023329 |
| 129 | 10 | C418053001 |
| 128 | 8 | C2097141675 |
| 130 | 7 | C2088638273 |
| 131 | 6 | C1598002267 |

Esses agrupamentos correspondem a cinco estruturas em formato de estrela: várias contas de origem conectadas a um mesmo destino de transferência.

A validação das 39 transferências indicou:

- 39 transferências internas às comunidades;
- 0 transferências entre comunidades.

A modularidade retornada pelo procedimento `stats` foi aproximadamente 0,77975. Entretanto, a saída do campo `communityCount` desse procedimento apresentou divergência em relação aos 175 identificadores de comunidade observados no `stream`. Por isso, o número de comunidades deste documento é baseado na contagem direta de identificadores distintos no `stream`.

A modularidade elevada deve ser interpretada no contexto da projeção esparsa e dos agrupamentos em estrela. Ela não demonstra, por si só, a existência de organizações criminosas ou grupos fraudulentos.

## 7. Concentração financeira

Além da quantidade de conexões, a investigação avaliou como o volume financeiro está distribuído entre as origens de cada intermediário.

### 7.1. Participação da maior origem

| Intermediário | Participação da maior origem |
|---|---:|
| C874023329 | 51,90% |
| C418053001 | 43,30% |
| C1598002267 | 42,01% |
| C2088638273 | 30,54% |
| C2097141675 | 29,43% |

A maior origem responde por mais da metade do volume registrado para C874023329. Os outros intermediários apresentam níveis diferentes de concentração.

### 7.2. Índice Herfindahl–Hirschman (HHI)

O HHI foi calculado pela soma dos quadrados das participações de cada origem no volume total do respectivo intermediário.

Os resultados abaixo utilizam a escala tradicional de 0 a 10.000.

| Intermediário | HHI | Origens efetivas aproximadas |
|---|---:|---:|
| C874023329 | 3.052,90 | 3,28 |
| C1598002267 | 2.850,04 | 3,51 |
| C418053001 | 2.501,76 | 4,00 |
| C2088638273 | 2.207,66 | 4,53 |
| C2097141675 | 2.200,40 | 4,54 |

O número de origens efetivas é calculado como o inverso do HHI em escala de 0 a 1. Ele oferece uma interpretação intuitiva da concentração: quantas origens com participações iguais produziriam a mesma concentração observada.

Por exemplo, C874023329 possui 12 origens distintas, mas seu índice equivale a aproximadamente 3,28 origens com participações iguais.

O HHI complementa o Degree porque distingue quantidade de conexões de distribuição financeira.

### 7.3. Participação Top 3

| Intermediário | Volume das três maiores origens | Participação Top 3 |
|---|---:|---:|
| C1598002267 | R$ 2.205.921,98 | 84,27% |
| C2097141675 | R$ 7.800.731,26 | 75,96% |
| C2088638273 | R$ 2.844.732,64 | 75,83% |
| C874023329 | R$ 15.293.847,99 | 73,28% |
| C418053001 | R$ 3.820.027,74 | 71,87% |

As três maiores origens representam entre 71,87% e 84,27% do volume de cada intermediário.

C1598002267 apresenta a maior participação Top 3, embora tenha o menor volume total entre os cinco intermediários.

A combinação de Degree, HHI e Top 3 permite analisar três dimensões diferentes:

- quantidade de origens;
- distribuição do volume entre todas as origens;
- participação conjunta das três maiores origens.

Essas medidas podem ser avaliadas futuramente como variáveis de engenharia de atributos para modelos de Machine Learning.

## 8. Síntese dos resultados

A investigação produziu os seguintes achados:

1. Foram identificados cinco intermediários que concentram 39 transferências na amostra selecionada.
2. O volume total registrado nessas transferências é de R$ 42.823.794,64.
3. Os cinco intermediários aparecem em comunidades distintas na projeção de transferências.
4. As 39 transferências analisadas são internas às respectivas comunidades, sem relacionamentos entre elas na projeção.
5. Degree e PageRank produziram a mesma ordenação dos cinco intermediários.
6. HHI e Top 3 demonstraram que o volume financeiro está concentrado em diferentes graus nas origens.
7. Nenhuma das 39 transferências analisadas está rotulada como fraude.

O resultado central não é uma classificação de contas como fraudulentas. É a identificação de estruturas relacionais e concentrações financeiras que podem ajudar uma equipe a decidir quais situações investigar primeiro.

## 9. Limitações

Os resultados devem ser interpretados considerando as seguintes limitações:

- O PaySim é um conjunto sintético, e seus rótulos não equivalem a evidências de casos reais.
- A projeção do GDS contém apenas 39 relacionamentos originais de transferência, selecionados a partir de um conjunto maior.
- O grafo é esparso e os resultados de comunidades dependem da projeção utilizada.
- A coincidência entre Degree e PageRank indica que essas métricas não forneceram sinais independentes neste caso.
- A sequência transferência–saque não demonstra rastreamento de fundos nem causalidade.
- Os resultados não foram validados como um sistema de produção ou como um modelo operacional de detecção de fraude.
- Não foram demonstrados ganhos de desempenho de Machine Learning decorrentes dessas variáveis.
- Os valores financeiros refletem a soma dos eventos selecionados, não necessariamente saldos econômicos ou recursos recuperáveis.

## 10. Próximos passos

A evolução do NGIF-03 pode incluir:

1. Comparar um modelo baseline de Machine Learning com um modelo enriquecido por atributos de grafo.
2. Avaliar se Degree, HHI, Top 3 e indicadores temporais acrescentam poder preditivo.
3. Utilizar separação temporal entre treino e teste para reduzir vazamento de informação.
4. Medir precisão, recall, falsos positivos, PR-AUC e custos de investigação.
5. Validar os resultados em amostras adicionais e em cenários que reproduzam melhor as necessidades de uma operação antifraude.
6. Integrar as análises em uma API e em um dashboard, caso a validação justifique essa evolução.

Qualquer avanço deverá ser acompanhado de métricas de desempenho, avaliação de custos e validação contextual.

## 11. Conclusão

O NGIF-03 demonstra como transformar transações tabulares em uma estrutura relacional que permite investigar conexões, caminhos temporais, comunidades e concentração financeira.

A contribuição do grafo não está em substituir o julgamento humano nem em atribuir culpa a partir de métricas estruturais. Está em tornar relações explícitas, formular perguntas mais precisas e apoiar a priorização de investigações.

A evolução para uma solução antifraude exige integração com contexto de negócio, validação das hipóteses, dados confiáveis e avaliação rigorosa dos resultados.

**Graph Intelligence não é apenas encontrar conexões. É transformar conexões em perguntas investigativas, evidências verificáveis e decisões melhores.**

> O grafo não acusa: ele organiza conexões para que a investigação faça as perguntas certas.

---

**Alexandre Lotti | Graph Intelligence**

*NGIF — Noxtron Graph Intelligence Framework*  
*Connecting Data. Revealing Decisions.*