
/************************************LIBNAME***********************************/

options compress = yes ;
%let infocar=GMF-IT-PP-VDB-202201;  /*change the month and year*/
LIBNAME it "&path\&quarter";
%LET quarter=2022_Q1; /*change quarter of current RV update*/
%let path=\\itrmewpefp001.eu.ds.ov.finance\SHARED\Residual Values;
%LET verf2ml=f2mQ4_21v5;     	/*Free2Move and PCP new, no interpolation, max 60m*/
%LET verdemo=DEMQ4_21v5;      	/*demo. Need special interpolation*/
%LET verf2mlN1=fN1Q4_21v5;

/**********************************IMPORT EXCEL*******************************/

PROC IMPORT OUT= VehicleDataBase
DATAFILE= "&path\&quarter\&infocar..xlsx" 
DBMS=Excel REPLACE; RANGE="&infocar$"; GETNAMES=YES; delimiter=','; MIXED=NO; SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;
RUN;

/********************************DATA CLEANING*********************************/

Data VehicleDataBase1;
SET VehicleDataBase;
where manufacturerName="OPEL";
drop vehicleType manufacturerName OBSOLETE_FLAG;
run;

/************************************FUEL***************************************/

Data VehicleDataBase2;
SET VehicleDataBase1;
format fuel_type $10.;
IF Fuel in ("P") THEN fuel_type="Petrol";
IF Fuel in ("G") THEN fuel_type="Petrol";
IF Fuel in ("B") THEN fuel_type="Petrol";
IF Fuel in ("D") THEN fuel_type="Diesel";
IF Fuel in ("E") THEN fuel_type="Electric";
IF Fuel in ("H", "Y") THEN fuel_type="Electric"; 
	
/************************************MODEL****************************************/

/*	X=substr(Variant,1,1);*/
modelName = UPCASE(modelName);
if modelName EQ "MOKKA 1 SERIE" then modelName="MOKKAX";
/*if index(modelName,"MOVANO 4")>0 and (infocarRef >= 132759 or 102017 <= infocarRef <= 102040) then modelName="MOVANO 4B SERIE"; /*INCLUDED NEW MOVANO*/
if index(modelName,"ASTRA 5")>0 and infocarRef >= 133216 then modelName="ASTRA 5B SERIE"; /*new Astra  to be differentiated from preiouvs versions*/	
if index(modelName,'VIVARO-E')>0 and index(Variant,'50kWh') >0 then modelName="VIVARO50KW-E";
if index(modelName,'VIVARO-E')>0 and index(Variant,'75kWh') >0 then modelName="VIVARO75KW-E"; 	
if index(modelName,'ZAFIRA-E LIFE')>0 and index(Variant,'50kWh') >0 then modelName="ZAFIRALIFE50KW-E";
if index(modelName,'ZAFIRA-E LIFE')>0 and index(Variant,'75kWh') >0 then modelName="ZAFIRALIFE75KW-E";
if index(modelName,'MOKKA 2 SERIE')>0 then modelName="NEWMOKKA";
if index(modelName,'MOKKA-E')>0 then modelName="NEWMOKKA-E"; 
if index(modelName,'CROSSLAND')>0 and index(Variant,'X')=1 then modelName="CROSSLANDX";
if index(modelName,'GRANDLAND')>0 and infocarRef > 142017 and infocarRef < 142036 then modelName="NEWGRANDLAND";
if index(modelName,'ASTRA 6 SERIE')>0 then modelName="NEWASTRA";

if index(modelName,'COMBO-E')>0 and index(modelName,'COMBO-E LIFE')=0 and index(Variant,'50kWh') >0 then modelName="COMBOCARGO50KW-E";
if index(modelName,'COMBO-E')>0 and index(modelName,'COMBO-E LIFE')=0 and index(Variant,'75kWh') >0 then modelName="COMBOCARGO75KW-E";
if index(modelName,'COMBO-E LIFE')>0 then modelName="COMBO-ELIFE";


