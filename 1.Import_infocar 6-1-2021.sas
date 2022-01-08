
/******************* APPLICATIONS TRACKING PROCEDURE ***********************

ORIGINATOR= RISK
DATE= 24/06/2016
LAST UPDATE= 26/03/2019 BY SG (Movano can be only LCV as provided by F2ML)
FREQUENCY= QUARTERLY
SOURCE= RV_DATA (RV_infocar_preview)

**************************************************************************/
options compress = yes;
%let quarter=2021_Q2; /*change quarter*/
%let path= \\itrmewpefp001.eu.ds.ov.finance\SHARED\Residual Values;
%let path_v=&path\&quarter\InfocarData\Veicoli;
%let path_macro=&path\&quarter\InfocarData\Veicoli;
libname it "&path\&quarter";

%let rrkm=10 15 20 25 30 40 50;
 %let list_term= term6 term9 term12 term24 term36 term48 term60 term72; 
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
            DATAFILE= "&path_macro\Veicoli_&elem.kkm.xlsx" 
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
if index(Origine_previsione,"&elem.") then km=&elem*1000;
run;

%do l=2 %to &longueur;

%let elem= %SCAN(&list, &l);
     
  PROC IMPORT OUT= infocar&elem.
            DATAFILE= "&path_macro\Veicoli_&elem.kkm.xlsx" 
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
	  km=&elem*1000;
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
term72=Previsione_____a_60_mesi0/2;
term9=.;
Previsione_____a_9_mesi=.;
Previsione_____a_72_mesi=Previsione_____a_60_mesi/2;
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


data base_out_1;
set base_out;
	format rv_sb 6.2 rv_lease 6.2 term_num 2.0;
	rv_sb=rv_infocar * 100;
	term_num = term*1;

	if km=50000 then do;
		rv_sb=0;
		rv_lease=0;
	end;
	if km notin (50000) then do;
		if term in ('6' '12') then rv_lease=25;
		else if term="24" then rv_lease=20;
		else if term="36" then rv_lease=15;
		else if term="48" then rv_lease=10;
		else if term="60" then rv_lease=5;
		else if term="72" then rv_lease=2;
	end;
	km_min=0;
	IF km=15000 THEN km_min=10001;
	    else IF km=20000 THEN km_min=15001;
	    ELSE IF km=25000 THEN km_min=20001;
		ELSE IF km=30000 THEN km_min=25001;
		ELSE IF km=40000 THEN km_min=30001;
		ELSE IF km=50000 THEN km_min=40001;
	drop term;
run;

/*sortie pour les tests DSR*/
proc contents data=base_out_1;
run;
proc freq data=base_out_1;
tables modello * Alimentazione;
run;

proc sort data=base_out_1;
by modello;
run;

data base_out_1;
set base_out_1;
format fuel_type $10.;
if Alimentazione in ("Benzina") then fuel_type="Petrol";
if Alimentazione in ("GPL") then fuel_type="LPG";
if Alimentazione in ("Metano") then fuel_type = "Gas";
if Alimentazione in ("Gasolio") then fuel_type="Diesel";
if Alimentazione in ("Elettrica") then fuel_type="Electric";
if Marca in ('OPEL') and index(upcase(Allestimento),"HYBRID")>0 then fuel_type="Hybrid"; /*Hybrid is always written as benzina or diesel depending on the engine. For Opel it should always be identifiable with hybrid in description*/
if index(upcase(Allestimento),"MOKKA X")>0 then modello="Mokka X";
run;

/* Adding RV for F2ML */
data base_out_2;
	set base_out_1;
	
	rename term_num = term;
	
	format segment $10. version $20. model $20.;
	if index(Allestimento,'aut.')>0 or index(upcase(Allestimento),'CVT')>0 or index(upcase(Allestimento),'AT9')>0 then gear='A';else gear='M';
	if index(UPCASE(modello), 'CORSA-E')>0 then gear='A';
	
	if index(Allestimento,'AWD')>0 or index(Allestimento,'4WD')>0 then transmission='4WD';else transmission='2WD';
	if index(Allestimento,'Country Tourer')>0 then Carrozzeria='Station Wagon CT';
	rv_infocar_amt=rv_infocar*Listino;
	
	modello=tranwrd(modello,"ª","");
	model=UPCASE(compress(tranwrd(modello,"*","")));
	
	/*if index(UPCASE(model),'MOVANO4SERIE')>0 and Codice_Infocar >= 132759 then model="MOVANO4BSERIE"; /*new Movano 4 to be differentiated from preiouvs versions*/ 
	if index(UPCASE(model),'ASTRA5SERIE')>0 and Codice_Infocar >= 133216 then model="ASTRA5BSERIE"; /*new Astra 5 to be differentiated from preiouvs versions*/
	if index(UPCASE(model),'VIVARO-E')>0 and index(Allestimento,'50kWh') >0 then model="VIVARO50KW-E";
	if index(UPCASE(model),'VIVARO-E')>0 and index(Allestimento,'75kWh') >0 then model="VIVARO75KW-E"; 
	
