-- -- 1) VISÃO GERAL DA FRAUDE
-- Resumo geral da base: total de transações, quantidade de fraudes, taxa de fraude (%),
-- valor exposto (soma das compras fraudulentas) e comparação entre o ticket médio das
-- fraudes e o ticket médio de todas as transações. É o ponto de partida da análise.

SELECT
COUNT(*) AS total,
SUM(fraude) AS fraude,
ROUND(AVG(100.0*fraude), 3) AS taxa_fraude,
ROUND(SUM(
  CASE WHEN fraude = 1 THEN valor_compra ELSE 0 END),2) AS valor_exposto,
ROUND(AVG(
  CASE WHEN fraude = 1 THEN valor_compra END),2) AS ticket_medio_fraude,
ROUND(AVG(valor_compra), 2) AS ticket_medio_total
FROM `fraudeprojetosql.abt_fraude.projeto_fraude`;

-- 2) RISCO POR PAÍS E REGIÃO
-- Cruza as transações com a tabela de países para mostrar volume, quantidade de fraudes e
-- taxa de fraude por país e região. Considera apenas países com 1.000 ou mais transações,
-- evitando conclusões baseadas em amostras pequenas. Ordenado pelo maior número de fraudes.
SELECT
t.pais,
p.regiao,
COUNT(*) AS total,
SUM(fraude) AS fraude,
ROUND(AVG(100.0*fraude),3) AS taxa_fraude

FROM `fraudeprojetosql.abt_fraude.projeto_fraude` AS t
INNER JOIN `fraudeprojetosql.abt_fraude.paises` AS p ON t.pais = p.sigla_pais
GROUP BY t.pais, p.regiao
HAVING COUNT (*) >=1000
ORDER BY fraude DESC;

-- 3) RISCO POR NÍVEL DE CATEGORIA
-- Junta as transações com a tabela de categorias e compara a taxa de fraude entre os níveis
-- de risco das categorias de produto. Permite validar se a classificação de risco cadastrada
-- realmente corresponde ao comportamento observado nos dados.
SELECT
c.nivel_risco_categoria,
COUNT(*) AS transcacoes,
ROUND(AVG(100.0*t.fraude), 3) AS taxa_fraude
FROM `fraudeprojetosql.abt_fraude.projeto_fraude` AS t
INNER JOIN `fraudeprojetosql.abt_fraude.categorias` AS c ON t.categoria_produto = c.id_categoria
GROUP BY c.nivel_risco_categoria
ORDER BY taxa_fraude DESC;

-- 4) TAXA DE FRAUDE POR FAIXA DE VALOR
-- Agrupa as compras em três faixas (até 100, entre 100 e 500, acima de 500) e calcula o
-- volume de transações e a taxa de fraude de cada uma. Mostra se o risco aumenta conforme
-- o valor da compra.
SELECT
CASE
  WHEN valor_compra < 100 THEN '1) Até 100'
  WHEN valor_compra < 500 THEN '2) Entre 100 - 500'
  ELSE '3) Acima de 500'
  END AS faixa_valor,
COUNT(*) AS transacoes, 
ROUND(AVG(100.0*fraude), 3) AS taxa_fraude,

FROM `fraudeprojetosql.abt_fraude.projeto_fraude`
GROUP BY faixa_valor
ORDER BY faixa_valor;

-- 5) IMPACTO FINANCEIRO POR FAIXA DE VALOR
-- Evolui a análise anterior usando uma CTE: além da taxa de fraude, calcula a participação
-- de cada faixa no total de fraudes, o valor exposto e a perda média por fraude. Responde
-- onde as fraudes se concentram e onde está o maior prejuízo financeiro.
WITH base AS (
SELECT
CASE
  WHEN valor_compra < 100 THEN '1) Até 100'
  WHEN valor_compra < 500 THEN '2) Entre 100 - 500'
  WHEN valor_compra >=500 THEN 'Acima de 500'
  ELSE '4) NULL'
  END AS faixa_valor,
fraude,
valor_compra

FROM `fraudeprojetosql.abt_fraude.projeto_fraude`
)

SELECT
faixa_valor,
COUNT(*) AS transcacoes,
SUM(fraude) AS fraude,
ROUND(AVG(100.0*fraude), 2) AS taxa_fraude,
ROUND(100*SUM(fraude)/SUM(SUM(fraude)) OVER (), 1) AS pct_valor,
ROUND(SUM(
  CASE WHEN fraude = 1 THEN valor_compra ELSE 0 END),2) AS valor_exposto,
ROUND(SAFE_DIVIDE(
  SUM(CASE WHEN fraude = 1 THEN valor_compra ELSE 0 END),
  SUM(fraude)
), 2) AS perda_media_por_fraude
FROM base
GROUP BY faixa_valor;

-- 6) VALIDAÇÃO DO MODELO POR DECIS
-- Divide as transações em 10 grupos de igual tamanho, ordenados pelo score do modelo de
-- fraude (decil 1 = menor score, decil 10 = maior), e mede a taxa de fraude real em cada um.
-- Se o modelo separa bem o risco, a taxa deve crescer ao longo dos decis.
WITH faixas AS (
SELECT
fraude,
NTILE(10) OVER (ORDER BY score_fraude_modelo) AS decil
FROM `fraudeprojetosql.abt_fraude.projeto_fraude`
)

SELECT
decil,
COUNT(*) AS transcacoes,
ROUND(AVG(100.0*fraude), 2) AS taxa_fraude,
FROM faixas
GROUP BY decil
ORDER BY decil;