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
-- Listar nome, categoria e poder do golpe que tem poder maior que todos de sua categoria
SELECT	g.nome,
		g.categoria,
		g.poder 
		
FROM golpe g
WHERE g.poder > (SELECT MAX(g2.poder)
                   FROM golpe g2
                  WHERE g2.categoria = g.categoria
                    AND g2.id_golpe <> g.id_golpe);



-- CONSULTA 9
-- Listar as evoluções: espécie de origem, espécie de destino,
-- nível mínimo e item necessário, ordenado pela espécie de origem
SELECT	s.nome AS especie_origem,
		sf.nome AS especie_destino,
		e.nivel_minimo, 
		e.item_necessario
		
FROM evolucao e
JOIN especie s ON s.id_especie = e.id_origem
JOIN especie sf ON sf.id_especie = e.id_destino

ORDER BY especie_origem ASC;



-- CONSULTA 1O
-- Mesma ideia da consulta 8 (golpe mais forte de cada categoria),
-- mas usando > ALL em vez de MAX
SELECT	g.nome,
		g.categoria,
		g.poder 
		
FROM golpe g
WHERE g.poder > ALL (SELECT g2.poder 
FROM golpe g2                  
WHERE g2.categoria = g.categoria
                    		AND g2.id_golpe <> g.id_golpe);




-- CONSULTA 11
-- Listar os treinadores com pelo menos 10 participações em batalhas
-- concluídas e mais de 70% de vitórias, mostrando vitórias, total e percentual
SELECT		t.nome AS treinador,
			COUNT(*) FILTER (WHERE pb.resultado = 'VITORIA') AS vitorias,
			COUNT(*) AS total,
			ROUND (100.0 * COUNT(*) FILTER (WHERE pb.resultado = 'VITORIA') / COUNT(*), 2) AS percentual

FROM treinador t
JOIN inscricao i ON i.id_treinador = t.id_treinador
JOIN participacao_batalha pb ON pb.id_inscricao = i.id_inscricao 
JOIN batalha b ON b.id_batalha = pb.id_batalha
WHERE b.situacao = 'CONCLUIDA'
GROUP BY t.id_treinador, t.nome
HAVING COUNT(*) >= 10
AND	   100.0 * COUNT(*) FILTER (WHERE pb.resultado = 'VITORIA') / COUNT(*) > 70;



-- CONSULTA 12
-- Listar as espécies que têm Pokémon cadastrado, mas nenhum
-- deles foi usado em batalha (sem registro em uso_pokemon)
SELECT	e.nome AS especie

FROM 	especie e
WHERE 	EXISTS	(SELECT *
				 FROM pokemon p2
				 WHERE p2.id_especie = e.id_especie) 
  AND	NOT EXISTS (SELECT *
  					FROM uso_pokemon u
					JOIN pokemon p ON p.id_pokemon = u.id_pokemon
					WHERE e.id_especie = p.id_especie);


 

-- CONSULTA 13
-- Listar os Pokémons com nível acima da média global (de todos
-- os Pokémons), mostrando essa média. Ordem decrescente por nível
SELECT	p.id_pokemon AS identificador,
		p.apelido,
		e.nome AS especie,
		p.nivel,
		ROUND((SELECT AVG(p3.nivel) FROM pokemon p3) , 2) AS media_global

FROM pokemon p 
JOIN especie e ON e.id_especie = p.id_especie
WHERE p.nivel > (SELECT AVG(p2.nivel)
				 FROM pokemon p2)  --pega todos os pokemons

ORDER BY p.nivel DESC;
 


-- CONSULTA 14
-- Listar os treinadores que já fizeram pelo menos uma
-- captura na região de Kanto
SELECT DISTINCT t.nome AS treinador,
				t.id_treinador AS identificador
				
FROM treinador t
WHERE t.id_treinador IN (SELECT c.id_treinador
			 		  FROM captura c
			          JOIN regiao r ON c.id_regiao = r.id_regiao
			          WHERE r.nome = 'Kanto');




