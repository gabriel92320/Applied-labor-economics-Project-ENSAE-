

/* Projet d'Applied Labor Economics: */

/* Ce programme cr�e la base d'�tude pour r�aliser l'�valuation ex-post du dispositif POEC � partir des donn�es de la base ForCE (vague n�12)*/

/* Chargement des librairies */

libname BREST "\\casd.fr\casdfs\Projets\ENSAE05\Data\FORCE_FORCE_2023T2\BREST";
libname MMO "\\casd.fr\casdfs\Projets\ENSAE05\Data\FORCE_FORCE_2023T2\MMO";
libname FH "\\casd.fr\casdfs\Projets\ENSAE05\Data\FORCE_FORCE_2023T2\FH";

libname REFFHS "\\casd.fr\casdfs\Projets\ENSAE05\Data\FORCE_FORCE_2023T2\Documentation\FHS FHA REFERENTIELS ET DOC";

libname etude "C:\Users\Public\Documents\tibo_gab\data\sas_data";

/* Objectif 1: identifier dans BREST les "primo-form�s" entr�s en POE sur la p�riode 2017-2019 et n'ayant suivi aucune formation � destination des
demandeurs d'emploi de plus de 30h sur la p�riode 2014-2016 + r�cup�rer toutes les variables pertinentes dans BREST pour notre �tude
(caract�ristiques socio-d�mo du form� et caract�ristiques de la formation) */


/* 1. On ne conserve dans la table Brest2_1721_v12 que les observations pour lesquelles on a un id_force renseign� pour les entr�es en formation professionnelle intervenues
sur la p�riode 2017-2019: */
proc sql;
create table brest_2017_2019 as
select *
from brest.Brest2_1721_v12
where id_force ne "" and annee_entree in ("2017","2018","2019");
quit;

/* 2. On se concentre sur la premi�re formation suivie sur la p�riode 2017-2019 -> champ de l'�tude: les "primo-form�s" */
proc sort data=brest_2017_2019;by id_force id_brest;run;
proc sort data=brest_2017_2019 out=brest_2017_2019_2 nodupkey;by id_force;run; /* 459 104 observations supprim�es */

/* 3. On ne garde que les entr�es en formation POEC/POEI (politique POE � �valuer): */
proc sql;
create table primoforma_poe_2017_2019 as
select *
from brest_2017_2019_2
where DISPOSITIF_TR in ("POEC","POEI");
quit;
/* 176 222 observations (stagiaires de la formation professionnelle �tant entr� dans une POE sur la p�riode 2017-2019) */

/* Nombre de stagiaires en POE par ann�e (avec ventilation POEC/POEI): */
proc freq data=primoforma_poe_2017_2019;table annee_entree*DISPOSITIF_TR;run;

/* 4. On identifie les demandeurs d'emploi ayant suivi une formation entre 2014 et 2016 d'une dur�e de plus de 30 heures: */
proc sql;
create table DE_formation_2014_2016 as
select id_force,P2DATDEB,P2DATFIN
from fh.p2_tempo
where P2DATDEB>="01JAN2014"d and P2DATFIN<="31DEC2016"d /*and P2NBHEUR>30*/; /* TODO: g�rer le passage carac->num de la variable P2NBHEUR*/
quit;

/* 5. Parmi les stagiaires entr�s en POE sur la p�riode 2017-2019, on ne retient que ceux n'ayant pas suivi de formation sur la p�riode ant�rieure
(2016-2016): */
proc sql;
create table primoforma_poe_2017_2019_2 as
select *
from primoforma_poe_2017_2019
where id_force not in (select id_force from DE_formation_2014_2016);
quit;
/* 158 986 stagiaires primo-form�s entr�s en POE entre 2017 et 2019. */

/* 6. On identifie les demandeurs d'emplois qui se sont inscrits au moins une fois � P�le Emploi � compter du 01/01/2017 ou qui 
�taient d�j� inscrits � P�le Emploi avant cette date et qui ont annul� cette demande apr�s le 01/01/2017 (actualisation de leur situation
� P�le Emploi): */
proc sql;
create table DE_inscrits_post010117 as 
select id_force
from fh.de_tempo
where datins>="01JAN2017"d or datann>"01JAN2017"d;
;
quit;

/* 7. On ne retient que les stagiaires en POEC qui ont �t� inscrits au moins une fois � P�le Emploi � compter du 1er janvier 2017: */
proc sql;
create table primoforma_poe_2017_2019_3 as
select *
from primoforma_poe_2017_2019_2
where id_force in (select id_force from DE_inscrits_post010117);
quit;
/* 158 173 stagiaires POE figurant dans le fichier historique des demandeurs d'emploi. */

/* 8. Cr�ation de l'indicatrice POEC_it (variable de traitement: le demandeur d'emploi i est entr� en POEC le mois t)*/

data primoforma_poe_2017_2019_3 ;
retain id_force
/*POEC_0117 POEC_0217 POEC_0317 POEC_0417 POEC_0517 POEC_0617 POEC_0717 POEC_0817 POEC_0917 POEC_1017 POEC_1117 POEC_1217
POEC_0118 POEC_0218 POEC_0318 POEC_0418 POEC_0518 POEC_0618 POEC_0718 POEC_0818 POEC_0918 POEC_1018 POEC_1118 POEC_1218
POEC_0119 POEC_0219 POEC_0319 POEC_0419 POEC_0519 POEC_0619 POEC_0719 POEC_0819 POEC_0919 POEC_1019 POEC_1119 POEC_1219*/
/* caract�ristique de la formation POEC: */
annee_entree date_entree date_fin duree_formation_heures_redressee objectif_stage domaine_formation
/* profil socio_d�mographique du DE entr� en POEC (infos de BREST): */
sexe age_entree_stage code_postal commune departement_habitation region_habitation qpv niv_diplome_tr travailleur_handicape
;
set primoforma_poe_2017_2019_3 (keep=id_force
sexe age_entree_stage code_postal commune departement_habitation region_habitation qpv niv_diplome_tr travailleur_handicape
annee_entree date_entree date_fin duree_formation_heures_redressee objectif_stage domaine_formation
);/*
POEC_0117=0;
POEC_0217=0;
POEC_0317=0;
POEC_0417=0;
POEC_0517=0;
POEC_0617=0;
POEC_0717=0;
POEC_0817=0;
POEC_0917=0;
POEC_1017=0;
POEC_1117=0;
POEC_1217=0;

POEC_0118=0;
POEC_0218=0;
POEC_0318=0;
POEC_0418=0;
POEC_0518=0;
POEC_0618=0;
POEC_0718=0;
POEC_0818=0;
POEC_0918=0;
POEC_1018=0;
POEC_1118=0;
POEC_1218=0;

POEC_0119=0;
POEC_0219=0;
POEC_0319=0;
POEC_0419=0;
POEC_0519=0;
POEC_0619=0;
POEC_0719=0;
POEC_0819=0;
POEC_0919=0;
POEC_1019=0;
POEC_1119=0;
POEC_1219=0;

if date_entree>="01JAN2017"d and date_entree<="31JAN2017"d then POEC_0117=1;
if date_entree>="01FEB2017"d and date_entree<="28FEB2017"d then POEC_0217=1;
if date_entree>="01MAR2017"d and date_entree<="31MAR2017"d then POEC_0317=1;
if date_entree>="01APR2017"d and date_entree<="30APR2017"d then POEC_0417=1;
if date_entree>="01MAY2017"d and date_entree<="31MAY2017"d then POEC_0517=1;
if date_entree>="01JUN2017"d and date_entree<="30JUN2017"d then POEC_0617=1;
if date_entree>="01JUL2017"d and date_entree<="31JUL2017"d then POEC_0717=1;
if date_entree>="01AUG2017"d and date_entree<="31AUG2017"d then POEC_0817=1;
if date_entree>="01SEP2017"d and date_entree<="30SEP2017"d then POEC_0917=1;
if date_entree>="01OCT2017"d and date_entree<="31OCT2017"d then POEC_1017=1;
if date_entree>="01NOV2017"d and date_entree<="30NOV2017"d then POEC_1117=1;
if date_entree>="01DEC2017"d and date_entree<="31DEC2017"d then POEC_1217=1;

if date_entree>="01JAN2018"d and date_entree<="31JAN2018"d then POEC_0118=1;
if date_entree>="01FEB2018"d and date_entree<="28FEB2018"d then POEC_0218=1;
if date_entree>="01MAR2018"d and date_entree<="31MAR2018"d then POEC_0318=1;
if date_entree>="01APR2018"d and date_entree<="30APR2018"d then POEC_0418=1;
if date_entree>="01MAY2018"d and date_entree<="31MAY2018"d then POEC_0518=1;
if date_entree>="01JUN2018"d and date_entree<="30JUN2018"d then POEC_0618=1;
if date_entree>="01JUL2018"d and date_entree<="31JUL2018"d then POEC_0718=1;
if date_entree>="01AUG2018"d and date_entree<="31AUG2018"d then POEC_0818=1;
if date_entree>="01SEP2018"d and date_entree<="30SEP2018"d then POEC_0918=1;
if date_entree>="01OCT2018"d and date_entree<="31OCT2018"d then POEC_1018=1;
if date_entree>="01NOV2018"d and date_entree<="30NOV2018"d then POEC_1118=1;
if date_entree>="01DEC2018"d and date_entree<="31DEC2018"d then POEC_1218=1;

if date_entree>="01JAN2019"d and date_entree<="31JAN2019"d then POEC_0119=1;
if date_entree>="01FEB2019"d and date_entree<="28FEB2019"d then POEC_0219=1;
if date_entree>="01MAR2019"d and date_entree<="31MAR2019"d then POEC_0319=1;
if date_entree>="01APR2019"d and date_entree<="30APR2019"d then POEC_0419=1;
if date_entree>="01MAY2019"d and date_entree<="31MAY2019"d then POEC_0519=1;
if date_entree>="01JUN2019"d and date_entree<="30JUN2019"d then POEC_0619=1;
if date_entree>="01JUL2019"d and date_entree<="31JUL2019"d then POEC_0719=1;
if date_entree>="01AUG2019"d and date_entree<="31AUG2019"d then POEC_0819=1;
if date_entree>="01SEP2019"d and date_entree<="30SEP2019"d then POEC_0919=1;
if date_entree>="01OCT2019"d and date_entree<="31OCT2019"d then POEC_1019=1;
if date_entree>="01NOV2019"d and date_entree<="30NOV2019"d then POEC_1119=1;
if date_entree>="01DEC2019"d and date_entree<="31DEC2019"d then POEC_1219=1;
*/
run;