/*By Simon START */
	if index(UPCASE(model),'ZAFIRA-ELIFE')>0 and index(Allestimento,'50kWh') >0 then model="ZAFIRALIFE55KW-E"; /*it should be 50KWh but worked it out wrongly in F"ML excel*/
	if index(UPCASE(model),'ZAFIRA-ELIFE')>0 and index(Allestimento,'75kWh') >0 then model="ZAFIRALIFE75KW-E"; 
	
	if index(UPCASE(model),'MOKKA2SERIE')>0 then model="NEWMOKKA";
	if index(UPCASE(model),'MOKKA-E')>0 then model="NEWMOKKA-E"; 
	
	/*By Simon END */
	
	if index(UPCASE(modello),'KARL')>0 then segment='A';
	if index(UPCASE(modello),'ADAM')>0 then segment='A';
	if index(UPCASE(modello),'CORSA')>0 then segment='B';
	if index(UPCASE(modello),'ASTRA')>0 then do;
		if Carrozzeria ='Berlina' then segment='C_BERLINA';
		if Carrozzeria ='Station Wagon' then segment='C_SW';
		end;	
	if index(UPCASE(modello),'INSIGNIA')>0 then do;
		if Carrozzeria ='Berlina' then segment='D_BERLINA';
		if Carrozzeria ='Station Wagon' then segment='D_SW';
		if Carrozzeria ='Station Wagon CT' then segment='D_SW_CT';
		end;	
	if index(UPCASE(modello),'MOKKA')>0 then segment='B_SUV';
	if index(UPCASE(modello),'CROSSLAND')>0 then segment='B_SUV';
	if index(UPCASE(modello),'GRANDLAND')>0 then segment='C_SUV';
	if index(UPCASE(modello),'ZAFIRA')>0 then segment='MPV';
	if index(UPCASE(modello),'COMBO')>0 then do;
		if Carrozzeria notin ('Multispazio') then segment='LCV';
		if Carrozzeria in ('Multispazio') then segment='MPV';
		end;
	if index(UPCASE(modello),'VIVARO')>0 then do; /*all life is under carrozzeria Combi/Multispazi therefore MPV*/
/*		if Carrozzeria notin ('Combi') then segment='LCV';*/
/*		if Carrozzeria in ('Combi') then segment='MPV';*/
		if index(UPCASE(model),'VIVAROLIFE')>0 then segment='MPV'; else segment='LCV'; /*all vivaro not life are LCV*/
		end;	
	if index(UPCASE(modello),'MOVANO')>0 then segment='LCV';
/*	if index(UPCASE(modello),'MOVANO')>0 then do;*/
/*		if Carrozzeria notin ('Combi') then segment='LCV';*/
/*		if Carrozzeria in ('Combi') then segment='MPV';*/
/*		end;*/
	
	/***overwrite on top to make all "N1" LCV. Currently only in Vivaro (already LCV) and Combolife.***/
	if index(Allestimento,'N1')>0 then segment='LCV';
		
	
	if segment notin ('LCV' '' ' ') then do;
