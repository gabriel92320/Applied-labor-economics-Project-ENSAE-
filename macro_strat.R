

library(tidyr)
library(dplyr)
library(readxl)
library(haven)
library(arrow)
load_data_path <- file.path("C:/Users/Public/Documents/tibo_gab/data/tension_data")
setwd(load_data_path)

#on commence � regarder des donn�es agreg�es � l'�chelle de la r�gion
#et des professions class�es selon la nomenclature FAP 87

tension_data <- read_excel("Dares_donn�es_tensions_2022_.xlsx", sheet=4)

load_output_path <- file.path("C:/Users/Public/Documents/tibo_gab/data/data_output")
setwd(load_output_path)
final_poec_transition_data <- read_parquet("poec_transitions.parquet")

#normalisation by the size of the market
#should I use more precise normalization by segmented labour market ?
load_data_path2 <- file.path("C:/Users/Public/Documents/tibo_gab/data/sas_data")
setwd(load_data_path2)
stat_unemployed <- read_sas("nb_de0117_reg.sas7bdat")


stat_unemployed <- tail(stat_unemployed, -1)


# est ce que cela a pour effet une baisse des tensions ?



poec_macro <- final_poec_transition_data[, c("id_force", "annee_entree", "date_fin" ,"duree_formation_heures_redressee", "siret_AF",
                                             "sexe" , "code_postal", "FAP87_found",  "region_habitation",  "Code r�gion"
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
  group_by(FAP87_found, `Code r�gion`, annee_eff) %>% 
  summarise(eff_poec = n())

poec_macro <- merge(poec_macro, stat_unemployed, by.x="Code r�gion", by.y="Region")
poec_macro$eff_poec <- poec_macro$eff_poec/poec_macro$nb_DE


macro_data <- merge(as.data.frame(poec_macro), tension_data, by.x=c("FAP87_found", "Code r�gion", "annee_eff") 
                    , by.y=c("Code FAP 87", "Code r�gion", "Ann�e"))


# est ce que cela a pour effet une baisse des tensions ?

colnames(macro_data)



macro_data <- macro_data %>%
  filter( !is.na(`Lien formation-emploi`) & `Lien formation-emploi`!="n.d.")


m_tens <- lm(data= macro_data, log(Tension)  ~   log(eff_poec) + annee_eff + `Code r�gion` + FAP87_found )

summary(m_tens)

macro_data$`Lien formation-emploi` <- as.numeric(macro_data$`Lien formation-emploi`)
m_skill_tens <- lm(data= macro_data, log(`Lien formation-emploi`) ~ log(eff_poec) +annee_eff + `Code r�gion` + FAP87_found  )

summary(m_skill_tens)


#on essaye diff�rentes sp�cifications temporelles pour trouver un effet












#On voudrait normaliser par un truc plus pr�cis
#demandeurs d'emploi dans cette r�gion qui demandent cette FAP
#capture mieux l'�lasticit� de l'offre




# m_tens_test <- lm(data= macro_data, `Tension` ~ eff_poec +annee_eff  )
# 
# summary(m_tens_test)
# 
# 
# m_skill_tens_test <- lm(data= macro_data, `Lien formation-emploi` ~ eff_poec +annee_eff  )
# 
# summary(m_skill_tens_test)



#panel analysis

library(plm)

#colnames(macro_data)

#print(class(macro_data$`Code r�gion`))
macro_data$code_region <- as.numeric(macro_data$`Code r�gion`)
macro_data_panel <- pdata.frame(macro_data, 
      index = table(index(macro_data[, c("code_region", "annee_eff", "FAP87_found")], useNA = "ifany")))


test <- table(index(macro_data[, c("code_region", "annee_eff", "FAP87_found")], useNA = "ifany"))
View(test)

m_tens <- lm(data= macro_data, Tension ~ eff_poec + `Code r�gion`  )

m_skill_tens <- lm(data= macro_data, `Lien formation-emploi` ~ eff_poec + `Code r�gion`  )


geo_info <- unique(poec_data[, c("DEPCOM", "region_habitation")])
write_parquet(geo_info, "geo_info.parquet")