/*
proc means data=primoforma_poec_2017_2019_3 missing sum;
var POEC_0117 POEC_0217 POEC_0317 POEC_0417 POEC_0517 POEC_0617 POEC_0717 POEC_0817 POEC_0917 POEC_1017 POEC_1117 POEC_1217
POEC_0118 POEC_0218 POEC_0318 POEC_0418 POEC_0518 POEC_0618 POEC_0718 POEC_0818 POEC_0918 POEC_1018 POEC_1118 POEC_1218
POEC_0119 POEC_0219 POEC_0319 POEC_0419 POEC_0519 POEC_0619 POEC_0719 POEC_0819 POEC_0919 POEC_1019 POEC_1119 POEC_1219;
run;
*/

/* TODO: filtre sur les variables relatives � l'utilisation du CPF? indicatrices -> CPF_autonome=0 et/ou CPF_PE=0 */

/* OBJECTIF n�1 atteint! */

/* Quelques premi�res statistiques descriptives sur le profil des 86 204 stagiaires "primo-form�s" entr�s en POEC sur la p�riode 2017-2019: */

/* a. Profil socio-d�mographique du stagiaire POEC: */

/* Sexe: */
proc freq data=primoforma_poe_2017_2019_3;table annee_entree*sexe;run;

/* Age: TODO -> coder une variable classe d'�ge (variable AGE_ENTREE_STAGE) */

/* Dipl�me: */
proc freq data=primoforma_poe_2017_2019_3;table annee_entree*NIV_DIPLOME_TR;run;

/* R�gion d'habitation:*/
proc freq data=primoforma_poe_2017_2019_3;table annee_entree*REGION_HABITATION;run;

/*...*/


/* OBJECTIF n�2:
Compl�ter la base Primoforma_poec_2017_2019_3 avec les informations compl�mentaires fournies par P�le Emploi sur les demandeurs d'emploi
entr�es en POEC entre 2017 et 2019. Il s'agit d'enrichir cette base de caract�ristiques socio-d�mo du DE non redondantes avec BREST
ainsi que de variables caract�risant la demande d'emploi du DU � l'entr�e en formation (type de contrat, m�tier recherch�, salaire, etc.).
; */


/* 1. On s�lectionne les DE entr�s en cat�gorie 4 de P�le Emploi (personnes � la recherche d'un emploi mais non imm�diatement disponibles
(en formation, en arr�t maladie, en cong� maternit�, en CRP...) entre le 01/01/17 et le 31/12/19 et ne retient que les variables fournies par
P�le Emploi utiles pour l'�tude (apr�s avoir v�rifi� les �ventuelles redondances d'info avec BREST): */
proc sql;
create table DE_inscrits_cat4_0117_1219 as 
select 
id_force,datins,motins,datann,
/* caract�ristiques socio-d�mo du DE � l'entr�e en cat�gorie 4: */
sexe as sexe_fh,datnais,depcom,nivfor,diplome,/* infos redondantes avec BREST (mais utiles � r�cup�rer pour le groupe de contr�le!)*/
nation,sitmat,nenf,qualif,zrr,
/* caract�ristiques de la recherche d'emploi du DE � l'entr�e en cat�gorie 4: */
CATREGR,contrat,temps,rome,romeapl,exper,expeunit,projentr,salmt,salunit,mobdist,mobunit
from fh.de_tempo
where datins>="01JAN2017"d and datins<="31DEC2019"d and CATREGR="4";
;
quit;


/* Jointure de type "inner join" entre la table "Primoforma_poe_2017_2019_3" et la table "DE_inscrits_cat4_0117_1219" sur la base
des deux cl�s: id_force et datins (date d'effet d'inscription) */

proc sql;
create table Primoforma_poe_2017_2019_4 as
select *
from Primoforma_poe_2017_2019_3 as a
inner join DE_inscrits_cat4_0117_1219 as b
on a.id_force=b.id_force
and a.date_entree=b.datins;
quit;
/* 154 721 DE entr�s en POE sur la p�riode 2017-2019 avec toutes les infos de BREST et de FH, c'est pas mal!*/


/* 3. Coder des variables cat�gorielles rassemblant certaines modalit�s lorsqu'elles sont tr�s nombreuses ou peu explicites
Par ex: variable "nombre d'enfants" - > 5 classes: 0 ; 1 enfant; 2 enfants; 3 enfants; 4 enfants ou plus;
nationalit�...
*/

/* TODO ! */

/* Objectif n�2 atteint! */


/* Objectif n�3: on souhaiterait r�cup�rer de l'info sur l'anciennet� au ch�mage des DE entr�s en POE entre 2017 et 2019:
- calcul de l'anciennet� au ch�mage � la date d'entr�e en POE du DE (en jours);
- calcul de la dur�e totale cumul�e d'inscription au ch�mage avant l'entr�e en POEC ( en jours);
- nombre d'�pisodes de ch�mage avant l'entr�e en POE;

WARNING: ces calculs seront effectu�s en appliquant au pr�alable la convention suivante:
si la dur�e entre deux �pisodes cons�cutufs est inf�rieure ou �gale � 31 jours alors on consid�re qu'il s'agit d'un 
m�me �pisode de ch�mage (agr�gation des deux �pisodes de ch�mage en un seul). Cette convention ne joue que sur le 1er
et le 3eme calcul!
*/

/* 1. On repart du fichier historique des DE et on le circonscrit au champ des DE entr�s en POE (table "Primoforma_poec_2017_2019_4")  */

proc sql;
create table tab0 as
select id_force,ndem,datins,datann,ancien,catregr
from fh.de_tempo
where id_force in (select id_force from Primoforma_poe_2017_2019_4);
quit;
/* 1 023 694 demandes aupr�s de P�le Emploi associ�es aux 154 721 DE entr�s en POE sur la p�riode 2017-2019 */

proc sort data=tab0;by id_force ndem;run;

proc sql;
create table tab1 as
select a.*,b.date_entree
from tab0 as a
left join Primoforma_poe_2017_2019_4 as b
on a.id_force=b.id_force
;
quit;

data tab2;
set tab1;
diff_date_entree_datins=date_entree-datins;
run;

data tab3;
set tab2;
where diff_date_entree_datins>=0;
run;

data tab4;
set tab3;
duree_chomage_jours=datann-datins;
run;

/* on compare pour chaque DE, la date d'annulation d'une demande avec la date d'inscription de la demande cons�cutive (s'il y en a!)*/

proc sort data=tab4 out=tab5;by id_force datann;run;

