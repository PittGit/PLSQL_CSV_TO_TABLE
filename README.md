# PLSQL---CSV-TO-TABLE
CREATE A TABLE DYNAMICALLY FROM AN EXTERNAL FILE

This is a PL/SQL code, to create a table Dinamycally in a Oracle DB.

Copyright (c) 2020 Pedro Alvarez Barbero 
linkedin: https://www.linkedin.com/in/pedro-alvarez-barbero/

#Pre-requisites.

You need to upload the .csv file into an auxiliar table with format Data CLOB, Numrow Number(10).

## Example

/* CSV */
FirStName;Lastname;email
John;Smith;JohnSmith@gmail.com
Pamela;Anderson;paman@hotmail.com


## Remebber that you need to insert the CSV in a table.
/* AUX_INPUT_FILE */
Data CLOB	Numrow Number (10)
****		1   --> DATA = FirStName;Lastname;email
****		2	--> DATA = John;Smith;JohnSmith@gmail.com
****		3	--> DATA = Pamela;Anderson;paman@hotmail.com


##Execute the code
Begin
P_CSV_TO_TABLE(';', 'MYSCHEMA'; 'T_USER_EMAILS'; false);
end;

## Results
----------
/* Table MYSCHEMA.T_USER_EMAILS */

C0_FirStName VARCHAR2(4000 Byte) 	C1_Lastname VARCHAR2(4000 Byte)		C2_email VARCHAR2(4000 Byte)
John								Smith								JohnSmith@gmail.com
Pamela								Anderson							paman@hotmail.com


Best Regards
Pedro A.
