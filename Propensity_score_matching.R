

# Applied labor economics Report:


# Dataset importation (format SAS):
library(haven)
library(lmtest)
library(ggplot2)
library(ggpubr)

#library(tidyverse)
library(tibble)
library(dplyr)
library(tidyr)

library(janitor)
library(forcats)
library(stringr)
library(readxl)
# Chargement des packages recommandés:
#library(Matching) # permet de mettre en oeuvre l'appariement sur score de propension;
#library(cobalt) # analyse statistique de la propriété équilibrante du score de propension;


library(marginaleffects)

library(sandwich)

library(MatchIt)

# Chargement de la base d'étude:

# Demendeurs d'emploi inscrits en janvier en 2017 à Pôle Emploi et qui ont retrouvé un emploi moins d'un an après:
Retour_emploi_moins1an_0117<-haven::read_sas(
  data_file = "C:/Users/Public/Documents/tibo_gab/data/sas_data/Retour_emploi_moins1an_0117.sas7bdat")

# Demendeurs d'emploi inscrits en janvier en 2017 à Pôle Emploi et qui ont retrouvé un emploi entre un et deux ans après:
Retour_emploi_entre1_2ans_0117<-haven::read_sas(
  data_file = "C:/Users/Public/Documents/tibo_gab/data/sas_data/Retour_emploi_entre1_2ans_0117.sas7bdat")


# Demendeurs d'emploi inscrits en janvier en 2017 à Pôle Emploi et qui ont retrouvé un emploi entre deux et trois ans après:
Retour_emploi_entre2_3ans_0117<-haven::read_sas(
  data_file = "C:/Users/Public/Documents/tibo_gab/data/sas_data/Retour_emploi_entre2_3ans_0117.sas7bdat")


# Conversion du data.frame en tibble:
Retour_emploi_moins1an_0117_tb <- as_tibble(Retour_emploi_moins1an_0117)
Retour_emploi_entre1_2ans_0117_tb <- as_tibble(Retour_emploi_entre1_2ans_0117)
Retour_emploi_entre2_3ans_0117_tb <- as_tibble(Retour_emploi_entre2_3ans_0117)


# Research question:
# If the jobseeker returns to work, to what extent does the POE program 
# increases the duration of employment?

# The treatment variable: entering in a POE program at date t 
# (over the period 2017-2019);

# The outcome variable: the duration of employment (first job found
# after a POE training).

# Scope of the analysis:
# Jobseekers registered at France Travail at date t who return to work 
# over the period t+1 and t+12 in France.

# This research question is addressed by propensity score matching.
# We will first match each jobseeker entering in a POE training (as 
# first training) at date t in the dataset to a jobseeker not entering
# in POE training at date t (or any other training course since 2014)
# based on a range of covariates (including socio-demographic 
# characteristics, job characteristics, unemployment duration...);

# Important remark: We run the propensity score matching at each date
# t (each month during the periode 2017-2019);

# Propensity score mathing analysis involves 2 steps:

# First step:
# Match each jobseeker entering in a POEC training at date t to a 
# jobseeker not entering in a POEC training at date t based on 
# propensity score, which is calculated based on a range of covariates.

# Second step:
# Check if balance between the treatment group and control group is
# achieved (ie both groups having similar characteristics).
# If balance is achieved, a simple regression analysis with cluster-robust
# standard error can be used to estimate the effect of POEC on
# duration of post-training employment.

# Covariables used to estimate propensity scores:

