-- operation 1: Add a new customer (individual)
EXPLAIN PLAN FOR
INSERT INTO Customers VALUES (
    Individual_t(
        'TEST_CODE', 
        ContactInfo_t('test@email.com', '555-0001'),
        Anagraphic_t('John', 'Doe', TO_DATE('1990-01-01', 'YYYY-MM-DD'), 'M')
    )
);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- operation 1: Add a new customer (company)
EXPLAIN PLAN FOR
INSERT INTO Customers VALUES (
    Company_t(
        'TEST_COMPANY', 
        ContactInfo_t('company@email.com', '555-0002'),
        'Test Company Inc', 
        'IT12345678'
    )
);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Operation 2: Add a new booking (one-time)
EXPLAIN PLAN FOR
INSERT INTO Bookings VALUES (
    Booking_t(
        -1,  -- Placeholder for sequence
        SYSDATE,
        120,
        (SELECT REF(t) FROM Teams t WHERE name = 'Team 1'),
        -- (SELECT REF(c) FROM Customers c WHERE code = 'IND1'),
        (SELECT REF(i) FROM Installations i WHERE name = 'Installation 1'),
        (SELECT REF(e) FROM EventLocations e WHERE code = 1)
    )
);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Operation 2: Add a new booking (recurrent)
EXPLAIN PLAN FOR
INSERT INTO Bookings VALUES (
    RecurrentBooking_t(
        -1,  -- Placeholder for sequence
        SYSDATE,
        120,
        (SELECT REF(t) FROM Teams t WHERE name = 'Team 1'),
        -- (SELECT REF(c) FROM Customers c WHERE code = 'IND1'),
        (SELECT REF(i) FROM Installations i WHERE name = 'Installation 1'),
        (SELECT REF(e) FROM EventLocations e WHERE code = 1),
        7,     -- interval
        10     -- n_times
    )
);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Query 3: Insert the event location
EXPLAIN PLAN FOR
INSERT INTO EventLocations 
    (code, location, postal_code, house_number, setup_time_estimate, eq_capacity, customer)
VALUES (
    -1,  -- Placeholder for sequence
    Location_t('Sicily', 'PA', 'Palermo', 'Via Roma 1'),
    '90100',
    '42',
    60,
    500,
    (SELECT REF(c) FROM Customers c WHERE code = 'IND1')
);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Operation 4: Get teams that have made bookings at a specific event location
EXPLAIN PLAN FOR
SELECT DEREF(b.team).id AS team_id,
    DEREF(b.team).name AS team_name, 
    DEREF(b.team).n_installations_made AS installations
FROM Bookings b
WHERE b.event_location = (SELECT REF(e) FROM EventLocations e WHERE code = 1);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Operation 5: Get event locations ranked by number of bookings
EXPLAIN PLAN FOR
SELECT DEREF(b.event_location).code AS loc_code,
    DEREF(b.event_location).location.address AS loc_address,
    DEREF(b.event_location).location.city AS loc_city,
    COUNT(*) AS total_bookings
FROM Bookings b
GROUP BY b.event_location, 
         DEREF(b.event_location).code,
         DEREF(b.event_location).location.address, 
         DEREF(b.event_location).location.city
ORDER BY total_bookings DESC;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

EXPLAIN PLAN FOR
SELECT b.event_location, COUNT(*) as total_bookings
FROM Bookings b
GROUP BY b.event_location;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);