
/******************* APPLICATIONS TRACKING PROCEDURE ***********************

ORIGINATOR= STEFANO GENTILE
DATE= 24/06/2016
LAST UPDATE= 26/03/2019 BY SG (move R code for interpolation and demo in WPS)
FREQUENCY= QUARTERLY
SOURCE= RV_DATA (allQX_16vX.txt, RV_infocarQx_201x.xls)

**************************************************************************/

/******************* LIBNMANE ***********************/
options compress = yes ;
%LET quarter=Q1_2021; /*change quarter of current RV update*/
%LET month=202103; /*change month of current RV update*/
/*%let path=C:\Users\BZEJKD\Documents;*/
%let path=\\itrmewpefp001.eu.ds.ov.finance\SHARED\Residual Values;
%let path_v=&path\&quarter\InfocarData\Veicoli;

%LET Anno_Edizione=2020; /*change the year of infocar edition - Edizione Dati Infocar Preview*/
%LET Mese_Edizione="10"; /*change the month of infocar edition - Edizione Dati Infocar Preview*/
%let infocar=GMF-IT-PP-VDB-202103;  /*change the month and year*/

/*txt file names should be within 10 characters for WCG to upload*/
%LET version=allQ1_21v5;      	/*New Opel PCP (age>0) & Leasing HRV. Need interpolation, max 72m (6+60)*/
/*%LET verbev=BEVQ3_20v1;*/      	/*no longer needed as Electric is inside the F2ML table. Was: New Opel PCP for Electric, BB Opel, no interpolation, term 24-48m, km<=40k*/
%LET verdemo=DEMQ1_21v5;      	/*demo. Need special interpolation, max term?*/
%LET verlease=nbbQ1_21v5;     	/*New Opel leasing LRV, no interpolation, max 66m*/
%LET verf2ml=f2mQ1_21v5;     	/*Free2Move and PCP New, no interpolation, max 60m, including Corsa-E*/
%LET verf2mlN1=fN1Q1_21v5;     	/*Free2Move N1 -5 pp on PC RV*/
%LET excesskm=EMf2mQ1_21v5;		/*excess mileage for F2ML*/
%LET PCPPost=POST21Q1v5; /*PCP postponed new vehicles*/
%LET verflex=ffQ1_21v5;

/*no need to change unless input changes*/
%LET verf2mlemp=fdpQ1_21v2;     /*Free2Move EMPLOYEES, NO NEED TO UPDATE UNLESS VEHICLES APPROVED GET CHANGED*/

LIBNAME it "&path\&quarter";

/*********************** NEW INFOCAR VEHICLE DATABASE IMPORT AND TREATMENT **************************/
/*csv*/
/*PROC IMPORT OUT= infocar_WCG */
/*		     DATAFILE= "&path\&quarter\&infocar..csv" */
/*		     DBMS=CSV REPLACE; RANGE="&infocar$"; GETNAMES=YES; delimiter=';'; MIXED=NO; SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;*/
/*RUN;*/

/*xlsx*/
PROC IMPORT OUT= infocar_WCG 
		     DATAFILE= "&path\&quarter\&infocar..xlsx" 
		     DBMS=Excel REPLACE; RANGE="&infocar$"; GETNAMES=YES; delimiter=','; MIXED=NO; SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;
RUN;

/*in case in the file from WCG, columns are not separated by ;*/
/*PROC IMPORT OUT= infocar_WCG */
/*		     DATAFILE= "&path\&quarter\&infocar..csv" */
/*		     DBMS=CSV REPLACE; RANGE="&infocar$"; GETNAMES=YES; MIXED=NO; SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;*/
/*RUN;*/

/*PROC IMPORT OUT= infocar_old */
/*		     DATAFILE= "&path\&quarter\&infocar_old..csv" */
/*		     DBMS=CSV REPLACE; RANGE="&infocar$"; GETNAMES=YES; delimiter=';'; MIXED=NO; SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;*/
/*RUN;*/

/*
PROC IMPORT OUT= infocar 
		     DATAFILE= "C:\Users\lzlxtx\Desktop\GM-IT-PP-VData-Extract-250718.csv" 
		     DBMS=CSV REPLACE; RANGE="&infocar$"; GETNAMES=YES; delimiter=';'; MIXED=NO; SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;
RUN;
	*/

DATA infocar;
	SET infocar_WCG;
	format fuel_type $10.;
	IF Fuel in ("P") THEN fuel_type="Petrol";
	IF Fuel in ("G") THEN fuel_type="Gas"; /*metano*/
	IF Fuel in ("B")  THEN fuel_type="LPG";
	IF Fuel in ("D") THEN fuel_type="Diesel";
	IF Fuel in ("E") THEN fuel_type="Electric";
	IF Fuel in ("H", "Y") then do;
		if manufacturerName in ('OPEL') THEN fuel_type="Hybrid"; 
		else if Fuel in ("H") then fuel_type="Petrol";
		else if Fuel in ("Y") then fuel_type="Diesel";
	end;
	
	/*	X=substr(Variant,1,1);*/
	if modelName EQ "MOKKA 1 SERIE" /*and X=X */then modelName="MOKKAX"; 
	
	/* if index(UPCASE(modelName),"MOVANO 4")>0 and infocarRef >= 132759 then modelName="MOVANO 4B SERIE"; /*new Movano 4 to be differentiated from preiouvs versions*/
	if index(UPCASE(modelName),"ASTRA 5")>0 and infocarRef >= 133216 then modelName="ASTRA 5B SERIE"; /*new Astra  to be differentiated from preiouvs versions*/
	
	if index(UPCASE(modelName),'VIVARO-E')>0 and index(Variant,'50kWh') >0 then modelName="VIVARO50KW-E";
	if index(UPCASE(modelName),'VIVARO-E')>0 and index(Variant,'75kWh') >0 then modelName="VIVARO75KW-E"; 
	
	/*By Simon START */
	if index(UPCASE(modelName),'ZAFIRA-E LIFE')>0 and index(Variant,'50kWh') >0 then modelName="ZAFIRALIFE55KW-E"; /*it should be 50KWh but worked it out wrongly in F2ML excel*/
	if index(UPCASE(modelName),'ZAFIRA-E LIFE')>0 and index(Variant,'75kWh') >0 then modelName="ZAFIRALIFE75KW-E";
	
	if index(UPCASE(modelName),'MOKKA 2 SERIE')>0 then modelName="NEWMOKKA";
	if index(UPCASE(modelName),'MOKKA-E')>0 then modelName="NEWMOKKA-E"; 
	
	if index(UPCASE(modelName),'CROSSLAND')>0 and index(Variant,'X')=1 then modelName="CROSSLANDX";
	
	/*By Simon END */
	
	WHERE manufacturerName="OPEL" and OBSOLETE_FLAG="N"/*or manufacturerName="CADILLAC"*/;
	DROP Fuel OBSOLETE_FLAG vehicleType manufacturerName/* X*/ F8;
	RENAME infocarRef=Codice_Infocar;
RUN;

