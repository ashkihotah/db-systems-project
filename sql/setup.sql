CREATE OR REPLACE TYPE ContactInfo_t AS OBJECT (
    email VARCHAR2(100), 
    phone VARCHAR2(20)
    -- CONSTRUCTOR FUNCTION ContactInfo_t(email VARCHAR2, phone VARCHAR2) RETURN SELF AS RESULT
);
/
-- CREATE OR REPLACE TYPE BODY ContactInfo_t AS
--     CONSTRUCTOR FUNCTION ContactInfo_t(email VARCHAR2, phone VARCHAR2) RETURN SELF AS RESULT IS
--     BEGIN
--         IF email IS NULL AND phone IS NULL THEN
--             RAISE_APPLICATION_ERROR(-20001, 'At least one of email or phone must be provided.');
--         END IF;
--         SELF.email := email;
--         SELF.phone := phone;
--         RETURN;
--     END;
-- END;
-- /

CREATE OR REPLACE TYPE Anagraphic_t AS OBJECT (
    name VARCHAR2(100), 
    surname VARCHAR2(100), 
    date_of_birth DATE, 
    gender VARCHAR2(10)
);
/

CREATE OR REPLACE TYPE Customer_t AS OBJECT (
    code VARCHAR2(20),
    contact_info ContactInfo_t
) NOT INSTANTIABLE NOT FINAL;
/

CREATE OR REPLACE TYPE Individual_t UNDER Customer_t (
    anagraphic Anagraphic_t
);
/

CREATE OR REPLACE TYPE Company_t UNDER Customer_t (
    name VARCHAR2(100),
    vat_number VARCHAR2(50)
);
/

CREATE OR REPLACE TYPE Location_t AS OBJECT (
    region VARCHAR2(100),
    province VARCHAR2(100), 
    city VARCHAR2(100), 
    address VARCHAR2(200)
);
/

CREATE OR REPLACE TYPE Installation_t AS OBJECT (
    name VARCHAR2(100), 
    description VARCHAR2(200), 
    cost NUMBER
) NOT FINAL;
/

CREATE OR REPLACE TYPE Promo_t UNDER Installation_t (
    code VARCHAR2(50), 
    discont NUMBER, 
    deadline DATE
);
/

CREATE OR REPLACE TYPE CentralOffice_t AS OBJECT (
    name VARCHAR2(100), 
    n_employees NUMBER, 
    location Location_t
);
/

CREATE OR REPLACE TYPE Municipality_t AS OBJECT (
    name VARCHAR2(100)
);
/
CREATE OR REPLACE TYPE MunicipalityTable AS TABLE OF Municipality_t;
/

CREATE OR REPLACE TYPE Depot_t AS OBJECT (
    name VARCHAR2(100), 
    n_employees NUMBER, -- redudancy
    location Location_t,
    municipalities MunicipalityTable,
    central_office REF CentralOffice_t
);
/

CREATE OR REPLACE TYPE Member_t AS OBJECT (
    anagraphic Anagraphic_t,
    contact_info ContactInfo_t
);
/

CREATE OR REPLACE TYPE MembersVarray AS VARRAY(10) OF Member_t;
-- CREATE OR REPLACE TYPE MembersTable AS TABLE OF Member_t;
/

CREATE OR REPLACE TYPE Team_t AS OBJECT (
    id NUMBER,
    name VARCHAR2(100), 
    n_installations_made NUMBER,
    depot REF Depot_t,
    members MembersVarray
    -- members MembersTable
);
/

CREATE OR REPLACE TYPE EventLocation_t AS OBJECT (
    code NUMBER,
    location Location_t, 
    postal_code VARCHAR2(20), 
    house_number VARCHAR2(20),
    setup_time_estimate NUMBER, 
    eq_capacity NUMBER, 
    customer REF Customer_t
);
/

CREATE OR REPLACE TYPE Booking_t AS OBJECT (
    code NUMBER,
    booking_date DATE, 
    duration NUMBER, 
    team REF Team_t, 
    -- customer REF Customer_t, -- redudancy
    installation REF Installation_t, 
    event_location REF EventLocation_t
) NOT FINAL;
/

CREATE OR REPLACE TYPE RecurrentBooking_t UNDER Booking_t (
    interval NUMBER, 
    n_times NUMBER
) NOT FINAL;
/

-- ##########################
-- CREATE TABLES
-- ##########################

