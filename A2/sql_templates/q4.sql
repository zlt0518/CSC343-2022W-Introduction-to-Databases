-- Q4. Plane Capacity Histogram

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4 (
	airline CHAR(2),
	tail_number CHAR(5),
	very_low INT,
	low INT,
	fair INT,
	normal INT,
	high INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS Completed_Flight CASCADE;
DROP VIEW IF EXISTS Plane_Info CASCADE;
DROP VIEW IF EXISTS Plane_Passenger_Info CASCADE;
DROP VIEW IF EXISTS Plane_Capicity_Info CASCADE;
DROP VIEW IF EXISTS Plane_Passenger_Count_Info CASCADE;
DROP VIEW IF EXISTS Very_Low_Plane CASCADE;
DROP VIEW IF EXISTS Low_Plane CASCADE;
DROP VIEW IF EXISTS Fair_Plane CASCADE;
DROP VIEW IF EXISTS Normal_Plane CASCADE;
DROP VIEW IF EXISTS High_Flight CASCADE;
DROP VIEW IF EXISTS VL_L_Plane CASCADE;
DROP VIEW IF EXISTS VL_F_Plane CASCADE;
DROP VIEW IF EXISTS VL_N_Plane CASCADE;
DROP VIEW IF EXISTS VL_H_Plane CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW Completed_Flight AS
SELECT Arrival.flight_id AS flight_id, 
	   Flight.plane AS plane

FROM Arrival, Flight 
WHERE Arrival.flight_id = Flight.id;

CREATE VIEW Plane_Info AS
SELECT Completed_Flight.flight_id AS flight_id,
       Plane.tail_number AS tail_number,

	   (Plane.capacity_economy+Plane.capacity_business+Plane.capacity_first) AS capicity_num
FROM Completed_Flight,Plane
WHERE Completed_Flight.plane = Plane.tail_number;

-- CREATE VIEW Plane_Info AS
-- SELECT Flight.id AS flight_id,
--        Plane.tail_number AS tail_number,
-- 	   (Plane.capacity_economy+Plane.capacity_business+Plane.capacity_first) AS capicity_num

-- FROM  Flight, Plane
-- WHERE Flight.plane = Plane.tail_number;


CREATE View Plane_Passenger_Info AS
SELECT Plane_Info.flight_id AS flight_id,
       Plane_Info.tail_number AS tail_number,
	   Plane_Info.capicity_num as capicity_num, 
	   Booking.id AS booking_id
FROM Plane_Info LEFT OUTER JOIN Booking
ON Plane_Info.flight_id = Booking.flight_id;


CREATE VIEW Plane_Passenger_Count_Info AS
SELECT flight_id, tail_number,capicity_num, COUNT(booking_id) AS booking_num
FROM Plane_Passenger_Info
GROUP BY flight_id, tail_number,capicity_num;

CREATE View Plane_Capicity_Info AS
SELECT flight_id,tail_number, (booking_num*100/capicity_num) AS capicity
FROM Plane_Passenger_Count_Info;


-- -----------CREATE THE TABLE
-- CREATE View Very_Low_Plane AS
-- SELECT tail_number,SUM(CASE when capicity>=0 AND capicity<20 THEN 1 ELSE 0 END) AS very_low
-- FROM Plane_Capicity_Info
-- GROUP BY tail_number;

-- CREATE View Normal_Plane AS
-- SELECT tail_number,SUM(CASE when capicity>=60 AND capicity<80 THEN 1 ELSE 0 END) AS normal
-- FROM Plane_Capicity_Info
-- GROUP BY tail_number;

CREATE View Very_Low_Plane AS
SELECT DISTINCT( Plane_Capicity_Info.tail_number) AS tail_number, nmd.num AS very_low
FROM Plane_Capicity_Info LEFT OUTER JOIN(
    SELECT tail_number,COUNT(flight_id) AS num
    FROM Plane_Capicity_Info
    WHERE capicity>=0 AND capicity<20
	GROUP BY tail_number
    ) nmd   
ON nmd.tail_number = Plane_Capicity_Info.tail_number;


CREATE View Low_Plane AS
SELECT DISTINCT( Plane_Capicity_Info.tail_number) AS tail_number,nmd.num AS low
FROM Plane_Capicity_Info LEFT OUTER JOIN(
    SELECT tail_number,COUNT(flight_id) AS num
    FROM Plane_Capicity_Info
    WHERE capicity>=20 AND capicity<40
	GROUP BY tail_number
    ) nmd   
ON nmd.tail_number= Plane_Capicity_Info.tail_number;


CREATE View Fair_Plane AS
SELECT DISTINCT( Plane_Capicity_Info.tail_number) AS tail_number, nmd.num AS fair
FROM Plane_Capicity_Info LEFT OUTER JOIN(
    SELECT tail_number,COUNT(flight_id) AS num
    FROM Plane_Capicity_Info
    WHERE capicity>=40 AND capicity<60
	GROUP BY tail_number
    )nmd   
ON nmd.tail_number= Plane_Capicity_Info.tail_number;


CREATE View Normal_Plane AS
SELECT DISTINCT( Plane_Capicity_Info.tail_number) AS tail_number,  nmd.num  AS normal
FROM Plane_Capicity_Info LEFT OUTER JOIN(
    SELECT tail_number,COUNT(flight_id) AS num
    FROM Plane_Capicity_Info
    WHERE capicity>=60 AND capicity<80
	GROUP BY tail_number
    )nmd   
ON nmd.tail_number= Plane_Capicity_Info.tail_number;


CREATE View High_Plane AS
SELECT DISTINCT( Plane_Capicity_Info.tail_number) AS tail_number, nmd.num AS high
FROM Plane_Capicity_Info LEFT OUTER JOIN(
    SELECT tail_number,COUNT(flight_id) AS num
    FROM Plane_Capicity_Info
    WHERE capicity>=80 AND capicity<100
	GROUP BY tail_number
    ) nmd   
ON nmd.tail_number= Plane_Capicity_Info.tail_number;


-- CREATE View Very_Low_Plane AS
-- SELECT tail_number,coalesce(COUNT(flight_id),0) AS very_low
-- FROM Plane_Capicity_Info
-- WHERE capicity>=0 AND capicity<20
-- GROUP BY tail_number;

-- CREATE View Low_Plane AS
-- SELECT tail_number,coalesce(COUNT(flight_id),0) AS low
-- FROM Plane_Capicity_Info
-- WHERE capicity>=20 AND capicity<40
-- GROUP BY tail_number;

-- CREATE View Fair_Plane AS
-- SELECT tail_number,coalesce(COUNT(flight_id),0) AS fair
-- FROM Plane_Capicity_Info 
-- WHERE capicity>=40 AND capicity<60
-- GROUP BY tail_number;

-- CREATE View Normal_Plane AS
-- SELECT tail_number,coalesce(COUNT(flight_id),0) AS normal
-- FROM Plane_Capicity_Info
-- WHERE capicity>=60 AND capicity<80
-- GROUP BY tail_number;

-- CREATE View High_Plane AS
-- SELECT tail_number,coalesce(COUNT(flight_id),0) AS high
-- FROM Plane_Capicity_Info
-- WHERE capicity>=80 AND capicity<100
-- GROUP BY tail_number;

------Join the five table

CREATE View VL_L_Plane AS
SELECT VL.tail_number AS tail_number,
       VL.very_low AS very_low,
	   L.low AS low
FROM Very_Low_Plane VL, Low_Plane L
WHERE VL.tail_number = L.tail_number;


CREATE View VL_F_Plane AS
SELECT VL_L.tail_number AS tail_number,
       VL_L.very_low AS very_low,
	   VL_L.low AS low,
	   F.fair AS fair
FROM VL_L_Plane VL_L, Fair_Plane F
WHERE VL_L.tail_number = F.tail_number;


CREATE View VL_N_Plane AS
SELECT VL_F.tail_number AS tail_number,
       VL_F.very_low AS very_low,
	   VL_F.low AS low,
	   VL_F.fair AS fair,
	   N.normal AS normal
FROM VL_F_Plane VL_F, Normal_Plane N
WHERE VL_F.tail_number = N.tail_number;


CREATE View VL_H_Plane AS
SELECT 
       VL_N.tail_number AS tail_number,
       VL_N.very_low AS very_low,
	   VL_N.low AS low,
	   VL_N.fair AS fair,
	   VL_N.normal AS normal,
	   H.high AS high
FROM VL_N_Plane VL_N, High_Plane H
WHERE VL_N.tail_number = H.tail_number;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
SELECT Plane.airline,
       Plane.tail_number,
	   coalesce(VL_H.very_low,0), 
	   coalesce(VL_H.low, 0),
	   coalesce(VL_H.fair, 0),
	   coalesce(VL_H.normal, 0),
	   coalesce(VL_H.high,0)
FROM Plane LEFT OUTER JOIN  VL_H_Plane VL_H 
ON  Plane.tail_number = VL_H.tail_number;