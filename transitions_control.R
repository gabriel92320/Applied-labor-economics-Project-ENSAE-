
library(tidyr)
library(dplyr)
library(readxl)
library(haven)

load_data_path <- file.path("C:/Users/Public/Documents/tibo_gab/data/tension_data")
setwd(load_data_path)

#on commence � regarder des donn�es agreg�es � l'�chelle de la r�gion
#et des professions class�es selon la nomenclature FAP 87

tension_data <- read_excel("Dares_donn�es_tensions_2022_.xlsx", sheet=4)

# question est ce que les POEC permettent de faire baisser les tensions dans les r�gions qui en ont besoin ?

load_data_path2 <- file.path("C:/Users/Public/Documents/tibo_gab/data/sas_data")
setwd(load_data_path2)

poec_data <- read_sas("non_treated_group_0117.sas7bdat")

sample <- sample_n(poec_data, 100000)


print(colnames(sample))

#formattage de la date de sortie de POEC
sample$PcsEse <- tolower(sample$PcsEse)


sample %>% count(is.na(PcsEse)| PcsEse=="")
sample %>% count(ROME=="")


sample <- sample %>% 
  filter(!is.na(PcsEse) & PcsEse!="") %>% 
  filter(!is.na(ROME) & ROME!="")

### op�ration fait perdre un peu de donn�es passe de 154 k � 136 k


load_path_data_corres <- file.path("C:/Users/Public/Documents/tibo_gab/data/nomenclature_data")
setwd(load_path_data_corres)
table_correspondance <- 
  read_excel("Table de correspondance PCS-2003, Rome-V3 vers Fap-2009.xls", sheet=2) #,sep="=")

sectors <- table_correspondance %>% 
  select(FAP, `Familles professionnelles`) %>% 
  filter(FAP==substr(FAP,1,1))

table_correspondance<- table_correspondance %>% fill(FAP, `Familles professionnelles`)

table_correspondance<- table_correspondance %>% group_by(FAP, `Familles professionnelles`) %>% 
  fill(ROME, `R�pertoire Op�rationnel des M�tiers et des Emplois`, PCS, `Professions et cat�gories socioprofessionnelles`)



table_correspondance <- unique(
  table_correspondance %>% 
    select(ROME, `R�pertoire Op�rationnel des M�tiers et des Emplois`, PCS, `Professions et cat�gories socioprofessionnelles`)
)

table_correspondance <- table_correspondance %>% 
  filter(!is.na(PCS) & PCS!="") %>% 
  filter(!is.na(ROME) & ROME!="")

library(arrow)

table_correspondance <- write_parquet(table_correspondance,
                                      "table_correspondance.parquet")

#la gestion des espaces est importante
pcs_list <- unique(sample$PcsEse)
pcs_not_found <- c()
for (pcs in pcs_list){
  if (!(pcs %in% table_correspondance$PCS)){
    pcs_not_found <- c(pcs_not_found, pcs)
  }
}

#on remarque qu'il y a parfois trop de d�tail pour la classe ROME 
#avec des codes � 5 chiffres qui n'existent que sous la forme de codes � 6 chiffres tr�s d�taill�s renvoyant� la m�me FAP

rome_list <- unique(sample$ROME)
rome_not_found <- c()
for (rome in rome_list){
  if (!(rome %in% table_correspondance$ROME)){
    rome_not_found <- c(rome_not_found, rome)
  }
}

#proportion de pcs que l'on arrive pas � classer avec la table de passage
sample %>% count(PcsEse %in% pcs_not_found)


# a priori si l'on merge comme �a,
# on devrait obtenir des gens qui ont eu exactement la ROME 
#\intersect pcs qu'ils cherchaient 


poec_data2 <- merge(sample, table_correspondance, 
                    by.x=c("ROME"), by.y= c("ROME"))

#ROME  R�pertoire Op�rationnel des M�tiers et des Emploi PCS 
#D1401 Assistanat commercial                              542a
#not matchable with
#542b	Dactylos, st�nodactylos (sans secr�tariat), op�rateurs de traitement de texte	M1607		Secr�tariat
# alors que c'est la m�me chose

#bonne mani�re de voir les transitions � l'�chelle des FAP
#changement FAP 87 transition professionnelle
#changement FAP adaptation professionnelle

#P0Z	Employ�s administratifs de la fonction publique (cat�gorie C et assimil�s)