--CONSULTA 15
-- Divisão relacional: listar os treinadores que possuem Pokémons
-- de TODOS os tipos que aparecem nas espécies de Kanto
-- (não existe tipo de Kanto que o treinador não tenha)
SELECT t.id_treinador, t.nome
FROM   treinador t
WHERE  NOT EXISTS (

        SELECT 1
        FROM   tipo tp
        WHERE  tp.id_tipo IN (SELECT et.id_tipo         
                                FROM especie e                      
                                JOIN regiao r ON r.id_regiao = e.id_regiao
                                JOIN especie_tipo et ON et.id_especie = e.id_especie
                               WHERE r.nome = 'Kanto')
          AND  NOT EXISTS (

                SELECT 1
                FROM   pokemon p
                JOIN   especie_tipo et2 ON et2.id_especie = p.id_especie   -- descobre o tipo de cada Pokémon
                WHERE  p.id_treinador = t.id_treinador     
                  AND  et2.id_tipo    = tp.id_tipo          

          )
);



-- CONSULTA 16
-- Listar as evoluções do Charmander com 1 e 2 etapas,
-- juntando os dois resultados com UNION
-- PERGUNTA 1: com 1 evolução, o Charmander vira o quê?
SELECT o.nome AS especie_origem,
       d.nome AS especie_final,
       1      AS etapas                                 
FROM   evolucao ev
JOIN   especie o ON o.id_especie = ev.id_origem         
JOIN   especie d ON d.id_especie = ev.id_destino        
WHERE  o.nome = 'Charmander'

UNION                                                   

-- PERGUNTA 2: com 2 evoluções, o Charmander vira o quê?
SELECT o.nome AS especie_origem,
       d.nome AS especie_final,
       2      AS etapas                                 
FROM   evolucao ev1                                    
JOIN   evolucao ev2 ON ev2.id_origem = ev1.id_destino  
JOIN   especie o    ON o.id_especie  = ev1.id_origem   
JOIN   especie d    ON d.id_especie  = ev2.id_destino  
WHERE  o.nome = 'Charmander'

ORDER BY etapas;   



-- CONSULTA 17
-- Listar o(s) treinador(es) dono(s) do Pokémon de maior nível,
-- com apelido, espécie e nível desse Pokémon
SELECT	t.nome AS treinador,
		p1.apelido,
		e.nome AS especie,
		p1.nivel AS nivel_pokemon
		
FROM treinador t
JOIN pokemon p1 ON p1.id_treinador = t.id_treinador
JOIN especie e ON e.id_especie = p1.id_especie
WHERE p1.nivel = (SELECT MAX(p.nivel) FROM pokemon p);
              


-- CONSULTA 18
-- Listar as regiões com pelo menos 20 capturas, mostrando a
-- quantidade de capturas e a data da última (subconsulta no FROM)

SELECT  r.nome AS regiao,
        tot.qtd_capturas,
        tot.ultima_captura
FROM    (
          SELECT   c.id_regiao AS regiao,
                   COUNT(*)              AS qtd_capturas,     
                   MAX(c.data_captura)  AS ultima_captura    
          FROM     captura c                                 
          GROUP BY c.id_regiao                               
          HAVING   COUNT(*) >= 20     
		 ) AS tot
JOIN    regiao r ON r.id_regiao = tot.regiao;            



-- CONSULTA 19
-- Contar os Pokémons por região do treinador e raridade da espécie,
-- com subtotais por região e total geral (ROLLUP + GROUPING)
SELECT   r.nome      AS regiao,          
         e.raridade, 
         GROUPING(r.nome)     AS resumo_regiao,      
		     GROUPING(e.raridade) AS resumo_raridade,  
         COUNT(p.id_pokemon) AS quantidade
		 
FROM     pokemon p
JOIN     treinador t ON t.id_treinador = p.id_treinador   
JOIN     regiao r    ON r.id_regiao    = t.id_regiao   
JOIN     especie e   ON e.id_especie   = p.id_especie   
GROUP BY ROLLUP (r.nome, e.raridade)
ORDER BY r.nome, e.raridade;



-- CONSULTA 20
-- Listar os treinadores com quantidade de Pokémons acima da
-- média de Pokémons por treinador (contando quem tem 0)
SELECT    t.id_treinador AS identificador,
          t.nome,
          COUNT(p.id_pokemon) AS quantidade
		  
FROM      treinador t
LEFT JOIN pokemon p ON p.id_treinador = t.id_treinador        
GROUP BY  t.id_treinador, t.nome                               
HAVING    COUNT(p.id_pokemon) > (
			  SELECT AVG(x.qtd)                        
              FROM (
                     SELECT COUNT(p2.id_pokemon) AS qtd    
                     FROM   treinador t2
                     LEFT JOIN pokemon p2 ON p2.id_treinador = t2.id_treinador
                     GROUP BY t2.id_treinador
                   ) AS x
          );