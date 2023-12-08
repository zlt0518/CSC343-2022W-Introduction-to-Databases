-- Q1. Airlines

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1 (
    pass_id INT,
    name VARCHAR(100),
    airlines INT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.

DROP VIEW IF EXISTS Passenger_Flight CASCADE;

-- Define views for your intermediate steps here:
CREATE VIEW Passenger_Flight AS 
SELECT Booking.pass_id AS passenger_id,Departure.flight_id AS flight_id ,Flight.airline AS airline
FROM Departure, Flight, Booking
WHERE Departure.flight_id = Flight.id AND
      Booking.flight_id = Departure.flight_id;




-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q1
SELECT  Passenger.id AS pass_id, 
        CONCAT(Passenger.firstname, ' ', Passenger.surname) AS "name",
        COUNT(distinct Passenger_Flight.airline) AS Airlines
FROM Passenger LEFT OUTER JOIN Passenger_Flight  ON Passenger.id = Passenger_Flight.passenger_id
GROUP BY Passenger.id;

