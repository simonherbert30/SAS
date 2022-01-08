
%let path=\\itrmewpefp001.eu.ds.ov.finance\SHARED\Residual Values\2022_Q1\LEV OPEL BB;
%let file=LEVQ1_22v2;
options compress = yes;

/*Import excel*/
PROC IMPORT OUT=WORK.Outfile1
		DATAFILE="&path\Mokka"
		DBMS=EXCEL Replace;
		sheet="Feuil1";
Run;

/*Keep only relevant columns*/
data Outfile2;
set Outfile1;
keep Modello Codice_Infocar Origine_previsione 
Previsione_____a_6_mesi0 
Previsione_____a_12_mesi0 
Previsione_____a_24_mesi0 
Previsione_____a_36_mesi0 
Previsione_____a_48_mesi0 
Previsione_____a_60_mesi0;
run;

/*Sorting*/
proc sort data=Outfile2 out=Outfile3;
	by Modello Codice_Infocar Origine_previsione;
run;

/*Transpose*/
proc transpose data=Outfile3 out=Outfile4;
	by Modello Codice_Infocar Origine_previsione;
	var Previsione_____a_6_mesi0 
	Previsione_____a_12_mesi0 
	Previsione_____a_24_mesi0 
	Previsione_____a_36_mesi0 
	Previsione_____a_48_mesi0 
	Previsione_____a_60_mesi0;
run;

/*Prepare table more*/
data Outfile5;
set Outfile4;
Drop _NAME_ COL2;
Origine_previsione=substr(Origine_previsione,1,5);
If substr(_LABEL_,18,2)="6 " then _LABEL_="6";
If substr(_LABEL_,18,2)="12" then _LABEL_="12";
If substr(_LABEL_,18,2)="24" then _LABEL_="24";
If substr(_LABEL_,18,2)="36" then _LABEL_="36";
If substr(_LABEL_,18,2)="48" then _LABEL_="48";
If substr(_LABEL_,18,2)="60" then _LABEL_="60";
rename _LABEL_=Term;
rename COL1=RV;
run;

data Outfile6;
set Outfile5;
where term in (24,36,48);
run;

data Outfile7;
set Outfile6;
where Origine_previsione in (10000,15000,20000);
rename Origine_previsione=km;
run;

data Outfile8;
set	Outfile7;
If km=10000 then km_min=0;
If km=15000 then km_min=10001;
If km=20000 then km_min=15001;
run;

/*Multiply by 110%*/
data Outfile9;
set	Outfile8;
RV=substr(RV, 1, length(RV)-1);
run;

data Outfile10;
set	Outfile9;
RV=tranwrd(RV,",",".");
run;

data Outfile11;
set	Outfile10;
RV1=input(RV,comma4.);
drop RV;
rename RV1=RV;
RV=1.1*RV;
run;

/*add and modify right coumns*/
data Outfile12;
retain manufacturer model codice_infocar fuel km_min km term rv;
set	Outfile11;
manufacturer="";
model="";
where Codice_Infocar in (142955, 142961, 142966, 142971, 142974, 143130, 143222);
rename Term=term RV=rv Codice_Infocar=codice_infocar;
drop Modello;
run;

/*output txt file*/
PROC EXPORT DATA= Outfile12 
OUTFILE= "&path\&file" DBMS=TAB;
RUN;

/*output excel*/
proc export
	data= Outfile12
	dbms=xlsx
	outfile="&path\&file"
	Replace;
run;