#P0Z60	Agents des imp�ts et des douanes
#P0Z61	Employ�s des services au public
#P0Z62	Employ�s de la Poste et des t�l�communications

poec_data2 <- poec_data2 %>% 
  rename(ROME_esp = ROME, PCS_esp = PCS, FAP_esp = FAP,
         ROME_esp_label = `R�pertoire Op�rationnel des M�tiers et des Emplois`,
         PCS_esp_label = `Professions et cat�gories socioprofessionnelles`,
         FAP_esp_label = `Familles professionnelles`)

poec_data2 <- merge(poec_data2, table_correspondance, 
                    by.x=c("PcsEse"), by.y= c("PCS"))
poec_data2 <- poec_data2 %>% 
  rename(ROME_found = ROME, PCS_found = PcsEse, FAP_found = FAP,
         ROME_found_label = `R�pertoire Op�rationnel des M�tiers et des Emplois`,
         PCS_found_label = `Professions et cat�gories socioprofessionnelles`,
         FAP_found_label = `Familles professionnelles`)

poec_data2 <- poec_data2 %>% arrange(id_force)

View(poec_data2[, c("id_force",
                    "ROME_esp_label", "PCS_esp_label", "FAP_esp_label",
                    "ROME_found_label", "PCS_found_label", "FAP_found_label")])


poec_transition <- poec_data2 %>% select(-c("ROME_esp_label", "PCS_esp_label",
                                            "ROME_esp", "PCS_esp",
                                            "ROME_found_label", "PCS_found_label",
                                            "ROME_found", "PCS_found"))
poec_transition <- unique(poec_transition)

View(poec_transition[, c("id_force", "FAP_esp_label", "FAP_found_label")])


# est ce que le POEC est bien cibl� vers les m�tiers en tension ?


#region_habitation est manquante
library(arrow)
load_data_path <- file.path("C:/Users/Public/Documents/tibo_gab/data/tension_data")
setwd(load_data_path)
geo_info <- read_parquet("geo_info.parquet")

poec_transition <- merge(poec_transition, geo_info, by="DEPCOM")

#on d�finit une FAP 87 comme �tant en tension si en moyenne sur 2017-2022
# le coefficient de tension discret est sup�rieur � 4
region_labels <- unique(tension_data[, c("Code r�gion", "Libell� r�gion")])
region_labels  <- as.data.frame(region_labels)  %>% 
  #rename ile de france pour jointure
  mutate(`Libell� r�gion` =
           ifelse(`Libell� r�gion`=="�le-de-France", "Ile-de-France", `Libell� r�gion`))

colnames(sample)

poec_transition <- merge(poec_transition, region_labels, 
                         by.y="Libell� r�gion", by.x ="region_habitation")


metiers_tension <- tension_data %>% 
  filter(as.numeric(Ann�e )>2016) %>% 
  group_by(`Code FAP 87`, `Libell� FAP 87`) %>% 
  summarise(index_tension = mean(as.numeric(`Tension - discret`, na.rm=TRUE))) %>% 
  filter(index_tension >= 4)

metiers_tension_par_reg <- tension_data %>% 
  filter(as.numeric(Ann�e )>2016) %>% 
  group_by(`Code FAP 87`, `Libell� FAP 87`, `Code r�gion`) %>% 
  summarise(index_tension = mean(as.numeric(`Tension - discret`, na.rm=TRUE))) %>% 
  filter(index_tension >= 4)



is_tension <- function(row){
  matching_line <- subset(metiers_tension_par_reg, `Code FAP 87`==row['FAP87_found'],
                          `Code r�gion`==row['Code r�gion'])
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
# les id_force ont �t� d�doubl�s

poec_transition_result <- poec_transition %>% 
  group_by(id_force) %>% 
  mutate(adaptation = is_transition(FAP_esp, FAP_found), 
         transition_occupation = is_transition(FAP87_esp, FAP87_found),
         transition_sector = is_transition(sector_esp, sector_found))


final_poec_transition_data <- unique(
  poec_transition_result[, c("id_force", "FAP_esp_label", "FAP_found_label",
                             "FAP_esp", "FAP_found","FAP87_esp", "FAP87_found",
                             "transition_sector", "transition_occupation", "adaptation",
                             "is_tension", "is_redirige" , "region_habitation",  "Code r�gion" 
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
write_parquet(final_poec_transition_data, "control_transitions.parquet")
