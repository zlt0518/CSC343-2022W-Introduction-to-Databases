-- Q2. Refunds!

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO air_travel;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2 (
    airline CHAR(2),
    name VARCHAR(50),
    year CHAR(4),
    seat_class seat_class,
    refund REAL
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS Completed_Flight CASCADE;
DROP VIEW IF EXISTS Flight_Info CASCADE;
DROP VIEW IF EXISTS Dom_delayed_1 CASCADE;
DROP VIEW IF EXISTS Dom_delayed_2 CASCADE;
DROP VIEW IF EXISTS Inter_delayed_1 CASCADE;
DROP VIEW IF EXISTS Inter_delayed_2 CASCADE;
DROP VIEW IF EXISTS Dom_return_1 CASCADE;
DROP VIEW IF EXISTS Dom_return_2 CASCADE;
DROP VIEW IF EXISTS Inter_return_1 CASCADE;
DROP VIEW IF EXISTS Inter_return_2 CASCADE;
DROP VIEW IF EXISTS Total_return CASCADE;
DROP VIEW IF EXISTS Total_return_name CASCADE;




-- Define views for your intermediate steps here:
CREATE VIEW Completed_Flight AS 
SELECT Arrival.flight_id AS flight_id,
       flight.airline AS airline,
       flight.outbound AS outbound,
       flight.inbound AS inbound,
       flight.s_dep as scheduled_departure,
       Departure.datetime as actural_departure,
       Flight.s_arv as scheduled_arrival,
       Arrival.datetime as actural_arrival

FROM Arrival, flight, Departure 
WHERE 
    Arrival.flight_id = flight.id AND
    Departure.flight_id = flight.id;



CREATE VIEW Flight_Info AS
SELECT F.flight_id AS flight_id,
       F.airline AS airline,
       inbound_airport.country AS outbound_country,
       outbound_airport.country AS inbound_country,
       F.scheduled_departure as scheduled_departure,
       F.actural_departure as actural_departure,
       F.scheduled_arrival as scheduled_arrival,
       F.actural_arrival as actural_arrival
FROM  Completed_Flight F, Airport inbound_airport, Airport outbound_airport
WHERE F.inbound = inbound_airport.code AND
      F.outbound = outbound_airport.code AND
      (F.actural_departure-F.scheduled_departure)<=(F.actural_arrival-F.scheduled_arrival)*2;


-----------------Devided into four parts and get the flight that need to refund---------------------

CREATE VIEW Dom_delayed_1 AS
SELECT flight_id,airline,EXTRACT(Year FROM actural_departure) AS year
FROM Flight_Info 
WHERE outbound_country=inbound_country AND
      (actural_departure-scheduled_departure)>='05:00:00' AND
      (actural_departure-scheduled_departure)<'10:00:00';
    --   (actural_departure-scheduled_departure)<=(actural_arrival-scheduled_arrival)*2;
      

CREATE VIEW Dom_delayed_2 AS
SELECT flight_id,airline,EXTRACT(Year FROM actural_departure) AS year,(actural_arrival - scheduled_arrival) AS test
FROM Flight_Info 
WHERE outbound_country=inbound_country AND
      (actural_departure-scheduled_departure)>='10:00:00';
    --   (actural_departure-scheduled_departure)<=(actural_arrival-scheduled_arrival)*2;


CREATE VIEW Inter_delayed_1 AS
SELECT flight_id,airline,EXTRACT(Year FROM actural_departure) AS year
FROM Flight_Info 
WHERE outbound_country<>inbound_country AND
      (actural_departure-scheduled_departure)>='08:00:00' AND
      (actural_departure-scheduled_departure)<'12:00:00';
    --   (actural_departure-scheduled_departure)<=(actural_arrival-scheduled_arrival)*2;


CREATE VIEW Inter_delayed_2 AS
SELECT flight_id,airline,EXTRACT(Year FROM actural_departure) AS year
FROM Flight_Info 
WHERE outbound_country<>inbound_country AND
      (actural_departure-scheduled_departure)>='12:00:00';
    --   (actural_departure-scheduled_departure)<=(actural_arrival-scheduled_arrival)*2;

-----------------Devided into four parts and use the flight to calculate the refund---------------------

CREATE VIEW Dom_return_1 AS
SELECT Dom_delayed_1.flight_id AS flight_id, 
       Dom_delayed_1.airline AS airline, 
       Dom_delayed_1.year AS year,
       Booking.seat_class AS class,
       (Booking.price*0.35) AS returned_money
FROM Dom_delayed_1, Booking
WHERE Dom_delayed_1.flight_id = Booking.flight_id;

CREATE VIEW Dom_return_2 AS
SELECT Dom_delayed_2.flight_id AS flight_id, 
       Dom_delayed_2.airline AS airline, 
       Dom_delayed_2.year AS year,
       Booking.seat_class AS class,
       (Booking.price*0.5) AS returned_money
FROM Dom_delayed_2, Booking
WHERE Dom_delayed_2.flight_id = Booking.flight_id;


CREATE VIEW Inter_return_1 AS
SELECT Inter_delayed_1.flight_id AS flight_id, 
       Inter_delayed_1.airline AS airline, 
       Inter_delayed_1.year AS year,
       Booking.seat_class AS class,
       (Booking.price*0.35) AS returned_money
FROM Inter_delayed_1, Booking
WHERE Inter_delayed_1.flight_id = Booking.flight_id;


CREATE VIEW Inter_return_2 AS
SELECT Inter_delayed_2.flight_id AS flight_id, 
       Inter_delayed_2.airline AS airline, 
       Inter_delayed_2.year AS year,
       Booking.seat_class AS class,
       (Booking.price*0.5) AS returned_money
FROM Inter_delayed_2, Booking
WHERE Inter_delayed_2.flight_id = Booking.flight_id;

--------------------concat four table------------------------

CREATE VIEW Total_return AS
    (SELECT * from Dom_return_1) UNION ALL
    (SELECT * from Dom_return_2) UNION ALL
    (SELECT * from Inter_return_1) UNION ALL
    (SELECT * from Inter_return_2);


CREATE VIEW Total_return_name AS 
SELECT Total_return.flight_id AS flight_id, 
       Total_return.airline AS airline,
       Airline.name AS name,
       Total_return.year AS year,
       Total_return.class AS seat_class,
       Total_return.returned_money AS returned_money

FROM Total_return,Airline
WHERE Total_return.airline = Airline.code;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
SELECT airline,name,year,seat_class,SUM(returned_money) AS refund
FROM Total_return_name
GROUP BY (airline,name,year,seat_class);
