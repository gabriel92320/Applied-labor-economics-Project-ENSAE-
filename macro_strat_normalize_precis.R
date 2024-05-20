

library(tidyr)
library(dplyr)
library(readxl)
library(haven)
library(arrow)
load_data_path <- file.path("C:/Users/Public/Documents/tibo_gab/data/tension_data")
setwd(load_data_path)

#on commence à regarder des données agregées à l'échelle de la région
#et des professions classées selon la nomenclature FAP 87

tension_data <- read_excel("Dares_données_tensions_2022_.xlsx", sheet=4)

load_output_path <- file.path("C:/Users/Public/Documents/tibo_gab/data/data_output")
setwd(load_output_path)
final_poec_transition_data <- read_parquet("poec_transitions.parquet")

#normalisation by the size of the market
#should I use more precise normalization by segmented labour market ?
#On voudrait normaliser par un truc plus précis
#demandeurs d'emploi dans cette région qui demandent cette FAP
#capture mieux l'élasticité de l'offre
load_data_path2 <- file.path("C:/Users/ENSAE05_T_HENNET0")
setwd(load_data_path2)
stat_unemployed_precis <- read_sas("nb_de0117_reg_rome.sas7bdat")


stat_unemployed_precis <- tail(stat_unemployed_precis, -1)

#il faut convertir au format FAP87


table_correspondance <- read_parquet("table_correspondance.parquet")
stat_unemployed_precis <- merge(stat_unemployed_precis, table_correspondance, 
                    by="ROME")

stat_unemployed_precis <- stat_unemployed_precis %>% 
  mutate(FAP87 = substr(FAP,1, 3))

colnames(stat_unemployed_precis)

stat_unemployed_precis <- stat_unemployed_precis %>% 
  group_by(Region, FAP87) %>% 
  summarise(nb_DE_precis = sum(nb_DE))

stat_unemployed_precis <- stat_unemployed_precis %>% 
  filter(Region!="")

# est ce que cela a pour effet une baisse des tensions ?



poec_macro <- final_poec_transition_data[, c("id_force", "annee_entree", "date_fin" ,"duree_formation_heures_redressee", "siret_AF",
                                             "sexe" , "code_postal", "FAP87_found",  "region_habitation",  "Code région"
)]
poec_macro <- poec_macro %>% 
  mutate(annee_fin = substr(date_fin,1,4),
         #lag une annee pour l'effet
         annee_fin_lag1 = as.numeric(annee_fin)+1,
        #lag deux annees pour l'effet
        annee_fin_lag2 = as.numeric(annee_fin)+2,
        #robustness test lag -1,
        annee_fin_robust = as.numeric(annee_fin)-1)


poec_macro <- poec_macro %>% 
  group_by(FAP87_found, `Code région`, annee_fin_lag1) %>% 
  summarise(eff_poec = n())

colnames(stat_unemployed_precis)

poec_macro_precis <- merge(poec_macro, stat_unemployed_precis, 
             by.x=c("Code région","FAP87_found")  , by.y=c("Region", "FAP87"))
poec_macro_precis$eff_poec <- poec_macro_precis$eff_poec/poec_macro_precis$nb_DE_precis


macro_data_lag1 <- merge(as.data.frame(poec_macro_precis), tension_data, 
                      by.x=c("FAP87_found", "Code région", "annee_fin_lag1") 
                    , by.y=c("Code FAP 87", "Code région", "Année"))


# est ce que cela a pour effet une baisse des tensions ?

macro_data_lag1 <- macro_data_lag1 %>%
  filter( !is.na(`Lien formation-emploi`) & `Lien formation-emploi`!="n.d.")

macro_data_lag1$`Lien formation-emploi` <- as.numeric(macro_data_lag1$`Lien formation-emploi`)
macro_data_lag1$Tension <- as.numeric(macro_data_lag1$Tension)


m_t_1 <- lm(data= macro_data_lag1, log(Tension)  ~   log(eff_poec) + annee_fin_lag1 + `Code région` + FAP87_found )

summary(m_t_1)

m_st_1 <- lm(data= macro_data_lag1, log(`Lien formation-emploi`) ~ log(eff_poec) +annee_fin_lag1 + `Code région` + FAP87_found  )

summary(m_st_1)


#on essaye différentes spécifications temporelles pour trouver un effet

poec_macro_precis$annee_fin <- poec_macro_precis$annee_fin_lag1 -1
poec_macro_precis$annee_fin_lag2 <- poec_macro_precis$annee_fin_lag1 +1
poec_macro_precis$annee_fin_robust <- poec_macro_precis$annee_fin_lag1 -2