data tab6;
set tab5;
by id_force;
format next_datann YYMMDD10.;
next_datann=lag(datann);
if first.id_force then next_datann=.;
run;


data tab7;
set tab6;
by id_force;
ecart_demandes_jours=datins-next_datann;
if first.id_force then ecart_demandes_jours=.;
run;

data tab8;
set tab7;
by id_force;
if first.id_force then ndem_bis=1;
else ndem_bis+1;
run;

data tab9;
set tab8;
var=0;
if ecart_demandes_jours ne . & ecart_demandes_jours<=31 then var=-1; /**/
run;

data tab10;
set tab9;
ndem_ter=ndem_bis+var;
run;

data tab11;
set tab10;
ndem_2=strip(put(ndem_ter,$2.));
run;

/* 1) calcul de l'anciennet� au ch�mage � la date d'entr�e en POE du DE (en jours)*/
proc means data=tab11 missing noprint;
class id_force ndem_2;
var duree_chomage_jours;
output out=duree_episode_chomage_jours 
sum=duree_episode_chomage_jours;
run;

data duree_episode_chomage_jours (keep=id_force ndem_2 duree_episode_chomage_jours);
set duree_episode_chomage_jours (where=( _type_=3));
run;

data duree_episode_chomage_jours;
set duree_episode_chomage_jours;
ndem_3=input(ndem_2,2.);
run;

proc sort data=duree_episode_chomage_jours;by id_force ndem_3;run;

data duree_episode_chomage_jours_2 (rename=(duree_episode_chomage_jours=anciennete_chomage_j));
set duree_episode_chomage_jours (drop=ndem_3 ndem_2);
by id_force;
if last.id_force then output;
run;

/* ok! */

/*2) calcul de la dur�e totale cumul�e d'inscription au ch�mage avant l'entr�e en POE (en jours): */
proc means data=duree_episode_chomage_jours missing noprint;
class id_force;
var duree_episode_chomage_jours;
output out=duree_tot_chomage_jours 
sum=duree_tot_chomage_j;
run;

data duree_tot_chomage_jours (keep=id_force duree_tot_chomage_j);
set duree_tot_chomage_jours (where=( _type_=1));
run;


/* 3)nombre d'�pisodes de ch�mage avant l'entr�e en POE: */
/* TODO! */


/* on r�unit ces calculs dans une m�me base: */
data duree_chomage_avant_POE;
merge duree_episode_chomage_jours_2 duree_tot_chomage_jours;
run;

/* Et on fait la jointure avec la base principale d'�tude "Primoforma_poec_2017_2019_4": */

proc sql;
create table Primoforma_poe_2017_2019_5 as 
select *
from Primoforma_poe_2017_2019_4 as a
left join duree_chomage_avant_POE as b
on a.id_force=b.id_force;
quit;

/* ok! */

/* Objectif n�4: On souhaiterait maintenant r�cup�rer de l'info dans le fichier MMO sur les retours � l'emploi des DE entr�s en POE entre 2017 et 2019;
En particulier, on souhaiterait construire nos premi�re variables d'outcome, du type:
- retour � l'emploi moins d'un an apr�s l'entr�e en POE;
- retour � l'emploi entre 1 et 2 ans apr�s l'entr�e en POE;
- retour � l'emploi entre 2 et 3 ans apr�s l'entr�e en POE;
*/

/* Ci-dessous, on traite successivement les diff�rents mill�simes de fichier MMO (2017 � 2022): */
/* TODO: on pourra faire une macro qui boucle que les 6 ann�es */

%macro codage_retour_emploi(tab_mmo=,annee=);

/* 1. On s�lectionne les contrats actifs* en A obtenus par des DE entr�s en POEC entre 2017 et 2019: 
*contrats actifs -> dont la date de d�but <=31/12/A et date de fin >= 01/12/A*/

proc sql;
create table contrats_actifs_DE_POE1719 as
select id_force,L_contrat_sqn,
debutCTT,finCTT,motifRecours,motifRupture,pcsese,DispPolitiquePublique,modeExercice,nature,salaire_base,
siret_af,siret_ut,catjuri_id
from &tab_mmo
where L_Contrat_SQN>0 /* contrat actif au moins 1 jour durant l'ann�e A */
and 
id_force in (select id_force from Primoforma_poe_2017_2019_5) /* individus entr�s en POE entre 2017 et 2019 */
and
secteur_PUBLIC=0 /* on exclue les contrats dans le secteur public*/
and
substr(debutCTT,1,4)=&annee /* s�lection de l'ann�e A de d�but du contrat de travail*/
order by id_force,DebutCTT
;
quit;

/* 2. On se restreint aux contrats d�but�s apr�s le 01/01/2017 (comme on s'int�resse ici au retour � l'emploi post_POEC d�but�s entre 
2017 et 2019) et on s�lectionne les variables pertinentes pour notre �tude (caract�ristiques des contrats: type de contrat,pcs,date de d�but, date de fin, etc.) */
/*
proc sql;
create table contrats_actifs_DE_POEC1719_2 as 
select id_force,L_contrat_sqn,
debutCTT,finCTT,motifRecours,motifRupture,pcsese,DispPolitiquePublique,modeExercice,nature,salaire_base,
siret_af,siret_ut,catjuri_id
from contrats_actifs_DE_POEC1719
where substr(debutCTT,1,4)=&annee
order by id_force,DebutCTT;
quit;
*/

/* 3. On applique la convention suivante: on consid�re ici qu'un �pisode d'emploi comme un contrat d'une dur�e effective d'au moins 31 jours.
On calcule donc pour chaque contrat leur dur�e effective et on �limine ceux de moins de 31 jours. */

 /* Conversion des cha�nes de caract�res en format date SAS: */
data contrats_actifs_DE_POE1719;
set contrats_actifs_DE_POE1719;
debutCTT2=input(debutCTT,yymmdd10.);
finCTT2=input(finCTT,yymmdd10.);
format debutCTT2 yymmdd10.;
format finCTT2 yymmdd10.;
run;

/* Calcul de la dur�e des contrats (en nb de jours) par diff�rence des dates de fin et de d�but de contrat: */
data contrats_actifs_DE_POE1719;
set contrats_actifs_DE_POE1719;
format date_ref YYMMDD10.;
date_ref=mdy(12,31,2022);
if finCTT2 ne . and debutCTT2 ne . then do;
duree_contrat_j=finCTT2-debutCTT2;
end;
else if debutCTT2 ne . and finCTT2=. then do;
duree_contrat_j=date_ref-debutCTT2;
end;
else do;
duree_contrat_j=.;
end;
run;

/* Suppression des contrats durant moins de 31 jours: */
data contrats_actifs_DE_POE1719_2;
set contrats_actifs_DE_POE1719;
where duree_contrat_j>=31;
run;

/* 4. On ajoute � cette table "contrats_actifs_DE_POE1719_2" obtenue l'info sur la date d'entr�e en POE des DE: */

proc sql;
create table contrats_actifs_DE_POE1719_3 as
select a.*,b.date_entree
from  contrats_actifs_DE_POE1719_2 as a
left join Primoforma_poe_2017_2019_5 as b
on a.id_force=b.id_force;
quit;

/* 5. On ne garde que les contrats d�but�s au moins 31 jours apr�s l'entr�es en POE: */

data contrats_actifs_DE_POE1719_3;
set contrats_actifs_DE_POE1719_3;
diff_dateCTT_date_entree=debutCTT2-date_entree;
run;

data contrats_actifs_DE_POE1719_4;
set contrats_actifs_DE_POE1719_3;
where diff_dateCTT_date_entree>31;
run;

/* 6. Lorsque l'on observe plusieurs contrats pour un m�me individu, on ne garde que le premier (ie le 1er contrat
qui a �t� obtenu apr�s l'entr�e en POEC); on ne s'int�resse pas ici � la trajectoire des diff�rents contrats qui
ont pu �tre obtenus apr�s la formation mais on se focalise ici seulement sur le premier contrat obtenu apr�s la
formation: */

data contrats_actifs_DE_POE1719_5;
set contrats_actifs_DE_POE1719_4;
by id_force;
if first.id_force then output;
run;

/* 7. Codage des indicatrices de retour � l'emploi des b�n�ficiaires de POE en ann�e A: 
- retour � l'emploi moins d'un an apr�s l'entr�e en POE;
- retour � l'emploi entre 1 et 2 ans apr�s l'entr�e en POE;
- retour � l'emploi entre 2 et 3 ans apr�s l'entr�e en POE;
*/

