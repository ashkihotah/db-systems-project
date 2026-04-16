CREATE OR REPLACE PROCEDURE cleanup_expired_promos IS
BEGIN
    DELETE FROM Installations i
    WHERE VALUE(i) IS OF (Promo_t) AND TREAT(VALUE(i) AS Promo_t).deadline < TRUNC(SYSDATE);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Cleanup completed: ' || SQL%ROWCOUNT || ' expired promos deleted.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in cleanup: ' || SQLERRM);
        ROLLBACK;
END cleanup_expired_promos;
/

CREATE OR REPLACE PROCEDURE update_recurrent_installations IS
BEGIN
    FOR rec IN (
        SELECT b.team
        FROM Bookings b
        WHERE VALUE(b) IS OF (RecurrentBooking_t)
          AND TRUNC(SYSDATE) >= b.booking_date
          AND TRUNC(SYSDATE) <= b.booking_date + (TREAT(VALUE(b) AS RecurrentBooking_t).interval * (TREAT(VALUE(b) AS RecurrentBooking_t).n_times - 1))
          AND MOD(TRUNC(SYSDATE) - b.booking_date, TREAT(VALUE(b) AS RecurrentBooking_t).interval) = 0
    ) LOOP
        UPDATE Teams t
        SET t.n_installations_made = NVL(t.n_installations_made, 0) + 1
        WHERE REF(t) = rec.team;
    END LOOP;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Update completed for recurrent bookings on ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD') || '.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error in update_recurrent_installations: ' || SQLERRM);
        ROLLBACK;
END update_recurrent_installations;
/