# Age "age_entree_stage"
# Age (au carré)
# Sexe "sexe"
# Ancienneté (nb de jours au chômage) "anciennete_chomage_j"
# Durée cumulée d'inscription à Pôle Emploi (en jours) "duree_tot_chomage_j"
# QPV/ZUS "qpv"
# ZRR "ZRR" 
# Handicap "travailleur_handicape"
# Expérience (en années)
# Diplôme (5 modalités):Pré-Bac/Bac/Bac+2/Licence/Bac+5 
# Qualification (5 modalités):ouvrier/employé non qualifié/employé
# qualifié/technicien/cadre/inconnue "QUALIF"
# Situation familiale (4 modalités): célibataire/marié/divorcé/veuf "SITMAT"
# Nombre d'enfants "NENF"
# Catégorie d'inscription
# Contrat recherché (CDI/CDD/Saisonnier) "CONTRAT"
# Motif d'inscription: fin de contrat/licenciement/première recherche d'emploi "MOTINS"
# Nationalité: France/UE proche/Autre Aurope/Maghreb/Asie/Afrique subsaharienne/Autre
# ROME 

# Using the matchit function from MatchIt to match each jobseeker "trainee" with a jobseeker ("no trainee") 
# (1 to 1 matching) based on: âge, sexe, ...


# 4 étapes:

# 1) Choix des caractéristiques observables à retenir et estimation du score de propension correspondant;
# 2) Implémentation de la méthode choisie;
# 3) Analyse de la propriété équilibrante du score de propension en réalisant si besoin à nouveau les étapes 1 et 2;
# 4) Estimation de l'effet de la mesure étudiée;


# Sélection des covariables et mise en forme (recodage/regroupement de modalités pour 
# certaines variables catégorielles):

Retour_emploi_moins1an_0117_tb2 <- Retour_emploi_moins1an_0117_tb %>%
                                   filter(!(DIPLOME == '') & !(NIVFOR == '') & !(QUALIF == '0') &
                                            !(CATREGR == '5') & !(Nature %in% c("03","07","08")) &
                                          !(is.na(anciennete_chomage_j)) & !(is.na(duree_tot_chomage_j))) %>%
                                   select(id_force,duree_contrat_j,POE,sexe_fh,age,SITMAT,NENF,ZRR,NATION,
                                          NIVFOR,DIPLOME,QUALIF,
                                          CATREGR,anciennete_chomage_j,duree_tot_chomage_j,
                                          CONTRAT,TEMPS,EXPER,ROME,DEPCOM,PcsEse) %>% 
                                   mutate(POE=factor(POE),
                                          sexe_fh=factor(sexe_fh),
                                          SITMAT=factor(SITMAT),
                                          NENF=factor(NENF),
                                          NIVFOR=factor(NIVFOR),
                                          DIPLOME=factor(DIPLOME),
                                          QUALIF=factor(QUALIF),
                                          CATREGR=factor(CATREGR),
                                          ZRR=factor(ZRR),
                                          NATION=factor(NATION),
                                          CONTRAT=factor(CONTRAT),
                                          TEMPS=factor(TEMPS),
                                          EXPER=factor(EXPER)) %>%
                                   mutate(POE = recode(POE,'1' = 'treated',
                                                       '0'= 'untreated'),
                                          sexe_fh=recode(sexe_fh,
                                                                '1' = 'M',
                                                                '2' = 'F'),
                                          SITMAT=recode(SITMAT,
                                                         'C' = 'Célibataire',
                                                         'D' = 'Divorcé',
                                                        'M' = "Marié",
                                                        'V' = 'Veuf'),
                                          CONTRAT=recode(CONTRAT,
                                                         '1' = 'CDI',
                                                         '2' = 'CDD ou contrat temporaire',
                                                         '3' = 'Contrat saisonnier'),
                                          TEMPS=recode(TEMPS,
                                                       '1' = 'Temps complet',
                                                       '2' = 'Temps partiel')
                                          ) %>%
                                  mutate(NENF = fct_collapse(NENF,
                                                             "4 enfants ou plus" = c("4","5","6","7","8","9")),
                                         NIVFOR = fct_collapse(NIVFOR,
                                                               "Pré-bac" = c("AFS","C12","C3A","CFG","CP4","NV1")),
                                         DIPLOME = fct_collapse(DIPLOME,
                                                                "Non diplômé" = c("N","Z")),
                                         QUALIF = fct_collapse(QUALIF,
                                                               'Ouvrier' = c('1','2','3','4'),
                                                               'Technicien' =c('7','8')),
                                         NATION = fct_collapse(NATION,
                                                               "France" = "01",
                                                               "Union Européenne" = c("11","05","12","97","02","26",
                                                                                      "17","21","92","06","19","90",
                                                                                      "18","14","93","91","15","13",
                                                                                      "24","22","94","98","95","96",
                                                                                      "07"),
                                                               "Maghreb" = c("31","32","33"),
                                                               "Autres pays africains" = c("42","43","44","49"),
                                                               "Asie" = c("51","59"),
                                                               other_level = "Autres pays"),
                                         EXPER = fct_collapse(EXPER,
                                                                "Sans expérience" = "00",
                                                                 other_level = "Avec expérience")
                                         ) %>%
                                  mutate(NENF=recode(NENF,
                                                       '1' = '1 enfant',
                                                       '2' = '2 enfants',
                                                       '3' = "3 enfants",
                                                       ),
                                         
                                         NIVFOR=recode(NIVFOR,
                                                       'NV2' = 'Bac',
                                                       'NV3' = 'Bac+2',
                                                       'NV4' = 'Bac+3 et +4',
                                                       'NV5' = 'Bac+5 et +'),
                                         DIPLOME=recode(DIPLOME,
                                                        'D'='Diplômé'),
                                         QUALIF=recode(QUALIF,
                                                       '5' = 'Employé non qualifié',
                                                       '6' = 'Employé qualifié',
                                                       '9' = 'Cadre')
                                  ) %>%
                                  mutate(ROME2 = str_sub(ROME,1,1))
  