data contrats_actifs_DE_POE1719_5;
set contrats_actifs_DE_POE1719_5;
retour_emploi_moins1an=0;
retour_emploi_entre1_2ans=0;
retour_emploi_entre2_3ans=0;

if diff_dateCTT_date_entree<=365 then retour_emploi_moins1an=1;
if diff_dateCTT_date_entree>365 & diff_dateCTT_date_entree<=730 then retour_emploi_entre1_2ans=1;
if diff_dateCTT_date_entree>730 & diff_dateCTT_date_entree<=1095 then retour_emploi_entre2_3ans=1;

run;

%mend;

/* 2017: */
%codage_retour_emploi(tab_mmo=mmo.Mmo_2_2017_f12,annee="2017");
data contrats_actifs_DE_POE1719_2017;
set contrats_actifs_DE_POE1719_5;
run;

/* 2018: */
%codage_retour_emploi(tab_mmo=mmo.Mmo_2_2018_f12,annee="2018");
data contrats_actifs_DE_POE1719_2018;
set contrats_actifs_DE_POE1719_5;
run;

/* 2019: */
%codage_retour_emploi(tab_mmo=mmo.Mmo_2_2019_f12,annee="2019");
data contrats_actifs_DE_POE1719_2019;
set contrats_actifs_DE_POE1719_5;
run;

/* 2020: */
%codage_retour_emploi(tab_mmo=mmo.Mmo_2_2020_f12,annee="2020");
data contrats_actifs_DE_POE1719_2020;
set contrats_actifs_DE_POE1719_5;
run;

/* 2021: */
%codage_retour_emploi(tab_mmo=mmo.Mmo_2_2021_f12,annee="2021");
data contrats_actifs_DE_POE1719_2021;
set contrats_actifs_DE_POE1719_5;
run;

/* 2022: */
%codage_retour_emploi(tab_mmo=mmo.Mmo_2_2022_f12,annee="2022");
data contrats_actifs_DE_POE1719_2022;
set contrats_actifs_DE_POE1719_5;
run;


/* Une fois obtenue une table de premiers contrats obtenus par les b�n�ficiaires de POEC pour chaque ann�e (ann�e d'obtention du contrat),
on peut empiler ces 6 tables et faire une jointure avec la table d'�tude de r�f�rence "Primoforma_poec_2017_2019_5".
*/

/* 1. Concat�nation verticale des 6 tables de contrat (retour � l'emploi des POEC sur la p�riode 2017-2022)*/

data retour_emploi_postPOE_2017_22;
set contrats_actifs_DE_POE1719_2017
contrats_actifs_DE_POE1719_2018
contrats_actifs_DE_POE1719_2019
contrats_actifs_DE_POE1719_2020
contrats_actifs_DE_POE1719_2021
contrats_actifs_DE_POE1719_2022;
run;
/* 300 135 contrats d�but�s apr�s un POE (attention, on peut avoir plusieurs contrats pour un m�me individu!)*/

/* On ne va garder ici que le premier contrat obtenu apr�s le POE: */
proc sort data=retour_emploi_postPOE_2017_22 out=First_retour_emploi_postPOE nodupkey;by id_force;run;
/* 139 499 premiers retours � l'emploi post-POEC sur la p�riode 2017-2022*/

/* Jointure avec la base d'�tude des DE entr�s en POE sur la p�riode 2017-2019 "Primoforma_poe_2017_2019_5": */

proc sql;
create table Primoforma_poe_2017_2019_6 as
select *
from  Primoforma_poe_2017_2019_5 as a
left join First_retour_emploi_postPOE as b
on a.id_force=b.id_force;
quit;

data Primoforma_poe_2017_2019_6;
set Primoforma_poe_2017_2019_6;
if retour_emploi_moins1an=. then retour_emploi_moins1an=0;
if retour_emploi_entre1_2ans=. then retour_emploi_entre1_2ans=0;
if retour_emploi_entre2_3ans=. then retour_emploi_entre2_3ans=0;

run;
/* 84 028 DE entr�s en POEC entre 2017 et 2019*/

/* Sauvegarde de la base d'�tude relative au groupe trait�: les DE entr�s en POE sur la p�riode 2017-2019
(carat�ristiques socio-d�mo du DE + anciennet� dans le ch�mage + caract�ristiques de l'emploi recherch� +
retour � l'emploi � horizon 1 an/2ans/3 ans + caract�ristique du 1er contrat de travail obtenu + dur�e effective du contrat en jours*)*/
data etude.base_etude_treated_group;
set Primoforma_poe_2017_2019_6;
run;
/* *dans le cas o� le contrat de travail n'est pas termin� au 31/12/2022, par convention, sa dur�e sera �valu�e en prenant comme date de
fin le 31/12/2022 (date de r�f�rence d'observation de la situation professionnelle des b�n�ficiaires de POE, car on ne dispose pas de donn�es
sur les contrats actifs apr�s 2022. */
/* 154 721 DE sont "trait�s" sur la p�riode d'�tude retenue (2017-2019) */



/* Construction du groupe des "non trait�s": */

/* Logique g�n�rale de construction: on proc�de mois par mois */


/* Objectif n�5: pour chaque cohorte de DE entr�s en POE le mois m de l'ann�e A, on souhaite s�lectionner des DE 
inscrits � P�le Emploi le mois m de l'ann�e A mais n'ayant pas suivi de POEC ce mois-ci. */

/* 1. D�coupage mensuel de la base des DE entr�s en POE sur la p�riode 2017-2019: */

/*
if date_entree>="01JAN2017"d and date_entree<="31JAN2017"d then POEC_0117=1;
if date_entree>="01FEB2017"d and date_entree<="28FEB2017"d then POEC_0217=1;
if date_entree>="01MAR2017"d and date_entree<="31MAR2017"d then POEC_0317=1;
if date_entree>="01APR2017"d and date_entree<="30APR2017"d then POEC_0417=1;
if date_entree>="01MAY2017"d and date_entree<="31MAY2017"d then POEC_0517=1;
if date_entree>="01JUN2017"d and date_entree<="30JUN2017"d then POEC_0617=1;
if date_entree>="01JUL2017"d and date_entree<="31JUL2017"d then POEC_0717=1;
if date_entree>="01AUG2017"d and date_entree<="31AUG2017"d then POEC_0817=1;
if date_entree>="01SEP2017"d and date_entree<="30SEP2017"d then POEC_0917=1;
if date_entree>="01OCT2017"d and date_entree<="31OCT2017"d then POEC_1017=1;
if date_entree>="01NOV2017"d and date_entree<="30NOV2017"d then POEC_1117=1;
if date_entree>="01DEC2017"d and date_entree<="31DEC2017"d then POEC_1217=1;

if date_entree>="01JAN2018"d and date_entree<="31JAN2018"d then POEC_0118=1;
if date_entree>="01FEB2018"d and date_entree<="28FEB2018"d then POEC_0218=1;
if date_entree>="01MAR2018"d and date_entree<="31MAR2018"d then POEC_0318=1;
if date_entree>="01APR2018"d and date_entree<="30APR2018"d then POEC_0418=1;
if date_entree>="01MAY2018"d and date_entree<="31MAY2018"d then POEC_0518=1;
if date_entree>="01JUN2018"d and date_entree<="30JUN2018"d then POEC_0618=1;
if date_entree>="01JUL2018"d and date_entree<="31JUL2018"d then POEC_0718=1;
if date_entree>="01AUG2018"d and date_entree<="31AUG2018"d then POEC_0818=1;
if date_entree>="01SEP2018"d and date_entree<="30SEP2018"d then POEC_0918=1;
if date_entree>="01OCT2018"d and date_entree<="31OCT2018"d then POEC_1018=1;
if date_entree>="01NOV2018"d and date_entree<="30NOV2018"d then POEC_1118=1;
if date_entree>="01DEC2018"d and date_entree<="31DEC2018"d then POEC_1218=1;

if date_entree>="01JAN2019"d and date_entree<="31JAN2019"d then POEC_0119=1;
if date_entree>="01FEB2019"d and date_entree<="28FEB2019"d then POEC_0219=1;
if date_entree>="01MAR2019"d and date_entree<="31MAR2019"d then POEC_0319=1;
if date_entree>="01APR2019"d and date_entree<="30APR2019"d then POEC_0419=1;
if date_entree>="01MAY2019"d and date_entree<="31MAY2019"d then POEC_0519=1;
if date_entree>="01JUN2019"d and date_entree<="30JUN2019"d then POEC_0619=1;
if date_entree>="01JUL2019"d and date_entree<="31JUL2019"d then POEC_0719=1;
if date_entree>="01AUG2019"d and date_entree<="31AUG2019"d then POEC_0819=1;
if date_entree>="01SEP2019"d and date_entree<="30SEP2019"d then POEC_0919=1;
if date_entree>="01OCT2019"d and date_entree<="31OCT2019"d then POEC_1019=1;
if date_entree>="01NOV2019"d and date_entree<="30NOV2019"d then POEC_1119=1;
if date_entree>="01DEC2019"d and date_entree<="31DEC2019"d then POEC_1219=1;
*/


