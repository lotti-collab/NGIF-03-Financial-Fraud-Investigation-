// NGIF-03 — Financial Fraud Investigation
// Etapa 01: restrições de unicidade

CREATE CONSTRAINT account_id IF NOT EXISTS
FOR (a:Account)
REQUIRE a.id IS UNIQUE;

CREATE CONSTRAINT transaction_id IF NOT EXISTS
FOR (t:Transaction)
REQUIRE t.tx_id IS UNIQUE;