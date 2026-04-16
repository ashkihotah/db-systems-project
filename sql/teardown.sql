DECLARE
    v_count NUMBER;
    v_sql VARCHAR2(200);
BEGIN
    DBMS_OUTPUT.ENABLE;
    LOOP
        SELECT COUNT(*) INTO v_count 
        FROM user_objects 
        WHERE object_type IN ('TYPE', 'TABLE', 'TRIGGER', 'SEQUENCE', 'VIEW', 'PROCEDURE', 'FUNCTION', 'MATERIALIZED VIEW'); -- , 'PACKAGE', 'SYNONYM'
        
        DBMS_OUTPUT.PUT_LINE('Objects remaining to drop: ' || v_count);
        EXIT WHEN v_count = 0;

        FOR obj IN (
            SELECT object_name, object_type 
            FROM user_objects 
            WHERE object_type IN ('TYPE', 'TABLE', 'TRIGGER', 'SEQUENCE', 'VIEW', 'PROCEDURE', 'FUNCTION', 'MATERIALIZED VIEW') -- , 'PACKAGE', 'SYNONYM'
        ) 
        LOOP
            BEGIN
                IF obj.object_type = 'TABLE' THEN
                    v_sql := 'DROP TABLE "' || obj.object_name || '" CASCADE CONSTRAINTS';
                ELSIF obj.object_type = 'TYPE' THEN
                    v_sql := 'DROP TYPE "' || obj.object_name || '" FORCE';
                ELSE
                    v_sql := 'DROP ' || obj.object_type || ' "' || obj.object_name || '"';
                END IF;
                
                EXECUTE IMMEDIATE v_sql;
                DBMS_OUTPUT.PUT_LINE('Successfully dropped ' || obj.object_type || ': ' || obj.object_name);
            EXCEPTION
                WHEN OTHERS THEN
                    -- Ignore errors and retry in the next iteration
                    DBMS_OUTPUT.PUT_LINE('Failed to drop ' || obj.object_type || ' ' || obj.object_name || ' (Dependencies may exist). Retrying later.');
            END;
        END LOOP;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('Teardown complete. All specified objects dropped.');
END;
/