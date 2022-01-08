
/******************* APPLICATIONS TRACKING PROCEDURE ***********************

ORIGINATOR= RISK
DATE= 24/06/2016
LAST UPDATE= 26/03/2019 BY SG (Movano can be only LCV as provided by F2ML)
FREQUENCY= QUARTERLY
SOURCE= RV_DATA (RV_infocar_preview)

**************************************************************************/
/*sauvegarder les fichiers infocar en extension .xlsx et renomer la feuille "Veicoli" */

options compress = yes;
%let Q2=Q2_2020;
%let Q1=Q1_2020;
%let Q4=Q4_2019;
%let Q3=Q3_2019;
%LET PATH=C:\Users\yz55ax\Documents\RISK\Local_working_folder\Residual Values;
/*%let Path=\\itrmewpefp001.eu.ds.ov.finance\SHARED\Risk\Residual Values;*/
libname Q1 "&path\&Q1";
libname Q2 "&path\&Q2";
libname Q3 "&path\&Q3";
libname Q4 "&path\&Q4";
libname OUT "&path\Q2_2020";
 
 /****************************************/
data Q1;
retain quarter Anno_Edizione Mese_Edizione Codice_Infocar Anno Mese Marca Modello Allestimento Cilindrata Alimentazione 
Carrozzeria listino rv_infocar km term fuel_type;
set Q1.RV_BASE_&Q1; quarter="&Q1";
keep quarter Anno_Edizione Mese_Edizione Codice_Infocar Anno Mese Marca Modello Allestimento Cilindrata Alimentazione 
Carrozzeria listino km term rv_infocar fuel_type;
run;

data Q2;
retain quarter Anno_Edizione Mese_Edizione Codice_Infocar Anno Mese Marca Modello Allestimento Cilindrata Alimentazione 
Carrozzeria listino rv_infocar km term fuel_type;
set Q2.RV_BASE_&Q2;quarter="&Q2";
keep quarter Anno_Edizione Mese_Edizione Codice_Infocar Anno Mese Marca Modello Allestimento Cilindrata Alimentazione 
Carrozzeria listino km term rv_infocar fuel_type;
run;

data Q3;
retain quarter Anno_Edizione Mese_Edizione Codice_Infocar Anno Mese Marca Modello Allestimento Cilindrata Alimentazione 
Carrozzeria listino rv_infocar km term fuel_type;
set Q3.RV_BASE_&Q3;quarter="&Q3";
keep quarter Anno_Edizione Mese_Edizione Codice_Infocar Anno Mese Marca Modello Allestimento Cilindrata Alimentazione 
Carrozzeria listino km term rv_infocar fuel_type;
run;

data Q4;
set Q4.RV_BASE_&Q4;quarter="&Q4";
rename term=term1;
keep quarter Anno_Edizione Mese_Edizione Codice_Infocar Anno Mese Marca Modello Allestimento Cilindrata Alimentazione 
Carrozzeria listino km term rv_infocar fuel_type;

data Q4;
retain quarter Anno_Edizione Mese_Edizione Codice_Infocar Anno Mese Marca Modello Allestimento Cilindrata Alimentazione 
Carrozzeria listino rv_infocar km term fuel_type;
set Q4;
term=term1*1;
drop term1;
run;

data infocar_evolution;set Q1 Q2 Q3 Q4;
data infocar_evolution; set infocar_evolution; if Alimentazione in ('Gasolio') and km=30000 then pivot=1;if Alimentazione notin ('Gasolio')  and km=20000 then pivot=1;
	modello=tranwrd(modello,"ª","");
	model=UPCASE(compress(tranwrd(modello,"*","")));
data infocar_evolution; set infocar_evolution; where pivot=1;run;

proc sql;
create table OUT.infocar_evolution_out as
select distinct quarter, model, mean(rv_infocar) as rv_avg from infocar_evolution
group by quarter, model;
quit;


/*************** END **********************/











	