CREATE SEQUENCE seq_event_locations START WITH 1 INCREMENT BY 1;
/
CREATE SEQUENCE seq_bookings START WITH 1 INCREMENT BY 1;
/
CREATE SEQUENCE seq_teams START WITH 1 INCREMENT BY 1;
/

CREATE TABLE CentralOffices OF CentralOffice_t(
    name NOT NULL PRIMARY KEY,
    CONSTRAINT chk_vld_location_data_on_central_offices CHECK (
        location.province IS NOT NULL AND
        location.city IS NOT NULL AND
        location.address IS NOT NULL
    )
);
/

CREATE TABLE Depots OF Depot_t (
    central_office NOT NULL REFERENCES CentralOffices ON DELETE CASCADE,
    name NOT NULL PRIMARY KEY,
    CONSTRAINT chk_vld_location_data_on_depots CHECK (
        location.province IS NOT NULL AND
        location.city IS NOT NULL AND
        location.address IS NOT NULL
    )
) NESTED TABLE municipalities STORE AS MunicipalitiesNT;
/

CREATE TABLE Teams OF Team_t (
    id DEFAULT seq_teams.NEXTVAL NOT NULL PRIMARY KEY,
    depot NOT NULL REFERENCES Depots ON DELETE CASCADE,
    name NOT NULL
);
/

CREATE TABLE Customers OF Customer_t (
    code NOT NULL PRIMARY KEY,

    -- Constraint for Base Type
    CONSTRAINT chk_contact_info CHECK (
        contact_info.email IS NOT NULL OR contact_info.phone IS NOT NULL
    ),
    
    -- Constraints for Individual_t
    CONSTRAINT chk_individual_not_null CHECK (
        TREAT(SYS_NC_ROWINFO$ AS Individual_t) IS NULL OR (
            TREAT(SYS_NC_ROWINFO$ AS Individual_t).anagraphic IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS Individual_t).anagraphic.name IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS Individual_t).anagraphic.surname IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS Individual_t).anagraphic.date_of_birth IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS Individual_t).anagraphic.gender IS NOT NULL
        )
    ),

    -- Constraints for Company_t
    CONSTRAINT chk_company_not_null CHECK (
        TREAT(SYS_NC_ROWINFO$ AS Company_t) IS NULL OR (
            TREAT(SYS_NC_ROWINFO$ AS Company_t).name IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS Company_t).vat_number IS NOT NULL
        )
    )
);
/

CREATE TABLE Installations OF Installation_t(
    name NOT NULL PRIMARY KEY,
    description NOT NULL,
    cost NOT NULL CHECK (cost >= 0),

    -- add constraints also for Promo_t attributes to ensure they are not null when the installation is a promo
    CONSTRAINT chk_promo_attributes CHECK (
        TREAT(SYS_NC_ROWINFO$ AS Promo_t) IS NULL OR (
            TREAT(SYS_NC_ROWINFO$ AS Promo_t).code IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS Promo_t).discont IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS Promo_t).deadline IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS Promo_t).discont >= 0 AND
            TREAT(SYS_NC_ROWINFO$ AS Promo_t).discont <= 100
        )
    )
);
/

-- CREATE TABLE Promos OF Promo_t(
--     code NOT NULL PRIMARY KEY,
--     name NOT NULL,
--     description NOT NULL,
--     cost NOT NULL CHECK (cost >= 0),
--     discont NOT NULL CHECK (discont >= 0 AND discont <= 100),
--     deadline NOT NULL
-- );
-- /

CREATE TABLE EventLocations OF EventLocation_t (
    code DEFAULT seq_event_locations.NEXTVAL NOT NULL PRIMARY KEY,
    customer NOT NULL REFERENCES Customers ON DELETE CASCADE,
    postal_code NOT NULL,
    house_number NOT NULL,
    eq_capacity NOT NULL CHECK (eq_capacity >= 0),
    CONSTRAINT chk_vld_location_data_on_event_locations CHECK (
        location.province IS NOT NULL AND
        location.city IS NOT NULL AND
        location.address IS NOT NULL
    )
);
/