DATA infocar_1;
	SET infocar;
	 
	modelName=tranwrd(modelName,"ª","");
	/*group_field=UPCASE(compress(tranwrd(modelName,"*","")||fuel_type));*/

	format segment $10. version $20. model $20.;
	if index(Variant,'aut.')>0 or index(upcase(Variant),'CVT')>0 or index(upcase(Variant),'AT9')>0 then gear='A';else gear='M';
	if UPCASE(modelName) in ('CORSA-E' 'VIVARO50KW-E' 'VIVARO75KW-E' 'ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E' 'NEWMOKKA-E') then gear='A';
	if index(Variant,'AWD')>0 or index(Variant,'4WD')>0 then transmission='4WD';else transmission='2WD';

	model=compress(modelName);
	
	if index(UPCASE(modelName),'KARL')>0 then segment='A';
	if index(UPCASE(modelName),'ADAM')>0 then segment='A';
	if index(UPCASE(modelName),'CORSA')>0 then segment='B';
	if index(UPCASE(modelName),'ASTRA')>0 then do;
		if index(Variant, 'Tourer')>0 then segment='C_SW';
		else segment='C_BERLINA';
		end;	
	if index(UPCASE(modelName),'INSIGNIA')>0 then do;
		if UPCASE(model) in ('INSIGNIA2SERI') then model = 'INSIGNIA2SERIE';
		if index(Variant, 'Country')>0 then segment='D_SW_CT';	
		else if index(Variant, 'Tourer')>0 then segment='D_SW';
		else segment='D_BERLINA';
		end; 
	if index(UPCASE(modelName),'MOKKA')>0 then segment='B_SUV';
	if index(UPCASE(modelName),'CROSSLAND')>0 then segment='B_SUV'; /*for crossland X and crossland*/ 
	if index(UPCASE(modelName),'GRANDLAND')>0 then segment='C_SUV';
	if index(UPCASE(modelName),'ZAFIRA')>0 then segment='MPV';

	if index(UPCASE(modelName),'COMBO')>0 then do;
		if index(Variant,'N1')>0 then segment='LCV';
		else if index(UPCASE(modelName),'LIFE')>0/*  or index(UPCASE(modelName),'TOUR')>0*/ then segment='MPV'; 
		else segment='LCV';
		end;
	if index(UPCASE(modelName),'VIVARO')>0 then do;
		if/* (index(Variant,'Tourer')>0 or index(Variant,'Combi')>0) or */index(UPCASE(modelName),'LIFE')>0 then segment='MPV'; 
		else segment='LCV';
		end;
	if index(UPCASE(modelName),'MOVANO')>0 then segment='LCV';
/*	if index(UPCASE(modelName),'MOVANO')>0 then do;*/
/*		if index(Variant,'Combi')>0 then segment='MPV'; */
/*		else segment='LCV';*/
/*		end;*/
	
	/***overwrite on top to make all "N1" LCV***/
	if index(Variant,'N1')>0 then segment='LCV';
	
	/*new segmentation of version according to Marco Speranza*/
	if segment notin ('LCV' '' ' ') then do;
/*		if index(Variant,'OPC Line')>0 or index(Variant,'GSi')>0 or index(Variant,'Ultimate')>0 or index(Variant,'Country Tourer Exclusive')>0 or */
/*		index(Variant,'Country T. Exclusive')>0 or index(Variant,'Exclusive')>0 or substr (Variant,length(Variant)-1,2)=' S' then version = 'upper_version';*/
/*		else if index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or index(Variant,'Glam')>0 or index(Variant,'Slam')>0 or index(Variant,'Dynamic')>0 or */
/*		index(Variant,'Design Line')>0 or index(Variant,'Black Edition')>0 or index(Variant,'Business')>0 or index(Variant,'Vision')>0 or */
/*		index(Variant,'b-color')>0  or index(Variant,'b-Color')>0 or index(Variant,'Country Tourer')>0 or index(Variant,'Cosmo')>0 or index(Variant,'Anniversary')>0 or index(Variant,'Anniversay')>0 then version = 'medium_version';*/
/*		else version = 'lower_version';	*/
		
		if UPCASE(model) in ('CORSA5SERIE') then do;
			if index(Variant,'GSi')>0 then version = 'upper_version';
			else if index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or index(Variant,'Black Edition')>0 or index(Variant,'Anniversary')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(modelName) in ('CORSA6SERIE') then do;
			if index(Variant,'Edition')>0 then version = 'medium_version';
			else if index(Variant,'GS Line')>0 or index(Variant,'Elegance')>0 then version = 'upper_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('CORSA-E') then do;
			if index(Variant,'Selection')>0 then version = 'lower_version';
			else if index(Variant,'First Edition')>0 or index(Variant,'Elegance')>0 or index(Variant,'GS Line')>0 then version = 'upper_version'; 
			else if index(Variant,'Edition')>0 then version = 'medium_version';
		end;
		else if UPCASE(model) in ('CROSSLAND','CROSSLANDX') then do;
			if index(Variant,'Ultimate')>0 then version = 'upper_version';
			else if index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or 
			index(Variant,'Anniversary')>0 or index(Variant,'Elegance')>0 or 
			index(Variant,'GS Line')>0 then version = 'medium_version';
			else version = 'lower_version';
		end; 
		else if UPCASE(model) in ('GRANDLANDX') then do;
			if index(Variant,'Ultimate')>0 then version = 'upper_version';
			else if index(Variant,'Business')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or index(Variant,'Anniversary')>0 or index(Variant,'Elegance')>0 or index(Variant,'Design Line')>0 then version = 'medium_version';
			else version = 'lower_version';
			if fuel_type="Hybrid" then version = 'medium_version'; /*to be confirmed by Marco Speranza on the version of Grandland hybrid*/
		end; 
		else if UPCASE(model) in ('MOKKAX') then do;
			if index(Variant,'Ultimate')>0 then version = 'upper_version';
			else if index(Variant,'Business')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('ASTRA5BSERIE') then do;
			if index(Variant,'Ultimate')>0 then version = 'upper_version';
			else if index(Variant,'Business Elegance')>0 or index(Variant,'Business Eleg.')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('ASTRA5SERIE') then do;
			if index(Variant,'OPC Line')>0 then version = 'upper_version';
			else if index(Variant,'Business')>0 or index(Variant,'Dynamic')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('INSIGNIA2SERIE') then do;
			if index(Variant,'GSi')>0 or index(Variant,'Country Tourer')>0 or index(Variant,'Ultimate')>0 then version = 'upper_version';
			else if index(Variant,'Business Ele')>0 or index(Variant,'Bus. Ele')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('COMBOLIFE') then do;
			if index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or index(Variant,'Elegance Plus')>0 then version = 'upper_version';
			else if index(Variant,'Advance')>0 or index(Variant,'Elegance')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('ZAFIRALIFE') then do; /*Zafira 3 serie not offered anymore on F2ML*/
			if index(Variant,'Business Edition')>0 then version = 'lower_version';
			else if index(Variant,'Advance')>0 or index(Variant,'Edition')>0 or index(Variant,'Business Ele')>0 or index(Variant,'Bus. Ele')>0 then version = 'medium_version';
			else if index(Variant,'Elegance')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 then version = 'upper_version';
			else version = 'lower_version';
		end;
		else if index(UPCASE(model),'VIVARO')>0 then do;
			if index(Variant,'Enjoy')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		
		/*By Simon START */
		else if index(UPCASE(model),'NEWMOKKA')>0 then do; 
			if index(Variant,'Edition')>0 then version = 'lower_version';
			else if index(Variant,'GS Line +')>0 or index(Variant,'Ultimate')>0 then version = 'upper_version';
			else if index(Variant,'Elegance')>0 or index(Variant,'GS Line')>0 then version = 'medium_version'; 
		end;
		
		/*else if UPCASE(model) in ('ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E') then do; 
			if index(Variant,'Edition')>0 then version = 'medium';
			else if index(Variant,'Elegance')>0 then version = 'upper_version';
			else version = 'lower_version';
		end;*/
		/*By Simon END */
		
		else if UPCASE(model) in ('VIVAROLIFE') then version = 'lower_version';
		else do; /*on models not quotabile anymore on F2ML, continue to use the old definition for PCP purpose*/
			if index(Variant,'OPC Line')>0 or index(Variant,'GSi')>0 or index(Variant,'Ultimate')>0 or index(Variant,'Country Tourer Exclusive')>0 or 
			index(Variant,'Country T. Exclusive')>0 or index(Variant,'Exclusive')>0 or substr(Variant,length(Variant)-1,2)=' S' then version = 'upper_version';
			else if index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or index(Variant,'Glam')>0 or index(Variant,'Slam')>0 or 
			index(Variant,'Dynamic')>0 or index(Variant,'Design Line')>0 or index(Variant,'Black Edition')>0 or index(Variant,'Business')>0 or 
			index(Variant,'Vision')>0 or index(Variant,'b-color')>0 or index(Variant,'b-Color')>0 or index(Variant,'Country Tourer')>0 or 
			index(Variant,'Cosmo')>0 or index(Variant,'Anniversary')>0 or index(Variant,'Anniversay')>0 or index(Variant,'Anniv.')>0 then version = 'medium_version';
			else version = 'lower_version';		
		end;
	end;
	
	if segment = 'LCV' then do;
		if UPCASE(model) in ('COMBO5SERIE') then do;
			if index(Variant,'Edition')>0 then version = 'medium_version';
			else/* if index(Variant,'Essentia')>0 then*/ version = 'lower_version';
		end;
		else if UPCASE(model) in ('COMBOLIFE') then do;
			if index(Variant,'Advance')>0 or index(Variant,'Elegance')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('VIVARO4SERIE') then do;
			if index(Variant,'Enjoy')>0 then version = 'medium_version';
			else/* if index(Variant,'Essentia')>0 then*/ version = 'lower_version';
		end;
		else if UPCASE(model) in ('VIVARO75KW-E', 'VIVARO50KW-E') then do;
			if index(Variant,'Enjoy')>0 then version = 'medium_version';
			else/* if index(Allestimento,'Essentia')>0 then*/ version = 'lower_version';
		end;
		else if UPCASE(model) in ('MOVANO4SERIE') or UPCASE(model) in ('MOVANO4BSERIE') then do;
			if index(Variant,'Edition')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;	
		else do; /*on models not quotabile anymore on F2ML, continue to use the old definition for PCP purpose*/
			if index(Variant,'Edition')>0 or index(Variant,'Innovation')>0 then version = 'medium_version';	
			else version = 'lower_version';
		end;
	end;
	
	drop modelName;