/*		if index(Allestimento,'OPC Line')>0 or index(Allestimento,'GSi')>0 or index(Allestimento,'Ultimate')>0 or index(Allestimento,'Country Tourer Exclusive')>0 or */
/*		index(Allestimento,'Country T. Exclusive')>0 or index(Allestimento,'Exclusive')>0 or substr(Allestimento,length(Allestimento)-1,2)=' S' then version = 'upper_version';*/
/*		else if index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 or index(Allestimento,'Glam')>0 or index(Allestimento,'Slam')>0 or */
/*		index(Allestimento,'Dynamic')>0 or index(Allestimento,'Design Line')>0 or index(Allestimento,'Black Edition')>0 or index(Allestimento,'Business')>0 or */
/*		index(Allestimento,'Vision')>0 or index(Allestimento,'b-color')>0 or index(Allestimento,'b-Color')>0 or index(Allestimento,'Country Tourer')>0 or */
/*		index(Allestimento,'Cosmo')>0 or index(Allestimento,'Anniversary')>0 or index(Allestimento,'Anniversay')>0 then version = 'medium_version';*/
/*		else version = 'lower_version';	*/
		if UPCASE(model) in ('CORSA5SERIE') then do;
			if index(Allestimento,'GSi')>0 then version = 'upper_version';
			else if index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 or index(Allestimento,'Black Edition')>0 or index(Allestimento,'Anniversary')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('CORSA6SERIE') then do;
			if index(Allestimento,'Edition')>0 then version = 'medium_version';
			else if index(Allestimento,'GS Line')>0 or index(Allestimento,'Elegance')>0 then version = 'upper_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('CORSA-E') then do;
			if index(Allestimento,'Selection')>0 then version = 'lower_version';
			else if index(Allestimento,'First Edition')>0 or index(Allestimento,'Elegance')>0 or index(Allestimento,'GS Line')>0 then version = 'upper_version'; 
			else if index(Allestimento,'Edition')>0 then version = 'medium_version';
		end;
		else if UPCASE(model) in ('CROSSLAND','CROSSLANDX') then do;
			if index(Allestimento,'Ultimate')>0 then version = 'upper_version';
			else if index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 or 
			index(Allestimento,'Anniversary')>0 or index(Allestimento,'Elegance')>0 or 
			index(Allestimento,'GS Line')>0 then version = 'medium_version';
			else version = 'lower_version';
		end; 
		else if UPCASE(model) in ('GRANDLANDX') then do;
			if index(Allestimento,'Ultimate')>0 then version = 'upper_version';
			else if index(Allestimento,'Business')>0 or index(Allestimento,'Elegance')>0 or index(Allestimento,'Design Line')>0 or index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 or index(Allestimento,'Anniversary')>0 then version = 'medium_version';
			else version = 'lower_version';
			if fuel_type="Hybrid" then version = 'medium_version'; /*to be confirmed by Marco Speranza on the version of Grandland hybrid*/
		end; 
		else if UPCASE(model) in ('MOKKAX') then do;
			if index(Allestimento,'Ultimate')>0 then version = 'upper_version';
			else if index(Allestimento,'Business')>0 or index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('ASTRA5BSERIE') then do;
			if index(Allestimento,'Ultimate')>0 then version = 'upper_version';
			else if index(Allestimento,'Business Elegance')>0 or index(Allestimento,'Business Eleg.')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('ASTRA5SERIE') then do;
			if index(Allestimento,'OPC Line')>0 then version = 'upper_version';
			else if index(Allestimento,'Business')>0 or index(Allestimento,'Dynamic')>0 or index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('INSIGNIA2SERIE') then do;
			if index(Allestimento,'GSi')>0 or index(Allestimento,'Country Tourer')>0 or index(Allestimento,'Ultimate')>0 then version = 'upper_version';
			else if index(Allestimento,'Business Ele')>0 or index(Allestimento,'Bus. Ele')>0 or index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('COMBOLIFE') then do;
			if index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 or index(Allestimento,'Elegance Plus')>0 then version = 'upper_version';
			else if index(Allestimento,'Advance')>0 or index(Allestimento,'Elegance')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if index(UPCASE(model),'ZAFIRALIFE')>0 then do; /*Zafira 3 serie not offered anymore on F2ML*/
			if index(Allestimento,'Business Edition')>0 then version = 'lower_version';
			else if index(Allestimento,'Advance')>0 or index(Allestimento,'Edition')>0 or index(Allestimento,'Business Ele')>0 or index(Allestimento,'Bus. Ele')>0 then version = 'medium_version';
			else if index(Allestimento,'Elegance')>0 or index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 then version = 'upper_version'; 
			else version = 'lower_version';
		end;
		else if index(UPCASE(model),'VIVARO')>0 then do;
			if index(Allestimento,'Enjoy')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if index(UPCASE(model),'NEWMOKKA')>0 then do; 
			if index(Allestimento,'Edition')>0 then version = 'lower_version';
			else if index(Allestimento,'GS Line +')>0 or index(Allestimento,'Ultimate')>0 then version = 'upper_version';
			else if index(Allestimento,'Elegance')>0 or index(Allestimento,'GS Line')>0 then version = 'medium_version'; 
		end;
		else do; /*on models not quotabile anymore on F2ML, continue to use the old definition for PCP purpose*/
			if index(Allestimento,'OPC Line')>0 or index(Allestimento,'GSi')>0 or index(Allestimento,'Ultimate')>0 or index(Allestimento,'Country Tourer Exclusive')>0 or 
			index(Allestimento,'Country T. Exclusive')>0 or index(Allestimento,'Exclusive')>0 or substr(Allestimento,length(Allestimento)-1,2)=' S' then version = 'upper_version';
			else if index(Allestimento,'Innovation')>0 or index(Allestimento,'Innov.')>0 or index(Allestimento,'Glam')>0 or index(Allestimento,'Slam')>0 or 
			index(Allestimento,'Dynamic')>0 or index(Allestimento,'Design Line')>0 or index(Allestimento,'Black Edition')>0 or index(Allestimento,'Business')>0 or 
			index(Allestimento,'Vision')>0 or index(Allestimento,'b-color')>0 or index(Allestimento,'b-Color')>0 or index(Allestimento,'Country Tourer')>0 or 
			index(Allestimento,'Cosmo')>0 or index(Allestimento,'Anniversary')>0 or index(Allestimento,'Anniversay')>0 or index(Allestimento,'Anniv.')>0 then version = 'medium_version';
			else version = 'lower_version';		
		end;
		
	end;

	if segment = 'LCV' then do;
		if UPCASE(model) in ('COMBO5SERIE') then do;
			if index(Allestimento,'Edition')>0 then version = 'medium_version';
			else/* if index(Allestimento,'Essentia')>0 then*/ version = 'lower_version';
		end;
		else if UPCASE(model) in ('COMBOLIFE') then do;
			if index(Allestimento,'Advance')>0 or index(Allestimento,'Elegance')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;
		else if UPCASE(model) in ('VIVARO4SERIE') then do;
			if index(Allestimento,'Enjoy')>0 then version = 'medium_version';
			else/* if index(Allestimento,'Essentia')>0 then*/ version = 'lower_version';
		end;
		else if UPCASE(model) in ('VIVARO75KW-E', 'VIVARO50KW-E') then do;
			if index(Allestimento,'Enjoy')>0 then version = 'medium_version';
			else/* if index(Allestimento,'Essentia')>0 then*/ version = 'lower_version';
		end;
		else if UPCASE(model) in ('MOVANO4SERIE') or UPCASE(model) in ('MOVANO4BSERIE') then do;
			if index(Allestimento,'Edition')>0 then version = 'medium_version';
			else version = 'lower_version';
		end;	
		else do; /*on models not quotabile anymore on F2ML, continue to use the old definition for PCP purpose*/
			if index(Allestimento,'Edition')>0 or index(Allestimento,'Innovation')>0 then version = 'medium_version';	
			else version = 'lower_version';
		end;
	end;
	
	/*code*/
	CODE=CATX("***",model, segment, fuel_type, version, term_num, km);
	CODE1=CATX("***",model, segment, fuel_type, version, term_num, km, gear, transmission);	 