# Création d'une variable catégorielle explicite sur le groupe de métiers recherchés par le DE (nomenclature ROME):
ROME2_vector <- Retour_emploi_moins1an_0117_tb2 %>% pull(ROME2)

Retour_emploi_moins1an_0117_tb2 <- Retour_emploi_moins1an_0117_tb2 %>%
                                  mutate(ROME3 = case_when(
                                    (ROME2_vector == "A") ~ "Agriculture",
                                    (ROME2_vector == "B") ~ "Arts",
                                    (ROME2_vector == "C") ~ "Banque,assurance,immobilier",
                                    (ROME2_vector == "D") ~ "Commerce",
                                    (ROME2_vector == "E") ~ "Communication,média",
                                    (ROME2_vector == "F") ~ "BTP",
                                    (ROME2_vector == "G") ~ "Hôtellerie-restautation,tourisme",
                                    (ROME2_vector == "H") ~ "Industrie",
                                    (ROME2_vector == "I") ~ "Installation,maintenance",
                                    (ROME2_vector == "J") ~ "Santé",
                                    (ROME2_vector == "K") ~ "Service à la personne/collectivité",
                                    (ROME2_vector == "L") ~ "Spectacle",
                                    (ROME2_vector == "M") ~ "Support à l'entreprise",
                                    (ROME2_vector == "N") ~ "Transport,logistique",
                                    TRUE ~ "Autres")
                                  ) %>%
                                  mutate(ROME3=factor(ROME3))

# Création d'une variable de classe d'âge:
Retour_emploi_moins1an_0117_tb2 <- Retour_emploi_moins1an_0117_tb2 %>%
  mutate(classe_age = case_when(
    (age<26) ~ "Moins de 26 ans",
    (age<50) ~ "Entre 26 et 50 ans",
    TRUE ~ "Plus de 50 ans"
  ))

# Récupération des zones d'emploi de l'Insee + appariement avec le code commune:
t.communes_zonages <- readxl::read_excel(path = "C:/Users/Public/Documents/tibo_gab/data/zonages/table-appartenance-geo-communes-23.xlsx",
                                         sheet = "COM",skip = 5)