RUN;
	
PROC SORT DATA=infocar_1
	OUT=it.infocar;
	BY Codice_Infocar;
RUN;

/************************** check new code infocar to add in the file ***************************/	
/*to do: try check with old WCG file */
PROC SORT DATA=it.RV_BASE_SHORT_CALMS_&quarter
	OUT=RV_BASE_SHORT_CALMS_&quarter;
	BY Codice_Infocar;
RUN;

data it.new_entry;
merge RV_BASE_SHORT_CALMS_&quarter (in=a keep=Codice_Infocar) it.INFOCAR (in=b);
by codice_infocar;
if b=1 and a=0;
run;

%let list_term= term6 term12 term24 term36 term48 term60 term72;
%let list_km= kmkm10 kmkm15 kmkm20 kmkm25 kmkm30 kmkm40 kmkm50;
 
/*expand in terms and km using existing macro %words and %transfo*/
%let parameter = term; /*parameter refers to term or km to expand*/

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

%transfo (table_in=it.new_entry, list_term=&list_term, table_out=new_entry_term);

%let parameter = km; /*parameter refers to term or km to expand*/
%transfo (table_in=new_entry_term, list_term=&list_km, table_out=new_entry_expand);
 
data new_entry_expand_1;
	set new_entry_expand;

	format /*rv_sb 6.2 rv_f2ml 6.2 */rv_lease 6.2;
	
	if km="50" then do;
		rv_lease=0;
	end;
	
	if km notin ("50") then do;
		if term in ('6' '12') then rv_lease=25;
		else if term="24" then rv_lease=20;
		else if term="36" then rv_lease=15;
		else if term="48" then rv_lease=10;
		else if term="60" then rv_lease=5;
		else if term="72" then rv_lease=2;
	end;
	
	format km_num 8.0 term_num 2.0;
	km_num = km * 1000;
	term_num = term*1;
	
	km_min=0;
	IF km_num=15000 THEN km_min=10001;
	    else IF km_num=20000 THEN km_min=15001;
	    ELSE IF km_num=25000 THEN km_min=20001;
		ELSE IF km_num=30000 THEN km_min=25001;
		ELSE IF km_num=40000 THEN km_min=30001;
		ELSE IF km_num=50000 THEN km_min=40001;

	CODE=CATX("***",model, segment, fuel_type, version, term, km_num); 
		
	CODE1=CATX("***",model, segment, fuel_type, version, term, km_num, gear, transmission); 
/*		if (index(model,'VIVARO') or index(model,'MOVANO') or index(model,'COMBO')) then do;*/
/*			CODE1=CATX("***",model, segment, version, term, km_num, gear, transmission);*/
/*			CODE=CATX("***",model, segment, version, term, km_num);*/
/*			end;	*/
	
	code2=CATX("***",Codice_Infocar,code);
	drop rv_infocar km term;
	if term_num >=60 and km_num=50000 then flag_over60_50=1; else flag_over60_50=0;
run;
 
proc sort data=new_entry_expand_1
		out=new_entry_expand_1;
		by Code1;
run;

proc sort data=it.RV_BASE_AVERAGE
		out=RV_BASE_AVERAGE;
		by Code1;
run;

data new_entry_rv (drop=flag_over60_50 rename=(km_num = km term_num = term));
merge new_entry_expand_1 (in=a where=(flag_over60_50=0)) RV_BASE_AVERAGE (in=b rename=(rv_sb_mean=rv_sb));
by code1;
if a;
run;

