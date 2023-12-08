"""
# This code is provided solely for the personal and private use of students 
# taking the CSC343H course at the University of Toronto. Copying for purposes 
# other than this use is expressly prohibited. All forms of distribution of 
# this code, including but not limited to public repositories on GitHub, 
# GitLab, Bitbucket, or any other online platform, whether as given or with 
# any changes, are expressly prohibited. 
"""
# This file is written by Litao Zhou(1006013092) and Shaoheng Wang(1003945181) in CSC343H 2022W 

from re import A
from typing import Optional
import psycopg2 as pg
import datetime

class Assignment2:

    ##### DO NOT MODIFY THE CODE BELOW. #####

    def __init__(self) -> None:
        """Initialize this class, with no database connection yet.
        """
        self.db_conn = None

    
    def connect_db(self, url: str, username: str, pword: str) -> bool:
        """Connect to the database at url and for username, and SET the
        search_path to "air_travel". Return True iff the connection was made
        successfully.

        >>> a2 = Assignment2()
        >>> # This example will make sense if you change the arguments as
        >>> # appropriate for you.
        >>> a2.connect_db("csc343h-<your_username>", "<your_username>", "")
        True
        >>> a2.connect_db("test", "postgres", "password") # test doesn't exist
        False
        """
        try:
            self.db_conn = pg.connect(dbname=url, user=username, password=pword,
                                      options="-c search_path=air_travel")
        except pg.Error:
            return False

        return True

    def disconnect_db(self) -> bool:
        """Return True iff the connection to the database was closed
        successfully.

        >>> a2 = Assignment2()
        >>> # This example will make sense if you change the arguments as
        >>> # appropriate for you.
        >>> a2.connect_db("csc343h-<your_username>", "<your_username>", "")
        True
        >>> a2.disconnect_db()
        True
        """
        try:
            self.db_conn.close()
        except pg.Error:
            return False

        return True

    ##### DO NOT MODIFY THE CODE ABOVE. #####

    # ----------------------- Airline-related methods ------------------------- */

    def book_seat(self, pass_id: int, flight_id: int, seat_class: str) -> Optional[bool]:


        """Attempts to book a flight for a passenger in a particular seat class. 
        Does so by inserting a row into the Booking table.
        
        Read the handout for information on how seats are booked.

        Parameters:
        * pass_id - id of the passenger
        * flight_id - id of the flight
        * seat_class - the class of the seat

        Precondition:
        * seat_class is one of "economy", "business", or "first".
        
        Return: 
        * True iff the booking was successful.
        * False iff the seat can't be booked, or if the passenger or flight cannot be found.
        """
        try:
            
            plane_num = 0 
            seat_row = 0
            seat_row_spot = "G"
            price = 0

            #check the existence of the passenger and the existence of the flight
            cursor = self.db_conn.cursor()
            cursor.execute("SELECT * FROM passenger WHERE id= %s::int",(pass_id,))
            check  = cursor.fetchone()
            if check == None:
                #print("Could not found the passenger")
                return False
            #print("seat found!")

            cursor.execute("SELECT plane FROM flight WHERE id= %s::int",(flight_id,))
            check  = cursor.fetchone()
            if check == None:
                #print("Could not found the flight")
                return False
           

            #get the plane number 
            plane_num = check[0]

            #get the capicity
            cursor.execute(f"""SELECT tail_number,capacity_economy,capacity_business,capacity_first
                            FROM plane 
                            WHERE tail_number='{plane_num}'
                            """)

            capicity  = cursor.fetchone()
            econ_capicity = capicity[1]
            bus_capicity = capicity[2]
            first_capicity = capicity[3]


            #check the valid class
            if seat_class not in ["economy","business","first"]:
                #print("Not a valid Class!")
                return False

            #get the list of people who bought the ticket
            cursor.execute(f"""SELECT count(*)
                            FROM booking 
                            WHERE flight_id={flight_id} AND 
                            seat_class = '{seat_class}'
                            """)

            already_booked  = cursor.fetchone()

            
            already_booked = already_booked[0]
            
            #print(f"already booked:{already_booked}")

            #get the price for the ticket and see if there is the info for the ticket
            cursor.execute(f"""SELECT *
                            FROM price 
                            WHERE flight_id = {flight_id}
                            """)

            price_list  = cursor.fetchone()
            if price_list == None:
                #print("No price info")
                return False

            #print(f"price list：{price_list}")

            if price_list==None:
                #print("No price Info found!")
                return False
            
            econ_price = price_list[1]
            bus_price = price_list[2]
            first_price= price_list[3]

            seat_row = already_booked//6+1
            seat_row_spot = chr(ord('A')+(already_booked)%6)

            #lets start to see if the seat's class
            if seat_class == "economy":
                if already_booked < econ_capicity:
                    #not oversell
                    if first_capicity !=0:
                        seat_row += (first_capicity-1)//6+1
                    
                    if bus_capicity!=0:
                        seat_row += (bus_capicity-1)//6+1 
                    
                    #change price
                    price = econ_price

                elif already_booked<=(econ_capicity+10):
                    seat_row = "NULL"
                    seat_row_spot = "NULL"
                    price = econ_price

                else:
                    #print(f"No enough{seat_class} spot")
                    return False


            elif seat_class == "business":

                if already_booked < bus_capicity:

                    if first_capicity !=0:
                        seat_row += (first_capicity-1)//6+1

                    price = bus_price
                    
                else:
                    #print(f"No enough{seat_class} spot")
                    return False


            elif seat_class == "first":
                #print("here!")
                if already_booked < first_capicity:

                    price = first_price

                else:
                    return False

            else:
                return False
            
            current_time = self._get_current_timestamp()
            #print(current_time)

            
            cursor.execute("(SELECT MAX(id) FROM booking)")
            booking_id_max = cursor.fetchone()

            booking_id = 1
            if booking_id_max is not None:
                booking_id = booking_id_max[0]+1

            if seat_row_spot != "NULL":
                cursor.execute(f"""INSERT INTO booking
                               VALUES (
                                   {booking_id},
                                   {pass_id},
                                   {flight_id},
                                   TIMESTAMP '{current_time}',
                                   {price},
                                   '{seat_class}',
                                   {seat_row},
                                   '{seat_row_spot}'
                               )
                                """)
                
            
            else:
                cursor.execute(f"""INSERT INTO booking
                               VALUES (
                                   {booking_id},
                                   {pass_id},
                                   {flight_id},
                                   TIMESTAMP '{current_time}',
                                   {price},
                                   '{seat_class}',
                                   {seat_row},
                                   {seat_row_spot}
                               )
                                """)
            self.db_conn.commit()


            return True
        
        except pg.Error:
            return None


    def upgrade(self, flight_id: int) -> Optional[int]:
        """Attempts to upgrade overbooked economy passengers to business class
        or first class (in that order until each seat class is filled).
        Does so by altering the database records for the bookings such that the
        seat and seat_class are UPDATEd if an upgrade can be processed.
        
        Upgrades should happen in order of earliest booking timestamp first.
        If economy passengers are left over without a seat (i.e. not enough higher class seats), 
        remove their bookings from the database.
        
        Parameters:
        * flight_id - the flight to upgrade passengers in
        
        Precondition: 
        * flight_id exists in the database (a valid flight id).
        
        Return: 
        * The number of passengers upgraded.
        """
        try:
            max_row_f = 0
            max_letter_num_f = 'A'
            count_f = 0
            count_b = 0
            cursor = self.db_conn.cursor()

            cursor.execute(f"""
            SELECT flight_id, count(*)
            FROM booking 
            WHERE flight_id = {flight_id}  and seat_class = 'first' 
            Group By (flight_id)""")
            booked_first = cursor.fetchall() 
            if cursor.rowcount == 0:
                max_row_f = 1
                max_letter_num_f = 'A'
            else:
                count_f = cursor.rowcount
                max_row_f =  (booked_first[0][1]+5) //6 
                max_letter_num_f =  chr(ord('A')+(booked_first[0][1])%6)
            #print(booked_first)

            cursor.execute(f"""
            SELECT flight_id, count(*) 
            FROM booking  
            WHERE flight_id = {flight_id} and seat_class = 'business' 
            Group By (flight_id)""")
            booked_business = cursor.fetchall()
            #print(booked_business)
            if cursor.rowcount == 0:
                max_row_b = max_row_f + 1
                max_letter_num_b = 'A'
            else:
                count_b = cursor.rowcount
                max_row_b =  (booked_business[0][1]+5) //6  + max_row_f
                max_letter_num_b =  chr(ord('A')+(booked_business[0][1])%6)

            cursor.execute(f"""
            SELECT flight_id, count(*)
            FROM booking  
            WHERE flight_id = {flight_id} and seat_class = 'economy'
            Group By (flight_id)""")
            booked_eco = cursor.fetchall()
            #print(booked_eco)

            cursor.execute(f"""
            SELECT flight.id, capacity_economy, capacity_business, capacity_first 
            FROM flight, plane 
            WHERE flight.id = {flight_id} 
            AND flight.plane = plane.tail_number""")
            flight_capacity = cursor.fetchall()
            #print(flight_capacity)
            i = 0
            #print("---------------------------------")
            
            
            

            #print(max_row_f)
            #print(max_letter_num_f)
            #print(max_row_b)
            #print(max_letter_num_b)
            #print("---------------------------------")
            max_up_business = flight_capacity[i][2]-count_b
            #print(max_up_business)
            max_up_first = flight_capacity[i][3]-count_f
            #print(max_up_first)
            count_up_business = 0
            count_up_first = 0
            if(booked_eco[i][1]<=flight_capacity[i][1]):
                #print("no need to perform upgrade")
                return 0
            else:
                cursor.execute(f"""
                SELECT id 
                FROM booking 
                WHERE flight_id = {flight_id} AND seat_class = 'economy' AND row is NULL AND letter is NULL 
                Order by datetime""")
                booked_null = cursor.fetchall()
                #print(booked_null)
                j = 0
                while j<len(booked_null):
                    #print("loop")
                    if max_up_business > 0:
                        #print("b u")
                        var1 = max_row_b
                        var2 = max_letter_num_b
                        #print(var1)
                        #print(var2)
                        #print(booked_null[j][0])
                        var3 = booked_null[j][0]
                        cursor.execute(f"""
                        UPDATE booking
                        SET seat_class = 'business', row = {var1}, letter = '{var2}'
                        WHERE booking.id = {var3} """)
                        #print("ok")
                        self.db_conn.commit()
                        #print("ok2")
                        max_up_business-=1
                        count_up_business+=1
                        cursor.execute(f"""
                        SELECT flight_id, count(*) 
                        FROM booking  
                        WHERE flight_id = {flight_id} and seat_class = 'business' 
                        Group By (flight_id)""")
                        booked_business = cursor.fetchall()
                        #print(booked_business)
                        if cursor.rowcount == 0:
                            max_row_b = max_row_f + 1
                            max_letter_num_b = 'A'
                        else:
                            count_b = cursor.rowcount
                            max_row_b =  (booked_business[0][1]+5) //6  + max_row_f
                            max_letter_num_b =  chr(ord('A')+(booked_business[0][1])%6)
                    elif max_up_first > 0 and max_up_business <= 0:
                        #print("here")
                        var1 = max_row_f
                        var2 = max_letter_num_f
                        var3 = booked_null[j][0]
                        #print(var1)
                        #print(var2)
                        #print(booked_null[j][0])
                        cursor.execute(f"""
                        UPDATE booking
                        SET seat_class = 'first', row = {var1}, letter = '{var2}'
                        WHERE booking.id = {var3} """)
                        #print("ok")
                        self.db_conn.commit()
                        #print("ok2")
                        max_up_first-=1
                        count_up_first+=1
                        cursor.execute(f"""
                        SELECT flight_id, count(*)
                        FROM booking 
                        WHERE flight_id = {flight_id}  and seat_class = 'first' 
                        Group By (flight_id)""")
                        booked_first = cursor.fetchall() 
                        if cursor.rowcount == 0:
                            max_row_f = 1
                            max_letter_num_f = 'A'
                        else:
                            count_f = cursor.rowcount
                            max_row_f =  (booked_first[0][1]+5) //6 
                            max_letter_num_f =  chr(ord('A')+(booked_first[0][1])%6)
                        #print(booked_first)                     
                    else:
                        #print("end")
                        var1 = booked_null[j][0]
                        #print(booked_null[j][0])
                        cursor.execute(f"""
                        delete from booking  
                        WHERE booking.id = {var1}""")
                        self.db_conn.commit()
                    j = j+1
                return count_up_business + count_up_first          
            pass
        except pg.Error:
            return None


# ----------------------- Helper methods below  ------------------------- */
    

    # A helpful method for adding a timestamp to new bookings.
    def _get_current_timestamp(self):
        """Return a datetime object of the current time, formatted as required
        in our database.
        """
        return datetime.datetime.now().replace(microsecond=0)

   
    ## Add more helper methods below if desired.                                                                                                                                                                                                                                                                                                                                                                           


# ----------------------- Testing code below  ------------------------- */

def sample_testing_function() -> None:
    a2 = Assignment2()
    # TODO: Change this to connect to your own database:
    print(a2.connect_db("csc343h-wangs293", "wangs293", ""))
    # TODO: Test one or more methods here.

    a2.upgrade(10)
    a2.db_conn.commit()


## You can put testing code in here. It will not affect our autotester.
if __name__ == '__main__':
    # TODO: Put your testing code here, or call testing functions such as
    # this one:
    sample_testing_function()