# Cas particulier des arrondissements:
t.arm_zonages <- readxl::read_excel(path = "C:/Users/Public/Documents/tibo_gab/data/zonages/table-appartenance-geo-communes-23.xlsx",
                                         sheet = "ARM",skip = 5)

# Sélection des variables pertinentes + concaténation:
t.communes_zonages <- t.communes_zonages %>% select(CODGEO,ZE2020)
t.arm_zonages <- t.arm_zonages %>% select(CODGEO,ZE2020)

t.communes_zonages <-rbind(t.communes_zonages,t.arm_zonages)

# Appariement avec la base d'étude sur le code commune:
Retour_emploi_moins1an_0117_tb2 <- Retour_emploi_moins1an_0117_tb2 %>%
        left_join(y = t.communes_zonages,
                  by = c("DEPCOM" = "CODGEO"))

Retour_emploi_moins1an_0117_tb2 <- Retour_emploi_moins1an_0117_tb2 %>%
                                   mutate(classe_age=factor(classe_age),
                                          ZE2020=factor(ZE2020))

# Premières stat des sur les variables retenues:
summary(Retour_emploi_moins1an_0117_tb2)

# Zoom sur certaines anomalies dans les données:

#valeur extrême d'ancienneté au chômage
zoom1 <- Retour_emploi_moins1an_0117_tb2 %>% filter(anciennete_chomage_j ==13698)


# Traitements réalisés (nettoyage):

#exclusion d'observations:
# raison 1: avec une ancienneté au chômage non renseignée:
# raison 2: avec une durée de contrat anormalement élevée (>=2500 jours);
# raison 3: avec un âge incohérent par rapport à leur statut d'actif (pop en âge de travailler: 15-64 ans)

Retour_emploi_moins1an_0117_tb2 <- Retour_emploi_moins1an_0117_tb2 %>% filter((!is.na(ZE2020)) &
                                                                              (duree_contrat_j<2500) &
                                                                              (age>14) & (age<65))

##########################################################################################################

# Répartition de la variable de traitement POE:

poe <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(POE)


# Distribution de la variable d'outcome selon la variable de traitement:

graph1 <- Retour_emploi_moins1an_0117_tb2 %>%
  ggplot(aes(x=duree_contrat_j,colour=POE)) +
  geom_density()

graph1


# Matrice de corrélations: TODO

mcor <- cor(Retour_emploi_moins1an_0117_tb2 %>% select(duree_contrat_j,age,anciennete_chomage_j,duree_tot_chomage_j))

mcor

library(corrplot)

corrplot(mcor)


# Tables de contingence (variables qualitatives):

# Sexe:
sexe <- Retour_emploi_moins1an_0117_tb2 %>%
        tabyl(sexe_fh,POE) %>%
        adorn_totals("row") %>%
        adorn_percentages("col") %>%
        adorn_pct_formatting(digits = 1)

# Situation familiale:

sitmat <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(SITMAT,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)

# Nombre d'enfants:

nenf <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(NENF,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)

# Diplôme:

nivfor <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(NIVFOR,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)

#nivfor %>% knitr::kable()

diplome <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(DIPLOME,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)

test <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(DIPLOME,POE)

chisq.test(test)
fisher.test(test)

#qualification:
qualif <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(QUALIF,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)

chisq.test(Retour_emploi_moins1an_0117_tb2 %>%
             tabyl(QUALIF,POE))


# Rajouter les variables suivantes: ZRR, nationalité, lieu d'habitation (zonage?),
# type de contrat de travail recherché, temps de travail associé, motif d'inscription au chômage,
# type de métier recherché (nomenclature ROME), expérience professionnelle...

#ZRR (Zone de Revitalisation rurale):
zrr <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(ZRR,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)

#Nationalité:
nationalite <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(NATION,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)


#ROME:
rome <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(ROME3,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)

#Type de contrat de travail:
contrat <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(CONTRAT,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)

