library(tidyr)
library(dplyr)
library(readxl)
library(haven)

# question est ce que les POEC permettent de faire baisser les tensions dans les régions qui en ont besoin ?

load_data_path2 <- file.path("C:/Users/Public/Documents/tibo_gab/data/sas_data")
setwd(load_data_path2)

poec_data <- read_sas("base_etude_treated_group.sas7bdat")




#formattage de la date de sortie de POEC
poec_data$mois_an <- format(poec_data$date_fin, "%Y%m")
poec_data$PcsEse <- tolower(poec_data$PcsEse)


colnames(poec_data)

poec_data %>% count(is.na(PcsEse)| PcsEse=="")
poec_data %>% count(ROME=="")

poec_data <- poec_data %>% 
  filter(!is.na(PcsEse) & PcsEse!="") %>% 
  filter(!is.na(ROME) & ROME!="")

### opération fait perdre un peu de données passe de 154 k à 136 k


load_path_data_corres <- file.path("C:/Users/Public/Documents/tibo_gab/data/nomenclature_data")
setwd(load_path_data_corres)
table_correspondance <- 
  read_excel("Table de correspondance PCS-2003, Rome-V3 vers Fap-2009.xls", sheet=2) #,sep="=")

sectors <- table_correspondance %>% 
  select(FAP, `Familles professionnelles`) %>% 
  filter(FAP==substr(FAP,1,1))

table_correspondance<- table_correspondance %>% fill(FAP, `Familles professionnelles`)

table_correspondance<- table_correspondance %>% group_by(FAP, `Familles professionnelles`) %>% 
  fill(ROME, `Répertoire Opérationnel des Métiers et des Emplois`, PCS, `Professions et catégories socioprofessionnelles`)



table_correspondance <- unique(
  table_correspondance %>% 
    select(ROME, `Répertoire Opérationnel des Métiers et des Emplois`, PCS, `Professions et catégories socioprofessionnelles`)
)

table_correspondance <- table_correspondance %>% 
  filter(!is.na(PCS) & PCS!="") %>% 
  filter(!is.na(ROME) & ROME!="")

library(arrow)

table_correspondance <- write_parquet(table_correspondance,
                                      "table_correspondance.parquet")

#la gestion des espaces est importante
pcs_list <- unique(poec_data$PcsEse)
pcs_not_found <- c()
for (pcs in pcs_list){
  if (!(pcs %in% table_correspondance$PCS)){
    pcs_not_found <- c(pcs_not_found, pcs)
  }
}

#on remarque qu'il y a parfois trop de détail pour la classe ROME 
#avec des codes à 5 chiffres qui n'existent que sous la forme de codes à 6 chiffres très détaillés renvoyantà la même FAP

rome_list <- unique(poec_data$ROME)
rome_not_found <- c()
for (rome in rome_list){
  if (!(rome %in% table_correspondance$ROME)){
    rome_not_found <- c(rome_not_found, rome)
  }
}

#proportion de pcs que l'on arrive pas à classer avec la table de passage
poec_data %>% count(PcsEse %in% pcs_not_found)


# a priori si l'on merge comme ça,
# on devrait obtenir des gens qui ont eu exactement la ROME 
#\intersect pcs qu'ils cherchaient 


poec_data2 <- merge(poec_data, table_correspondance, 
                    by.x=c("ROME"), by.y= c("ROME"))

#ROME  Répertoire Opérationnel des Métiers et des Emploi PCS 
#D1401 Assistanat commercial                              542a
#not matchable with
#542b	Dactylos, sténodactylos (sans secrétariat), opérateurs de traitement de texte	M1607		Secrétariat
# alors que c'est la même chose

#bonne manière de voir les transitions à l'échelle des FAP
#changement FAP 87 transition professionnelle
#changement FAP adaptation professionnelle

#P0Z	Employés administratifs de la fonction publique (catégorie C et assimilés)

#P0Z60	Agents des impôts et des douanes
#P0Z61	Employés des services au public
#P0Z62	Employés de la Poste et des télécommunications

poec_data2 <- poec_data2 %>% 
  rename(ROME_esp = ROME, PCS_esp = PCS, FAP_esp = FAP,
         ROME_esp_label = `Répertoire Opérationnel des Métiers et des Emplois`,
         PCS_esp_label = `Professions et catégories socioprofessionnelles`,
         FAP_esp_label = `Familles professionnelles`)

poec_data2 <- merge(poec_data2, table_correspondance, 
                    by.x=c("PcsEse"), by.y= c("PCS"))
