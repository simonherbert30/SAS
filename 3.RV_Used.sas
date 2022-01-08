
/******************* APPLICATIONS TRACKING PROCEDURE ***********************

ORIGINATOR= STEFANO GENTILE
DATE= 26/08/2019
LAST UPDATE= 27/08/2019 BY SG
FREQUENCY= monthly
SOURCE= RV_DATA (allQX_16vX.txt, RV_infocarQx_201x.xls)

**************************************************************************/

/******************* LIBNMANE ***********************/
options compress = yes ;
%LET quarter=Q4_2020; /*change the year and quarter of current update*/
%LET month=202010; /*change the month of current update*/
%let path_v=\\itrmewpefp001.eu.ds.ov.finance\SHARED\Residual Values\&quarter\InfocarData\Veicoli;
%let path_m=\\itrmewpefp001.eu.ds.ov.finance\SHARED\Residual Values\&quarter\InfocarData\Multibrand; 
%let path=\\itrmewpefp001.eu.ds.ov.finance\SHARED\Residual Values;

%LET Anno_Edizione=2020; /*change the year for edition of Infocar Preview - Edizione Dati*/
%LET Mese_Edizione="10"; /*change the month for edition of Infocar Preview - Edizione Dati*/
%let infocar=GMF-IT-PP-VDB-202010;  /*change the month for vehicle database file*/

/*txt file names should be within 10 characters for WCG to upload*/
%LET used=useQ4_20v1; /*change the quarter and version*/

/*LIBNAME it "&path\&quarter";*/
/*LIBNAME opel "&path_v";*/
/*LIBNAME multi "&path_m";*/


/*********************** NEW INFOCAR VEHICLE DATABASE IMPORT AND TREATMENT **************************/
/*** Infocar vehicles database ***/
/*xlsx*/
PROC IMPORT OUT= infocar_WCG 
		     DATAFILE= "&path\&quarter\&infocar..xlsx" 
		     DBMS=Excel REPLACE; RANGE="&infocar$"; GETNAMES=YES; delimiter=','; MIXED=NO; SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;
RUN;

DATA infocar;
	SET infocar_WCG;
	
	length vehicleType $10. manufacturerName $40. modelName $100. Variant $100. Fuel $20. OBSOLETE_FLAG $1.;

	format fuel_type $10.;
	IF Fuel in ("P", "H") THEN fuel_type="Petrol";
	IF Fuel in ("G") THEN fuel_type="Gas"; /*metano*/
	IF Fuel in ("B")  THEN fuel_type="LPG";
	IF Fuel in ("D", "Y") THEN fuel_type="Diesel";
	IF Fuel in ("E") THEN fuel_type="Electric";
	IF Fuel in ("F") then fuel_type="Other";
	
	format transmission $3. gear $1.;
	if index(Variant,'aut.')>0 or index(Variant,'automatic')>0 or index(Variant,'automatico')>0 then gear='A';else gear='M';
	if index(Variant,'AWD')>0 or index(Variant,'4WD')>0 or index(Variant,'quattro')>0 or index(Variant,'integrale')>0 then transmission='4WD';else transmission='2WD';	
	
    if modelName eq 'C-MAX 2 SERIE' then modelName='C MAX 2 SERIE';
    if modelName eq 'MINI CABRIO   (F57)' then modelName='MINI CABRIO F57';
	
	format model $40.;	
	model=compress(modelName);
	
	length CODE0 $100.;
	CODE0=CATX("***",manufacturerName, vehicleType, model, fuel_type, gear, transmission); 
	
	T6=6;T12=12;T24=24;T36=36;T48=48;T60=60;/*T72=72;*/
	
	codice_infocar=infocarRef*1;
	DROP Fuel infocarRef;
run;

