// NGIF-03 — Financial Fraud Investigation
// Etapa 04: identificação de caminhos temporais
// Hipótese: TRANSFER seguida de CASH_OUT pela mesma conta

MATCH
    (origem:Account)-[:SENT]->(transferencia:Transaction)-[:RECEIVED_BY]->(intermediaria:Account),
    (intermediaria)-[:SENT]->(saque:Transaction)-[:RECEIVED_BY]->(destino:Account)

WHERE
    transferencia.type = 'TRANSFER'
    AND saque.type = 'CASH_OUT'
    AND saque.step > transferencia.step

WITH
    origem,
    intermediaria,
    destino,
    transferencia,
    saque,
    saque.step - transferencia.step AS intervalo_horas

RETURN
    origem.id AS conta_origem,
    intermediaria.id AS conta_intermediaria,
    destino.id AS conta_destino,
    transferencia.tx_id AS id_transferencia,
    saque.tx_id AS id_cashout,
    transferencia.amount AS valor_transferido,
    saque.amount AS valor_cashout,
    intervalo_horas,
    transferencia.isFraud AS transferencia_rotulada_fraude,
    saque.isFraud AS cashout_rotulado_fraude

ORDER BY intervalo_horas ASC;