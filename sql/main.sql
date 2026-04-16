@@setup.sql
@@procedures.sql
@@operations.sql
@@populate.sql

begin
    populate_central_offices(2);
    populate_depots(10);
    populate_teams(100);
    populate_installations(50, 0);
    populate_installations(10, 1); -- promo installations
    populate_customers(50, 0); -- individuals
    populate_customers(50, 1); -- companies
    populate_event_locations(1000);
    populate_bookings(4000, 0); -- one-time bookings
    populate_bookings(1000, 1); -- recurrent bookings

    -- DBMS_SCHEDULER.CREATE_JOB (
    --     job_name => 'JOB_CLEANUP_PROMOS',
    --     job_type => 'STORED_PROCEDURE',
    --     job_action => 'cleanup_expired_promos',
    --     start_date => SYSDATE,
    --     repeat_interval => 'FREQ=DAILY;BYHOUR=2',  -- Runs daily at 2 AM
    --     enabled => TRUE
    -- );

    -- DBMS_SCHEDULER.CREATE_JOB (
    --     job_name => 'JOB_UPDATE_RECURRENT_INSTALLATIONS',
    --     job_type => 'STORED_PROCEDURE',
    --     job_action => 'update_recurrent_installations',
    --     start_date => SYSDATE,
    --     repeat_interval => 'FREQ=DAILY;BYHOUR=3',  -- Runs daily at 3 AM
    --     enabled => TRUE
    -- );
end;
/