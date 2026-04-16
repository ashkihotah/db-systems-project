CREATE OR REPLACE PROCEDURE populate_central_offices(n IN NUMBER) IS
BEGIN
    FOR i IN 1..n LOOP
        -- Using location constructor assuming it exists, or insert directly into attributes if possible
        -- Since it's an object table, we insert the object
        INSERT INTO CentralOffices p (p.name, p.n_employees, p.location)
        VALUES (
            'Central Office ' || i,
            0, -- MOD(i, 50) + 10,
            Location_t('Region' || i, 'Province' || i, 'City' || i, 'Address ' || i)
        );
    END LOOP;
    COMMIT;
END;
/
CREATE OR REPLACE PROCEDURE populate_depots(n IN NUMBER) IS
    TYPE ref_co_list IS TABLE OF REF CentralOffice_t INDEX BY PLS_INTEGER;
    v_co_refs ref_co_list;
    v_co_count NUMBER;
    v_co_ref REF CentralOffice_t;
    v_num_municipalities NUMBER;
    v_municipalities MunicipalityTable;
BEGIN
    SELECT REF(c) BULK COLLECT INTO v_co_refs FROM CentralOffices c;
    v_co_count := v_co_refs.COUNT;

    FOR i IN 1..n LOOP
        -- Get a random CentralOffice
        v_co_ref := v_co_refs(TRUNC(DBMS_RANDOM.VALUE(1, v_co_count + 1)));

        v_num_municipalities := TRUNC(DBMS_RANDOM.VALUE(1, 6)); -- 1 to 5 municipalities
        v_municipalities := MunicipalityTable();
        FOR j IN 1..v_num_municipalities LOOP
            v_municipalities.EXTEND;
            v_municipalities(j) := Municipality_t('Municipality ' || i || '_' || j);
        END LOOP;

        INSERT INTO Depots (name, n_employees, location, municipalities, central_office)
        VALUES (
            'Depot ' || i,
            0, -- MOD(i, 20) + 5,
            Location_t('Region' || (i+100), 'Province' || (i+100), 'City' || (i+100), 'Address ' || (i+100)),
            v_municipalities,
            v_co_ref
        );
    END LOOP;
    COMMIT;
END;
/
CREATE OR REPLACE PROCEDURE populate_teams(n IN NUMBER) IS
    TYPE ref_depot_list IS TABLE OF REF Depot_t INDEX BY PLS_INTEGER;
    v_depot_refs ref_depot_list;
    v_depot_count NUMBER;
    v_depot_ref REF Depot_t;
    v_num_members NUMBER;
    v_members MembersVarray;
    v_gender VARCHAR2(10);
BEGIN
    SELECT REF(d) BULK COLLECT INTO v_depot_refs FROM Depots d;
    v_depot_count := v_depot_refs.COUNT;

    FOR i IN 1..n LOOP
        v_depot_ref := v_depot_refs(TRUNC(DBMS_RANDOM.VALUE(1, v_depot_count + 1)));

        v_num_members := TRUNC(DBMS_RANDOM.VALUE(1, 6)); -- 1 to 5 members
        v_members := MembersVarray();
        FOR j IN 1..v_num_members LOOP
            v_members.EXTEND;

            -- v_gender := CASE MOD(j, 2) WHEN 0 THEN 'male' ELSE 'female' END;
            IF MOD(j, 3) = 0 THEN
                v_gender := 'male';
            ELSIF MOD(j, 3) = 1 THEN
                v_gender := 'female';
            ELSE
                v_gender := 'other';
            END IF;

            v_members(j) := Member_t(
                Anagraphic_t(
                    'MName' || i || '_' || j, 
                    'MSurname' || i || '_' || j, 
                    TO_DATE('1985-01-01', 'YYYY-MM-DD') + MOD(i * j * 100, 10000), 
                    v_gender
                ),
                ContactInfo_t(
                    'member' || i || '_' || j || '@team.com', 
                    '+39' || TO_CHAR(DBMS_RANDOM.value(3000000000, 3999999999), 'FM0000000000')
                )
            );
        END LOOP;

        INSERT INTO Teams (id, name, n_installations_made, depot, members)
        VALUES (
            seq_teams.NEXTVAL,
            'Team ' || i,
            0,
            v_depot_ref,
            v_members
        );
    END LOOP;
    COMMIT;
END;
/
CREATE OR REPLACE PROCEDURE populate_installations(n IN NUMBER, is_promo IN NUMBER) IS
BEGIN
    FOR i IN 1..n LOOP
        IF is_promo = 0 THEN
            INSERT INTO Installations VALUES (
                Installation_t(
                    'Installation ' || i,
                    'Description for installation ' || i,
                    MOD(i * 15, 1000) + 50
                )
            );
        ELSE
            INSERT INTO Installations VALUES (
                Promo_t(
                    'Promo ' || i,
                    'Description for promo ' || i,
                    MOD(i * 10, 500) + 20,
                    'CODE' || i || '_' || DBMS_RANDOM.STRING('U', 4),
                    MOD(i * 5, 50) + 5,
                    SYSDATE + MOD(i, 365)
                )
            );
        END IF;
    END LOOP;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE populate_customers(n IN NUMBER, is_company IN NUMBER) IS
    v_gender VARCHAR2(10);