data new_entry_append (drop=RV_BASE_F2ML);
merge new_entry_rv (in=a) it.RV_BASE_F2ML (in=b);
by code;
if a; 
if RV_BASE_F2ML=. then RV_BASE_F2ML=0;
rv_f2ml=RV_BASE_F2ML*100;
format rv_f2ml 6.2;
if RV_BASE_F2ML>0 then do;
	if gear eq 'M' and transmission eq '2WD' then rv_f2ml=RV_BASE_F2ML*100;
	if gear eq 'A' and transmission eq '2WD' and model notin ('CORSA-E' 'VIVARO50KW-E' 'VIVARO75KW-E' 'ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E') then rv_f2ml=RV_BASE_F2ML*100+1;
	if gear eq 'M' and transmission eq '4WD' then rv_f2ml=RV_BASE_F2ML*100+1;
	if gear eq 'A' and transmission eq '4WD' then do;
		if model in ('CORSA-E' 'VIVARO50KW-E' 'VIVARO75KW-E' 'ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E') then rv_f2ml=rv_base_f2ml*100+1; else rv_f2ml=rv_base_f2ml*100+2;
	end;
end;
run;

proc sort data=new_entry_append
		out=new_entry_append;
		by code2;
run;

data new_entry_append_1 (drop=RV_F2ML_EMPLOYEE code2);
merge new_entry_append (in=a) IT.RV_BASE_F2ML_EMP (in=b);
by code2;
if a; 
if RV_F2ML_EMPLOYEE=. then RV_F2ML_EMPLOYEE=0;
RV_F2ML_EMP=RV_F2ML_EMPLOYEE*100;
format RV_F2ML_EMP 6.2;
run;

/*** RV adjustment per RV committee Q4 ***/
/*for Corsa-E PCP, RV equals to F2ML and BB by Opel*/
data RV_update_&quarter;
	set it.RV_BASE_SHORT_CALMS_&quarter new_entry_append_1;
	
	if km=50000 then rv_sb=0;
	if RV_F2ML_EMP=. then RV_F2ML_EMP=0;
	
	format rv_sb_BB_opel 6.2 rv_benchmark_infocar 6.2;
	rv_sb_BB_opel=0;
	rv_benchmark_infocar=rv_sb;
	if fuel_type in ('Electric') then do;
		rv_sb=0; 
		if term in (24 36 48) and km<=40000 then rv_sb_BB_opel = rv_f2ml;
	end;
/*	if codice_infocar = "120083" and km = 10000 and term = 36 then rv_sb = 40.00;*/
/*	if codice_infocar = "120083" and km = 15000 and term = 36 then rv_sb = 38.00;*/
/*	if codice_infocar = "120080" and km = 10000 and term = 36 then rv_sb = 40.00;*/
/*	if codice_infocar = "120080" and km = 15000 and term = 36 then rv_sb = 38.00;*/
/*	if codice_infocar = "120082" and km = 10000 and term = 36 then rv_sb = 40.00;*/
/*	if codice_infocar = "120082" and km = 15000 and term = 36 then rv_sb = 38.00;*/
/*	if codice_infocar = "120081" and km = 10000 and term = 36 then rv_sb = 40.00;*/
/*	if codice_infocar = "120081" and km = 15000 and term = 36 then rv_sb = 38.00;*/
/*	if codice_infocar = "124632" and km = 10000 and term = 36 then rv_sb = 40.00;*/
/*	if codice_infocar = "124632" and km = 15000 and term = 36 then rv_sb = 38.00;*/
/*	if codice_infocar = "124631" and km = 10000 and term = 36 then rv_sb = 40.00;*/
/*	if codice_infocar = "124631" and km = 15000 and term = 36 then rv_sb = 38.00;*/
run;

/*to calculate the PCP RV for 25000km annual mileage for new fuel type that has Opel BB*/
data RV_PCP_25kkm_new_fuel;
	set RV_update_&quarter;
/*	drop rv_f2ml RV_F2ML_EMP rv_sb rv_lease;*/
	where fuel_type in ('Electric') and term in (24 36 48) and km in (20000 25000 30000);
run;

PROC SORT DATA=RV_PCP_25kkm_new_fuel
			OUT=RV_PCP_25kkm_new_fuel;
			BY codice_infocar term km;
RUN;

PROC TRANSPOSE DATA=RV_PCP_25kkm_new_fuel OUT=RV_PCP_25kkm_new_fuel;
BY codice_infocar term fuel_type segment version model;
VAR rv_sb_BB_opel;
ID km;
RUN;

data RV_PCP_25kkm_new_fuel;
	set RV_PCP_25kkm_new_fuel;
	_25000=(_20000+_30000)/2;
	CODE=CATX("***",model, segment, fuel_type, version, term, "25000");
	rename _25000=rv_sb_BB_opel;
	keep CODE _25000;
run;

PROC SORT DATA=RV_update_&quarter
			OUT=RV_update_&quarter;
			BY CODE;
RUN;

PROC SORT DATA=RV_PCP_25kkm_new_fuel
			OUT=RV_PCP_25kkm_new_fuel;
			BY CODE;
RUN;

data RV_update_&quarter;
merge RV_update_&quarter (in=a) RV_PCP_25kkm_new_fuel (in=b);
if a;
by CODE;
run;

data it.RV_update_&quarter;
	retain codice_infocar km_min km term rv_f2ml RV_F2ML_EMP rv_sb_BB_opel rv_sb rv_lease rv_benchmark_infocar code code1 Anno_Edizione Mese_Edizione fuel_type segment version model gear transmission flag_over60_50 Variant;
	set RV_update_&quarter;
run;

/*RV missing even from checking the avg rv in existing table. To be worked out manually*/
data RV_missing;
	set new_entry_append;
	
	where (rv_sb=0 or rv_sb=.) /*and km <> 50000*/;
run;

proc sort data= RV_missing (where=(term=36 and km=30000))
			out=it.RV_missing_code nodupkey equals;
			by CODE1;
run;

PROC EXPORT DATA= it.RV_update_&quarter
	            OUTFILE= "&path\&quarter\RV_UPDATE_&month..xlsx" 
	            DBMS=EXCEL REPLACE;
	     SHEET="RV"; 
RUN;

/*********************STOP HERE AND CHECK OUTPUT FILE "RV_UPDATE_&month..xlsx" AND ADD VALUES TO COLUMN RV_SB WHERE BLANK********************************/


/*** ACTIVE IN CASE OF MISSING RV VALUE (sb), after manual input of missing RV in  RV_UPDATE_&quarter..xlsx file***/
PROC IMPORT OUT= it.RV_update_&quarter
            DATAFILE= "&path\&quarter\RV_UPDATE_&month..xlsx" 
            DBMS=Excel REPLACE;sheet="RV";
            GETNAMES=YES;

data it.RV_missing;
	set it.RV_update_&quarter;	
	where (rv_sb=.) and flag_over60_50=0;
run;

data it.RV_update_&quarter; set it.RV_update_&quarter; format rv_sb_BB_opel 6.2 rv_sb 6.2 rv_lease 6.2 rv_f2ml 6.2 RV_F2ML_EMP 6.2 rv_benchmark_infocar 6.2; run;

