// NGIF-03 — Financial Fraud Investigation
// Etapa 03: identificação de contas intermediárias
// Critério: contas que recebem transferências de múltiplas origens

MATCH (origem:Account)-[:SENT]->(t:Transaction)-[:RECEIVED_BY]->(intermediaria:Account)
WHERE t.type = 'TRANSFER'

WITH
    intermediaria,
    count(t) AS total_transferencias,
    count(DISTINCT origem.id) AS origens_distintas,
    sum(t.amount) AS volume_recebido

WHERE origens_distintas >= 2

RETURN
    intermediaria.id AS conta_intermediaria,
    total_transferencias,
    origens_distintas,
    round(volume_recebido, 2) AS volume_recebido

ORDER BY total_transferencias DESC;