data treated_group_0117 treated_group_0217;
set etude.base_etude_treated_group;
if date_entree>="01JAN2017"d and date_entree<="31JAN2017"d then output treated_group_0117;
if date_entree>="01FEB2017"d and date_entree<="28FEB2017"d then output treated_group_0217;
/* TODO: ajouter ici les autres mois manquants sur la p�riode d'�tude */

run;

/* On se concentre sur le mois de janvier 2017 (et ensuite on g�n�ralisera le code pour tous les autres mois) */


/* Cr�ation de la variable indicatrice de traitement "POE" + sauvegarde :*/

data etude.treated_group_0117;
retain id_force POE;
set treated_group_0117;
POE=1;
run;


/* 2. S�lection des DE qui ne sont pas rentr�s en formation (POE ou autres) sur la p�riode 2017-2022
ET
qui n'ont pas suivi de formation d'une dur�e>30h sur la p�riode 2014-2016
ET
qui se sont inscrits au moins une fois � P�le Emploi sur la p�riode 2017-2022
+
S�lections des variables pertinentes (on reprend la liste retenue lors de la s�lection des DE entr�s en POE!)
*/

proc sql;
create table DE_sans_forma_2014_2022 as
select 
id_force,datins,motins,datann,
/* caract�ristiques socio-d�mo du DE � l'entr�e en cat�gorie 4 (non redondantes avec celles fournies par BREST): */
nation,sitmat,nenf,qualif,zrr,
/* caract�ristiques de la recherche d'emploi du DE: */
sexe as sexe_fh,datnais,depcom,nivfor,diplome,/* infos redondantes avec BREST (mais utiles � r�cup�rer pour le groupe de contr�le!)*/
CATREGR,contrat,temps,rome,romeapl,exper,expeunit,projentr,salmt,salunit,mobdist,mobunit
from fh.de_tempo
where 
id_force not in (select id_force from brest.Brest2_1721_v12) /* DE non pr�sent dans la base BREST 2017-21*/
and
id_force not in (select id_force from brest.Brest2_22_v12) /* DE non pr�sent dans la base BREST 2022*/
and
id_force not in (select id_force from DE_formation_2014_2016) /* DE n'ayant pas suivi de formation de plus de 30h sur la p�riode 2014-2016.*/
and
((datann>"01JAN2017"d) ! (datann=.)) /* DE inscrits � P�le Emploi ayant annul� leur demande apr�s le 31/01/2017 ou qui n'ont pas encore annul� leur demande*/
;
quit;
/* 31 099 277 observations  */

/* S�lections des variables pertinentes (on reprend la liste retenue lors de la s�lection des DE entr�s en POE!): */
/*
proc sql;
create table DE_sans_forma_2014_2022 as 
select 
id_force,datins,motins,datann,
nation,sitmat,nenf,qualif,zrr,
CATREGR,contrat,temps,rome,romeapl,exper,expeunit,projentr,salmt,salunit,mobdist,mobunit
from DE_sans_forma_2014_2022
;
quit;
*/

/* D�coupage mensuel: pour un mois m de l'ann�e A, on cr�e une table rassemblant tous les DE pr�sents dans DE_sans_forma_2014_2022
et qui sont inscrits au moins 1 jour � P�le Emploi durant ce mois.
*/

/* Janvier 2017: */
proc sql;
create table DE0117_sans_forma_2014_2022 as
select *
from DE_sans_forma_2014_2022
where 
((datins>="01JAN2017"d) & (datins<="31JAN2017"d)) /* DE qui se sont inscrits � P�le Emploi entre le 01/01/17 et le 31/01/17 */
!
((datins<"01JAN2017"d) & (datann>"01JAN2017"d)) /* DE qui se sont inscrits � P�le Emploi avant le 01/01/17 et qui ont cl�tur� leur demande apr�s le 01/01/17*/
!
((datins<"01JAN2017"d) & (datann=.)) /* DE qui se sont inscrits � P�le Emploi avant le 01/01/17 et qui n'ont pas encore cl�tur� leur demande � ce jour.*/
order by id_force,datins desc 
;
quit;
/* 5 196 828 observations */

/* on retient l'�pisode de ch�mage le plus r�cent: */
proc sort data=DE0117_sans_forma_2014_2022 nodupkey;by id_force;run;
/* 5 121 157 DE */



/* Objectif n�3: on souhaiterait r�cup�rer de l'info sur l'anciennet� au ch�mage des DE entr�s en POE entre 2017 et 2019:
- calcul de l'anciennet� au ch�mage � la date d'entr�e en POE du DE (en jours);
- calcul de la dur�e totale cumul�e d'inscription au ch�mage avant l'entr�e en POE ( en jours);
- nombre d'�pisodes de ch�mage avant l'entr�e en POE;

WARNING: ces calculs seront effectu�s en appliquant au pr�alable la convention suivante:
si la dur�e entre deux �pisodes cons�cutifs est inf�rieure ou �gale � 31 jours alors on consid�re qu'il s'agit d'un 
m�me �pisode de ch�mage (agr�gation des deux �pisodes de ch�mage en un seul). Cette convention ne joue que sur le 1er
et le 3eme calcul!
*/

/* 1. On repart du fichier historique des DE et on le circonscrit au champ des DE sans formation (table "Primoforma_poec_2017_2019_4")  */

proc sql;
create table tab0 as
select id_force,ndem,datins,datann,ancien,catregr
from fh.de_tempo
where id_force in (select id_force from DE0117_sans_forma_2014_2022);
quit;
/* 18 164 326 demandes pour 5 121 157 DE (sur la p�riode 2013-2023) */

proc sort data=tab0;by id_force ndem;run;


data tab1;
set tab0;
format date_ref YYMMDD10.;
date_ref=mdy(01,31,2017);
diff_date_entree_datins=date_ref-datins;
run;

data tab2;
set tab1;
where diff_date_entree_datins>=0;
run;

data tab3;
set tab2;
duree_chomage_jours=datann-datins;
run;

/* on compare pour chaque DE, la date d'annulation d'une demande avec la date d'inscription de la demande cons�cutive (s'il y en a!)*/

proc sort data=tab3 out=tab4;by id_force datann;run;

data tab5;
set tab4;
by id_force;
format next_datann YYMMDD10.;
next_datann=lag(datann);
if first.id_force then next_datann=.;
run;


data tab6;
set tab5;
by id_force;
ecart_demandes_jours=datins-next_datann;
if first.id_force then ecart_demandes_jours=.;
run;

data tab7;
set tab6;
by id_force;
if first.id_force then ndem_bis=1;
else ndem_bis+1;
run;

data tab8;
set tab7;
var=0;
if ecart_demandes_jours ne . & ecart_demandes_jours<=31 then var=-1; /**/
run;

data tab9;
set tab8;
ndem_ter=ndem_bis+var;
run;

data tab10;
set tab9;
ndem_2=strip(put(ndem_ter,$2.));
run;

/* 1) calcul de l'anciennet� au ch�mage du DE au 31/01/2017 (en jours)*/
proc means data=tab10 missing noprint;
class id_force ndem_2;
var duree_chomage_jours;
output out=duree_episode_chomage_jours 
sum=duree_episode_chomage_jours;
run;

data duree_episode_chomage_jours (keep=id_force ndem_2 duree_episode_chomage_jours);
set duree_episode_chomage_jours (where=( _type_=3));
run;

data duree_episode_chomage_jours;
set duree_episode_chomage_jours;
ndem_3=input(ndem_2,2.);
run;

proc sort data=duree_episode_chomage_jours;by id_force ndem_3;run;

data duree_episode_chomage_jours_2 (rename=(duree_episode_chomage_jours=anciennete_chomage_j));
set duree_episode_chomage_jours (drop=ndem_3 ndem_2);
by id_force;
if last.id_force then output;
run;

/* ok! */

/*2) calcul de la dur�e totale cumul�e d'inscription au ch�mage du DE au 31/01/2017 (en jours): */
proc means data=duree_episode_chomage_jours missing noprint;
class id_force;
var duree_episode_chomage_jours;
output out=duree_tot_chomage_jours 
sum=duree_tot_chomage_j;
run;

