
library(tidyr)
library(dplyr)
library(readxl)
library(haven)
library(arrow)

load_data_path2 <- file.path("C:/Users/ENSAE05_T_HENNET0")
setwd(load_data_path2)

mmo_data <- read_sas("aggregated_data.sas7bdat")



#on trouve qu'il y a 38 M de contrats
# donc tous les contrats en France en 2019
#on suppose que la composition d'âge et de taille des établissements
#n'a pas significativement changé

mmo_data %>% 
  summarise(contracts = sum(nombre_de_lignes))

etablissements_tot2 <- read_sas("table_A21.sas7bdat")

colnames(etablissements_tot2)
etablissements <- etablissements_tot2[, c("A21" ,"EFF_ET", "EFF_TR_ET" ,
                                          "REGION_ET", "SIRET", "AGE_ENTREPRISE")] %>% 
  filter(EFF_TR_ET!="00" & EFF_TR_ET!="NN")


test <- sample_n(mmo_data_merged, 1000)
mmo_data_merged <- merge(mmo_data, etablissements, by.x="siret_AF", by.y="SIRET")





library(arrow)
load_data_path2 <- file.path("C:/Users/Public/Documents/tibo_gab/data/data_output")
setwd(load_data_path2)
table_correspondance <- read_parquet("table_correspondance.parquet")


mmo_data_merged2 <- merge(mmo_data_merged, table_correspondance, 
                    by.x="PcsEse", by.y= "PCS")

mmo_data_merged2 <- mmo_data_merged2 %>% 
  mutate(FAP87 = substr(FAP,1,3), 
         sector = substr(FAP,1,1),
         EFF_ET_TRS = substr(EFF_TR_ET,1,1)
  )

unique(stat_des_recours_age$AGE_ENTREPRISE)


stat_reg_fap <- mmo_data_merged2 %>% 
  group_by(FAP87, REGION_ET) %>% 
  summarise(eff_et_moy = mean(EFF_ET))


level_age = c("- 1 an","1 an"  ,  "2 ans"  , "3 ans",
              "4 ans","5 ans","6 à 9 ans", "10 ans et +")

age_num = c(0, 1 ,2 , 3, 4, 5, 7.5, 12)
table_age <- data.frame(level_age, age_num)

mmo_data_merged2 <- merge(mmo_data_merged2, table_age, by.x= "AGE_ENTREPRISE", by.y= "level_age")

stat_reg_fap <- mmo_data_merged2 %>% 
  group_by(FAP87, REGION_ET) %>% 
  summarise(eff_et_moy = mean(EFF_ET), age_moy = mean(age_num))


# load_data_path2 <- file.path("C:/Users/Public/Documents/tibo_gab/data/sas_data")
# setwd(load_data_path2)
# stat_unemployed <- read_sas("nb_de0117_reg.sas7bdat")
# 
# 
# stat_unemployed <- tail(stat_unemployed, -1)







poec_1st_reg <- merge(stat_reg_fap, poec_macro_precis,  
          by.y=c("FAP87_found", "Code région"), by.x = c("FAP87", "REGION_ET"))

# poec_1st_reg <- poec_1st_reg %>% 
#   filter(as.numeric(REGION_ET)>10)

m_1st <- lm(data= macro_IV, 
               log(eff_poec)  ~ eff_et_moy + age_moy + REGION_ET + FAP87+ annee_fin_lag1 )

summary(m_1st)
macro_IV$X_hat <- predict(m_1st)
second_stage <-  lm(data=macro_IV, 
                    log(Tension) ~ X_hat +REGION_ET + FAP87 + annee_fin_lag1  )


summary(second_stage)

m_rd <- lm(data=macro_IV, 
           log(Tension) ~ eff_et_moy +REGION_ET + FAP87 + annee_fin_lag1   )


summary(m_rd)

# 
# stat_reg_fap2 <- mmo_data_merged2 %>% 
#   group_by(FAP87, REGION_ET) %>% 
#   summarise(prop_table = prop.table(table(AGE_ENTREPRISE)))


## IV estimation

colnames(macro_data2_bis)
colnames(poec_1st_reg)
macro_data2_bis <- macro_data_lag1[, c(
  "FAP87_found" ,"Code région", "annee_fin_lag1",                                           
  "eff_poec" ,  "Libellé FAP 87" , "Libellé région" ,                                     
  "Tension" , "Lien formation-emploi" , "Lien formation-emploi - discret")]

