CREATE OR REPLACE PROCEDURE MYSCHEMA.P_CSV_TO_TABLE  
 (    IN_DELIMITER IN  VARCHAR2 DEFAULT ';',
       IN_SCHEMA IN VARCHAR2 DEFAULT 'MYSCHEMA',
       IN_TABLENAME IN VARCHAR2 DEFAULT 'AUX_FINAL_TABLE',
    IN_REMOVE_QUOTES IN BOOLEAN DEFAULT TRUE)  AS
/******************************************************************************
	NAME:       P_CSV_TO_TABLE
	PURPOSE:    CREATE A TABLE DYNAMICALLY FROM AN EXTERNAL FILE (.CSV)
   
	PARAMETERS: 
				IN_DELIMITER - IT IS THE FIELD DELIMITER OF THE INPUT FILE
				IN_SCHEMA - IT DEFINES THE SCHEMA WHERE THE TABLE IS GOING TO BE STORED
				IN_TABLENAME - THE NAME OF THE TABLE TO BE CREATED
				IN_REMOVE_QUOTES - BOOLEAN - IF TRUE THE CSV WERE WITH DOBLE QUOTES
	
	PRE-REQUISITES: YOU NEED TO INCLUDE THE FILE AS IT IS IN A AUXILIAR TABLE. (AUX_INPUT_FILE)
	
		TABLES: AUX_INPUT_FILE - AUX TABLE TO STORE THE TEXT FILE.
				COLUMNS: 
					DATA - CLOB, VARIABLE THAT STORES THE PLAIN TEXT.
					NUMROW - NUMBER(10) - VARIABLE THAT STORES THE NUMBRE OF ROWS OF THE TEXT FILE
				
   REVISIONS:
   Ver        Date        	Author                   		Description
   ---------  ----------  	----------------------        ------------------------------------
   1.0        07/12/2020   	Pedro Alvarez Barbero          1. Created this procedure. 

   
   
   NOTES:
   
	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


******************************************************************************/


/* STATIC */
V_PROCESS_NAME VARCHAR2(100 BYTE) := 'P_CSV_TO_TABLE';
V_STATUS_INI VARCHAR2(10 BYTE) := 'RUNNING';
V_STATUS_END VARCHAR2(10 BYTE) := 'COMPLETED';

/*INPUT VARIABLES */
V_DELIMITER VARCHAR2(10):=IN_DELIMITER;
V_SCHEMA VARCHAR2(30):=IN_SCHEMA;
V_TABLENAME VARCHAR2(30):=IN_TABLENAME;
V_QUOTE VARCHAR(30):='"';

/*-----------*/
/* VARIABLES */
/*-----------*/

/*AUX VARIABLES TO MANAGE THE LINES */
V_HEADER VARCHAR2 (4000 BYTE);
V_LINE VARCHAR2 (4000 BYTE);
V_ROWNUM NUMBER := 0;

/*AUX VARIABES LOS HANDLE THE COLUMNS */
V_SUB_LENGTH INTEGER (10):=0;
V_LAST_POSITION INTEGER (10):=1;
V_POSITION INTEGER (10):=0;
V_COLUMN VARCHAR2(4000):='';
V_NUM_COLUMS NUMBER := 0;

/*AUX VARIABLES FOR SQL DML AND DDL*/
V_SQL_DML_TABLE CLOB:='';
V_SQL_DML_TABLE_LOG CLOB:='';
V_SQL_EXECUTE VARCHAR2(4000):='';
V_SQL_COLUMNS CLOB:='';

V_FIRST_ROW NUMBER := 0 ;

/* CURSOR */
V_ROW AUX_INPUT_FILE%ROWTYPE;
CURSOR C_INPUT_FILE is SELECT DATA, NUMROW FROM AUX_INPUT_FILE ORDER BY NUMROW;


BEGIN


----------------------
/* DROP  TABLE */
---------------------
begin
    V_SQL_EXECUTE:='DROP TABLE ' || V_SCHEMA || '.' || V_TABLENAME;
    DBMS_OUTPUT.PUT_LINE(V_SQL_EXECUTE);
    EXECUTE IMMEDIATE  V_SQL_EXECUTE;
   
     V_SQL_EXECUTE:='TRUNCATE TABLE AUX_INPUT_FILE';
     EXECUTE IMMEDIATE  V_SQL_EXECUTE;
exception
    when others then
        dbms_output.put_line('Exception: Drop table not executed' );