/********************export to txt*******************************/
/*RV_sb*/
data RV_sb_complete;
	retain codice_infocar km_min km term rv_sb;
	set IT.RV_UPDATE_&quarter;
	keep codice_infocar km_min km term rv_sb model;
	rename rv_sb=rv;
	where /*km ne 50000 and */fuel_type notin ('Electric'); /*50kkm is needed for the PCP first instalment postponed calculation*/
run;

data RV_sb;
	set RV_sb_complete;
	keep codice_infocar km_min km term rv;
	where codice_infocar<>. and km ne 50000;
run;

PROC EXPORT DATA= RV_sb OUTFILE= "&path\DSR Outs\&quarter\&version._Not_Interpolated.txt" DBMS=TAB;RUN;

/*RV_sb Electric Corsa-E, BB Opel*/

/*data RV_sb_Opel_BB;*/
/*	retain codice_infocar km_min km term rv_sb_BB_opel;*/
/*	set IT.RV_UPDATE_&quarter;*/
/*	keep codice_infocar km_min km term rv_sb_BB_opel;*/
/*	rename rv_sb_BB_opel=rv;*/
/*	where rv_sb_BB_opel>0;*/
/*run;*/
/**/
/*PROC EXPORT DATA= RV_sb_Opel_BB OUTFILE= "&path\DSR Outs\&quarter\&verbev..txt" DBMS=TAB;RUN;*/

/*sb table transpose preparation*/
/*to add RV for 50kkm*/
data RV_SB_50kkm; set RV_sb_complete; where km=40000; run;

data RV_SB_50kkm_1; 
	set RV_SB_50kkm; 
	km_min=40001;
	km=50000;
	rv_50=rv-0.000142555121817047*10000*(term/12);
	if rv_50<0 then rv_50=0;
	format rv_50 6.2;
	drop rv;
	rename rv_50=rv;
run;

data RV_sb_complete_new;
	set RV_sb_complete (where=(km ne 50000)) RV_SB_50kkm_1;
run;

proc sort data=RV_sb_complete_new out=RV_sb_com_ordered;by codice_infocar km_min km term; quit;
proc transpose data=RV_sb_com_ordered
     out=RV_sb_com_trasposed (rename=(col1=T6 col2=T12 col3=T24 col4=T36 col5=T48 col6=T60 col7=T72) drop=_NAME_ rename=(_LABEL_=table));
   var rv;
   by codice_infocar km_min km model;
run;

/*RV_sb_Interpolated*/
data RV_sb_interpolated_trasposed_com; 
retain codice_infocar table km_min km model
T6 T7 T8 T9 T10 T11 T12 
T13 T14 T15 T16 T17 T18 T19 T20 T21 T22 T23 T24 
T25 T26 T27 T28 T29 T30 T31 T32 T33 T34 T35 T36 
T37 T38 T39 T40 T41 T42 T43 T44 T45 T46 T47 T48 
T49 T50 T51 T52 T53 T54 T55 T56 T57 T58 T59 T60 
T61 T62 T63 T64 T65 T66 T67 T68 T69 T70 T71 T72;
set RV_sb_com_trasposed;

T7=T6-(T6-T12)/6;
T8=T7-(T6-T12)/6;
T9=T8-(T6-T12)/6;
T10=T9-(T6-T12)/6;
T11=T10-(T6-T12)/6;

T13=T12-(T12-T24)/12;
T14=T13-(T12-T24)/12;
T15=T14-(T12-T24)/12;
T16=T15-(T12-T24)/12;
T17=T16-(T12-T24)/12;
T18=T17-(T12-T24)/12;
T19=T18-(T12-T24)/12;
T20=T19-(T12-T24)/12;
T21=T20-(T12-T24)/12;
T22=T21-(T12-T24)/12;
T23=T22-(T12-T24)/12;

T25=T24-(T24-T36)/12;
T26=T25-(T24-T36)/12;
T27=T26-(T24-T36)/12;
T28=T27-(T24-T36)/12;
T29=T28-(T24-T36)/12;
T30=T29-(T24-T36)/12;
T31=T30-(T24-T36)/12;
T32=T31-(T24-T36)/12;
T33=T32-(T24-T36)/12;
T34=T33-(T24-T36)/12;
T35=T34-(T24-T36)/12;

T37=T36-(T36-T48)/12;
T38=T37-(T36-T48)/12;
T39=T38-(T36-T48)/12;
T40=T39-(T36-T48)/12;
T41=T40-(T36-T48)/12;
T42=T41-(T36-T48)/12;
T43=T42-(T36-T48)/12;
T44=T43-(T36-T48)/12;
T45=T44-(T36-T48)/12;
T46=T45-(T36-T48)/12;
T47=T46-(T36-T48)/12;

T49=T48-(T48-T60)/12;
T50=T49-(T48-T60)/12;
T51=T50-(T48-T60)/12;
T52=T51-(T48-T60)/12;
T53=T52-(T48-T60)/12;
T54=T53-(T48-T60)/12;
T55=T54-(T48-T60)/12;
T56=T55-(T48-T60)/12;
T57=T56-(T48-T60)/12;
T58=T57-(T48-T60)/12;
T59=T58-(T48-T60)/12;

T61=T60-(T60-T72)/12;
T62=T61-(T60-T72)/12;
T63=T62-(T60-T72)/12;
T64=T63-(T60-T72)/12;
T65=T64-(T60-T72)/12;
T66=T65-(T60-T72)/12;
T67=T66-(T60-T72)/12;
T68=T67-(T60-T72)/12;
T69=T68-(T60-T72)/12;
T70=T69-(T60-T72)/12;
T71=T70-(T60-T72)/12;

format
T6 6.2 T7 6.2 T8 6.2 T9 6.2 T10 6.2 T11 6.2 T12 6.2 
T13 6.2 T14 6.2 T15 6.2 T16 6.2 T17 6.2 T18 6.2 T19 6.2 T20 6.2 T21 6.2 T22 6.2 T23 6.2 T24 6.2 
T25 6.2 T26 6.2 T27 6.2 T28 6.2 T29 6.2 T30 6.2 T31 6.2 T32 6.2 T33 6.2 T34 6.2 T35 6.2 T36 6.2 
T37 6.2 T38 6.2 T39 6.2 T40 6.2 T41 6.2 T42 6.2 T43 6.2 T44 6.2 T45 6.2 T46 6.2 T47 6.2 T48 6.2 
T49 6.2 T50 6.2 T51 6.2 T52 6.2 T53 6.2 T54 6.2 T55 6.2 T56 6.2 T57 6.2 T58 6.2 T59 6.2 T60 6.2 
T61 6.2 T62 6.2 T63 6.2 T64 6.2 T65 6.2 T66 6.2 T67 6.2 T68 6.2 T69 6.2 T70 6.2 T71 6.2 T72 6.2;
run;

proc transpose data=RV_sb_interpolated_trasposed_com
     out=RV_sb_interpolated_new_trasposed (rename=(col1=rv) drop=table); 
   var T6 T7 T8 T9 T10 T11 T12 T13 T14 T15 T16 T17 T18 T19 T20 T21 T22 T23 T24 T25 T26 T27 T28 T29 T30 T31 T32 T33 T34 T35 T36 
   T37 T38 T39 T40 T41 T42 T43 T44 T45 T46 T47 T48 T49 T50 T51 T52 T53 T54 T55 T56 T57 T58 T59 T60 T61 T62 T63 T64 T65 T66 T67 T68 T69 T70 T71 T72;
   by codice_infocar table km_min km model;
   