/************************************GEAR****************************************/

format segment $10. version $20. model $20.;
if index(Variant,'aut.')>0 or index(upcase(Variant),'CVT')>0 or index(upcase(Variant),'AT9')>0 then gear='A';else gear='M';
if modelName in ('COMBOCARGO50KW-E' 'COMBOCARGO75KW-E' 'COMBO-E LIFE' 'CORSA-E' 'VIVARO50KW-E' 'VIVARO75KW-E' 'ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E' 'NEWMOKKA-E') then gear='A';
if index(Variant,'AWD')>0 or index(Variant,'4WD')>0 then transmission='4WD';else transmission='2WD';
model=compress(modelName);

/************************************SEGMENT**************************************/

if index(modelName,'KARL')>0 then segment='A';
if index(modelName,'ADAM')>0 then segment='A';
if index(modelName,'CORSA')>0 then segment='B';
if index(modelName,'ASTRA')>0 then do;
	if index(Variant, 'Tourer')>0 then segment='C_SW';
	else segment='C_BERLINA';
	end;	
if index(modelName,'INSIGNIA')>0 then do;
	/*if model in ('INSIGNIA2SERI') then model = 'INSIGNIA2SERIE';*/
	if index(Variant, 'Country')>0 then segment='D_SW_CT';	
	else if index(Variant, 'Tourer')>0 then segment='D_SW';
	else segment='D_BERLINA';
	end; 
if index(modelName,'MOKKA')>0 then segment='B_SUV';
if index(modelName,'CROSSLAND')>0 then segment='B_SUV'; /*for crossland X and crossland*/ 
if index(modelName,'GRANDLAND')>0 then segment='C_SUV';
if index(modelName,'ZAFIRA')>0 then segment='MPV';

/* also applicable for combo-e*/
if index(modelName,'COMBO')>0 then do;
	if index(Variant,'N1')>0 then segment='LCV';
	else if index(modelName,'LIFE')>0/*  or index(UPCASE(modelName),'TOUR')>0*/ then segment='MPV'; 
	else segment='LCV';
	end;
if index(modelName,'VIVARO')>0 then do;
	if/* (index(Variant,'Tourer')>0 or index(Variant,'Combi')>0) or */index(modelName,'LIFE')>0 then segment='MPV'; 
	else segment='LCV';
	end;
if index(modelName,'MOVANO')>0 then segment='LCV';
/* if index(modelName,'COMBO-E')>0 then segment='LCV';*/
/*	if index(UPCASE(modelName),'MOVANO')>0 then do;*/
/*		if index(Variant,'Combi')>0 then segment='MPV'; */
/*		else segment='LCV';*/
/*		end;*/
if index(modelName,'NEWASTRA')>0 then segment='BERLINA';
	
/***overwrite on top to make all "N1" LCV***/
if index(Variant,'N1')>0 then segment='LCV';

/************************************VERSION****************************************/

/***********************************1. NON LCV**************************************/