#Temps complet/temps partiel:
temps <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(TEMPS,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)

#Avec/sans expérience professionnelle:
experience <- Retour_emploi_moins1an_0117_tb2 %>%
  tabyl(EXPER,POE) %>%
  adorn_totals("row") %>%
  adorn_percentages("col") %>%
  adorn_pct_formatting(digits = 1)


##########################################################################################################

# A) Implémentation du matching mixte (score de propension + exact)

# 1) Estimation des scores de propension:

# On dispose d'un ensemble de covariables pouvant expliquer la probabilité de rentrer dans une formation POE
# et qui peut influer sur la durée de l'emploi post-POE;

# 1) Régression logistique n°1: on met toutes les covariables

poe.ps.logit1 <- glm(POE ~ sexe_fh  + SITMAT + NENF + ZRR + NATION +
                       NIVFOR + DIPLOME + QUALIF +
                       CONTRAT + TEMPS + EXPER + ROME3 +
                       age + I(age^2)+
                       anciennete_chomage_j + duree_tot_chomage_j,
                     family = binomial(link = "logit"),
                     data = Retour_emploi_moins1an_0117_tb2
)

summary(poe.ps.logit1)
# il apparaît que les covariables NIVFOR, CONTRAT et TEMPS ne sont pas significatives dans ce modèle.

# Régression logistique n°2: on ne retient ici que les covariables significatives dans le 1er Logit. 

poe.ps.logit2 <- glm(POE ~ sexe_fh  + NATION +
                       DIPLOME + QUALIF +
                       EXPER + ROME3 +
                       age + I(age^2)+
                       anciennete_chomage_j,
                     family = binomial(link = "logit"),
                     data = Retour_emploi_moins1an_0117_tb2
)

summary(poe.ps.logit2)
# Ici toutes les covariables sont significatives! 

# sortie Latex des coeffs du logit (en vue du rapport final):
library(stargazer)
stargazer(poe.ps.logit2,type = "latex", out = "logit")

# question: comment rajouter un effet fixe "agence Pôle emploi" dans le logit? TODO;

# On va donc utiliser cet ensemble de covariables pour le matching;

# 2) Matching + assessing the quality of matches:

m.out <- MatchIt::matchit(POE ~ sexe_fh  + NATION +
                             DIPLOME + QUALIF +
                             EXPER + ROME3 +
                             age + I(age^2)+
                             anciennete_chomage_j,data = Retour_emploi_moins1an_0117_tb2,
                           method = "nearest",replace = F,
                           distance = "glm",
                           exact = ~ classe_age + ZE2020,
                           ratio = 3
)

m.out

# Premiers outputs automatiques du matching (assessing the quality of matches):
summary(m.out)

# Graphs automatiques:
plot(summary(m.out))
# Possibilité de customizer les graphs de sortie avec le package "cobalt";) TODO

# Récupération des données post-matching (dataframe):
m.data <- match.data(m.out)

# 3) Estimating thes ATT

# Simple OLS regression (assuming that CIA is verified -> the treatement variable is exogenous after matching..., strong assumption!)
fit1 <- lm(duree_contrat_j ~ POE,data = m.data,weights = weights)

summary(fit1)

# Calcul d'écart-types robustes et clusterisés (cluster-robust standard errors)
coeftest(fit1,vcov. = vcovCL,cluster=~subclass)
# ATT estimé + écart-type + p-value

duree_moy_brute <- Retour_emploi_moins1an_0117_tb2 %>%
                   group_by(POE) %>%
                   summarise(duree_empl_moy = mean(duree_contrat_j,na.rm=T))



# TODO: ce qui reste à faire pour le diapo du 3 mai 2024:

# Mettre en forme "jolie" le graphique balance check (see "assessing-balance" avec le package "cobalt")

library(cobalt)