data RV_sb_interpolated;retain codice_infocar table km_min km term rv;set RV_sb_interpolated_new_trasposed; term=substr(_NAME_,2,2)*1;format rv 6.2;drop _NAME_ model; run;

/*regular PCP (without first instalment postponed)*/
PROC EXPORT DATA= RV_sb_interpolated (where=(km ne 50000)) OUTFILE= "&path\DSR Outs\&quarter\&version..txt" DBMS=TAB;RUN;

/*PCP with first instalment postponed*/
/*Scenario 1: with 3 months in delay and km+5k/10k: new term=term-3, km goes down to the previous cutoff*/
/*data RV_sb_post_interpolated;*/
/*	set RV_sb_interpolated;*/
/**/
/*	term_new=term-3;*/
/*	if km>=40000 then km_new=km-10000; else km_new=km-5000;*/
/*	*/
/*	km_min_new=0;*/
/*	IF km_new=15000 THEN km_min_new=10001;*/
/*	    else IF km_new=20000 THEN km_min_new=15001;*/
/*	    ELSE IF km_new=25000 THEN km_min_new=20001;*/
/*		ELSE IF km_new=30000 THEN km_min_new=25001;*/
/*		ELSE IF km_new=40000 THEN km_min_new=30001;*/
/*		ELSE IF km_new=50000 THEN km_min_new=40001;*/
/*	drop km_min km term;*/
/*	rename term_new=term km_new=km km_min_new=km_min;*/
/*	*/
/*	where term in (27,39) and km>=15000; */
/*run;*/
/**/
/*data RV_sb_post_interpolated; retain codice_infocar km_min km term rv; set RV_sb_post_interpolated;run;*/

/*Scenario 2: with 2 months in delay and km+5k/10k: new term=term-2, km goes down to the previous cutoff*/
/*data RV_sb_post_interpolated;*/
/*	set RV_sb_interpolated;*/
/**/
/*	term_new=term-2;*/
/*	if km>=40000 then km_new=km-10000; else km_new=km-5000;*/
/*	*/
/*	km_min_new=0;*/
/*	IF km_new=15000 THEN km_min_new=10001;*/
/*	    else IF km_new=20000 THEN km_min_new=15001;*/
/*	    ELSE IF km_new=25000 THEN km_min_new=20001;*/
/*		ELSE IF km_new=30000 THEN km_min_new=25001;*/
/*		ELSE IF km_new=40000 THEN km_min_new=30001;*/
/*		ELSE IF km_new=50000 THEN km_min_new=40001;*/
/*	drop km_min km term;*/
/*	rename term_new=term km_new=km km_min_new=km_min;*/
/*	*/
/*	where term in (26,38) and km>=15000;*/
/*run;*/
/**/
/*data RV_sb_post_interpolated; retain codice_infocar km_min km term rv; set RV_sb_post_interpolated;run;*/

/*PROC EXPORT DATA= RV_sb_post_interpolated*/
/*	            OUTFILE= "&path\&quarter\RV_PCP_Postponed_2M_&quarter..xlsx" */
/*	            DBMS=EXCEL REPLACE;*/
/*	     SHEET="RV"; */
/*RUN;*/

/*Scenario 3: with 3 months in delay and without adj on km*/
/*data RV_sb_post_interpolated;*/
/*	set RV_sb_interpolated;*/
/**/
/*	term_new=term-3;*/
/*	*/
/*	drop term;*/
/*	rename term_new=term;*/
/*	*/
/*	where term in (27,39) and km<50000;*/
/*run;*/
/*data RV_sb_post_interpolated; retain codice_infocar km_min km term rv; set RV_sb_post_interpolated;run;*/
/**/
/*PROC EXPORT DATA= RV_sb_post_interpolated*/
/*	            OUTFILE= "&path\&quarter\RV_PCP_Postponed_3M_+0km_&quarter..xlsx" */
/*	            DBMS=EXCEL REPLACE;*/
/*	     SHEET="RV"; */
/*RUN;*/

/*Scenario 4: on top of scenario 3, with F2ML RV as benchmark instead of sb*/
/*data RV_F2ML;*/
/*	retain codice_infocar km_min km term rv_f2ml fuel_type;*/
/*	set IT.RV_UPDATE_&quarter;*/
/*	keep codice_infocar km_min km term rv_f2ml model fuel_type;*/
/*	rename rv_f2ml=rv;*/
/*	where rv_f2ml>0;*/
/*run;*/
/*proc sort data=RV_F2ML out=RV_F2ML_ordered;by codice_infocar km_min km term; quit;*/
/**/
/*proc transpose data=RV_F2ML_ordered*/
/*     out=RV_F2ML_trasposed (rename=(col1=T12 col2=T24 col3=T36 col4=T48 col5=T60) drop=_NAME_ rename=(_LABEL_=table));*/
/*   var rv;*/
/*   by codice_infocar km_min km model fuel_type;*/
/*run;*/
/**/
/*data RV_F2ML_interpolated_trasposed; */
/*retain codice_infocar table km_min km model fuel_type*/
/*T24 T25 T26 T27 T36 T37 T38 T39;*/
/*set RV_F2ML_trasposed;*/
/**/
/*T25=T24-(T24-T36)/12;*/
/*T26=T25-(T24-T36)/12;*/
/*T27=T26-(T24-T36)/12;*/
/**/
/*T37=T36-(T36-T48)/12;*/
/*T38=T37-(T36-T48)/12;*/
/*T39=T38-(T36-T48)/12;*/
/**/
/*format*/
/*T24 6.2 T25 6.2 T26 6.2 T27 6.2 T36 6.2 T37 6.2 T38 6.2 T39 6.2;*/
/*drop T12 T48 T60;*/
/*run;*/
/**/
/*proc transpose data=RV_F2ML_interpolated_trasposed*/
/*     out=RV_F2ML_interp_new_trasposed (rename=(col1=rv) drop=table); */
/*   var T24 T25 T26 T27 T36 T37 T38 T39;*/
/*   by codice_infocar table km_min km model fuel_type;*/
/*   */
/*data RV_F2ML_interpolated;retain codice_infocar table km_min km term rv fuel_type;set RV_F2ML_interp_new_trasposed; term=substr(_NAME_,2,2)*1;format rv 6.2;drop _NAME_ model; run;*/
/**/
/*data RV_sb_post_interpolated;*/
/*	set RV_F2ML_interpolated;*/
/**/
/*	term_new=term-3;*/
/*	*/
/*	drop term;*/
/*	rename term_new=term;*/
/*	*/
/*	where term in (27,39) and km<50000;*/
/*run;*/
/*data RV_sb_post_interp_all; retain codice_infocar km_min km term rv; set RV_sb_post_interpolated; drop fuel_type; run;*/
/*data RV_sb_post_interp_NoElet; retain codice_infocar km_min km term rv; set RV_sb_post_interpolated; where fuel_type notin ('Electric'); drop fuel_type; run;*/
/**/
/*PROC EXPORT DATA= RV_sb_post_interpolated*/
/*	            OUTFILE= "&path\&quarter\RV_PCP_Postponed_F2ML_3M_+0km_&quarter..xlsx" */
/*	            DBMS=EXCEL REPLACE;*/
/*	     SHEET="RV"; */
/*RUN;*/
/**/
/*PROC EXPORT DATA= RV_sb_post_interp_all OUTFILE= "&path\DSR Outs\&quarter\&PCPPost..txt" DBMS=TAB;RUN;*/


