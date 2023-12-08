-- schema for skippers
-- Our schema satisfies all FDs in S and resulted in no redundancies
-- User have the option to join Skipper and Model to retrieve all attributes in original Reservation relation 
DROP schema if exists reservation cascade;
CREATE schema reservation;
SET search_path to reservation;

CREATE TABLE Skipper (
  sID INTEGER PRIMARY KEY,
  sName VARCHAR(50) NOT NULL,
  rating INTEGER NOT NULL
  check(rating in (0,1,2,3,4,5)),
  age INTEGER NOT NULL
  check (age>=0),
  day INTEGER NOT NULL
);

CREATE TABLE Model (
  sID INTEGER NOT NULL,
  day INTEGER NOT NULL,
  mID INTEGER NOT NULL,
  dID INTEGER NOT NULL,
  length INTEGER NOT NULL,
  PRIMARY KEY(sID,day)
);