graph1a <- cobalt::love.plot(POE ~ sexe_fh  + NATION +
                   DIPLOME + QUALIF +
                   EXPER +
                   age + I(age^2)+
                   anciennete_chomage_j,data=Retour_emploi_moins1an_0117_tb2,weights=get.w(m.out),binary="std",
                  thresholds = c(m=.1),
                  var.order = "unadjusted",abs = T)

graph1b <- cobalt::love.plot(POE ~ ROME3,data=Retour_emploi_moins1an_0117_tb2,weights=get.w(m.out),binary="std",
                  thresholds = c(m=.1),
                  var.order = "unadjusted",abs = T)

ggsave("graph1a.pdf",plot = graph1a, path = "C:/Users/Public/Documents/tibo_gab/sorties")
ggsave("graph1b.pdf",plot = graph1b, path = "C:/Users/Public/Documents/tibo_gab/sorties")



# récupérer le graph des densités des durées de contrat (groupe traité/non traité) calculées sur base matchée

graph2a <- ggplot2::ggplot(Retour_emploi_moins1an_0117_tb2, aes(x=duree_contrat_j,colour=POE)) +
  geom_density()+
  labs(x="Durée du contrat (en jours)")+
  theme_minimal()


graph2b <- ggplot2::ggplot(m.data, aes(x=duree_contrat_j,colour=POE)) +
  geom_density()+
  labs(x="Durée du contrat (en jours)")+
  theme_minimal()

ggsave("graph2a.pdf",plot = graph2a, path = "C:/Users/Public/Documents/tibo_gab/sorties")
ggsave("graph2b.pdf",plot = graph2b, path = "C:/Users/Public/Documents/tibo_gab/sorties")


# Créer le dataframe faisant le passage entre la FAP et la PCS, merger avec la base d'étude, créer l'indicatrice
# "métier en tension" et refaire le matching exact sur cette variable et calculer les ATT correspondant pour chaque
# modalité de la variable; compléter le tableau dans le beamer ;)


# ATT selon le sexe: 
m.out_sexe <- MatchIt::matchit(POE ~ sexe_fh  + NATION +
                            DIPLOME + QUALIF +
                            EXPER + ROME3 +
                            age + I(age^2)+
                            anciennete_chomage_j,data = Retour_emploi_moins1an_0117_tb2,
                          method = "nearest",replace = F,
                          distance = "glm",
                          exact = ~ classe_age + ZE2020+sexe_fh,
                          ratio = 3
)

m.out_sexe

# Récupération des données post-matching (dataframe):
m.data_sexe <- match.data(m.out_sexe)

m.data_male <- m.data_sexe %>% filter(sexe_fh=="M")
m.data_female <- m.data_sexe %>% filter(sexe_fh=="F")

# 3) Estimating thes ATT

# Simple OLS regression (assuming that CIA is verified -> the treatement variable is exogenous after matching..., strong assumption!)
fit1_male <- lm(duree_contrat_j ~ POE,data = m.data_male,weights = weights)
summary(fit1_male)

fit1_female <- lm(duree_contrat_j ~ POE,data = m.data_female,weights = weights)
summary(fit1_female)


# Calcul d'écart-types robustes et clusterisés (cluster-robust standard errors)
coeftest(fit1_male,vcov. = vcovCL,cluster=~subclass)
coeftest(fit1_female,vcov. = vcovCL,cluster=~subclass)

# ATT estimé + écart-type + p-value

duree_moy_brute_f <- Retour_emploi_moins1an_0117_tb2 %>% filter(sexe_fh=='F') %>%
  group_by(POE) %>%
  summarise(duree_empl_moy = mean(duree_contrat_j,na.rm=T))

duree_moy_brute_m <- Retour_emploi_moins1an_0117_tb2 %>% filter(sexe_fh=='M') %>%
  group_by(POE) %>%
  summarise(duree_empl_moy = mean(duree_contrat_j,na.rm=T))





# ATT selon le type de métier (métiers "en tension" vs métiers pas "en tension": 