/*	if (index(modello,'Vivaro') or index(modello,'Movano') or index(modello,'Combo')) then do;*/
/*		CODE=CATX("***",model, segment, version, term_num, km);*/
/*		CODE1=CATX("***",model, segment, version, term_num, km, gear, transmission);*/
run;

	/*In case of changes to F2ML RV for monthly RV update, run line 377 to 388, and then line 412 to 426, and 433 to the end. */
	/*Make sure to delete the file "RV_infocar_&quarter..xlsx" before running the code*/
	PROC IMPORT OUT= RV_BASE_F2ML
            DATAFILE= "&path\&quarter\RV_BASE_F2ML.xlsx" 
            DBMS=Excel REPLACE;sheet="RVBASE$";
            GETNAMES=YES;
      
	    data RV_BASE_F2ML;
	    set RV_BASE_F2ML;
	    format RV 6.4;
	    rename RV=RV_BASE_F2ML;
	    keep code rv;
	    where code ne "";
	RUN;
	
	/*** add F2ML for employees***/
	/*In case of changes to F2ML Employees RV for monthly RV update, run line 393 to 405, and then line 417 to the end. */
	/*Make sure to delete the file "RV_infocar_&quarter..xlsx" before running the code*/
	PROC IMPORT OUT= RV_BASE_F2ML_EMP
            DATAFILE= "&path\&quarter\RV_BASE_F2ML_EMP.xlsx" 
            DBMS=Excel REPLACE;sheet="RVBASE$";
            GETNAMES=YES;
            
	    data RV_BASE_F2ML_EMP;
	    set RV_BASE_F2ML_EMP;
	    format RV 6.4;
	    code2=CATX("***",Infocar_code,code);
	    rename RV=RV_F2ML_EMPLOYEE;
	    keep code2 rv;
	    where code ne "";
	RUN;

	proc sort data=base_out_2
	out=it.RV_BASE; 
	by code;
	run;
	
	proc sort data=RV_BASE_F2ML
	out=it.RV_BASE_F2ML;  
	by code;
	run;
	
	data RV_BASE;
	merge it.RV_BASE (in=a) it.RV_BASE_F2ML (in=b);
	if a;
	by code;
	code2=CATX("***",Codice_Infocar,code);
	run;
	
	proc sort data=RV_BASE;
	by code2;
	run;
	
	proc sort data=RV_BASE_F2ML_EMP
	out=it.RV_BASE_F2ML_EMP;  
	by code2;
	run;
	
	data it.RV_BASE_&quarter (drop=code2);
	merge RV_BASE (in=a) it.RV_BASE_F2ML_EMP (in=b);
	if a;
	by code2;
	run;
	
	data it.RV_BASE_CALMS_&quarter;
		retain
		codice_infocar
		km_min
		km
		term
		rv_f2ml
		RV_F2ML_EMP
		rv_sb
		rv_lease
		code
		code1;
		set it.RV_BASE_&quarter;
		format rv_f2ml 6.2 RV_F2ML_EMP 6.2;
		if rv_base_f2ml=. then rv_base_f2ml=0; 
		rv_f2ml=rv_base_f2ml*100;
		if rv_base_f2ml>0 then do;
			if gear eq 'M' and transmission eq '2WD' then rv_f2ml=rv_base_f2ml*100;
			if gear eq 'A' and transmission eq '2WD' and model notin ('CORSA-E' 'VIVARO50KW-E' 'VIVARO75KW-E' 'NEWMOKKA' 'NEWMOKKA-E' 'ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E') then rv_f2ml=rv_base_f2ml*100+1;
			if gear eq 'M' and transmission eq '4WD' then rv_f2ml=rv_base_f2ml*100+1;
			if gear eq 'A' and transmission eq '4WD' then do;
				if model in ('CORSA-E' 'VIVARO50KW-E' 'VIVARO75KW-E' 'NEWMOKKA-E' 'ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E') then rv_f2ml=rv_base_f2ml*100+1; else rv_f2ml=rv_base_f2ml*100+2;
			end;
		end;
		if RV_F2ML_EMPLOYEE=. then RV_F2ML_EMPLOYEE=0; 
		RV_F2ML_EMP=RV_F2ML_EMPLOYEE*100;
		if term >=60 and km=50000 then flag_over60_50=1; else flag_over60_50=0;
	drop rv_base_f2ml RV_F2ML_EMPLOYEE;
	run;
	
		proc sql;
		create table it.rv_base_average as
		select distinct code1, mean(rv_sb) as rv_sb_mean format 6.2 from it.RV_BASE_CALMS_&quarter
		group by code1;
		quit;

data it.RV_base_short_CALMS_&quarter;
	set it.RV_BASE_CALMS_&quarter;

	format Variant $64.;
	Variant = Allestimento;

	keep Anno_Edizione Mese_Edizione codice_infocar km_min km term rv_f2ml RV_F2ML_EMP rv_sb rv_lease code1 code Variant fuel_type segment version model gear transmission flag_over60_50;
run;

	PROC EXPORT DATA= it.RV_BASE_CALMS_&quarter
	            OUTFILE= "&path\&quarter\RV_infocar_&quarter..xlsx" 
	            DBMS=EXCEL REPLACE;
	     SHEET="RV"; 
	RUN;






/***************************************************************   END   ***********************************************************************/


