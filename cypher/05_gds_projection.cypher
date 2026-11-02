// NGIF-03 — Financial Fraud Investigation
// Etapa 05: projeção do grafo para Neo4j GDS
// Objetivo: analisar a rede de transferências entre contas

// Remove projeção anterior, caso exista
CALL gds.graph.drop('ngif03_transfer', false)
YIELD graphName;

// Cria projeção com contas e transferências
MATCH (origem:Account)-[:SENT]->(t:Transaction)-[:RECEIVED_BY]->(destino:Account)
WHERE t.type = 'TRANSFER'

WITH origem, destino

CALL gds.graph.project(
    'ngif03_transfer',
    origem,
    destino
)
YIELD graphName, nodeCount, relationshipCount

RETURN
    graphName,
    nodeCount,
    relationshipCount;