/*Scenario 4b: on top of scenario 3, with F2ML RV as benchmark instead of sb*/
%let M_delay=3; /*month of delay for first payment*/

data RV_F2ML;
	retain codice_infocar km_min km term rv_f2ml fuel_type;
	set IT.RV_UPDATE_&quarter;
	keep codice_infocar km_min km term rv_f2ml model fuel_type;
	rename rv_f2ml=rv;
	where rv_f2ml>0;
run;
proc sort data=RV_F2ML out=RV_F2ML_ordered;by codice_infocar km_min km term; quit;

proc transpose data=RV_F2ML_ordered
     out=RV_F2ML_trasposed (rename=(col1=T12 col2=T24 col3=T36 col4=T48 col5=T60) drop=_NAME_ rename=(_LABEL_=table));
   var rv;
   by codice_infocar km_min km model fuel_type;
run;

/*24, 36, 48 months*/
data RV_F2ML_interpolated_trasposed; 
retain codice_infocar table km_min km model fuel_type
T24 T25 T26 T27 /*T28 T29 */T36 T37 T38 T39 /*T40 T41 */T48 T49 T50 T51/* T52 T53*/;
set RV_F2ML_trasposed;

T25=T24-(T24-T36)/12;
T26=T25-(T24-T36)/12;
T27=T26-(T24-T36)/12;
T28=T27-(T24-T36)/12;
T29=T28-(T24-T36)/12;

T37=T36-(T36-T48)/12;
T38=T37-(T36-T48)/12;
T39=T38-(T36-T48)/12;
T40=T39-(T36-T48)/12;
T41=T40-(T36-T48)/12;

T49=T48-(T48-T60)/12;
T50=T49-(T48-T60)/12;
T51=T50-(T48-T60)/12;
T52=T51-(T48-T60)/12;
T53=T52-(T48-T60)/12;

format
T24 6.2 T25 6.2 T26 6.2 T27 6.2 T28 6.2 T29 6.2 T36 6.2 T37 6.2 T38 6.2 T39 6.2 T40 6.2 T41 6.2 T48 6.2 T49 6.2 T50 6.2 T51 6.2 T52 6.2 T53 6.2;
drop T12 T60 T28 T29 T40 T41 T52 T53;
run;

proc transpose data=RV_F2ML_interpolated_trasposed
     out=RV_F2ML_interp_new_trasposed (rename=(col1=rv) drop=table); 
   var T24 T25 T26 T27 /*T28 T29 */T36 T37 T38 T39 /*T40 T41 */T48 T49 T50 T51;
   by codice_infocar table km_min km model fuel_type;
   
data RV_F2ML_interpolated;retain codice_infocar table km_min km term rv fuel_type;set RV_F2ML_interp_new_trasposed; term=substr(_NAME_,2,2)*1;format rv 6.2;drop _NAME_ model; run;

data RV_sb_post_interpolated;
	set RV_F2ML_interpolated;

	term_new=term-&M_delay;
	
	drop term;
	rename term_new=term;
	
	where (term=24+&M_delay or term=36+&M_delay or term=48+&M_delay) and km<50000;
run;

data RV_sb_post_interp_all; retain codice_infocar km_min km term rv; set RV_sb_post_interpolated; drop fuel_type; run;
/*data RV_sb_post_interp_NoElet; retain codice_infocar km_min km term rv; set RV_sb_post_interpolated; where fuel_type notin ('Electric'); drop fuel_type; run;*/

PROC EXPORT DATA= RV_sb_post_interpolated
	            OUTFILE= "&path\&quarter\RV_PCP_Postponed_F2ML_3M_+0km_&quarter..xlsx" 
	            DBMS=EXCEL REPLACE;
	     SHEET="RV"; 
RUN;

PROC EXPORT DATA= RV_sb_post_interp_all OUTFILE= "&path\DSR Outs\&quarter\&PCPPost..txt" DBMS=TAB;RUN;



data RV_sb_demo_trasposed1; retain codice_infocar table km_min km T12 T13 T14 T15 T16 T17 T18 T24 T25 T26 T27 T28 T29 T30 T36 T37 T38 T39 T40 T41 T42 T48 T49 T50 T51 T52 T53 T54 /*T60 T72*/;
set RV_F2ML_trasposed;T13=T12;T14=T12;T15=T12;T16=T12;T17=T12;T18=T12;T25=T24;T26=T24;T27=T24;T28=T24;T29=T24;T30=T24;T37=T36;T38=T36;T39=T36;T40=T36;T41=T36;T42=T36;T49=T48;T50=T48;T51=T48;T52=T48;T53=T48;T54=T48;
format T13 6.2 T14 6.2 T15 6.2 T16 6.2 T17 6.2 T18 6.2 T25 6.2 T26 6.2 T27 6.2 T28 6.2 T29 6.2 T30 6.2 T37 6.2 T38 6.2 T39 6.2 T40 6.2 T41 6.2 T42 6.2 T49 6.2 T50 6.2 T51 6.2 T52 6.2 T53 6.2 T54 6.2; drop T60 model fuel_type table;run;

proc transpose data=RV_sb_demo_trasposed1
     out=RV_sb_demo_new_trasposed1 (rename=(col1=rv) rename=(km_min=km_min_original km=km_original)); 
   var T12 T13 T14 T15 T16 T17 T18 T24 T25 T26 T27 T28 T29 T30 T36 T37 T38 T39 T40 T41 T42 T48 T49 T50 T51 T52 T53 T54 /*T60 T72*/;
   by codice_infocar km_min km;
   
data RV_sb_demo1;retain codice_infocar km_min km term rv;set RV_sb_demo_new_trasposed1; term=substr(_NAME_,2,2)*1;km_adj=round(6000*12/term,1);
   km=km_original+km_adj;km_min=km_min_original+km_adj;if km_min_original=0 then km_min=0;format rv 6.2;drop _NAME_ km_min_original km_original km_adj;
   where km_original ne 50000; 
   
run;
PROC EXPORT DATA= RV_sb_demo1 OUTFILE= "&path\DSR Outs\&quarter\&verdemo..txt" DBMS=TAB;RUN;




