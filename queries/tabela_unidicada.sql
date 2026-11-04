CREATE TABLE `fraudeprojetosql.abt_fraude.projeto_fraude` AS (
SELECT
t.entrega_doc_1,
t.entrega_doc_2,
t.entrega_doc_3,
t.data_compra,
t.valor_compra,
t.pais,
t.produto,
t.categoria_produto,
c.score_1,
c.score_2,
c.score_4,
c.score_5,
c.score_7,
m.score_fraude_modelo,
m.score_8,
m.fraude,
f.score_3,
f.score_6,
f.score_9,
f.score_10

FROM `fraudeprojetosql.abt_fraude.transcacoes` AS t
  INNER JOIN `fraudeprojetosql.abt_fraude.scores_comportamentais` AS c ON t.id_transacao = c.id_transacao
  INNER JOIN  `fraudeprojetosql.abt_fraude.score_modelo` AS m ON t.id_transacao = m.id_transacao
  INNER JOIN `fraudeprojetosql.abt_fraude.scores_financeiros` f ON t.id_transacao = f.id_transacao
WHERE t.is_teste = 0
)