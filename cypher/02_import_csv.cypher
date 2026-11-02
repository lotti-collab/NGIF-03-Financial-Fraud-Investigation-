// NGIF-03 — Financial Fraud Investigation
// Etapa 02: importação das transações para o Neo4j
// Arquivo de origem: NGIF03_subgrafo_contas.csv
// Modelo: Account → Transaction → Account

LOAD CSV WITH HEADERS
FROM 'file:///NGIF03_subgrafo_contas.csv'
AS row

MERGE (origem:Account {id: row.source_account})
MERGE (destino:Account {id: row.target_account})

MERGE (t:Transaction {tx_id: toInteger(row.tx_id)})
SET
    t.step = toInteger(row.step),
    t.type = row.type,
    t.amount = toFloat(row.amount),
    t.isFraud = toInteger(row.isFraud),
    t.isFlaggedFraud = toInteger(row.isFlaggedFraud)

MERGE (origem)-[:SENT]->(t)
MERGE (t)-[:RECEIVED_BY]->(destino);