macro_data_lag0 <- merge(as.data.frame(poec_macro_precis), tension_data, 
                      by.x=c("FAP87_found", "Code région", "annee_fin") 
                      , by.y=c("Code FAP 87", "Code région", "Année"))
macro_data_lag0 <- macro_data_lag0 %>%
  filter( !is.na(`Lien formation-emploi`) & `Lien formation-emploi`!="n.d.")
macro_data_lag0$`Lien formation-emploi` <- as.numeric(macro_data_lag0$`Lien formation-emploi`)
macro_data_lag0$Tension <- as.numeric(macro_data_lag0$Tension)


m_t_0 <- lm(data= macro_data_lag0, log(`Tension`)  ~   log(eff_poec) + annee_fin + `Code région` + FAP87_found )

m_st_0 <- lm(data= macro_data_lag0, log(`Lien formation-emploi`) ~ log(eff_poec) +annee_fin + `Code région` + FAP87_found  )


macro_data_lag2 <- merge(as.data.frame(poec_macro_precis), tension_data, 
                         by.x=c("FAP87_found", "Code région", "annee_fin_lag2") 
                         , by.y=c("Code FAP 87", "Code région", "Année"))
macro_data_lag2 <- macro_data_lag2 %>%
  filter( !is.na(`Lien formation-emploi`) & `Lien formation-emploi`!="n.d.")
macro_data_lag2$`Lien formation-emploi` <- as.numeric(macro_data_lag2$`Lien formation-emploi`)
macro_data_lag2$Tension <- as.numeric(macro_data_lag2$Tension)


m_t_2 <- lm(data= macro_data_lag2, log(`Tension`)  ~   log(eff_poec) + annee_fin_lag2 + `Code région` + FAP87_found )

m_st_2 <- lm(data= macro_data_lag2, log(`Lien formation-emploi`) ~ log(eff_poec) +annee_fin_lag2 + `Code région` + FAP87_found  )

macro_data_robust <- merge(as.data.frame(poec_macro_precis), tension_data, 
                         by.x=c("FAP87_found", "Code région", "annee_fin_robust") 
                         , by.y=c("Code FAP 87", "Code région", "Année"))
macro_data_robust <- macro_data_robust %>%
  filter( !is.na(`Lien formation-emploi`) & `Lien formation-emploi`!="n.d.")
macro_data_robust$`Lien formation-emploi` <- as.numeric(macro_data_robust$`Lien formation-emploi`)
macro_data_robust$Tension <- as.numeric(macro_data_robust$Tension)

m_t_r <- lm(data= macro_data_robust,
            log(`Tension`)  ~   log(eff_poec) + annee_fin_robust + `Code région` + FAP87_found )

m_st_r <- lm(data= macro_data_robust,
             log(`Lien formation-emploi`) ~ log(eff_poec) +annee_fin_robust + `Code région` + FAP87_found  )

setwd(load_data_poec)

table_regression_temp_tens <- stargazer(m_t_r, m_t_0,
                                   m_t_1,m_t_2, 
                              type = "html")#, covariate.labels = covariate_labels)
table_regression_temp_formation <- stargazer(m_st_r, m_st_0,
                                    m_st_1, m_st_2,
                                   type = "html")
writeLines(table_regression_temp_tens, "table_regression_temp_tens.html")
writeLines(table_regression_temp_formation, "table_regression_temp_formation.html")













# m_tens_test <- lm(data= macro_data_2, `Tension` ~ eff_poec +annee_fin_lag1  )
# 
# summary(m_tens_test)
# 
# 
# m_skill_tens_test <- lm(data= macro_data_2, `Lien formation-emploi` ~ eff_poec +annee_fin_lag1  )
# 
# summary(m_skill_tens_test)



#panel analysis

library(plm)

#colnames(macro_data_2)

#print(class(macro_data_2$`Code région`))
macro_data_2$code_region <- as.numeric(macro_data_2$`Code région`)
macro_data_panel <- pdata.frame(macro_data_2, 
      index = table(index(macro_data_2[, c("code_region", "annee_fin_lag1", "FAP87_found")], useNA = "ifany")))


test <- table(index(macro_data_2[, c("code_region", "annee_fin_lag1", "FAP87_found")], useNA = "ifany"))
View(test)

m_tens <- lm(data= macro_data_2, Tension ~ eff_poec + `Code région`  )

m_skill_tens <- lm(data= macro_data_2, `Lien formation-emploi` ~ eff_poec + `Code région`  )


geo_info <- unique(poec_data[, c("DEPCOM", "region_habitation")])
write_parquet(geo_info, "geo_info.parquet")