if segment notin ('LCV' '' ' ') then do;
	if model in ('CORSA5SERIE') then do;
		if index(Variant,'GSi')>0 then version = 'upper_version';
		else if index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or index(Variant,'Black Edition')>0 or index(Variant,'Anniversary')>0 then version = 'medium_version';
		else version = 'lower_version';
	end;
	else if model in ('CORSA6SERIE') then do;
		if index(Variant,'Edition')>0 then version = 'medium_version';
		else if index(Variant,'GS Line')>0 or index(Variant,'Elegance')>0 then version = 'upper_version';
		else version = 'lower_version';
	end;
	else if model in ('CORSA-E') then do;
		if index(Variant,'Selection')>0 then version = 'lower_version';
		else if index(Variant,'First Edition')>0 or index(Variant,'Elegance')>0 or index(Variant,'GS Line')>0 then version = 'upper_version'; 
		else version = 'medium_version';
	end;
	else if model in ('CROSSLAND','CROSSLANDX') then do;
		if index(Variant,'Ultimate')>0 then version = 'upper_version';
		else if index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or 
		index(Variant,'Anniversary')>0 or index(Variant,'Elegance')>0 or 
		index(Variant,'GS Line')>0 then version = 'medium_version';
		else version = 'lower_version';
	end; 
	else if model in ('GRANDLANDX') then do;
		if index(Variant,'Ultimate')>0 then version = 'upper_version';
		else if index(Variant,'Business')>0 or index(Variant,'GS Line')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or index(Variant,'Anniversary')>0 or index(Variant,'Elegance')>0 or index(Variant,'Design Line')>0 then version = 'medium_version';
		else version = 'lower_version';
		if fuel_type="Electric" then version = 'medium_version'; 
	end; 
	else if model in ('MOKKAX') then do;
		if index(Variant,'Ultimate')>0 then version = 'upper_version';
		else if index(Variant,'Business')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 then version = 'medium_version';
		else version = 'lower_version';
	end;
	else if model in ('ASTRA5BSERIE') then do;
		if index(Variant,'Ultimate')>0 then version = 'upper_version';
		else if index(Variant,'Business Elegance')>0 or index(Variant,'Business Eleg.')>0 or index(Variant,'GS Line')>0 then version = 'medium_version';
		else version = 'lower_version';
	end;
	else if model in ('ASTRA5SERIE') then do;
		if index(Variant,'OPC Line')>0 then version = 'upper_version';
		else if index(Variant,'Business')>0 or index(Variant,'Dynamic')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or index(Variant,'GS Line')>0 then version = 'medium_version';
		else version = 'lower_version';
	end;
	else if model in ('INSIGNIA2SERIE') then do;
		if index(Variant,'Line')>0 or index(Variant,'GSi')>0 or index(Variant,'Country Tourer')>0 or index(Variant,'Ultimate')>0 then version = 'upper_version';
		else if index(Variant,'Business')>0 or index(Variant,'Bus. Ele')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 then version = 'medium_version';
		else version = 'lower_version';
	end;
	else if model in ('COMBOLIFE') then do;
		if index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 or index(Variant,'Elegance Plus')>0 then version = 'upper_version';
		else if index(Variant,'Advance')>0 or index(Variant,'Elegance')>0 then version = 'medium_version';
		else version = 'lower_version';
	end;
	else if model in ('ZAFIRALIFE') then do; /*Zafira 3 serie not offered anymore on F2ML*/
		if index(Variant,'Business Edition')>0 then version = 'lower_version';
		else if index(Variant,'Advance')>0 or index(Variant,'Edition')>0 or index(Variant,'Business Ele')>0 or index(Variant,'Bus. Ele')>0 then version = 'medium_version';
		else if index(Variant,'Elegance')>0 or index(Variant,'Innovation')>0 or index(Variant,'Innov.')>0 then version = 'upper_version';
		else version = 'lower_version';
	end;
	else if index(model,'VIVARO')>0 then do;
		if index(Variant,'Enjoy')>0 then version = 'medium_version';
		else version = 'lower_version';
	end;
	else if index(model,'NEWMOKKA')>0 then do; 
		if index(Variant,'Edition')>0 then version = 'medium_version';
		else if index(Variant,'GS Line +')>0 or index(Variant,'GS Line')>0 or index(Variant,'Elegance')>0 or index(Variant,'Ultimate')>0 then version = 'upper_version';
	end;
	else if UPCASE(model) in ('ZAFIRALIFE50KW-E' 'ZAFIRALIFE75KW-E') then do; 
		if index(Variant,'Edition')>0 then version = 'medium_version';
		else if index(Variant,'Elegance')>0 then version = 'upper_version';
		else version = 'lower_version';
	end;
	else if model in ('NEWASTRA') then version = 'upper_version';
	else if model in ('COMBO-E') then version = 'upper_version';
	else if model in ('VIVAROLIFE') then version = 'lower_version';
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