/*data infocar;*/
/*	length infocarRef vehicleType $10. manufacturerName $40. modelName $100. Variant $100. Fuel $20. OBSOLETE_FLAG $1.;*/
/**/
/*	infile "&path\&quarter\&infocar..csv" dlm=';' firstobs=2;*/
/*	input infocarRef vehicleType manufacturerName modelName	Variant	Fuel OBSOLETE_FLAG;	*/
/**/
/*	format fuel_type $10.;*/
/*	IF Fuel in ("P", "H") THEN fuel_type="Petrol";*/
/*	IF Fuel in ("G") THEN fuel_type="Gas";*/
/*	IF Fuel in ("B")  THEN fuel_type="LPG";*/
/*	IF Fuel in ("D", "Y") THEN fuel_type="Diesel";*/
/*	IF Fuel in ("E") THEN fuel_type="Electric";*/
/*	IF Fuel in ("F") then fuel_type="Other";*/
/*	*/
/*	format transmission $3. gear $1.;*/
/*	if index(Variant,'aut.')>0 or index(Variant,'automatic')>0 or index(Variant,'automatico')>0 then gear='A';else gear='M';*/
/*	if index(Variant,'AWD')>0 or index(Variant,'4WD')>0 or index(Variant,'quattro')>0 or index(Variant,'integrale')>0 then transmission='4WD';else transmission='2WD';	*/
/*	*/
/*    if modelName eq 'C-MAX 2 SERIE' then modelName='C MAX 2 SERIE';*/
/*    if modelName eq 'MINI CABRIO   (F57)' then modelName='MINI CABRIO F57';*/
/*	*/
/*	format model $40.;	*/
/*	model=compress(modelName);*/
/*	*/
/*	length CODE0 $100.;*/
/*	CODE0=CATX("***",manufacturerName, vehicleType, model, fuel_type, gear, transmission); */
/*	*/
/*	T6=6;T12=12;T24=24;T36=36;T48=48;T60=60;/*T72=72;*/*/
/*	*/
/*	codice_infocar=infocarRef*1;*/
/*	DROP Fuel X infocarRef;*/
/*	run;
	
	proc sort data=infocar
	out=infocar_sorted noduplicate;
	by codice_infocar vehicleType manufacturerName modelName Variant OBSOLETE_FLAG fuel_type transmission gear model CODE0 T6 T12 T24 T36 T48 T60 /*T72*/;
	quit;
	
	proc transpose data=infocar_sorted
	    out=infocar_term_transposed (rename=(col1=term) drop=_NAME_ /*rename=(km_min=km_min_original km=km_original)*/); 
		var T6 T12 T24 T36 T48 T60 /*T72*/;
		by codice_infocar vehicleType manufacturerName modelName Variant OBSOLETE_FLAG fuel_type transmission gear model CODE0;
		data infocar_term_transposed;set infocar_term_transposed;KM10=10;KM15=15;KM20=20;KM25=25;KM30=30;KM40=40;/*KM50=50;*/
			proc transpose data=infocar_term_transposed
		    out=infocar_transposed (rename=(col1=km) drop=_NAME_ /*rename=(km_min=km_min_original km=km_original)*/); 
			var KM10 KM15 KM20 KM25 KM30 KM40 /*KM50*/;
			by codice_infocar vehicleType manufacturerName modelName Variant OBSOLETE_FLAG fuel_type transmission gear model CODE0 term; 
				data infocar_transposed;retain CODE0 CODE1 codice_infocar vehicleType manufacturerName modelName Variant OBSOLETE_FLAG fuel_type transmission gear model term km;
				set infocar_transposed;length CODE1 $100.;CODE1=CATX("***",manufacturerName,vehicleType,model,fuel_type,gear,transmission,term,km);
				proc sql;create table infocar_short as select distinct codice_infocar, CODE0 from infocar_transposed group by codice_infocar;
				proc sort data=infocar_transposed;by CODE1;
	 run;
	 
/*** (procedure 2) expand infocar file with all combination of term and km ***/

