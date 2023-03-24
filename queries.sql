-- QUERIES

-- 1) Ottiene tutte le partite di una determinata stagione e lega mostrandone la data e i risultati.
SELECT p.Data, p.SquadraCasa AS Casa, p.PunteggioCasa, p.PunteggioOspite, p.SquadraOspite AS Ospite
FROM Competizione AS c join Partita AS p on (c.Zona, c.Divisione) = (p.Zona, p.Divisione)
WHERE 	(EXTRACT(YEAR FROM p.Data) = 2021 and TO_CHAR(p.Data, 'MM DD') >= TO_CHAR(c.InizioStagione, 'MM DD')
		or EXTRACT(YEAR FROM p.Data) = 2022 and TO_CHAR(p.Data, 'MM DD') <= TO_CHAR(c.FineStagione, 'MM DD'))
		and c.Zona = 'Italia' and c.Divisione = 1
ORDER BY p.Data
;


-- 2) Mostra la classifica calcolando i punti per ogni squadra dato il numero di vittorie e pareggi ottenuto dalle rispettive view.
-- Le sconfitte sono calcolate a partire dal numero di incontri in una stagione.

-- Ottiene tutte le partite di una determinata stagione e lega mostrandone la data e i risultati.
DROP VIEW IF EXISTS Stagione2122 CASCADE;
CREATE VIEW Stagione2122 AS
SELECT p.Data, p.SquadraCasa, p.PunteggioCasa, p.PunteggioOspite, p.SquadraOspite
FROM Competizione AS c join Partita AS p on (c.Zona, c.Divisione) = (p.Zona, p.Divisione)
WHERE 	(EXTRACT(YEAR FROM p.Data) = 2021 and TO_CHAR(p.Data, 'MM DD') >= TO_CHAR(c.InizioStagione, 'MM DD')
		or EXTRACT(YEAR FROM p.Data) = 2022 and TO_CHAR(p.Data, 'MM DD') <= TO_CHAR(c.FineStagione, 'MM DD'))
		and c.Zona = 'Italia' and c.Divisione = 1
ORDER BY p.Data
;

-- Calcola le vittorie in casa e le somma alle vittorie in trasferta.
CREATE VIEW Vittorie AS
SELECT vc.Squadra, (COALESCE(VittorieCasa, 0)+COALESCE(VittorieOspite, 0)) AS Vittorie
FROM (
	SELECT SquadraCasa AS Squadra, COUNT(*) AS VittorieCasa
	FROM Stagione2122
	WHERE PunteggioCasa > PunteggioOspite
	GROUP BY SquadraCasa
	) AS vc FULL JOIN (
	SELECT SquadraOspite AS Squadra, COUNT(*) AS VittorieOspite
	FROM Stagione2122
	WHERE PunteggioCasa < PunteggioOspite
	GROUP BY SquadraOspite
	) AS vo ON vc.Squadra = vo.Squadra
ORDER BY Vittorie DESC
;

-- Calcola i pareggi in casa e li somma ai pareggi in trasferta.
CREATE VIEW Pareggi AS
SELECT pc.Squadra, (COALESCE(PareggiCasa, 0)+COALESCE(PareggiOspite, 0)) AS Pareggi
FROM (
	SELECT SquadraCasa AS Squadra, COUNT(*) AS PareggiCasa
	FROM Stagione2122
	WHERE PunteggioCasa = PunteggioOspite
	GROUP BY SquadraCasa
	) AS pc FULL JOIN (
	SELECT SquadraOspite AS Squadra, COUNT(*) AS PareggiOspite
	FROM Stagione2122
	WHERE PunteggioCasa = PunteggioOspite
	GROUP BY SquadraOspite
	) AS po ON pc.Squadra=po.Squadra
ORDER BY Pareggi DESC
;

-- Mostra la classifica calcolando i punti per ogni squadra dato il numero di vittorie e pareggi ottenuto dalle rispettive view.
-- Le sconfitte sono calcolate a partire dal numero di incontri in una stagione.
SELECT 	v.Squadra, (COALESCE(Vittorie, 0)*3 + COALESCE(Pareggi, 0)) AS Punti,
		COALESCE(Vittorie, 0) AS Vittorie,
		COALESCE(Pareggi, 0) AS Pareggi,
		((SELECT COUNT(*) FROM Stagione2122)/(SELECT COUNT(DISTINCT(SquadraCasa)) FROM Stagione2122)*2
		 -COALESCE(Vittorie, 0)-COALESCE(Pareggi, 0)) AS Sconfitte
FROM 	Vittorie AS v FULL JOIN Pareggi AS p
			on v.Squadra = p.Squadra
ORDER BY Punti DESC
;


-- 3) Visualizzare i calciatori che hanno almeno N trasferimenti “Possibili” (in questo caso 3).
SELECT t.Calciatore, c.Nome, c.Cognome, COUNT(*) AS Numero
FROM Trasferimento AS t JOIN Calciatore AS c ON t.Calciatore = c.CF
WHERE t.Veridicita = 'POSSIBILE'
GROUP BY t.Calciatore, c.Nome, c.Cognome
HAVING COUNT(*) >= 3
:


-- 4) Visualizzare l’elenco delle squadre vincitrici di una determinata
-- coppa ordinate per anno (ad esempio della Coppa Italia).

SELECT 	(case
			when p.PunteggioCasa > p.punteggioospite then p.SquadraCasa 
    		when p.PunteggioCasa < p.punteggioospite then p.SquadraOspite 
		 end) as Vincitore,
		 (TO_CHAR(p.Data, 'YYYY')) as Anno
FROM Competizione as c JOIN Partita as p
	on (c.Zona, c.Divisione) = (p.Zona, p.Divisione)
WHERE c.Zona = 'Italia' and c.Divisione = 0
ORDER BY (TO_CHAR(p.Data, 'MM')) DESC, (TO_CHAR(p.Data, 'YYYY')) DESC, (TO_CHAR(p.Data, 'DD')) DESC
LIMIT (
SELECT COUNT(DISTINCT((TO_CHAR(p.Data, 'YYYY'))))
FROM Competizione as c JOIN Partita as p
	on (c.Zona, c.Divisione) = (p.Zona, p.Divisione)
WHERE c.Zona = 'Italia' and c.Divisione = 0
)
;


-- 5) Nome, Cognome degli allenatori che allenano una squadra che ha almeno un giocatore con 50 gol in carriera.
SELECT DISTINCT a.Nome, a.Cognome, s.Nome as Allena
FROM (Allenatore AS a JOIN Squadra AS s on a.CF = s.Allenatore) JOIN Calciatore AS c on s.Nome = c.Squadra
WHERE c.CF in (SELECT c.CF
               FROM Statistica as s JOIN Calciatore AS c ON s.Calciatore = c.CF
               GROUP BY c.CF
               HAVING SUM(s.Gol) > 50)
;


-- 6) Visualizzare gli allenatori delle squadre che hanno una media gol casalinga
-- superiore al doppio della media gol complessiva casalinga.
SELECT A.Nome, A.Cognome, S.Nome
FROM Allenatore AS a JOIN Squadra as s ON a.CF = s.Allenatore
WHERE s.Nome in (SELECT p.SquadraCasa
                    FROM Partita AS p 
                    WHERE p.PunteggioCasa > p.PunteggioOspite 
                    GROUP BY p.SquadraCasa
                    HAVING AVG(p.PunteggioCasa) > 2*(SELECT AVG(p.PunteggioCasa)
                                                   FROM Partita AS p))
;