/************************************2. LCV****************************************/
/****All the tables are the same for lower, medium and upper, so not important*****/
	
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
RUN;

/************************************SORTING****************************************/

PROC SORT DATA=VehicleDataBase2
OUT=VehicleDataBase3;
BY infocarRef;
RUN; 

/****************************ADD TERMS AND MILEAGE***********************************/

data VehicleDataBase4;
set	VehicleDataBase3;
Terms=6; output;
Terms=9; output;
Terms=12; output;
Terms=24; output;
Terms=36; output;
Terms=48; output;
Terms=60; output;
Terms=72; output;
run;

data VehicleDataBase5;
set	VehicleDataBase4;
km_min=0;     km=10000; output;
km_min=10001; km=15000; output;
km_min=15001; km=20000; output;
km_min=20001; km=25000; output;
km_min=25001; km=30000; output;
km_min=30001; km=35000; output;
km_min=35001; km=40000; output;
km_min=40001; km=45000; output;
km_min=45001; km=50000; output;
km_min=50001; km=55000; output;
km_min=55001; km=60000; output;
km_min=60001; km=65000; output;
km_min=65001; km=70000; output;
km_min=70001; km=75000; output;
km_min=75001; km=80000; output;
km_min=80001; km=85000; output; /*added on 16 Nov*/
km_min=80001; km=90000; output;
km_min=90001; km=95000; output;
run;

data VehicleDataBase6 (rename=(Fuel_Type=fuel infocarref=codice_infocar));
set	VehicleDataBase5;
drop variant fuel;
where 
	(terms=60 and km<40001) or 
	(terms=48 and km<50001) or
	(terms=36 and km<65001) or
	(terms=9 and km<60001) or
	terms=6 or
	terms=12 or
	terms=24;
CODE=CATX("***", model, segment, fuel_type, version, terms, km); 		
run;

/***********************************IMPORT F2ML RVS*****************************************/

PROC IMPORT OUT= F2MLRVS
DATAFILE= "&path\&quarter\RV_BASE_F2ML.xlsx" 
DBMS=Excel REPLACE; SHEET= RVBASE; GETNAMES=YES; delimiter=','; MIXED=NO; SCANTEXT=YES; USEDATE=YES; SCANTIME=YES;
RUN;

/*********************************ADDING F2ML RVS / MERGING********************************/

PROC SQL;
Create table VehicleDataBase7 as
Select * 
from VehicleDataBase6 as x left join F2MLRVS as y
On VehicleDataBase6.Code = F2MLRVS.Code;
Quit;

/*************************ADJUSTMENTS FOR 4WD AND AUT AND LEV 75KW**************************/

data VehicleDataBase8;
set	VehicleDataBase7;
RV=RV*100;
format RV 6.2;
if index(model,'75KW-E')>0 then RV=RV+2;
if gear = 'A' and model in ('GRANDLANDX' 'NEWGRANDLAND') then RV=RV+1;
if transmission = '4WD' then RV=RV+1;
/*if gear = 'A' and transmission = '2WD' and model notin ('COMBO-E LIFE' 'CORSA-E' 'VIVARO50KW-E' 'VIVARO75KW-E' 'ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E' 'NEWMOKKA_E') then RV=RV+1;
if gear = 'A' and transmission = '4WD' and model in ('COMBO-E LIFE' 'CORSA-E' 'VIVARO50KW-E' 'VIVARO75KW-E' 'ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E' 'NEWMOKKA-E') then RV=RV+1;
if gear = 'A' and transmission = '4WD' and model notin ('COMBO-E LIFE' 'CORSA-E' 'VIVARO50KW-E' 'VIVARO75KW-E' 'ZAFIRALIFE55KW-E' 'ZAFIRALIFE75KW-E' 'NEWMOKKA-E') then RV=RV+2;
if gear = 'M' and transmission = '4WD' then RV=RV+1; */
run;

