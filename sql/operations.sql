CREATE OR REPLACE PROCEDURE add_new_individual_customer (
    p_code          IN VARCHAR2,
    p_email         IN VARCHAR2,
    p_phone         IN VARCHAR2,
    -- Individual attributes
    p_name          IN VARCHAR2,
    p_surname       IN VARCHAR2,
    p_date_of_birth IN DATE,
    p_gender        IN VARCHAR2
) IS
BEGIN
    INSERT INTO Customers VALUES (
        Individual_t(
            p_code, 
            ContactInfo_t(p_email, p_phone), 
            Anagraphic_t(p_name, p_surname, p_date_of_birth, p_gender)
        )
    );
    
    COMMIT;
    -- DBMS_OUTPUT.PUT_LINE('Individual Customer added successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- DBMS_OUTPUT.PUT_LINE('Error adding customer: ' || SQLERRM);
        -- Raise the error so the Python driver catches it as an exception
        RAISE_APPLICATION_ERROR(-20001, 'Error adding individual customer: ' || SQLERRM);
END add_new_individual_customer;
/

CREATE OR REPLACE PROCEDURE add_new_company_customer (
    p_code          IN VARCHAR2,
    p_email         IN VARCHAR2,
    p_phone         IN VARCHAR2,
    -- Company attributes
    p_company_name  IN VARCHAR2,
    p_vat_number    IN VARCHAR2
) IS
BEGIN
    INSERT INTO Customers VALUES (
        Company_t(
            p_code, 
            ContactInfo_t(p_email, p_phone), 
            p_company_name, 
            p_vat_number
        )
    );
    
    COMMIT;
    -- DBMS_OUTPUT.PUT_LINE('Company Customer added successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- DBMS_OUTPUT.PUT_LINE('Error adding customer: ' || SQLERRM);
        -- Raise the error so the Python driver catches it as an exception
        RAISE_APPLICATION_ERROR(-20001, 'Error adding company customer: ' || SQLERRM);
END add_new_company_customer;
/

CREATE OR REPLACE PROCEDURE add_new_one_time_booking (
    p_booking_date        IN DATE,
    p_duration            IN NUMBER,
    p_team_name           IN VARCHAR2,
    -- p_customer_code       IN VARCHAR2,
    p_installation_name   IN VARCHAR2,
    p_event_location_code IN NUMBER
) IS
    v_team_ref           REF Team_t;
    v_customer_ref       REF Customer_t;
    v_installation_ref   REF Installation_t;
    v_event_location_ref REF EventLocation_t;
BEGIN
    SELECT REF(t) INTO v_team_ref FROM Teams t WHERE name = p_team_name;
    -- SELECT REF(c) INTO v_customer_ref FROM Customers c WHERE code = p_customer_code;
    SELECT REF(i) INTO v_installation_ref FROM Installations i WHERE name = p_installation_name;
    SELECT REF(e) INTO v_event_location_ref FROM EventLocations e WHERE code = p_event_location_code;

    INSERT INTO Bookings VALUES (
        Booking_t(
            seq_bookings.NEXTVAL,
            p_booking_date,
            p_duration,
            v_team_ref,
            -- v_customer_ref,
            v_installation_ref,
            v_event_location_ref
        )
    );
    
    COMMIT;
    -- DBMS_OUTPUT.PUT_LINE('One-time Booking added successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- DBMS_OUTPUT.PUT_LINE('Error adding one-time booking: ' || SQLERRM);
        -- Raise the error so the Python driver catches it as an exception
        RAISE_APPLICATION_ERROR(-20001, 'Error adding one-time booking: ' || SQLERRM);
END add_new_one_time_booking;
/

CREATE OR REPLACE PROCEDURE add_new_recurrent_booking (
    p_booking_date        IN DATE,
    p_duration            IN NUMBER,
    p_team_name           IN VARCHAR2,
    -- p_customer_code       IN VARCHAR2,
    p_installation_name   IN VARCHAR2,
    p_event_location_code IN NUMBER,
    p_interval            IN NUMBER,
    p_n_times             IN NUMBER
) IS
    v_team_ref           REF Team_t;
    v_customer_ref       REF Customer_t;
    v_installation_ref   REF Installation_t;
    v_event_location_ref REF EventLocation_t;
BEGIN
    SELECT REF(t) INTO v_team_ref FROM Teams t WHERE name = p_team_name;
    -- SELECT REF(c) INTO v_customer_ref FROM Customers c WHERE code = p_customer_code;
    SELECT REF(i) INTO v_installation_ref FROM Installations i WHERE name = p_installation_name;
    SELECT REF(e) INTO v_event_location_ref FROM EventLocations e WHERE code = p_event_location_code;

    INSERT INTO Bookings VALUES (
        RecurrentBooking_t(
            seq_bookings.NEXTVAL,
            p_booking_date,
            p_duration,
            v_team_ref,
            -- v_customer_ref,
            v_installation_ref,
            v_event_location_ref,
            p_interval,
            p_n_times
        )
    );
    
    COMMIT;
    -- DBMS_OUTPUT.PUT_LINE('Recurrent Booking added successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- DBMS_OUTPUT.PUT_LINE('Error adding recurrent booking: ' || SQLERRM);
        -- Raise the error so the Python driver catches it as an exception
        RAISE_APPLICATION_ERROR(-20001, 'Error adding recurrent booking: ' || SQLERRM);
END add_new_recurrent_booking;
/

CREATE OR REPLACE PROCEDURE add_event_location (
    p_region               IN VARCHAR2,
    p_province             IN VARCHAR2,
    p_city                 IN VARCHAR2,
    p_address              IN VARCHAR2,
    
    p_postal_code          IN VARCHAR2,
    p_house_number         IN VARCHAR2,
    p_setup_time_estimate  IN NUMBER,
    p_eq_capacity          IN NUMBER,
    p_customer_code        IN VARCHAR2
) IS
    v_customer_ref REF Customer_t;
BEGIN
    SELECT REF(c) INTO v_customer_ref FROM Customers c WHERE code = p_customer_code;

    INSERT INTO EventLocations (code, location, postal_code, house_number, setup_time_estimate, eq_capacity, customer)
    VALUES (
        seq_event_locations.NEXTVAL,
        Location_t(p_region, p_province, p_city, p_address), 
        p_postal_code, 
        p_house_number, 
        p_setup_time_estimate, 
        p_eq_capacity, 
        v_customer_ref
    );
    
    COMMIT;
    -- DBMS_OUTPUT.PUT_LINE('Event location registered successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- DBMS_OUTPUT.PUT_LINE('Error registering event location: ' || SQLERRM);
        -- Raise the error so the Python driver catches it as an exception
        RAISE_APPLICATION_ERROR(-20001, 'Error registering event location: ' || SQLERRM);
END add_event_location;
/

CREATE OR REPLACE PROCEDURE get_teams_for_location (
    p_event_location_code IN NUMBER,
    p_result_cursor       OUT SYS_REFCURSOR
) IS
    v_event_location_ref REF EventLocation_t;
BEGIN
    SELECT REF(e) INTO v_event_location_ref FROM EventLocations e WHERE code = p_event_location_code;

    OPEN p_result_cursor FOR
        SELECT DISTINCT 
            DEREF(b.team).id AS team_id,
            DEREF(b.team).name AS team_name, 
            DEREF(b.team).n_installations_made AS installations
        FROM Bookings b
        WHERE b.event_location = v_event_location_ref;
END get_teams_for_location;
/

CREATE OR REPLACE PROCEDURE get_top_event_locations (
    p_result_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_result_cursor FOR
        SELECT 
            DEREF(b.event_location).code AS loc_code,
            DEREF(b.event_location).location.address AS loc_address,
            DEREF(b.event_location).location.city AS loc_city,
            COUNT(*) AS total_bookings
        FROM Bookings b
        GROUP BY b.event_location, 
            DEREF(b.event_location).code,
            DEREF(b.event_location).location.address, 
            DEREF(b.event_location).location.city
        ORDER BY total_bookings DESC;
END get_top_event_locations;
/