macro_IV <- merge(stat_reg_fap, macro_data2_bis,  
    by.y= c("FAP87_found", "Code région"), by.x = c("FAP87", "REGION_ET"))
library(AER)


m_IV_1 <-  ivreg( 
log(Tension) ~  log(eff_poec) + REGION_ET + FAP87 + annee_fin_lag1| eff_et_moy + age_moy + REGION_ET + FAP87+ annee_fin_lag1,
data= macro_IV)


m_IV_s_1 <-  ivreg( 
  log(`Lien formation-emploi`) ~  log(eff_poec) + REGION_ET + FAP87 + annee_fin_lag1| eff_et_moy + age_moy + REGION_ET + FAP87+ annee_fin_lag1,
  data= macro_IV)


macro_IV <- merge(stat_reg_fap, macro_data_lag2[, c(
  "FAP87_found" ,"Code région", "annee_fin_lag2",                                           
  "eff_poec" ,  "Libellé FAP 87" , "Libellé région" ,                                     
  "Tension" , "Lien formation-emploi" , "Lien formation-emploi - discret")],  
                  by.y= c("FAP87_found", "Code région"), by.x = c("FAP87", "REGION_ET"))
m_IV_2 <-  ivreg( 
  log(Tension) ~   log(eff_poec) + REGION_ET + FAP87 + annee_fin_lag2|
    eff_et_moy + age_moy + REGION_ET + FAP87+ annee_fin_lag2,
  data= macro_IV)

m_IV_s_2 <-  ivreg( 
  log(`Lien formation-emploi`) ~  log(eff_poec) + REGION_ET + FAP87 + annee_fin_lag2|
    eff_et_moy + age_moy + REGION_ET + FAP87+ annee_fin_lag2,
  data= macro_IV)

macro_IV <- merge(stat_reg_fap, macro_data_robust[, c(
  "FAP87_found" ,"Code région", "annee_fin_robust",                                           
  "eff_poec" ,  "Libellé FAP 87" , "Libellé région" ,                                     
  "Tension" , "Lien formation-emploi" , "Lien formation-emploi - discret")],  
  by.y= c("FAP87_found", "Code région"), by.x = c("FAP87", "REGION_ET"))
m_IV_r <-  ivreg( 
  log(Tension) ~   log(eff_poec) + REGION_ET + FAP87 + annee_fin_robust|
    eff_et_moy + age_moy + REGION_ET + FAP87+ annee_fin_robust,
  data= macro_IV)

m_IV_s_r <-  ivreg( 
  log(`Lien formation-emploi`) ~   log(eff_poec)+ REGION_ET + FAP87 + annee_fin_robust|
    eff_et_moy + age_moy + REGION_ET + FAP87+ annee_fin_robust,
  data= macro_IV)

macro_IV <- merge(stat_reg_fap, macro_data_lag0[, c(
  "FAP87_found" ,"Code région", "annee_fin",                                           
  "eff_poec" ,  "Libellé FAP 87" , "Libellé région" ,                                     
  "Tension" , "Lien formation-emploi" , "Lien formation-emploi - discret")],  
  by.y= c("FAP87_found", "Code région"), by.x = c("FAP87", "REGION_ET"))
m_IV_0 <-  ivreg( 
  log(Tension) ~   log(eff_poec) + REGION_ET + FAP87 + annee_fin|
    eff_et_moy + age_moy + REGION_ET + FAP87+ annee_fin,
  data= macro_IV)

m_IV_s_0 <-  ivreg( 
  log(`Lien formation-emploi`) ~   log(eff_poec) + REGION_ET + FAP87 + annee_fin|
    eff_et_moy + age_moy + REGION_ET + FAP87+ annee_fin,
  data= macro_IV)


table_regression_IV_temp <- stargazer(m_IV_r,  m_IV_0, 
                                      m_IV_1, m_IV_2,
                              type = "html")#, covariate.labels = covariate_labels)
#
table_regression_IV_temp_formation<- stargazer(m_IV_s_r,m_IV_s_0, m_IV_s_1, m_IV_s_2,
                                      type = "html")#, covariate.labels = covariate_labels)

writeLines(table_regression_IV_temp , "table_regression_IV_temp_tens.html")
writeLines(table_regression_IV_temp_formation , "table_regression_IV_temp_formation.html")

#test

table_regression <- stargazer(m_t_1, m_st_1, m_IV_1, m_IV_s_1,
                              type = "html")#, covariate.labels = covariate_labels)
writeLines(table_regression, "table_regression_precis.html")