# Création de l'indicatrice "métier en tension":

# Récupération de la table de passage PCE_ESE -> FAP 2009:

tab_passage_pcsese_fap2009<-haven::read_sas(
  data_file = "C:/Users/Public/Documents/tibo_gab/data/sas_data/tab_passage_pcsese_fap2009.sas7bdat")
# Conversion du data.frame en tibble:
tab_passage_pcsese_fap2009_tb <- as_tibble(tab_passage_pcsese_fap2009) %>% mutate(PcsEse2 = str_to_upper(PcsEse))

# Jointure entre la base d'étude et cette table de passage par PcsEse:
Retour_emploi_moins1an_0117_tb2 <- Retour_emploi_moins1an_0117_tb2 %>%
  left_join(y = tab_passage_pcsese_fap2009_tb,
            by = c("PcsEse" = "PcsEse2"))

# On crée l'indicatrice identifiant les métiers "en tension" à partir des codes FAP:

top30_metiers_en_tension_2017 <-c("C2Z71",
                                  "M2Z90",
                                  "D1Z40",
                                  "M2Z91",
                                  "D6Z71",
                                  "B6Z70",
                                  "C2Z70",
                                  "B2Z43",
                                  "G0B40",
                                  "M2Z92",
                                  "D2Z41",
                                  "B6Z72",
                                  "V3Z80",
                                  "G0B41",
                                  "D2Z40",
                                  "L4Z81",
                                  "B6Z73",
                                  "S0Z40",
                                  "B4Z41",
                                  "S0Z41",
                                  "M1Z80",
                                  "F3Z41",
                                  "S1Z80",
                                  "G0A40",
                                  "G0A41",
                                  "S0Z42",
                                  "S1Z40",
                                  "B4Z43",
                                  "T0Z60",
                                  "C1Z40")



Retour_emploi_moins1an_0117_tb3 <- Retour_emploi_moins1an_0117_tb2 %>%
  filter(!(is.na(FAP))) %>%
  mutate(metier_en_tension = case_when(
    (FAP %in% top30_metiers_en_tension_2017) ~ "oui",
    TRUE ~ "non"
  ))



m.out_metier_tension


# Récupération des données post-matching (dataframe):
m.data_metier_tension <- match.data(m.out_metier_tension)

m.data_metier_top30_tension17 <- m.data_metier_tension %>% filter(metier_en_tension=="oui")
m.data_metier_horstop30_tension17 <- m.data_metier_tension %>% filter(metier_en_tension=="non")

# 3) Estimating thes ATT

# Simple OLS regression (assuming that CIA is verified -> the treatement variable is exogenous after matching..., strong assumption!)
fit1_metier_top30_tension17 <- lm(duree_contrat_j ~ POE,data = m.data_metier_top30_tension17,weights = weights)
summary(fit1_metier_top30_tension17)

fit1_metier_horstop30_tension17 <- lm(duree_contrat_j ~ POE,data = m.data_metier_horstop30_tension17,weights = weights)
summary(fit1_metier_horstop30_tension17)


# Calcul d'écart-types robustes et clusterisés (cluster-robust standard errors)
coeftest(fit1_metier_top30_tension17,vcov. = vcovCL,cluster=~subclass)
coeftest(fit1_metier_horstop30_tension17,vcov. = vcovCL,cluster=~subclass)

# ATT estimé + écart-type + p-value

duree_moy_brute_top30_tension17 <- Retour_emploi_moins1an_0117_tb3 %>% filter(metier_en_tension=="oui") %>%
  group_by(POE) %>%
  summarise(duree_empl_moy = mean(duree_contrat_j,na.rm=T))

duree_moy_brute_horstop30_tension17 <- Retour_emploi_moins1an_0117_tb3 %>% filter(metier_en_tension=="non") %>%
  group_by(POE) %>%
  summarise(duree_empl_moy = mean(duree_contrat_j,na.rm=T))