/*******************************************************************************************/
/*****************************************CONTROLS******************************************/
/*******************************************************************************************/

/*****************************************ControlA******************************************/
/*Missing RV for infocar codes in vehicle database*/

PROC SQL;
Create table ControlA as
Select * 
from VehicleDataBase6 as x left join F2MLRVS as y
On VehicleDataBase6.Code = F2MLRVS.Code
where rv = . ;
Quit;

data ControlAv2;
retain Codice_Infocar Model Fuel Segment Version;
keep Codice_Infocar Model Fuel Segment Version;
set	ControlA ;
Run;
proc sort data=ControlAv2
out=ControlAv3 noduprecs;
by Codice_infocar ; 
Run;

/*****************************************ControlB******************************************/
/*missing Infocar codes for Marco's F2ML RVs*/

PROC SQL;
Create table ControlB as
Select *
from F2MLRVS as x left join VehicleDataBase6 as y
On F2MLRVS.Code = VehicleDataBase6.Code
where codice_infocar = . ;
Quit;

data ControlBv2;
set	ControlB (keep= Model Segment Fuel Version);
Run;
proc sort data=ControlBv2
out=ControlBv3 noduprecs;
by Model Segment Fuel Version;
run;

/*******************************************************************************************/
/*****************************************EXPORT********************************************/
/*******************************************************************************************/

/************************************1. EXPORT F2ML RVS*************************************/

data VehicleDataBase9;
manufacturer="";
retain manufacturer model codice_infocar fuel km_min km terms rv;
set	VehicleDataBase8;
model=null;
fuel='*';
drop modelName segment version gear transmission code null term;
where rv ne. ;
run;

PROC SORT DATA= VehicleDataBase9
OUT= VehicleDataBase10
NODUPRECS;
BY codice_infocar km_min terms;
RUN ;

PROC EXPORT DATA= VehicleDataBase10 (rename=(terms=term)) OUTFILE= "&path\DSR Outs\&quarter\f2mQ4_21v5" DBMS=TAB;
RUN;

/***********************************2. EXPORT DEMO RVS**************************************/

data VehicleDataBase11 (rename=(km_min=km_min_original km=km_original));
set	VehicleDataBase10;
run;

data VehicleDataBase12;
retain manufacturer model codice_infocar fuel km_min km terms rv;
set	VehicleDataBase11;
where terms not in (6,9) and km_original<45000;
do i = 0 to 6;
	km_adj=round(72000/terms,1); 
	if km_min_original=0 then km_min=km_min_original; 
	else km_min=km_min_original+km_adj; km=km_original+km_adj;
	output;
	terms = terms + 1;
end;
drop km_original km_min_original i km_adj term;	
run;

PROC EXPORT DATA= VehicleDataBase12 (rename=(terms=term)) OUTFILE= "&path\DSR Outs\&quarter\&verdemo" DBMS=TAB;
RUN;

/*************************************3. EXPORT N1 RVS**************************************/

data VehicleDataBase13;
manufacturer=.;
retain manufacturer model codice_infocar fuel km_min km terms rv;
set	VehicleDataBase8;
format rv_N1 6.2;
if index(Variant,'N1')>0 then rv_N1=rv;
	else if segment = 'LCV' then rv_N1='';
	else rv_N1=rv-5;
where terms not in (6,9) and rv ne.;
fuel='*';
model=null;
drop modelName segment version gear transmission code variant rv term null;
run;

data VehicleDataBase14;
set	VehicleDataBase13;
where rv_N1>0;
rename rv_N1=rv;
run;

PROC SORT DATA= VehicleDataBase14
OUT= VehicleDataBase15
NODUPRECS;
BY codice_infocar km_min terms;
RUN ;

PROC EXPORT DATA= VehicleDataBase15 (rename=(terms=term)) OUTFILE= "&path\DSR Outs\&quarter\&verf2mlN1" DBMS=TAB;
RUN;

/*******************************************************************************/
			