CREATE TABLE Bookings OF Booking_t (
    code DEFAULT seq_bookings.NEXTVAL NOT NULL PRIMARY KEY,
    team NOT NULL REFERENCES Teams ON DELETE CASCADE,
    -- customer NOT NULL REFERENCES Customers ON DELETE CASCADE,
    installation NOT NULL REFERENCES Installations ON DELETE CASCADE, 
    event_location NOT NULL REFERENCES EventLocations ON DELETE CASCADE,
    booking_date NOT NULL,
    duration NOT NULL CHECK (duration > 0),

    -- add constraints for RecurrentBooking_t attributes to ensure they are not null when the booking is recurrent
    CONSTRAINT chk_recurrent_booking_attributes CHECK (
        TREAT(SYS_NC_ROWINFO$ AS RecurrentBooking_t) IS NULL OR (
            TREAT(SYS_NC_ROWINFO$ AS RecurrentBooking_t).interval IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS RecurrentBooking_t).interval > 0 AND
            TREAT(SYS_NC_ROWINFO$ AS RecurrentBooking_t).n_times IS NOT NULL AND
            TREAT(SYS_NC_ROWINFO$ AS RecurrentBooking_t).n_times > 0
        )
    )
);
/

-- CREATE TABLE RecurrentBookings OF RecurrentBooking_t(
--     code DEFAULT seq_recurrent_bookings.NEXTVAL NOT NULL PRIMARY KEY,
--     team NOT NULL REFERENCES Teams ON DELETE CASCADE,
--     customer NOT NULL REFERENCES Customers ON DELETE CASCADE,
--     installation NOT NULL REFERENCES Installations ON DELETE CASCADE, 
--     event_location NOT NULL REFERENCES EventLocations ON DELETE CASCADE,
--     booking_date NOT NULL,
--     duration NOT NULL CHECK (duration > 0),
--     interval NOT NULL CHECK (interval > 0),
--     n_times NOT NULL CHECK (n_times > 0)
-- );
-- /

CREATE OR REPLACE TRIGGER trg_validate_promo_deadline
BEFORE INSERT OR UPDATE ON Bookings
FOR EACH ROW
DECLARE
    promo_deadline DATE;
BEGIN
    IF :NEW.installation IS NOT NULL THEN
        -- Safely attempt to read the deadline if the referenced installation is a Promo_t
        SELECT TREAT(VALUE(i) AS Promo_t).deadline INTO promo_deadline
        FROM Installations i
        WHERE REF(i) = :NEW.installation AND VALUE(i) IS OF (Promo_t);
        
        IF promo_deadline IS NOT NULL AND TRUNC(SYSDATE) > promo_deadline THEN
            RAISE_APPLICATION_ERROR(-20001, 'This promo has expired and cannot be used.');
        END IF;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        NULL; -- Not a promo or doesn't exist, skip validation
END;
/

CREATE OR REPLACE TRIGGER trg_n_installations
AFTER INSERT OR DELETE OR UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE Teams t 
        SET t.n_installations_made = NVL(t.n_installations_made, 0) + 1 
        WHERE REF(t) = :NEW.team;
    ELSIF DELETING THEN
        UPDATE Teams t 
        SET t.n_installations_made = GREATEST(NVL(t.n_installations_made, 0) - 1, 0) 
        WHERE REF(t) = :OLD.team;
    ELSIF UPDATING THEN
        IF :OLD.team != :NEW.team THEN
            UPDATE Teams t 
            SET t.n_installations_made = GREATEST(NVL(t.n_installations_made, 0) - 1, 0) 
            WHERE REF(t) = :OLD.team;
            UPDATE Teams t 
            SET t.n_installations_made = NVL(t.n_installations_made, 0) + 1 
            WHERE REF(t) = :NEW.team;
        END IF;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER trg_setup_time
AFTER INSERT OR DELETE OR UPDATE ON Bookings
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE EventLocations e 
        SET e.setup_time_estimate = NVL(e.setup_time_estimate, 0) + NVL(:NEW.duration, 0)
        WHERE REF(e) = :NEW.event_location;
    ELSIF DELETING THEN
        UPDATE EventLocations e SET e.setup_time_estimate = GREATEST(NVL(e.setup_time_estimate, 0) - NVL(:OLD.duration, 0), 0)
        WHERE REF(e) = :OLD.event_location;
    ELSIF UPDATING THEN
        IF :OLD.event_location = :NEW.event_location THEN
            -- Same location, only duration changed
            UPDATE EventLocations e 
            SET e.setup_time_estimate = GREATEST(NVL(e.setup_time_estimate, 0) - NVL(:OLD.duration, 0) + NVL(:NEW.duration, 0), 0)
            WHERE REF(e) = :NEW.event_location;
        ELSE
            -- Location changed, remove from old and add to new
            UPDATE EventLocations e 
            SET e.setup_time_estimate = GREATEST(NVL(e.setup_time_estimate, 0) - NVL(:OLD.duration, 0), 0)
            WHERE REF(e) = :OLD.event_location;
            UPDATE EventLocations e 
            SET e.setup_time_estimate = NVL(e.setup_time_estimate, 0) + NVL(:NEW.duration, 0)
            WHERE REF(e) = :NEW.event_location;
        END IF;
    END IF;