end;


    ----------------------
    /* CREATE  TABLE */
    ---------------------
    V_SQL_DML_TABLE:= 'CREATE TABLE ' || V_SCHEMA || '.' || V_TABLENAME || ' (';

	dbms_output.put_line('V_SQL_DML_TABLE: '||V_SQL_DML_TABLE );

	SELECT MIN(NUMROW)
	INTO V_FIRST_ROW
	FROM CMDB_INPUT_FILE1;

    -- SELECT THE HEADER
    SELECT DATA || V_DELIMITER
    INTO V_HEADER
    FROM AUX_INPUT_FILE
    WHERE NUMROW = V_FIRST_ROW;

    dbms_output.put_line('HEADER: '||V_HEADER);

    -- NUMBER OF COLUMNS -1 BECAUSE AT THE LOOP WE START AT 0
    V_NUM_COLUMS := REGEXP_COUNT(V_HEADER, V_DELIMITER) -1;

    dbms_output.put_line('V_NUM_COLUMS: '||V_NUM_COLUMS);

	-- ITERATE ALL THE COLUMNS
    FOR N IN 0..V_NUM_COLUMS
    LOOP


		-- SELECT ALL THE COLUMNS
		V_POSITION:= INSTR(V_HEADER, V_DELIMITER, V_LAST_POSITION);
		V_SUB_LENGTH:= V_POSITION - V_LAST_POSITION;
		V_COLUMN :=  SUBSTR(V_HEADER, V_LAST_POSITION, V_SUB_LENGTH);

		dbms_output.put_line('V_POSITION: '||V_POSITION);
		dbms_output.put_line('V_SUB_LENGTH: '||V_SUB_LENGTH);
		dbms_output.put_line('V_COLUMN: '||V_COLUMN);


       IF   IN_REMOVE_QUOTES THEN
            V_COLUMN:= REPLACE(V_COLUMN, V_QUOTE, '');
       END IF;
       
        -- TRIM
        V_COLUMN:=TRIM(V_COLUMN);
       
        -- REMOVE SPACES
        V_COLUMN:= REPLACE(V_COLUMN, ' ', '_' );
       
        -- ACCENT are not allowed at headers
        V_COLUMN:=TRANSLATE (UPPER(V_COLUMN),'ÁÉÍÓÚÀÈÌÒÙÃÇÂÊÎÔÛÄËÏÖÜ','AEIOUAEIOUACAEIOUAEIOU');

        -- Remove non Alphanumeric characters
        V_COLUMN:=REGEXP_REPLACE(V_COLUMN, '[^A-Z0-9_]', '');

        -- Max  length 30
        V_COLUMN:= 'C' || N || '_'|| SUBSTR(V_COLUMN, 1, 25);
           
       
		dbms_output.put_line('V_COLUMN: '||V_COLUMN);


           
        -- UPDATE THE POSITION  
        V_LAST_POSITION:= V_POSITION+1;
		
		dbms_output.put_line('V_LAST_POSITION: '||V_LAST_POSITION);
		dbms_output.put_line('N: '||N);
		dbms_output.put_line('V_NUM_COLUMS: '||V_NUM_COLUMS);

        IF N <> V_NUM_COLUMS
        THEN  

            -- ADD COLUMNS
             V_SQL_COLUMNS:= V_SQL_COLUMNS || UPPER(V_COLUMN) || ', ' ;
			--dbms_output.put_line('V_SQL_COLUMNS: '||V_SQL_COLUMNS);

             --ADD TO SQL
            V_SQL_DML_TABLE:= V_SQL_DML_TABLE || UPPER(V_COLUMN) || ' VARCHAR (4000), ';
			--dbms_output.put_line('V_SQL_DML_TABLE: '||V_SQL_DML_TABLE);

        ELSE  
            -- ADD COLUMNS    
            V_SQL_COLUMNS:= V_SQL_COLUMNS || V_COLUMN ;
             
             --ADD TO SQL
            V_SQL_DML_TABLE:= V_SQL_DML_TABLE || UPPER(V_COLUMN) || ' VARCHAR (4000) ) ';

        END IF;
       
    END LOOP;


   
    --CREATE THE TABLE  
    begin
            DBMS_OUTPUT.PUT_LINE('V_SQL_INSERT_TABLE: ' || V_SQL_DML_TABLE );

            EXECUTE IMMEDIATE V_SQL_DML_TABLE ;
    exception
        when others then
           dbms_output.put_line('EXCEPTION: CREATE TABLE NOT EXECUTED' );
    end;


----------------------
/* INSERT INTO */
---------------------
DBMS_OUTPUT.PUT_LINE('*** Start inserting DATA ***');


-- OPEN THE CURSOR
OPEN C_INPUT_FILE;