data duree_tot_chomage_jours (keep=id_force duree_tot_chomage_j);
set duree_tot_chomage_jours (where=( _type_=1));
run;


/* 3)nombre d'�pisodes de ch�mage accumul�s au 31/01/2017: */
/* TODO! */

/* on r�unit ces calculs dans une m�me base: */
data duree_chomage_avant_0117;
merge duree_episode_chomage_jours_2 duree_tot_chomage_jours;
run;

/* Et on fait la jointure avec la base principale d'�tude "DE0117_sans_forma_2014_2022": */

proc sql;
create table DE0117_sans_forma_2014_2022_2 as 
select *
from DE0117_sans_forma_2014_2022 as a
left join duree_chomage_avant_0117 as b
on a.id_force=b.id_force;
quit;

/* TODO! s'occuper de la partie MMO pour le groupe de contr�le:
taux de retour � l'emploi post-310117 des DE n'ayant pas suivi de formation
*/
/* On applique la m�me m�thodo qu'avec les DE entr�s en POEC*/

/* Objectif n�4: On souhaiterait maintenant r�cup�rer de l'info dans le fichier MMO sur les retours � l'emploi des DE sans formation;
En particulier, on souhaiterait construire nos premi�re variables d'outcome, du type:
- retour � l'emploi moins d'un an apr�s l'entr�e en POEC;
- retour � l'emploi entre 1 et 2 ans apr�s l'entr�e en POEC;
- retour � l'emploi entre 2 et 3 ans apr�s l'entr�e en POEC;
*/

/* Ci-dessous, on traite successivement les diff�rents mill�simes de fichier MMO (2017 � 2022): */
/* TODO: on pourra faire une macro qui boucle que les 6 ann�es */

%macro codage_retour_emploi2(tab_mmo=,tab_DE_nonformes=,annee=);

/* 1. On s�lectionne les contrats actifs* en A obtenus par des DE entr�s en POEC entre 2017 et 2019: 
*contrats actifs -> dont la date de d�but <=31/12/A et date de fin >= 01/12/A*/

proc sql;
create table contrats_actifs_DE_nonform as
select id_force,L_contrat_sqn,
debutCTT,finCTT,motifRecours,motifRupture,pcsese,DispPolitiquePublique,modeExercice,nature,salaire_base,
siret_af,siret_ut,catjuri_id
from &tab_mmo
where L_Contrat_SQN>0 /* contrat actif au moins 1 jour durant l'ann�e A */
and 
id_force in (select id_force from &tab_DE_nonformes) /* DE non form�s inscrits au ch�mage durant le mois de r�f�rence */
and
secteur_PUBLIC=0 /* on exclue les contrats dans le secteur public*/
and
substr(debutCTT,1,4)=&annee /* s�lection de l'ann�e A de d�but du contrat de travail*/
order by id_force,DebutCTT
;
quit;

/* 3. On applique la convention suivante: on consid�re ici qu'un �pisode d'emploi comme un contrat d'une dur�e effective d'au moins 31 jours.
On calcule donc pour chaque contrat leur dur�e effective et on �limine ceux de moins de 31 jours. */

 /* Conversion des cha�nes de caract�res en format date SAS: */
data contrats_actifs_DE_nonform;
set contrats_actifs_DE_nonform;
debutCTT2=input(debutCTT,yymmdd10.);
finCTT2=input(finCTT,yymmdd10.);
format debutCTT2 yymmdd10.;
format finCTT2 yymmdd10.;
run;

/* Calcul de la dur�e des contrats (en nb de jours) par diff�rence des dates de fin et de d�but de contrat: */
data contrats_actifs_DE_nonform;
set contrats_actifs_DE_nonform;
format date_ref YYMMDD10.;
date_ref=mdy(12,31,2022);
if finCTT2 ne . and debutCTT2 ne . then do;
duree_contrat_j=finCTT2-debutCTT2;
end;
else if debutCTT2 ne . and finCTT2=. then do;
duree_contrat_j=date_ref-debutCTT2;
end;
else do;
duree_contrat_j=.;
end;
run;

/* Suppression des contrats durant moins de 31 jours: */
data contrats_actifs_DE_nonform_2;
set contrats_actifs_DE_nonform;
where duree_contrat_j>=31;
run;

/* 5. On ne garde que les contrats d�but�s au moins 31 jours apr�s la fin de la p�riode de r�f�rence (ici fin janvier 2017): */

data contrats_actifs_DE_nonform_3;
set contrats_actifs_DE_nonform_2;
format date_ref2 YYMMDD10.;
date_ref2=mdy(01,31,2017);

diff_dateCTT_date_ref2=debutCTT2-date_ref2;
run;

data contrats_actifs_DE_nonform_4;
set contrats_actifs_DE_nonform_3;
where diff_dateCTT_date_ref2>31;
run;

/* 6. Lorsque l'on observe plusieurs contrats pour un m�me individu, on ne garde que le premier (ie le 1er contrat
qui a �t� obtenu apr�s la fin de la p�riode de r�f�rence, ici le 31/01/2017); on ne s'int�resse pas ici � la trajectoire des diff�rents contrats qui
ont pu �tre obtenus apr�s la formation mais on se focalise ici seulement sur le premier contrat obtenu apr�s la
formation: */

data contrats_actifs_DE_nonform_5;
set contrats_actifs_DE_nonform_4;
by id_force;
if first.id_force then output;
run;

/* 7. Codage des indicatrices de retour � l'emploi apr�s la fin de la p�riode de r�f�rence (ici le 31/01/2017): 
- retour � l'emploi moins d'un an apr�s l'entr�e en POE;
- retour � l'emploi entre 1 et 2 ans apr�s l'entr�e en POE;
- retour � l'emploi entre 2 et 3 ans apr�s l'entr�e en POE;
*/

data contrats_actifs_DE_nonform_5;
set contrats_actifs_DE_nonform_5;
retour_emploi_moins1an=0;
retour_emploi_entre1_2ans=0;
retour_emploi_entre2_3ans=0;

if diff_dateCTT_date_ref2<=365 then retour_emploi_moins1an=1;
if diff_dateCTT_date_ref2>365 & diff_dateCTT_date_ref2<=730 then retour_emploi_entre1_2ans=1;
if diff_dateCTT_date_ref2>730 & diff_dateCTT_date_ref2<=1095 then retour_emploi_entre2_3ans=1;

run;

%mend;


/* 2017: */
%codage_retour_emploi2(tab_mmo=mmo.Mmo_2_2017_f12,tab_DE_nonformes=DE0117_sans_forma_2014_2022_2,annee="2017");
data contrats_actifs_DE_nonform_2017;
set contrats_actifs_DE_nonform_5;
run;

/* 2018: */
%codage_retour_emploi2(tab_mmo=mmo.Mmo_2_2018_f12,tab_DE_nonformes=DE0117_sans_forma_2014_2022_2,annee="2018");
data contrats_actifs_DE_nonform_2018;
set contrats_actifs_DE_nonform_5;
run;

/* 2019: */
%codage_retour_emploi2(tab_mmo=mmo.Mmo_2_2019_f12,tab_DE_nonformes=DE0117_sans_forma_2014_2022_2,annee="2019");
data contrats_actifs_DE_nonform_2019;
set contrats_actifs_DE_nonform_5;
run;

/* 2020: */
%codage_retour_emploi2(tab_mmo=mmo.Mmo_2_2020_f12,tab_DE_nonformes=DE0117_sans_forma_2014_2022_2,annee="2020");
data contrats_actifs_DE_nonform_2020;
set contrats_actifs_DE_nonform_5;
run;

/* 2021: */
%codage_retour_emploi2(tab_mmo=mmo.Mmo_2_2021_f12,tab_DE_nonformes=DE0117_sans_forma_2014_2022_2,annee="2021");
data contrats_actifs_DE_nonform_2021;
set contrats_actifs_DE_nonform_5;
run;

/* 2022: */
%codage_retour_emploi2(tab_mmo=mmo.Mmo_2_2022_f12,tab_DE_nonformes=DE0117_sans_forma_2014_2022_2,annee="2022");
data contrats_actifs_DE_nonform_2022;
set contrats_actifs_DE_nonform_5;
run;


/* TODO: adapter le code ci-dessous:*/

/* Une fois obtenue une table de premiers contrats obtenus par les b�n�ficiaires de POEC pour chaque ann�e (ann�e d'obtention du contrat),
on peut empiler ces 6 tables et faire une jointure avec la table d'�tude de r�f�rence "Primoforma_poec_2017_2019_5".
*/

