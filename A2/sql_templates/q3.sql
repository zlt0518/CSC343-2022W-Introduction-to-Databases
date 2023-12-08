-- Q3. North and South Connections

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q3 CASCADE;

CREATE TABLE q3 (
    outbound VARCHAR(30),
    inbound VARCHAR(30),
    direct INT,
    one_con INT,
    two_con INT,
    earliest timestamp
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS USACity CASCADE;
DROP VIEW IF EXISTS CanadaCity CASCADE;
DROP VIEW IF EXISTS CA_USA CASCADE;
DROP VIEW IF EXISTS USA_CA CASCADE;
DROP VIEW IF EXISTS In_Out_Combo CASCADE;
DROP VIEW IF EXISTS CA_Dep CASCADE;
DROP VIEW IF EXISTS USA_Dep CASCADE;
DROP VIEW IF EXISTS CA_Direct_USA CASCADE;
DROP VIEW IF EXISTS USA_Direct_CA CASCADE;
DROP VIEW IF EXISTS Direct_Info CASCADE;
DROP VIEW IF EXISTS Direct_Count CASCADE;
DROP VIEW IF EXISTS CA_Con1 CASCADE;
DROP VIEW IF EXISTS USA_Con1 CASCADE;
DROP VIEW IF EXISTS Con1 CASCADE;
DROP VIEW IF EXISTS CA_Con1_Info CASCADE;
DROP VIEW IF EXISTS USA_Con1_Info CASCADE;
DROP VIEW IF EXISTS CA_Con2_Info CASCADE;
DROP VIEW IF EXISTS USA_Con2_Info CASCADE;
DROP VIEW IF EXISTS CA_Con2 CASCADE;
DROP VIEW IF EXISTS USA_Con2 CASCADE;
DROP VIEW IF EXISTS Con2 CASCADE;
DROP VIEW IF EXISTS Direct_Int_Info CASCADE;
DROP VIEW IF EXISTS Direct_Int CASCADE;
DROP VIEW IF EXISTS Con1_Int_Info CASCADE;
DROP VIEW IF EXISTS Con1_Int CASCADE;
DROP VIEW IF EXISTS Con2_Int_Info CASCADE;
DROP VIEW IF EXISTS Con2_Int CASCADE;
DROP VIEW IF EXISTS Earlist_Result_Combo CASCADE;
DROP VIEW IF EXISTS Earlist_Result CASCADE;
DROP VIEW IF EXISTS TEST CASCADE;


-- Define views for your intermediate steps here:

CREATE VIEW USACity AS
SELECT DISTINCT city
FROM airport
WHERE country = 'USA';

CREATE VIEW CanadaCity AS
SELECT DISTINCT city
FROM airport
WHERE country = 'Canada';

CREATE VIEW CA_USA AS
SELECT CanadaCity.city AS inbound,  USACity.city AS outbound
FROM CanadaCity, USACity;

CREATE VIEW USA_CA AS
SELECT USACity.city AS inbound, CanadaCity.city AS outbound
FROM CanadaCity, USACity;

CREATE VIEW In_Out_Combo AS
SELECT outbound, inbound
FROM CA_USA 
UNION 
SELECT outbound, inbound
FROM USA_CA
ORDER BY outbound DESC;



CREATE VIEW CA_Dep AS
SELECT city AS outbound, inbound, s_dep, s_arv
FROM flight JOIN airport ON flight.outbound = airport.code
WHERE country = 'Canada' and s_dep >= timestamp'Apr-30-2022 00:00' and s_arv <= timestamp'Apr-30-2022 23:59';

CREATE VIEW USA_Dep AS
SELECT city AS outbound, inbound, s_dep, s_arv
FROM flight JOIN airport ON flight.outbound = airport.code
WHERE country = 'USA' and s_dep >= timestamp'Apr-30-2022 00:00' and s_arv <= timestamp'Apr-30-2022 23:59';

CREATE VIEW CA_Direct_USA AS
SELECT outbound, city AS inbound, s_dep, s_arv
FROM CA_Dep JOIN airport ON CA_Dep.inbound = airport.code
WHERE country = 'USA';

CREATE VIEW USA_Direct_CA AS
SELECT outbound, city AS inbound, s_dep, s_arv
FROM USA_Dep JOIN airport ON USA_Dep.inbound = airport.code
WHERE country = 'Canada';

CREATE VIEW Direct_Info AS
SELECT outbound, inbound
FROM CA_Direct_USA
UNION ALL
SELECT outbound, inbound
FROM USA_Direct_CA
ORDER BY outbound DESC;

CREATE VIEW Direct_Count AS
SELECT outbound, inbound, count(outbound) AS direct
FROM Direct_Info
GROUP BY outbound, inbound;

CREATE VIEW CA_Con1 AS
SELECT CA_Dep.outbound, airport.city AS inbound, count(CA_Dep.outbound) AS one_con
FROM CA_Dep JOIN flight ON CA_Dep.inbound = flight.outbound JOIN airport ON flight.inbound = airport.code
WHERE (flight.s_dep - CA_Dep.s_arv) > interval '30 minutes' AND CA_Dep.outbound != airport.city
GROUP BY CA_Dep.outbound, airport.city;

CREATE VIEW USA_Con1 AS
SELECT USA_Dep.outbound, airport.city AS inbound, count(USA_Dep.outbound) AS one_con
FROM USA_Dep JOIN flight ON USA_Dep.inbound = flight.outbound JOIN airport ON flight.inbound = airport.code
WHERE (flight.s_dep - USA_Dep.s_arv) > interval '30 minutes' AND USA_Dep.outbound != airport.city
GROUP BY USA_Dep.outbound, airport.city;

CREATE VIEW Con1 AS
SELECT outbound, inbound, one_con
FROM CA_Con1
UNION ALL
SELECT outbound, inbound, one_con
FROM USA_Con1;




CREATE VIEW CA_Con1_Info AS
SELECT CA_Dep.outbound, flight.outbound AS con1, airport.city AS inbound,flight.s_arv AS s_arv
FROM CA_Dep JOIN flight ON CA_Dep.inbound = flight.outbound JOIN airport ON flight.inbound = airport.code
WHERE (flight.s_dep - CA_Dep.s_arv) > interval '30 minutes' AND CA_Dep.outbound != airport.city;

CREATE VIEW USA_Con1_Info AS
SELECT USA_Dep.outbound, flight.outbound AS con1, airport.city AS inbound,flight.s_arv AS s_arv
FROM USA_Dep JOIN flight ON USA_Dep.inbound = flight.outbound JOIN airport ON flight.inbound = airport.code
WHERE (flight.s_dep - USA_Dep.s_arv) > interval '30 minutes' AND USA_Dep.outbound != airport.city;

CREATE VIEW CA_Con2_Info AS
SELECT CA_Con1_Info.outbound, CA_Con1_Info.con1, flight.outbound AS con2, airport.city AS inbound, flight.s_arv AS s_arv
FROM CA_Con1_Info JOIN flight ON CA_Con1_Info.inbound = flight.outbound JOIN airport ON flight.inbound = airport.code
WHERE (flight.s_dep - CA_Con1_Info.s_arv) > interval '30 minutes' AND CA_Con1_Info.outbound != airport.city;

CREATE VIEW USA_Con2_Info AS
SELECT USA_Con1_Info.outbound, USA_Con1_Info.con1, flight.outbound AS con2, airport.city AS inbound, flight.s_arv AS s_arv
FROM USA_Con1_Info JOIN flight ON USA_Con1_Info.inbound = flight.outbound JOIN airport ON flight.inbound = airport.code
WHERE (flight.s_dep - USA_Con1_Info.s_arv) > interval '30 minutes' AND USA_Con1_Info.outbound != airport.city;




CREATE VIEW CA_Con2 AS
SELECT outbound,  inbound, count(outbound) AS two_con
FROM CA_Con2_Info
GROUP BY outbound, inbound;

CREATE VIEW USA_Con2 AS
SELECT outbound,  inbound, count(outbound) AS two_con
FROM USA_Con2_Info
GROUP BY outbound, inbound;


CREATE VIEW Con2 AS
SELECT outbound, inbound, two_con
FROM CA_Con2
UNION ALL
SELECT outbound, inbound, two_con
FROM USA_Con2;




CREATE VIEW Direct_Int_Info AS
SELECT outbound, inbound, s_dep, s_arv
FROM CA_Direct_USA
UNION ALL
SELECT outbound, inbound, s_dep, s_arv
FROM USA_Direct_CA
ORDER BY outbound DESC;

CREATE VIEW Direct_Int AS
SELECT outbound, inbound, min(s_arv) AS earliest
FROM Direct_Int_Info
GROUP BY outbound, inbound;



CREATE VIEW Con1_Int_Info AS
SELECT outbound, inbound, s_arv
FROM CA_Con1_Info
UNION ALL
SELECT outbound, inbound, s_arv
FROM USA_Con1_Info
ORDER BY outbound DESC;

CREATE VIEW Con1_Int AS
SELECT outbound, inbound, min(s_arv) AS earliest
FROM Con1_Int_Info
GROUP BY outbound, inbound;


CREATE VIEW Con2_Int_Info AS
SELECT outbound, inbound, s_arv
FROM CA_Con2_Info
UNION ALL
SELECT outbound, inbound, s_arv
FROM USA_Con2_Info
ORDER BY outbound DESC;

CREATE VIEW Con2_Int AS
SELECT outbound, inbound, min(s_arv) AS earliest
FROM Con2_Int_Info
GROUP BY outbound, inbound;

CREATE VIEW Earlist_Result_Combo AS
SELECT Direct_Int.outbound, Direct_Int.inbound,  Direct_Int.earliest
FROM Direct_Int 
UNION ALL
SELECT Con1_Int.outbound, Con1_Int.inbound,  Con1_Int.earliest
FROM Con1_Int
UNION ALL
SELECT Con2_Int.outbound, Con2_Int.inbound,  Con2_Int.earliest
FROM Con2_Int;

CREATE VIEW Earlist_Result AS
SELECT outbound, inbound,  min(earliest) AS earliest
FROM Earlist_Result_Combo 
GROUP BY outbound, inbound;

CREATE VIEW TEST AS
SELECT In_Out_Combo.outbound, In_Out_Combo.inbound, COALESCE(Direct_Count.direct,0) AS direct, COALESCE(Con1.one_con,0) AS one_con, COALESCE(Con2.two_con,0) AS two_con,earliest
FROM Direct_Count NATURAL FULL JOIN Con1 NATURAL FULL JOIN Con2 NATURAL FULL JOIN Earlist_Result NATURAL FULL JOIN In_Out_Combo;



-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q3
(SELECT outbound,inbound, direct, one_con, two_con,earliest FROM TEST)
