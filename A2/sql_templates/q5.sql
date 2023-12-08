-- Q5. Flight Hopping

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5 (
	destination CHAR(3),
	num_flights INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS day CASCADE;
DROP VIEW IF EXISTS n CASCADE;

CREATE VIEW day AS
SELECT day::date as day FROM q5_parameters;
-- can get the given date using: (SELECT day from day)

CREATE VIEW n AS
SELECT n FROM q5_parameters;
-- can get the given number of flights using: (SELECT n from n)
WITH RECURSIVE Flight_Hopping AS (
	(SELECT inbound AS destination, s_arv, 1 AS num_flights
			FROM flight
	 		WHERE outbound = 'YYZ' 
			AND EXTRACT (day from s_dep) = EXTRACT(day FROM(SELECT day from day))
	 		AND EXTRACT (month from s_dep) = EXTRACT(month FROM(SELECT day from day))
			AND EXTRACT (year from s_dep) = EXTRACT(year FROM(SELECT day from day))
			)
	UNION ALL
	(SELECT inbound AS destination, flight.s_arv, num_flights+1 AS num_flights
	 		FROM Flight_Hopping, flight
	 		WHERE Flight_Hopping.destination = flight.outbound
			AND num_flights < (SELECT n FROM n) 
			AND (flight.s_dep - Flight_Hopping.s_arv) > '00:00:00'
			AND (flight.s_dep - Flight_Hopping.s_arv) < '24:00:00' 
			AND flight.s_dep != Flight_Hopping.s_arv
			)		 
)
-- HINT: You can answer the question by writing one recursive query below, without any more views.
-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
select destination, num_flights
from Flight_Hopping;