/*%let list_term= term6 term12 term24 term36 term48 term60 term72;*/
/*%let list_km= kmkm10 kmkm15 kmkm20 kmkm25 kmkm30 kmkm40 kmkm50;*/
/*	*/
/*%let parameter = term;*/
/**/
/*	 %macro words(string=);*/
/*	  %local count word;*/
/*	  %let count=1;*/
/*	  %let word=%qscan(&string,&count," ");*/
/*	  %do %while(&word ne);*/
/*	    %let count=%eval(&count+1);*/
/*	    %let word=%qscan(&string,&count," ");*/
/*	  %end;*/
/*	  %eval(&count-1)*/
/*	 %mend words;*/
/**/
/*	%macro transfo (table_in= ,list_term=, table_out=); 	*/
/*		data test;*/
/*		set &table_in.;*/
/*		*/
/*		 %let longueur=%words(string=&list_term);*/
/*		*/
/*		%do l=1 %to &longueur;*/
/*		%let elem= %SCAN(&list_term, &l);*/
/*		*/
/*		if &elem. <1 then*/
/*				%do;  &parameter=compbl(substr("&elem.",5,2)); */
/*				          	 output;*/
/*				%end;*/
/*		%end;*/
/*		run;*/
/*		data test;*/
/*		set test;*/
/*		if &parameter=""  then delete;*/
/*		run;*/
/*		data &table_out;*/
/*		set test;*/
/*		drop &list_term;*/
/*		run;*/
/*		*/
/*		proc delete data=test;run;*/
/*	%mend;*/
/**/
/*%transfo (table_in=infocar, list_term=&list_term, table_out=infocar_term);*/
/**/
/*%let parameter = km;*/
/*%transfo (table_in=infocar_term, list_term=&list_km, table_out=infocar_expand);*/

/**************************** Infocar preview tables ***************************/
%let rrkm=10 15 20 25 30 40;/*50*/
 %let list_term= term6 term12 term24 term36 term48 term60; /*term72*/ /* si cette liste change il faut changer dans le macro import_info aussi*/
 %let parameter = term; /*parameter refers to term or km to expand*/
 
 /****************************************/
 
 %macro words(string=);
  %local count word;
  %let count=1;
  %let word=%qscan(&string,&count," ");
  %do %while(&word ne);
    %let count=%eval(&count+1);
    %let word=%qscan(&string,&count," ");
  %end;
  %eval(&count-1)
 %mend words;
 
 %macro import_info(table_out= , list= );
 
 %let longueur=%words(string=&list);

%let l=1;
%let elem= %SCAN(&list, &l);

PROC IMPORT OUT= infocar&elem.
            DATAFILE= "&path_m\Veicoli_&elem.kkm.xlsx" 
            DBMS=Excel REPLACE;sheet="Veicoli$";
            GETNAMES=YES;
    
RUN;   

proc sort data=infocar&elem.
			out=infocar&elem.;
			by descending Anno Mese;
		run;

proc sort data=infocar&elem.
			out=infocar&elem. nodupkey equals;
			by Codice_Infocar;
		run;

data base_infocar;
set infocar&elem.;
if index(Origine_previsione,"&elem.") then km=&elem/**1000*/;
run;

%do l=2 %to &longueur;

%let elem= %SCAN(&list, &l);
     
  PROC IMPORT OUT= infocar&elem.
            DATAFILE= "&path_m\Veicoli_&elem.kkm.xlsx" 
            DBMS=Excel REPLACE;sheet="Veicoli$";
            GETNAMES=YES;
  
proc sort data=infocar&elem.
			out=infocar&elem.;
			by descending Anno Mese;
		run;

proc sort data=infocar&elem.
			out=infocar&elem. nodupkey equals;
			by Codice_Infocar;
		run;
		
  data infocar&elem.;
  set infocar&elem.;
	  if &elem=50 then do;
		  drop Quotazione_____1_2020 Quotazione_____7_2019; 
	  end;
run;
  
  data infocar&elem.;
  set infocar&elem.;
	  /*reformat the fields with incompatible format in file 50kkm*/
	  if &elem=50 then do;
		  format Quotazione_____1_2020 8.0 Quotazione_____7_2019; 
	  end;
	  km=&elem*1;
run;
  
  data base_infocar;
  set base_infocar infocar&elem.;
run;    
%end;

 data &table_out;
 set base_infocar;
 run;
 
 proc delete data=base_infocar;
 run;

data &table_out;
set &table_out;
/*term72=Previsione_____a_60_mesi0/2;*/
/*Previsione_____a_72_mesi=Previsione_____a_60_mesi/2;*/
rename 
Previsione_____a_12_mesi0 =	term12
Previsione_____a_24_mesi0 =	term24
Previsione_____a_36_mesi0 =	term36
Previsione_____a_48_mesi0 =	term48
Previsione_____a_60_mesi0 =	term60
Previsione_____a_6_mesi0= term6
Prezzo_a_nuovo__= listino
Cilindrata__cm3_ = Cilindrata;
run;
%mend;

options mprint;
%import_info(table_out=base,list=&rrkm);

proc contents data=base; run;

%macro transfo (table_in= ,list_term=, table_out=); 