poec_data2 <- poec_data2 %>% 
  rename(ROME_found = ROME, PCS_found = PcsEse, FAP_found = FAP,
         ROME_found_label = `Répertoire Opérationnel des Métiers et des Emplois`,
         PCS_found_label = `Professions et catégories socioprofessionnelles`,
         FAP_found_label = `Familles professionnelles`)

poec_data2 <- poec_data2 %>% arrange(id_force)


poec_transition <- poec_data2 %>% select(-c("ROME_esp_label", "PCS_esp_label",
                                            "ROME_esp", "PCS_esp",
                                            "ROME_found_label", "PCS_found_label",
                                            "ROME_found", "PCS_found"))
poec_transition <- unique(poec_transition)


# est ce que le POEC est bien ciblé vers les métiers en tension ?


#on définit une FAP 87 comme étant en tension si en moyenne sur 2017-2022
# le coefficient de tension discret est supérieur à 4
region_labels <- unique(tension_data[, c("Code région", "Libellé région")])
region_labels  <- as.data.frame(region_labels)  %>% 
  #rename ile de france pour jointure
  mutate(`Libellé région` =
           ifelse(`Libellé région`=="Île-de-France", "Ile-de-France", `Libellé région`))

poec_transition <- merge(poec_transition, region_labels, 
                         by.y="Libellé région", by.x ="region_habitation")


metiers_tension <- tension_data %>% 
  filter(as.numeric(Année )>2016) %>% 
  group_by(`Code FAP 87`, `Libellé FAP 87`) %>% 
  summarise(index_tension = mean(as.numeric(`Tension - discret`, na.rm=TRUE))) %>% 
  filter(index_tension >= 4)

metiers_tension_par_reg <- tension_data %>% 
  filter(as.numeric(Année )>2016) %>% 
  group_by(`Code FAP 87`, `Libellé FAP 87`, `Code région`) %>% 
  summarise(index_tension = mean(as.numeric(`Tension - discret`, na.rm=TRUE))) %>% 
  filter(index_tension >= 4)



is_tension <- function(row){
  matching_line <- subset(metiers_tension_par_reg, `Code FAP 87`==row['FAP87_found'],
                          `Code région`==row['Code région'])
  if (nrow(matching_line)>0){
    return(TRUE)
  }
  else{
    return(FALSE)
  }
}

is_redirige <- function(row){
  found <- is_tension(row)
  row['FAP87_found'] <- row['FAP87_esp']
  esp <- is_tension(row)
  return(found & !esp)
}



###


poec_transition <- poec_transition %>% 
  mutate(FAP87_esp = substr(FAP_esp,1,3), 
         FAP87_found = substr(FAP_found,1,3),
         sector_esp = substr(FAP_esp,1,1), 
         sector_found = substr(FAP_found,1,1) 
  )

poec_transition$is_tension <- apply(poec_transition, 1, is_tension)

poec_transition$is_redirige <- apply(poec_transition, 1, is_redirige)


is_transition <- function(FAP_esp, FAP_found){
  n = length(FAP_esp)
  for (i in c(1:n)){
    if (FAP_esp[i]==FAP_found[i]){
      return(FALSE)
    }
    return(TRUE)
  }
}




# comme il ya plusieurs correspondances possibles de FAP
# les id_force ont été dédoublés

poec_transition_result <- poec_transition %>% 
  group_by(id_force) %>% 
  mutate(adaptation = is_transition(FAP_esp, FAP_found), 
         transition_occupation = is_transition(FAP87_esp, FAP87_found),
         transition_sector = is_transition(sector_esp, sector_found))




final_poec_transition_data <- unique(
  poec_transition_result[, c("id_force", "FAP_esp_label", "FAP_found_label","date_fin",
                             "FAP_esp", "FAP_found","transition_sector", "transition_occupation", "adaptation",
                             "is_tension", "is_redirige","siret_AF","FAP87_esp", "FAP87_found",  "region_habitation",  "Code région",
                             "annee_entree", "duree_formation_heures_redressee","objectif_stage" ,
                             "domaine_formation" ,"sexe","age_entree_stage", "code_postal", "niv_diplome_tr",                  
                             "travailleur_handicape"
  )] %>% 
    arrange(id_force) %>% 
    ungroup())



final_poec_transition_data %>% summarise(taux_trans_sector = mean(transition_sector),
                                         taux_trans_occ = mean(transition_occupation),
                                         taux_tension = mean(is_tension),
                                         taux_adaptation = mean(adaptation),
                                         taux_redirige = mean(is_redirige) ) 



library(arrow)
setwd("C:/Users/Public/Documents/tibo_gab/data/data_output")
write_parquet(final_poec_transition_data, "poec_transitions.parquet")