BEGIN
    FOR i IN 1..n LOOP
        IF is_company = 0 THEN
            IF MOD(i, 2) = 0 THEN
                v_gender := 'male';
            ELSE
                v_gender := 'female';
            END IF;
            
            INSERT INTO Customers VALUES (
                Individual_t(
                    'IND' || i,
                    ContactInfo_t('individual' || i || '@example.com', '+39' || TO_CHAR(DBMS_RANDOM.value(3000000000, 3999999999), 'FM0000000000')),
                    Anagraphic_t('IName' || i, 'ISurname' || i, TO_DATE('1970-01-01', 'YYYY-MM-DD') + MOD(i * 133, 15000), v_gender)
                )
            );
        ELSE
            INSERT INTO Customers VALUES (
                Company_t(
                    'COMP' || i,
                    ContactInfo_t('contact@company' || i || '.com', '+39' || TO_CHAR(DBMS_RANDOM.value(3000000000, 3999999999), 'FM0000000000')),
                    'Company Name ' || i,
                    'IT' || TO_CHAR(DBMS_RANDOM.value(10000000000, 99999999999), 'FM00000000000')
                )
            );
        END IF;
    END LOOP;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE populate_event_locations(n IN NUMBER) IS
    TYPE ref_cust_list IS TABLE OF REF Customer_t INDEX BY PLS_INTEGER;
    v_cust_refs ref_cust_list;
    v_cust_count NUMBER;
    v_cust_ref REF Customer_t;
BEGIN
    SELECT REF(c) BULK COLLECT INTO v_cust_refs FROM Customers c;
    v_cust_count := v_cust_refs.COUNT;

    FOR i IN 1..n LOOP
        -- Get a random Customer
        v_cust_ref := v_cust_refs(TRUNC(DBMS_RANDOM.VALUE(1, v_cust_count + 1)));

        INSERT INTO EventLocations (location, postal_code, house_number, setup_time_estimate, eq_capacity, customer)
        VALUES (
            Location_t('Region' || (i+200), 'Province' || (i+200), 'City' || (i+200), 'Address ' || (i+200)),
            TO_CHAR(MOD(i * 1234, 99999), 'FM00000'),
            TO_CHAR(MOD(i, 200) + 1),
            0,
            MOD(i, 1000) + 50,
            v_cust_ref
        );
    END LOOP;
    COMMIT;
END;
/

CREATE OR REPLACE PROCEDURE populate_bookings(n IN NUMBER, is_recurrent IN NUMBER) IS
    TYPE ref_team_list IS TABLE OF REF Team_t INDEX BY PLS_INTEGER;
    -- TYPE ref_cust_list IS TABLE OF REF Customer_t INDEX BY PLS_INTEGER;
    TYPE ref_inst_list IS TABLE OF REF Installation_t INDEX BY PLS_INTEGER;
    TYPE ref_eloc_list IS TABLE OF REF EventLocation_t INDEX BY PLS_INTEGER;
    v_team_refs ref_team_list;
    -- v_cust_refs ref_cust_list;
    v_inst_refs ref_inst_list;
    v_eloc_refs ref_eloc_list;
    v_team_count NUMBER;
    v_cust_count NUMBER;
    v_inst_count NUMBER;
    v_eloc_count NUMBER;
    v_team_ref REF Team_t;
    -- v_cust_ref REF Customer_t;
    v_inst_ref REF Installation_t;
    v_eloc_ref REF EventLocation_t;
    v_code NUMBER;
BEGIN
    SELECT REF(t) BULK COLLECT INTO v_team_refs FROM Teams t;
    v_team_count := v_team_refs.COUNT;
    -- SELECT REF(c) BULK COLLECT INTO v_cust_refs FROM Customers c;
    -- v_cust_count := v_cust_refs.COUNT;
    SELECT REF(i) BULK COLLECT INTO v_inst_refs FROM Installations i;
    v_inst_count := v_inst_refs.COUNT;
    SELECT REF(e) BULK COLLECT INTO v_eloc_refs FROM EventLocations e;
    v_eloc_count := v_eloc_refs.COUNT;

    FOR i IN 1..n LOOP
        v_team_ref := v_team_refs(TRUNC(DBMS_RANDOM.VALUE(1, v_team_count + 1)));
        -- v_cust_ref := v_cust_refs(TRUNC(DBMS_RANDOM.VALUE(1, v_cust_count + 1)));
        v_inst_ref := v_inst_refs(TRUNC(DBMS_RANDOM.VALUE(1, v_inst_count + 1)));
        v_eloc_ref := v_eloc_refs(TRUNC(DBMS_RANDOM.VALUE(1, v_eloc_count + 1)));

        v_code := seq_bookings.NEXTVAL;
        IF is_recurrent = 0 THEN
            INSERT INTO Bookings VALUES (
                Booking_t(
                    v_code,
                    SYSDATE + MOD(i, 30),
                    MOD(i, 8) + 1,
                    v_team_ref,
                    -- v_cust_ref,
                    v_inst_ref,
                    v_eloc_ref
                )
            );
        ELSE
            INSERT INTO Bookings VALUES (
                RecurrentBooking_t(
                    v_code,
                    SYSDATE + MOD(i, 30),
                    MOD(i, 4) + 1,
                    v_team_ref,
                    -- v_cust_ref,
                    v_inst_ref,
                    v_eloc_ref,
                    MOD(i, 30) + 7,
                    MOD(i, 12) + 2
                )
            );
        END IF;
    END LOOP;
    COMMIT;
END;
/

