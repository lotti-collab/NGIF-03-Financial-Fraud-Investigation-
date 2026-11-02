// NGIF-03 — Financial Fraud Investigation
// Etapa 07: detecção de comunidades com Louvain
// Objetivo: identificar agrupamentos estruturais na rede

// Converte a projeção direcionada em não direcionada
CALL gds.graph.relationships.toUndirected(
    'ngif03_transfer',
    {
        relationshipType: '__ALL__',
        mutateRelationshipType: 'TRANSFER_UNDIRECTED'
    }
)
YIELD
    inputRelationships,
    relationshipsWritten

RETURN
    inputRelationships,
    relationshipsWritten;


// Executa Louvain e retorna a comunidade de cada conta
CALL gds.louvain.stream(
    'ngif03_transfer',
    {
        relationshipTypes: ['TRANSFER_UNDIRECTED']
    }
)
YIELD
    nodeId,
    communityId

RETURN
    communityId,
    count(*) AS total_contas,
    collect(gds.util.asNode(nodeId).id) AS contas

ORDER BY total_contas DESC;