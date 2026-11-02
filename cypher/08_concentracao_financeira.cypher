// NGIF-03 — Financial Fraud Investigation
// Etapa 08: concentração financeira por conta intermediária
// Objetivo: avaliar a concentração das origens dos recursos

MATCH
    (origem:Account)-[:SENT]->(t:Transaction)-[:RECEIVED_BY]->(intermediaria:Account)

WHERE t.type = 'TRANSFER'

WITH
    intermediaria,
    origem,
    sum(t.amount) AS valor_origem

WITH
    intermediaria,
    collect(valor_origem) AS valores,
    sum(valor_origem) AS volume_total,
    count(*) AS total_origens

WITH
    intermediaria,
    valores,
    volume_total,
    total_origens,
    [valor IN valores | valor / volume_total] AS participacoes

WITH
    intermediaria,
    volume_total,
    total_origens,
    participacoes,
    reduce(
        hhi = 0.0,
        p IN participacoes |
        hhi + p * p
    ) AS hhi

WITH
    intermediaria,
    volume_total,
    total_origens,
    hhi,
    1.0 / hhi AS effective_origins,
    participacoes

RETURN
    intermediaria.id AS conta_intermediaria,
    total_origens,
    round(volume_total, 2) AS volume_total,
    round(hhi * 10000, 2) AS hhi,
    round(effective_origins, 2) AS effective_origins,
    round(100 * reduce(m = 0.0, p IN participacoes | CASE WHEN p > m THEN p ELSE m END), 2) AS top1_percent,
    round(100 * reduce(
        soma = 0.0,
        p IN participacoes |
        soma + p
    ), 2) AS participacao_total_percent

ORDER BY hhi DESC;