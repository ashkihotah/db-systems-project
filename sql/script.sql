-- -- insert a member to a team to check if the trigger for n_employee works
-- DECLARE
--     v_team Teams%ROWTYPE;
-- BEGIN
--     SELECT VALUE(t) INTO v_team FROM Teams t WHERE name = 'Team 1' FOR UPDATE;
--     v_team.members.EXTEND;
--     v_team.members(v_team.members.COUNT) := Person_t('John', 'Doe', TO_DATE('1990-01-01', 'YYYY-MM-DD'), 'male', 'john.doe@gmail.com', '+391234567890');
--     UPDATE Teams SET members = v_team.members WHERE name = 'Team 1';
-- END;
-- /

SELECT COUNT(*) AS total_members 
FROM Teams t, TABLE(t.members) m;

-- select all tuples in installations that are promos
SELECT 
    i.name,
    i.description,
    i.cost,
    TREAT(VALUE(i) AS Promo_t).code AS promo_code,
    TREAT(VALUE(i) AS Promo_t).discont AS discount,
    TREAT(VALUE(i) AS Promo_t).deadline AS deadline
FROM Installations i
WHERE VALUE(i) IS OF (Promo_t);

-- select all tuples in customers that are individuals
SELECT 
    c.code,
    c.contact_info.email,
    c.contact_info.phone,
    TREAT(VALUE(c) AS Individual_t).anagraphic.name AS name,
    TREAT(VALUE(c) AS Individual_t).anagraphic.surname AS surname,
    TREAT(VALUE(c) AS Individual_t).anagraphic.date_of_birth AS birth_date,
    TREAT(VALUE(c) AS Individual_t).anagraphic.gender AS gender
FROM Customers c
WHERE VALUE(c) IS OF (Individual_t);

-- select all tuples in customers that are companies
SELECT 
    c.code,
    c.contact_info.email,
    c.contact_info.phone,
    TREAT(VALUE(c) AS Company_t).name AS name,
    TREAT(VALUE(c) AS Company_t).vat_number AS vat_number
FROM Customers c
WHERE VALUE(c) IS OF (Company_t);

--select all one-time bookings
SELECT 
    b.code,
    b.booking_date,
    b.duration
FROM Bookings b
WHERE VALUE(b) IS NOT OF (RecurrentBooking_t);

--select all recurrent bookings
SELECT 
    b.code,
    b.booking_date,
    b.duration,
    TREAT(VALUE(b) AS RecurrentBooking_t).interval AS interval,
    TREAT(VALUE(b) AS RecurrentBooking_t).n_times AS n_times
FROM Bookings b
WHERE VALUE(b) IS OF (RecurrentBooking_t);

-- insert a simple new individual customer calling the procedure add_new_individual_customer
BEGIN
    add_new_individual_customer(
        p_code => 'NicoProva',
        p_email => 'john.doe@gmail.com',
        p_phone => '+391234567890',
        p_name => 'John',
        p_surname => 'Doe',
        p_date_of_birth => TO_DATE('1990-01-01', 'YYYY-MM-DD'),
        p_gender => 'male'
    );
END;
/