/*RV sb citycar campaign May 2019 pilot - New cars, Corsa/Adam, all versions, all dealers except Autosanlorenzo & general cars who should be closed*/
/*data RV_sb_cam_interpolated;retain codice_infocar table km_min km term rv;set RV_sb_interpolated_new_trasposed; term=substr(_NAME_,2,2)*1;*/
/*   if model in ('ADAM' 'CORSA5SERIE') then rv=rv+5;*/
/*   format rv 6.2;drop _NAME_ model;*/
/*   where km ne 50000 and model in ('ADAM' 'CORSA5SERIE'); */
/*run;*/
/*PROC EXPORT DATA= RV_sb_cam_interpolated OUTFILE= "&path\DSR Outs\&quarter\&citycam..txt" DBMS=TAB;RUN;*/

/*RV_lease*/
data RV_lease;
	retain codice_infocar km_min km term rv_lease;
	set IT.RV_UPDATE_&quarter;
	keep codice_infocar km_min km term rv_lease;
	rename rv_lease=rv;
	if term=72 then term=66;
	where km<50000 and term<=72;
run;
PROC EXPORT DATA= RV_lease OUTFILE= "&path\DSR Outs\&quarter\&verlease..txt" DBMS=TAB;RUN;
	
/*RV_f2ml*/
data RV_f2ml_1;
	retain Anno_Edizione Mese_Edizione codice_infocar km_min km term segment Variant rv_f2ml rv_N1;
	set it.RV_UPDATE_&quarter;
	if rv_f2ml=. then rv_f2ml='';
	if km=30000 then km_min=20001;
	if rv_f2ml>0 then do;
		if index(Variant,'N1')>0 then rv_N1=rv_f2ml;
			else if segment = 'LCV' then rv_N1='';
			else rv_N1=rv_f2ml-5;
	end;
	else rv_N1=0;
	format rv_N1 6.2;
	keep Anno_Edizione Mese_Edizione codice_infocar km_min km term segment Variant rv_f2ml rv_N1;
	rename rv_f2ml=rv;
	where 12<=term<=60 and km<>25000 and segment notin ('' ' ');

data RV_f2ml;
	set RV_f2ml_1;
	keep codice_infocar km_min km term rv;
	where rv>0;

/*written by Simon */
data RV_flexandfree;
	set RV_f2ml_1;
	keep codice_infocar km_min km term rv;
	where rv>0 and 
		((codice_infocar=135942) or 
		(codice_infocar<135429 and codice_infocar>135075) or 
		(codice_infocar<134784 and codice_infocar>134772) or
		(codice_infocar=134145) or
		(codice_infocar<132401 and codice_infocar>131559) or
		(codice_infocar<129050 and codice_infocar>129043) or
		(codice_infocar<126403 and codice_infocar>126312) or
		(codice_infocar<124787 and codice_infocar>123404) or
		(codice_infocar<122697 and codice_infocar>122694) or
		(codice_infocar<122697 and codice_infocar>122694) or
		(codice_infocar<121287 and codice_infocar>120610) or
		(codice_infocar<137244 and codice_infocar>137239));
	rv=rv*0.85;
	
data RV_f2ml_N1;
	set RV_f2ml_1;
	keep codice_infocar km_min km term rv_N1;
	rename rv_N1=rv;
	where rv_N1>0;

data RV_f2ml_emp;
	retain codice_infocar km_min km term RV_F2ML_EMP;
	set it.RV_UPDATE_&quarter;
	if RV_F2ML_EMP=. then RV_F2ML_EMP='';
	keep codice_infocar km_min km term RV_F2ML_EMP;
	rename RV_F2ML_EMP=rv;
	where RV_F2ML_EMP>0;
	
	data RV_f2ml_output;
		retain codice_infocar model Variant fuel_type segment version gear transmission km_min km term rv_f2ml RV_F2ML_EMP code code1;
		if km=30000 then km_min=20001;		
		drop rv_sb rv_lease;
		set it.RV_UPDATE_&quarter;
		where (12<=term<=60 and km<>25000) or RV_F2ML_EMP>0;
		
data Excess_Km_f2ml;
	set RV_f2ml_1;
	excess_km_cost=0.1;
	format Mese_Edizione_1 $2.;
	if Anno_Edizione=. then Anno_Edizione=&Anno_Edizione;
	if 0<Mese_Edizione<10 then Mese_Edizione_1=CAT("0",Mese_Edizione);
	if Mese_Edizione>=10 then Mese_Edizione_1=Mese_Edizione;
	if Mese_Edizione=. then Mese_Edizione_1=&Mese_Edizione; 
	Infocar_Code=compress(CAT(Anno_Edizione,Mese_Edizione_1,codice_infocar));
	if segment notin ('LCV' '') then segment = 'Car';
	drop Anno_Edizione Mese_Edizione Mese_Edizione_1 codice_infocar km_min rv rv_N1;	
run;
data Excess_Km_f2ml; retain Infocar_Code term km excess_km_cost segment; set Excess_Km_f2ml; run;

PROC EXPORT DATA= RV_f2ml OUTFILE= "&path\DSR Outs\&quarter\&verf2ml..txt" DBMS=TAB;RUN;
PROC EXPORT DATA= RV_f2ml_N1 OUTFILE= "&path\DSR Outs\&quarter\&verf2mlN1..txt" DBMS=TAB;RUN;
/*PROC EXPORT DATA= RV_f2ml_output OUTFILE= "&path\&quarter\F2ML\RV_output_f2ml_&quarter..xlsx" DBMS=EXCEL REPLACE;SHEET="RV";RUN;*/
PROC EXPORT DATA= Excess_Km_f2ml OUTFILE= "&path\DSR Outs\&quarter\&excesskm..xlsx" DBMS=EXCEL REPLACE; SHEET="excess"; RUN;
PROC EXPORT DATA= RV_flexandfree OUTFILE= "&path\DSR Outs\&quarter\&verflex..txt" DBMS=TAB;RUN;

/*in case of no update for F2ML employees, no need to run below code*/
PROC EXPORT DATA= RV_f2ml_emp OUTFILE= "&path\DSR Outs\&quarter\&verf2mlemp..txt" DBMS=TAB;RUN;

/*data car; set Excess_Km_f2ml;where segment='Car';run; */
/*PROC EXPORT DATA= Excess_Km_f2ml OUTFILE= "&path\DSR Outs\&quarter\&excesskmcar..txt" DBMS=TAB;RUN;*/
/*data lcv; set Excess_Km_f2ml;where segment='LCV';run;*/
/*PROC EXPORT DATA= Excess_Km_f2ml OUTFILE= "&path\DSR Outs\&quarter\&excesskmlcv..txt" DBMS=TAB;RUN;*/

/*RV_sb RIOLO pilot*/

/*data RV_sb_riolo;set RV_sb_interpolated;if rv>0 then rv=rv+5;where km<=40000;run;*/
/*data RV_sb_demo_riolo;set RV_sb_demo;if rv>0 then rv=rv+5;run;*/
/*PROC EXPORT DATA= RV_sb_riolo OUTFILE= "&path\DSR Outs\&quarter\&riolo..txt" DBMS=TAB;RUN;*/
/*PROC EXPORT DATA= RV_sb_demo_riolo OUTFILE= "&path\DSR Outs\&quarter\&riolodemo..txt" DBMS=TAB;RUN;*/

/***************************************************************************END****************************************************************************/