END;
/

-- CREATE OR REPLACE TRIGGER trg_max_n_of_members
-- BEFORE INSERT OR UPDATE ON Teams
-- FOR EACH ROW
-- BEGIN
--     IF :NEW.max_n_of_members IS NOT NULL AND :NEW.members IS NOT NULL THEN
--         IF CARDINALITY(:NEW.members) > :NEW.max_n_of_members THEN
--             RAISE_APPLICATION_ERROR(-20002, 'Number of members exceeds the maximum allowed.');
--         END IF;
--     END IF;
-- END;
-- /

CREATE OR REPLACE TRIGGER trg_n_employees
AFTER INSERT OR DELETE OR UPDATE ON Teams
FOR EACH ROW
DECLARE
    v_diff NUMBER := 0;
    v_co_ref REF CentralOffice_t;
BEGIN
    IF INSERTING THEN
        v_diff := NVL(:NEW.members.COUNT, 0);
        IF v_diff != 0 AND :NEW.depot IS NOT NULL THEN
            UPDATE Depots d SET d.n_employees = NVL(d.n_employees, 0) + v_diff WHERE REF(d) = :NEW.depot RETURNING d.central_office INTO v_co_ref;
            IF v_co_ref IS NOT NULL THEN
                UPDATE CentralOffices c SET c.n_employees = NVL(c.n_employees, 0) + v_diff WHERE REF(c) = v_co_ref;
            END IF;
        END IF;
    ELSIF DELETING THEN
        v_diff := NVL(:OLD.members.COUNT, 0);
        IF v_diff != 0 AND :OLD.depot IS NOT NULL THEN
            UPDATE Depots d SET d.n_employees = GREATEST(NVL(d.n_employees, 0) - v_diff, 0) WHERE REF(d) = :OLD.depot RETURNING d.central_office INTO v_co_ref;
            IF v_co_ref IS NOT NULL THEN
                UPDATE CentralOffices c SET c.n_employees = GREATEST(NVL(c.n_employees, 0) - v_diff, 0) WHERE REF(c) = v_co_ref;
            END IF;
        END IF;
    ELSIF UPDATING THEN
        IF :OLD.depot = :NEW.depot THEN
            v_diff := NVL(:NEW.members.COUNT, 0) - NVL(:OLD.members.COUNT, 0);
            IF v_diff != 0 AND :NEW.depot IS NOT NULL THEN
                UPDATE Depots d SET d.n_employees = GREATEST(NVL(d.n_employees, 0) + v_diff, 0) WHERE REF(d) = :NEW.depot RETURNING d.central_office INTO v_co_ref;
                IF v_co_ref IS NOT NULL THEN
                    UPDATE CentralOffices c SET c.n_employees = GREATEST(NVL(c.n_employees, 0) + v_diff, 0) WHERE REF(c) = v_co_ref;
                END IF;
            END IF;
        ELSE
            -- Remove from old depot
            v_diff := NVL(:OLD.members.COUNT, 0);
            IF v_diff != 0 AND :OLD.depot IS NOT NULL THEN
                UPDATE Depots d SET d.n_employees = GREATEST(NVL(d.n_employees, 0) - v_diff, 0) WHERE REF(d) = :OLD.depot RETURNING d.central_office INTO v_co_ref;
                IF v_co_ref IS NOT NULL THEN
                    UPDATE CentralOffices c SET c.n_employees = GREATEST(NVL(c.n_employees, 0) - v_diff, 0) WHERE REF(c) = v_co_ref;
                END IF;
            END IF;
            -- Add to new depot
            v_diff := NVL(:NEW.members.COUNT, 0);
            IF v_diff != 0 AND :NEW.depot IS NOT NULL THEN
                UPDATE Depots d SET d.n_employees = NVL(d.n_employees, 0) + v_diff WHERE REF(d) = :NEW.depot RETURNING d.central_office INTO v_co_ref;
                IF v_co_ref IS NOT NULL THEN
                    UPDATE CentralOffices c SET c.n_employees = NVL(c.n_employees, 0) + v_diff WHERE REF(c) = v_co_ref;
                END IF;
            END IF;
        END IF;
    END IF;
END;
/

CREATE INDEX idx_bookings_event_loc ON Bookings (event_location);