/* 1. Concat�nation verticale des 6 tables de contrat (retour � l'emploi des POEC sur la p�riode 2017-2022)*/

data retour_emploi_De0117_sans_forma;
set contrats_actifs_DE_nonform_2017
contrats_actifs_DE_nonform_2018
contrats_actifs_DE_nonform_2019
contrats_actifs_DE_nonform_2020
contrats_actifs_DE_nonform_2021
contrats_actifs_DE_nonform_2022;
run;
/* 6 666 567 contrats d�but�s sur la p�riode 2017-2022 apr�s avoir �t� inscrit au ch�mage  (attention, on peut avoir plusieurs contrats pour un m�me individu!)*/

/* On ne va garder ici que le premier contrat obtenu apr�s le POEC: */
proc sort data=retour_emploi_De0117_sans_forma out=retour_emploi_De0117_sans_forma2 nodupkey;by id_force;run;
/* 2 911 147 premiers retours � l'emploi post-ch�mage en 01/2017.  */

/* Jointure avec la base d'�tude des DE entr�s en POEC sur la p�riode 2017-2019 "De0117_sans_forma_2014_2022_2": */

proc sql;
create table De0117_sans_forma_2014_2022_3 as
select *
from  De0117_sans_forma_2014_2022_2 as a
left join retour_emploi_De0117_sans_forma2 as b
on a.id_force=b.id_force;
quit;
/* 5 121 157 DE inscrits au ch�mage aupr�s de P�le Emploi en janvier 2017 -> retour en emploi sur la p�riode 2017-2022. */

data De0117_sans_forma_2014_2022_3;
set De0117_sans_forma_2014_2022_3;
if retour_emploi_moins1an=. then retour_emploi_moins1an=0;
if retour_emploi_entre1_2ans=. then retour_emploi_entre1_2ans=0;
if retour_emploi_entre2_3ans=. then retour_emploi_entre2_3ans=0;

run;


/* Sauvegarde la base d'�tude portant sur le groupe des non trait�s pour les DE 0117: */




/* Cr�ation de la variable indicatrice de traitement "POE" + sauvegarde :*/

data etude.non_treated_group_0117;
retain id_force POE;
set De0117_sans_forma_2014_2022_3;
POE=0;
run;

/* Concat�nation des bases "treated" et "non_treated": */

data etude.Treated_non_treated_group_0117;
set etude.Treated_group_0117 etude.Non_treated_group_0117;
run;

/* Restriction aux DE ayant retrouv� un emploi dans les 3 ans apr�s le 0117: champ de notre �valuation! */

data etude.base_evaluation_0117;
set etude.Treated_non_treated_group_0117;
where (retour_emploi_moins1an=1) ! (retour_emploi_entre1_2ans=1) ! (retour_emploi_entre2_3ans=1);
run;
/* 2 493 198 DE */

/* D�coupage de la base d'�valuation selon l'horizon de retour � l'emploi: */
data etude.retour_emploi_moins1an_0117 etude.retour_emploi_entre1_2ans_0117 etude.retour_emploi_entre2_3ans_0117;
set etude.base_evaluation_0117;
if retour_emploi_moins1an=1 then output etude.retour_emploi_moins1an_0117; /* 1 538 277 DE*/
if retour_emploi_entre1_2ans=1 then output etude.retour_emploi_entre1_2ans_0117; /* 633 796 DE */
if retour_emploi_entre2_3ans=1 then output etude.retour_emploi_entre2_3ans_0117;/* 321 125 DE */
run;


/***********************************************************************************************/

/* TODO: calculs de variables utiles pour l'analyse: 
�ge, etc.

*/

/* Calcul de l'�ge du DE au 31/01/2017*/

data etude.retour_emploi_moins1an_0117 (drop=date_ref3);
set etude.retour_emploi_moins1an_0117;

/* calcul de l'�ge */
format date_ref3 YYMMDD10.;
date_ref3=mdy(01,31,2017);
age=round((date_ref3-datnais)/365);

run;

data etude.Retour_emploi_entre1_2ans_0117 (drop=date_ref3);
set etude.Retour_emploi_entre1_2ans_0117;

/* calcul de l'�ge */
format date_ref3 YYMMDD10.;
date_ref3=mdy(01,31,2017);
age=round((date_ref3-datnais)/365);

run;

data etude.Retour_emploi_entre2_3ans_0117 (drop=date_ref3);
set etude.Retour_emploi_entre2_3ans_0117;

/* calcul de l'�ge */
format date_ref3 YYMMDD10.;
date_ref3=mdy(01,31,2017);
age=round((date_ref3-datnais)/365);

run;



/* Cr�ation de la table de passage PCS-ESE -> FAP 2009: */

