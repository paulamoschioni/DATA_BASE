--CONSULTA 01: 
-- Listagem de 50 Pokemons de nível 50 ou superior 
-- que possuem treinador atual. Ordem derescente por nível 
-- e em caso de empate, pelo nome do treinador
SET search_path TO liga_pokemon;

SELECT  p.id_pokemon AS identificador,
        p.apelido    AS apelido,
        e.nome       AS especie,     -- nome que veio da tabela especie
        t.nome    AS treinador,   		
        p.nivel      AS nivel        
FROM    pokemon p                    
JOIN    especie e   ON e.id_especie = p.id_especie   -- traduz id_especie → nome da espécie
JOIN    treinador t ON t.id_treinador = p.id_treinador 
WHERE	p.nivel >= 50 AND p.id_treinador IS NOT NULL
ORDER BY p.nivel DESC, t.nome;



--CONSULTA 02: 
--Listar a regiao do treinador e o nome do tipo do pokemon
--atual, tirando as colunas repetidas
SELECT DISTINCT	r.nome AS regiao,
				tp.nome AS tipo
		
FROM treinador t
JOIN regiao r ON t.id_regiao = r.id_regiao
JOIN pokemon p ON t.id_treinador = p.id_treinador
JOIN especie_tipo et ON p.id_especie = et.id_especie
JOIN tipo tp ON tp.id_tipo = et.id_tipo

ORDER BY r.nome, tp.nome;



-- CONSULTA 3:
-- Lista o nome, a quantidade de pokemons por treinador,
-- e a quantidade de pokemons com + de 40 de nivel
SELECT	t.nome,
		COUNT(p.id_pokemon) AS total_pokemon,
		COUNT(p.nivel) FILTER (WHERE p.nivel >= 40) AS nivel_
		
FROM	treinador t
LEFT JOIN 	pokemon p ON p.id_treinador = t.id_treinador

GROUP BY t.id_treinador, t.nome			--“Junte as linhas de cada treinador num montinho só (usando o id para não confundir pessoas com o mesmo nome), e mantenha o nome disponível para mostrar no resultado.”
ORDER BY total_pokemon DESC;




-- CONSULTA 4:
-- Liste todas as capturas realizadas em 2025: treinador responsável pela captura, 
-- apelido, espécie, método, região e data


SELECT	t.nome AS treinador_responsavel,
		p.apelido AS apelido_pokemon,
		e.nome AS especie,
		c.metodo AS metodo, 
		r.nome AS regiao,
		c.data_captura

FROM captura c
INNER JOIN treinador t ON t.id_treinador = c.id_treinador
JOIN pokemon p ON p.id_pokemon = c.id_pokemon
JOIN especie e ON e.id_especie = p.id_especie
JOIN regiao r ON r.id_regiao = c.id_regiao

WHERE c.data_captura >= '2025-01-01'
  AND c.data_captura <  '2026-01-01';


-- CONSULTA 5: 
-- Listar os treinadores que possuem pelo menos 5 especies
--de Pokemon distintas e com nível amior que 30
SELECT	t.nome				   AS treinador,
		COUNT(p.id_pokemon)    AS total_individuos,
		COUNT(DISTINCT e.nome) AS num_especies,
		AVG(p.nivel)		   AS media_nivel

FROM treinador t
JOIN pokemon p ON p.id_treinador = t.id_treinador
JOIN especie e ON p.id_especie = e.id_especie
GROUP BY t.id_treinador, t.nome
HAVING COUNT(DISTINCT e.nome) >= 5
AND	   AVG(p.nivel) > 30;



-- CONSULTA 6
-- Listar os torneios e quantas batalhas com o resultado
--"EMPATE", a soma dessas batalhas, e a porcentagem de 
-- empates
SELECT   t.nome              AS torneio,
         COUNT(DISTINCT b.id_batalha) AS batalhas_concluidas,
         COUNT(DISTINCT b.id_batalha) FILTER (WHERE p.resultado = 'EMPATE') AS empates,    
         ROUND(
             100.0 * COUNT(DISTINCT b.id_batalha) FILTER (WHERE p.resultado = 'EMPATE')    
                   / COUNT(DISTINCT b.id_batalha),
         2) AS porcentagem_empates
FROM     batalha b
JOIN     torneio t              ON b.id_torneio = t.id_torneio
JOIN     participacao_batalha p ON p.id_batalha = b.id_batalha    
WHERE    b.situacao = 'CONCLUIDA'
GROUP BY t.id_torneio, t.nome
HAVING   COUNT(DISTINCT b.id_batalha) >= 10; 



-- CONSULTA 7:
-- Listar os Pokemons com nível acima da média da sua
-- espécie, mostrando essa média, considerando só espécies
-- com pelo menos 3 Pokemons cadastrados

SELECT  p.id_pokemon,
        p.apelido,
        e.nome  AS especie,
        p.nivel,
        (SELECT AVG(p2.nivel)                            -- mostra a média da espécie
           FROM pokemon p2
          WHERE p2.id_especie = p.id_especie) AS media_especie
FROM    pokemon p
JOIN    especie e ON e.id_especie = p.id_especie
WHERE   p.nivel > (SELECT AVG(p2.nivel)                  -- pega a média da espécie
                     FROM pokemon p2
                    WHERE p2.id_especie = p.id_especie)
  AND   (SELECT COUNT(*)                                 -- conta quantos Pokémon a espécie tem
           FROM pokemon p2
          WHERE p2.id_especie = p.id_especie) >= 3;      -- pelo menos 3 Pokémon cadastrado



-- CONSULTA 8
-- Listar nome, categoria e poder do poder que tem poder maior que todos de sua categoria
SELECT	g.nome,
		g.categoria,
		g.poder 
		
FROM golpe g
WHERE g.poder > (SELECT MAX(g2.poder)
                   FROM golpe g2
                  WHERE g2.categoria = g.categoria
                    AND g2.id_golpe <> g.id_golpe)



-- CONSULTA 9
-- 