-- GO ACROSS ALL THE ROWS
    LOOP
         
		V_SQL_DML_TABLE:='';
        V_SQL_DML_TABLE_LOG:='';
       
		FETCH C_INPUT_FILE INTO V_ROW;
		EXIT WHEN C_INPUT_FILE%NOTFOUND;
       
		V_ROWNUM:=V_ROW.NUMROW;
     
		-- ROW
		--DBMS_OUTPUT.PUT_LINE('V_LINE ' || V_ROWNUM || ': ' || V_ROW.DATA || V_DELIMITER);
       
		-- SKIP THE HEADER
		IF V_ROWNUM = V_FIRST_ROW THEN CONTINUE;
		END IF;       
     
        -- RESET FOR EACH LINE
        V_SUB_LENGTH:=0;
        V_LAST_POSITION:=1;
        V_POSITION:=0;
       
		--DBMS_OUTPUT.PUT_LINE('len: ' || LENGTH(V_SQL_COLUMNS));
       
        V_SQL_DML_TABLE:= 'INSERT INTO ' || V_SCHEMA || '.' || V_TABLENAME || ' (' || V_SQL_COLUMNS || ') VALUES (';
       
		-- FOR EACH LINE
        FOR J IN 0..V_NUM_COLUMS
        LOOP
                   
           
        -- SELECT THE COLUMN
         -- the row contains columns with quotes and the delimiter inside one colum
            IF SUBSTR(V_ROW.DATA,V_LAST_POSITION,1) = V_QUOTE then
                --  Field1, "Field2a, Field2b", Field3
                V_POSITION:= INSTR( V_ROW.DATA || V_DELIMITER,  V_QUOTE, V_LAST_POSITION+1);
                V_SUB_LENGTH:= V_POSITION - V_LAST_POSITION;
                V_COLUMN := SUBSTR( V_ROW.DATA || V_DELIMITER, V_LAST_POSITION, V_SUB_LENGTH +1);
                V_POSITION:=V_POSITION+1;
            ELSE        
                -- NORMAL field
                V_POSITION:= INSTR( V_ROW.DATA || V_DELIMITER, V_DELIMITER, V_LAST_POSITION);
                V_SUB_LENGTH:= V_POSITION - V_LAST_POSITION;
                V_COLUMN :=  SUBSTR( V_ROW.DATA || V_DELIMITER, V_LAST_POSITION, V_SUB_LENGTH);
			END IF;
           
			-- REMOVE SINGLE QUOTE
			V_COLUMN:= REPLACE(V_COLUMN, '''', '' );
           
			IF   IN_REMOVE_QUOTES THEN
                V_COLUMN:= REPLACE(V_COLUMN, V_QUOTE, '');
			END IF;            

			-- UPDATE THE POSITION  
            V_LAST_POSITION:= V_POSITION+1;
                   
            IF J <> V_NUM_COLUMS
            THEN  
                --ADD TO SQL
                    V_SQL_DML_TABLE:= V_SQL_DML_TABLE || ''''  || V_COLUMN || ''''  ||  ', ';
            ELSE  
                    V_SQL_DML_TABLE:= V_SQL_DML_TABLE  || ''''  || V_COLUMN || ''''  || ' ) ';
            END IF;
           
        END LOOP;
       
         

        BEGIN
        -- INSERT INTO
            DBMS_OUTPUT.PUT_LINE('V_SQL_INSERT_TABLE: ' || V_SQL_DML_TABLE );
            EXECUTE IMMEDIATE V_SQL_DML_TABLE;

          
           IF MOD(V_ROWNUM, 1000) = 0 THEN
                COMMIT;
            END IF;
           
        EXCEPTION
            WHEN OTHERS THEN
               dbms_output.put_line('EXCEPTION: insert NOT EXECUTED. rownum '  || V_ROWNUM );
               DBMS_OUTPUT.PUT_LINE('V_SQL_INSERT_TABLE: ' || V_SQL_DML_TABLE );
                          DBMS_OUTPUT.PUT_LINE('V_SQL_INSERT_TABLE: ' || V_SQL_DML_TABLE_LOG );
           V_SQL_DML_TABLE_LOG:='INSERT INTO AUX_INPUT_FILE_LOG (NUMROW, STATUS, DATA, FECHA) VALUES (' || V_ROWNUM || ',  ''KO'', '  || ''''  ||  REPLACE(V_ROW.DATA, '''', '' )  || ''''  || ', SYSDATE' || ')';
           DBMS_OUTPUT.PUT_LINE('V_SQL_INSERT_TABLE: ' || V_SQL_DML_TABLE_LOG );
            EXECUTE IMMEDIATE V_SQL_DML_TABLE_LOG;

        END;

         
     END LOOP;

CLOSE C_INPUT_FILE;
 

COMMIT;


       
END P_CSV_TO_TABLE;
/