data etude.tab_passage_PCSESE_FAP2009;
input PcsEse $ FAP $;
format PcsEse $4.;
format FAP $5.;
datalines;
111a A0Z00
111f A0Z00
121a A0Z00
121f A0Z00
122a A0Z00
131a A0Z00
131f A0Z00
111d A0Z01
111e A0Z01
121d A0Z01
121e A0Z01
131d A0Z01
131e A0Z01
122b A0Z02
100x A0Z40
691e A0Z40
691b A0Z41
533b A0Z42
691f A0Z42
691a A0Z43
111b A1Z00
121b A1Z00
131b A1Z00
111c A1Z01
121c A1Z01
131c A1Z01
691c A1Z40
631a A1Z41
691d A1Z42
471a A2Z70
471b A2Z70
480a A2Z70
381a A2Z90
381b A2Z90
381c A2Z90
122c A3Z00
692a A3Z40
656a A3Z41
656b A3Z41
656c A3Z41
389c A3Z90
480b A3Z90
671a B0Z20
671b B0Z20
671c B0Z20
671d B0Z20
681a B0Z21
211h B1Z40
621a B1Z40
621b B1Z40
621d B1Z40
621e B1Z40
621f B1Z40
621g B1Z40
211a B2Z40
632a B2Z40
214d B2Z41
632b B2Z41
624d B2Z42
632c B2Z43
211c B2Z44
632e B2Z44
681b B3Z20
211d B4Z41
632f B4Z41
211b B4Z42
632d B4Z42 
632j B4Z42
211e B4Z43
633a B4Z43
211f B4Z44
632g B4Z44
632h B4Z44
621c B5Z40
651a B5Z40
472b B6Z70
211j B6Z71
472c B6Z71
472d B6Z71
472a B6Z72
481a B6Z73
481b B6Z73
312f B7Z90
382b B7Z90
382a B7Z91
382c B7Z91
672a C0Z20
622a C1Z40
622b C1Z40
622c C1Z40
622d C1Z40
622e C1Z40
622f C1Z40
622g C1Z40
473b C2Z70
473c C2Z70
473a C2Z71
482a C2Z80
673a D0Z20
673b D0Z20
628c D1Z40
628d D1Z40
623f D1Z41
623g D1Z41
211g D2Z40
212b D2Z40
623a D2Z40
634b D2Z40
623b D2Z41
623c D2Z42
623d D2Z42
623e D2Z42
673c D3Z20
682a D3Z20
624a D4Z40
624b D4Z40
624c D4Z40
624e D4Z40
624g D4Z40
624f D4Z41
474b D6Z70
474c D6Z70
474a D6Z71
212c D6Z80
212d D6Z80
483a D6Z80
674a E0Z20
674b E0Z21
674c E0Z21
674d E0Z22
674e E0Z23
676e E0Z24
625a E1Z40
626a E1Z40
625c E1Z41
625e E1Z42
625f E1Z42
625g E1Z42
625h E1Z43
626b E1Z43
637a E1Z43
626c E1Z44
479a E1Z46
625b E1Z46
628f E1Z46
628g E1Z47
475a E2Z70
475b E2Z70
485a E2Z70
484a E2Z80
484b E2Z80
675a F0Z20
627a F1Z40
627b F1Z40
627c F1Z40
213a F1Z41
635a F1Z41
675b F2Z20
214a F3Z40
214b F3Z40
627d F3Z41
675c F4Z20
214c F4Z41
627e F4Z41
627f F4Z41
476a F5Z70
476b F5Z70
485b F5Z70
628a G0A40
634d G0A40
628b G0A41
633d G0A41
216c G0A42
633b G0A42
632k G0A43
216b G0B40
634a G0B40
212a G0B41
216a G0B41
633c G0B41
634c G0B41
477b G1Z70
477c G1Z70
477d G1Z70
486a G1Z70
486b G1Z70
486c G1Z70
486d G1Z70
479b G1Z71
486e G1Z80
380a H0Z90
383b H0Z90
384b H0Z90
385b H0Z90
386d H0Z90
386e H0Z90
387e H0Z91
387f H0Z91
387c H0Z92
387d H0Z92
676a J0Z20
676b J0Z20
676c J0Z20
676d J0Z20
652a J1Z40
652b J1Z40
653a J1Z40
487a J1Z80
487b J1Z80
217a J3Z40
526e J3Z40
642a J3Z40
641b J3Z41
643a J3Z42
644a J3Z42
217b J3Z43
218a J3Z43
641a J3Z43
651b J3Z44
654a J3Z44
654b J3Z44
654c J3Z44
655a J4Z40
546a J4Z60
466c J4Z80
477a J4Z80
546d J5Z60
546e J5Z60
546c J5Z61
546b J5Z62
226b J5Z80
466a J5Z80
466b J5Z80
389a J6Z90
451d J6Z90
389b J6Z91
387b J6Z92
685a K0Z20
210x K0Z40
214e K0Z40
214f K0Z40
217d K0Z40
637b K0Z40
637d K0Z40
542a L0Z60
542b L0Z60
543a L1Z60
543b L1Z60
543c L1Z60
313a L2Z60
541a L2Z60
541b L2Z60
541c L2Z60
541d L2Z60
543d L2Z61
543e L2Z61
543f L2Z61
543g L2Z61
543h L2Z61
461a L3Z80
461b L3Z80
461c L3Z80
461e L4Z80
461f L4Z80
461d L4Z81
312c L5Z90
312d L5Z90
372a L5Z90
372b L5Z90
373a L5Z90
373b L5Z90
373c L5Z90
373d L5Z90
372e L5Z91
372c L5Z92
372d L5Z92
232a L6Z00
233a L6Z00
233b L6Z00
233c L6Z00
233d L6Z00
231a L6Z90
371a L6Z90
544a M0Z60
478a M1Z80
478b M1Z81
478c M1Z81
478d M1Z81
388a M2Z90
388c M2Z90
388b M2Z91
388e M2Z92
312e N0Z90
383a N0Z90
384a N0Z90
385a N0Z90
386a N0Z90
386b N0Z90
386c N0Z90
N0Z90 N0Z90
342e N0Z91
342f N0Z91
342g N0Z91
342h N0Z91
522a P0Z60
523a P0Z61
523b P0Z61
523c P0Z61
523d P0Z61
524a P0Z61
524b P0Z61
524c P0Z61
524d P0Z61
533c P0Z61
521a P0Z62
521b P0Z62
451c P1Z80
451e P1Z81
451f P1Z81
451g P1Z81
451h P1Z81
451a P1Z82
451b P1Z82
331a P2Z90
332a P2Z90
332b P2Z90
333b P2Z90
333e P2Z90
333f P2Z90
351a P2Z90
333c P2Z91
333d P2Z91
334a P2Z92
312a P3Z90
312b P3Z90
312g P3Z90
333a P3Z91
531a P4Z60
531c P4Z60
532a P4Z60
532b P4Z60
532c P4Z60
533a P4Z60
531b P4Z61
452a P4Z80
452b P4Z80
545a Q0Z60
545b Q0Z60
545c Q0Z60
545d Q0Z60
467a Q0Z60
467b Q1Z80
467c Q1Z81
467d Q1Z81
376a Q2Z90
376b Q2Z90
376c Q2Z90
376d Q2Z90
226a Q2Z91
376e Q2Z91
376f Q2Z91
551a R0Z60
552a R0Z61
554j R0Z61
219a R1Z06
554a R1Z06
554b R1Z61
554c R1Z61
554d R1Z62
554e R1Z62
554f R1Z62
554g R1Z62
556a R1Z63
553a R1Z66
553b R1Z66
553c R1Z66
554h R1Z66
555a R1Z67
225a R2Z80
463a R2Z80
463b R2Z80
463c R2Z80
463d R2Z80
463e R2Z83
220x R3Z80
222a R3Z80
222b R3Z80
223a R3Z80
223b R3Z80
223c R3Z80
223d R3Z80
223eR3Z80
223f R3Z80
223g R3Z80
223h R3Z80
462a R3Z80
462b R3Z80
462d R3Z80
221a R3Z81
221b R3Z81
462c R3Z82
462e R3Z82
374b R4Z90
374c R4Z90
374d R4Z90
382d R4Z91
383c R4Z91
384c R4Z91
385c R4Z91
387a R4Z91
388d R4Z91
374a R4Z92
226c R4Z93
376g R4Z93
215d S0Z20
683a S0Z20
215b S0Z40
625d S0Z40
636a S0Z40
215c S0Z41
636b S0Z41
215a S0Z42
636c S0Z42
561d S1Z20
636d S1Z40
488a S1Z80
561e S2Z60
561f S2Z60
561a S2Z61
561b S2Z61
561c S2Z61
468a S2Z80
468b S2Z81
224a S3Z00
224b S3Z00
224c S3Z00
224d S3Z00
377a S3Z90
488b S3Z90
217c T0Z60
562a T0Z60
562b T0Z60
563c T1Z60
563b T2A60
563a T2B60
564a T3Z60
534a T3Z61
534b T3Z61
217e T4Z60
525a T4Z60
525b T4Z60
525c T4Z60
684a T4Z60
525d T4Z61
628e T4Z62
684b T4Z62
227c T6Z61
227d T6Z61
564b T6Z61
464a U0Z80
464b U0Z81
375a U0Z90
375b U0Z90
372f U0Z91
425a U0Z91
352a U0Z92
353a U0Z92
353b U1Z80
353c U1Z80
465b U1Z80
637c U1Z80
465c U1Z81
465a U1Z82
354b U1Z91
354c U1Z91
354d U1Z91
354e U1Z91
354f U1Z91
354g U1Z91
352b U1Z92
354a U1Z93
526a V0Z60
526b V0Z60
526c V0Z60
526d V0Z60
431a V1Z80
431b V1Z80
431c V1Z80
431d V1Z80
431f V1Z80
431g V1Z80
431e V1Z81
311a V2Z90
311b V2Z90
344a V2Z90
344b V2Z90
344c V2Z90
311c V2Z91
311e V2Z92
311f V2Z93
344d V2Z93
433a V3Z70
433d V3Z70
433b V3Z71
433c V3Z71
432a V3Z80
432b V3Z80
432c V3Z80
432d V3Z80
311d V3Z90
343a V4Z80
434a V4Z83
434d V4Z83
434e V4Z83
434f V4Z83
434g V4Z83
434b V4Z85
434c V4Z85
227a V5Z00
435a V5Z81
435b V5Z81
424a V5Z82
422d V5Z84
422e V5Z84
421a W0Z80
421b W0Z80
341a W0Z90
422a W0Z90 
422b W0Z90
422c W0Z90
227b W0Z91
341b W0Z91
342a W0Z92
342b W0Z92
342c W0Z92
342d W0Z92
423a W1Z80
423b W1Z80
335a X0Z00
441a X0Z01
441b X0Z01
;
run;


/* Nombre de DE inscrits en janvier 2017 par r�gion (pour Thibaud): */

proc sql;
create table DE0117_reg as
select id_force,region,datins,catregr
from Fh.De_tempo
where 
((datins>="01JAN2017"d) & (datins<="31JAN2017"d)) /* DE qui se sont inscrits � P�le Emploi entre le 01/01/17 et le 31/01/17 */
!
((datins<"01JAN2017"d) & (datann>"01JAN2017"d)) /* DE qui se sont inscrits � P�le Emploi avant le 01/01/17 et qui ont cl�tur� leur demande apr�s le 01/01/17*/
!
((datins<"01JAN2017"d) & (datann=.)) /* DE qui se sont inscrits � P�le Emploi avant le 01/01/17 et qui n'ont pas encore cl�tur� leur demande � ce jour.*/
order by id_force,datins desc 
;
quit;
/* on retient l'�pisode de ch�mage le plus r�cent: */
proc sort data=DE0117_reg nodupkey;by id_force;run;

data DE0117_reg_hors_categE;
set DE0117_reg;
compteur=1;
where catregr ne "5";
run;

proc means data=DE0117_reg_hors_categE noprint missing;
class region;
var compteur;
output out=nb_DE0117_reg sum(compteur)=nb_DE;
run;

data etude.nb_DE0117_reg;
set nb_DE0117_reg;
drop _type_ _freq_;
run;