data test;
set &table_in.;

 %let longueur=%words(string=&list_term);

%do l=1 %to &longueur;
%let elem= %SCAN(&list_term, &l);

if &elem. <1 then
		%do;  &parameter=compbl(substr("&elem.",5,2)); 
		        	 rv_infocar=&elem;
		          	 output;
		%end;
%end;
run;
data test;
set test;
if &parameter=""  and rv_infocar=. then delete;
run;
data &table_out;
set test;
drop &list_term;
run;

proc delete data=test;run;

%mend;

%transfo (table_in=base, list_term=&list_term, table_out=base_out);

/************************* RV setting ***********************/
proc sort data=base_out; by codice_infocar;
data preview;merge base_out (in=a) infocar_short (in=b);by codice_infocar;if a;
data preview;set preview;CODE1=CATX("***",CODE0,term,km);
proc sql;create table preview_group as select distinct CODE1, mean(rv_infocar) as RV format 4.2 from preview group by CODE1;
proc sort data=preview_group;by CODE1;
data RV_grid_Used;merge infocar_transposed (in=a) preview_group (in=b);by CODE1;if a;
data RV_grid_Used;set RV_grid_Used;CODE2=CATX("***",CODE1,codice_infocar);km_max=km*1000;where RV>0;
proc sort data=RV_grid_Used out=RV_grid_Used nodupkey;by CODE2;
data RV_grid_Used;set RV_grid_Used;	
	RV=RV*100;
	format RV 6.2;
	km_min=0;
	IF km_max=15000 THEN km_min=10001;
	    else IF km_max=20000 THEN km_min=15001;
	    ELSE IF km_max=25000 THEN km_min=20001;
		ELSE IF km_max=30000 THEN km_min=25001;
		ELSE IF km_max=40000 THEN km_min=30001;
		ELSE IF km_max=50000 THEN km_min=40001;
	drop CODE2 km;
run;

PROC EXPORT DATA=RV_grid_Used
	OUTFILE= "&path\&quarter\RV_Grid_Used.xlsx" 
	DBMS=Excel REPLACE;
RUN;

/************************* RV interpolation ***********************/
proc sort data=RV_grid_Used;by code0 codice_infocar km_min km_max term; quit;
proc transpose data=RV_grid_Used
     out=RV_trasposed (rename=(col1=T6 col2=T12 col3=T24 col4=T36 col5=T48 col6=T60) drop=_NAME_);
   var rv;
   by code0 codice_infocar km_min km_max;
run;

data RV_trasposed_complete; retain code0 codice_infocar km_min km_max T6 T12 T18 T24 T30 T36 T42 T48 T54 T60 T66 T72 T78 T84;
set RV_trasposed;T18=(T12+T24)/2;T30=(T24+T36)/2;T42=(T36+T48)/2;T54=(T48+T60)/2;T66=T60*0.875;T72=T60*0.75;T78=T60*0.65625;T84=T60*0.75*0.75;rename km_max=km;
format T18 6.2 T30 6.2 T42 6.2 T54 6.2 T66 6.2 T72 6.2 T78 6.2 T84 6.2;run;

proc transpose data=RV_trasposed_complete
     out=RV_retrasposed (rename=(_NAME_=term COL1=rv));
   var T6 T12 T18 T24 T30 T36 T42 T48 T54 T60 T66 T72 T78 T84;
   by code0 codice_infocar km_min km;
   data RV_GRID_USED_CALMS;retain code0 codice_infocar km_min km term rv;set RV_retrasposed; term=substr(term,2,2)*1;format rv 6.2;
run;

proc sql;
create table rv_group as
select distinct code0, km_min, km, term, mean(rv) as rv format 6.2 from RV_GRID_USED_CALMS
group by code0, km_min, km, term;
quit;

data RV_GRID_USED_CALMS_txt;set RV_GRID_USED_CALMS; drop code0; run;
PROC EXPORT DATA= RV_GRID_USED_CALMS_txt OUTFILE= "&path\DSR Outs\&quarter\&used..txt" DBMS=TAB;RUN;

/*PROC EXPORT DATA= RV_GRID_USED_CALMS_txt OUTFILE= "C:\Users\YZ55AX\Documents\RISK\Local_working_folder\&used..txt" DBMS=TAB;RUN;*/



