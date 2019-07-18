# hotelmanagement
SQL project code

# Tasks:
1. Create a database with name hotelmanagementProject

2. Inside this database, create the following tables:
* Hotel, with attributes name,street-number,street-name,city,zip,phone,manager-name. Each
hotel has a unique name. Attributes street-number,street-name,city,zip give the address of the hotel. The phone must hold a full number with area code. Each hotel has only one address, one phone, and one manager.

* Capacity with attributes hotel-id, type, number. The first attribute is a reference to the
hotel, the second is a type of room (always one of 'regular', 'extra', 'family' or 'suite'), and
number indicates how many rooms of the given type that hotel has. Each hotel may have several
types of rooms.

* Customer(cust-id,name,street,city,zip,status). The first one is an identifier and should be
generated by the system. Attributes number,street,city,zip give the address of the customer.
status is one 'gold', 'silver', 'business'. Each customer has only one name, one address, and one
status.

* Reservation(hotel-name,cust-id,room-type,begin-date,end-date,credit-card-number,exp-date)
that states a customer cust-id has made a reservation of a room of type room-type in hotel
hotel-name from begin-date to end-date, paying with credit card credit-card-number with
expiration date exp-date. It is assumed that each customer can make several reservations (and,
of course, a hotel may take several reservations), but a customer can only make one reservation
in a given hotel for a given date.

You will have to pick primary keys, foreign keys, and adequate data types for each attribute. Make
sure to enforce that values entered in any table obey the constraints noted. Make sure to declare all
primary key and all foreign keys in order to have integrity constraints!

3. Insert at least five tuples into each relation (you can make up the values, but they should be valid
data, i.e. respecting all constraints).

4. Add a table OCCUPANCY(hotel-name,type,number) that keeps track, for a given hotel, of how many
rooms of that type are occupied. You will update this table automatically by writing a trigger that
will, when a reservation is made, check that a room of the type requested is still available in the given
hotel (compare current occupancy with the hotel's capacity). If a room of that type is not available,
the reservation should be rejected; otherwise, the reservation should be allowed and table OCCUPANCY
should be updated to reflect this new reservation. NOTE: you should populate this table once when
you create it, and then update its value with this trigger as needed. The update should involve only
modifying whatever values are necessary, never redoing the whole table.

5. Add a table PREFERREDCUSTOMER(cust-id,cust-name,hotel-name) that will keep track of 'preferred'
customers and their 'favorite' hotels. A 'preferred' customer is one that has stayed more than 100 days
in total in any combination of hotels. The 'favorite' hotel of a preferred customer is the one where the
customer has stayed the longest (i.e. the hotel where the customer has spent the most days, not the
one with the most reservations). Update this table whenever there is a reservation. NOTE: you should
populate this table once when you create it, and then update its value with this trigger as needed. The
update should involve only modifying whatever values are necessary, never redoing the whole table.
