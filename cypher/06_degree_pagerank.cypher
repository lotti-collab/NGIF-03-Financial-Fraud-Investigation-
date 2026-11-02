// NGIF-03 — Financial Fraud Investigation
// Etapa 06: Degree e PageRank
// Objetivo: identificar contas estruturalmente relevantes

// 1. Degree: conexões de entrada e saída
CALL gds.degree.stream('ngif03_transfer')
YIELD nodeId, score

RETURN
    gds.util.asNode(nodeId).id AS conta,
    score AS degree

ORDER BY degree DESC
LIMIT 20;


// 2. PageRank: importância estrutural na rede
CALL gds.pageRank.stream('ngif03_transfer')
YIELD nodeId, score

RETURN
    gds.util.asNode(nodeId).id AS conta,
    round(score, 4) AS pagerank

ORDER BY pagerank DESC
LIMIT 20;