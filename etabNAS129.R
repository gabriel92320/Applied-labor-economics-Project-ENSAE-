library(tidyr)
library(dplyr)
library(readxl)
library(haven)
library(arrow)

load_data_path2 <- file.path("C:/Users/ENSAE05_T_HENNET0")
setwd(load_data_path2)

#etablissements_tot <- read_sas("work_query_for_stetab_31122017_1.sas7bdat")
etablissements_tot2 <- read_sas("table_NAS129.sas7bdat")

colnames(etablissements_tot2)
etablissements <- etablissements_tot2[, c("NAS129" ,"EFF_ET", "EFF_TR_ET" ,
  "REGION_ET", "SIRET", "AGE_ENTREPRISE")] %>% 
  filter(EFF_TR_ET!="00" & EFF_TR_ET!="NN")

#on tej les intérimaires
etablissements <- etablissements_tot2[, c("NAS129" ,"EFF_ET", "EFF_TR_ET" ,
                        "REGION_ET", "SIRET", "AGE_ENTREPRISE")] %>% 
  filter(EFF_TR_ET!="00" & EFF_TR_ET!="NN" & NAS129!="N78Z")

# etab_gros <- etablissements[, c("A21_ET" , "EFF_TR_ET" ,"REGION_ET", "SIRET")] %>% 
#   filter(EFF_TR_ET!="01" & EFF_TR_ET!="02" & EFF_TR_ET!="03" )

#attention nous avons perdu pas mal de données
# de nos 153 k; plus que 107k
#potentiellement parce que c'est le stock de 2017 dépôt de bilans ou ouverture



load_data_poec <- file.path("C:/Users/Public/Documents/tibo_gab/data/data_output")
setwd(load_data_poec)

final_poec_transition_data <- read_parquet("poec_transitions.parquet")


#attention ici on ne regarde que les établissements qui ont effectivement
#recour au POEC au moins une fois
etab_poec <- merge(final_poec_transition_data, etablissements, by.x="siret_AF", by.y = "SIRET")



# EFF_TR : Taille d'effectif salariés de l'unité légale
# NN - Effectif non renseigné
# 00 - 0 salarié
# 01 - 1 à 2 salariés
# 02 - 3 à 5 salariés
# 03 - 6 à 9 salariés
# 11 - 10 à 19 salariés
# 12 - 20 à 49 salariés
# 21 - 50 à 99 salariés
# 22 - 100 à 199 salariés
# 31 - 200 à 249 salariés
# 32 - 250 à 499 salariés
# 41 - 500 à 999 salariés
# 42 - 1 000 à 1 999 salariés
# 51 - 2 000 à 4 999 salariés
# 52 - 5 000 à 9 999 salariés
# 53 - 10 000 salariés et plus



#on teste ce qui serait notre first stage regression

etab_macro <- etab_poec %>% 
  mutate(annee_fin = substr(date_fin,1,4)) %>% 
  #lag une annee pour l'effet
  mutate(annee_eff = as.numeric(annee_fin)+1) 


etab_macro <- etab_macro[, c("siret_AF","EFF_TR_ET", "EFF_ET", "NAS129")] %>% 
  group_by(siret_AF, EFF_TR_ET, EFF_ET, NAS129) %>% 
  summarise(effectif_poec = n(), effectif_poec_relatif = effectif_poec/(EFF_ET+1) )

etab_macro <- unique(etab_macro)


# 
# stat_des <- etab_macro %>% 
#   group_by(EFF_TR_ET) %>% 
#   summarise(eff_poec = sum(effectif_poec), eff_poec_rel = mean(effectif_poec_relatif))
# 
# 
# labels <- c("1 à 2 salariés","3 à 5 salariés", "6 à 9 salariés","10 à 19 salariés", "20 à 49 salariés",
# "50 à 99 salariés", "100 à 199 salariés", "200 à 249 salariés",
# "250 à 499 salariés", "500 à 999 salariés", "1 000 à 1 999 salariés",
# "2 000 à 4 999 salariés", "5 000 à 9 999 salariés", "10 000 salariés et plus")
# 
# code_label <- c( "01", "02",
#                  "03", "11", "12", "21",
#                 "22", "31" ,"32" ,"41", "42", "51", "52", "53")
# 
# my_labels <- data.frame(labels, code_label)
# stat_des <- merge(stat_des, my_labels, by.x="EFF_TR_ET", by.y="code_label")
# 
# stat_des_robus <- etab_macro %>% 
#   group_by(EFF_TR_ET, NAS129) %>% 
#   summarise(eff_poec = sum(effectif_poec), eff_poec_rel = mean(effectif_poec_relatif)) %>% 
#   arrange(NAS129)
# stat_des_robus <- merge(stat_des_robus, my_labels, by.x="EFF_TR_ET", by.y="code_label")
# 
# 
# 
# library(ggplot2)
# my_plot <- ggplot(data=stat_des, aes(x = code_label , y=eff_poec))+
#   geom_bar(position="dodge", stat="identity")+ 
#   labs(title= "Recours au POEC selon la tranche d'entreprise",
#              x= "Tranche d'entreprise",
#              y="Effectifs de POEC bruts")+
#   theme(legend.text=element_text(angle= 20, hjust=1))
# 
# my_plot
# 
# 
# library(ggplot2)
# my_plot <- ggplot(data=stat_des, aes(x = code_label , y=eff_poec_rel))+
#   geom_bar(position="dodge", stat="identity")+ 
#   labs(title= "Recours au POEC selon la tranche d'entreprise",
#        x= "Tranche d'entreprise",
#        y="Effectifs de POEC bruts")+
#   theme(legend.text=element_text(angle= 20, hjust=1))
# 
# 
# my_plot

#conclusion les petites entreprises qui recourent au POEC
# l'utilisent à fond car gros investissement administratif









# maintenant on regarde l'ensemble des établissements


#attention ici on en fat plus de différence sur les années
# on regarde le pourcentage par tranche qui ont fait appel au POEC
#on regarde le pourcentage relatif rapporté à la taille

colnames(etab_macro)
#je rajoute plein de zéros à tous les établissements qui n'emploient pas le POEC

etab_macro_2 <- etab_macro %>% 
  rename(SIRET= siret_AF)

colnames(etablissements)


etab_macro_2 <- left_join(etablissements, etab_macro_2)

etab_macro_2 <- etab_macro_2 %>% 
  mutate(effectif_poec= ifelse(is.na(effectif_poec), 0, effectif_poec),
  effectif_poec_relatif= ifelse(is.na(effectif_poec_relatif), 0, effectif_poec_relatif))


#porucentage d'entreprises de la tranche qui ont recours au POEC

stat_des_recours <- etab_macro_2 %>% 
  group_by(EFF_TR_ET) %>% 
  summarise(recours = mean(effectif_poec>1))
stat_des_recours <- merge(stat_des_recours, my_labels, by.x="EFF_TR_ET", by.y="code_label")


level_legend = c("0 salarié"  , "1 à 2 salariés","3 à 5 salariés" ,        
                "6 à 9 salariés" ,"10 à 19 salariés", "20 à 49 salariés" ,      
              "50 à 99 salariés","100 à 199 salariés","200 à 249 salariés"   ,  
            "250 à 499 salariés" , "500 à 999 salariés","1 000 à 1 999 salariés" ,
          "2 000 à 4 999 salariés" , "5 000 à 9 999 salariés",  "10 000 salariés et plus")
  
library(ggplot2)
stat_des_recours$labels <- factor(stat_des_recours$labels, levels= level_legend)
my_plot <- ggplot(data=stat_des_recours, aes(x = code_label , y=recours, fill= labels))+
  geom_bar(position="dodge", stat="identity")+ 
  labs(title= "Recours au POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Pourcentage de recours")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

#recours selon l'âge de l'entreprise
# plutôt que sur le critère de la taille
# intuition il faut être déjà bien installé administrativement

#on peut construire des tranches d'âge ou bins d'histogramme

stat_des_recours_age <- etab_macro_2 %>% 
  group_by(AGE_ENTREPRISE) %>% 
  summarise(recours = mean(effectif_poec>1),
            eff_poec = sum(effectif_poec),
            eff_poec_rel = mean(effectif_poec_relatif))

unique(stat_des_recours_age$AGE_ENTREPRISE)
level_age = c("- 1 an","1 an"  ,  "2 ans"  , "3 ans",
              "4 ans","5 ans","6 à 9 ans", "10 ans et +")

stat_des_recours_age$AGE_ENTREPRISE <- 
  factor(stat_des_recours_age$AGE_ENTREPRISE, levels= level_age)
my_plot <- ggplot(data=stat_des_recours_age, aes(x = AGE_ENTREPRISE , y=recours))+
  geom_bar(position="dodge", stat="identity", fill="skyblue")+ 
  labs(title= "Pourcentage de recours de POEC selon la tranche d'âge de l'entreprise",
       x= "Age de l'entreprise",
       y="Pourcentage de recours")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot


setwd(load_data_poec)
ggsave("Recours au POEC selon la tranche d'âge.png",my_plot
       , width=6, height=4, units="in")

# effectifs en nombre âge
my_plot <- ggplot(data=stat_des_recours_age, aes(x = AGE_ENTREPRISE  , y=eff_poec_rel))+
  geom_bar(position="dodge", stat="identity", fill="skyblue")+ 
  labs(title= "Embauches POEC selon l'âge de l'entreprise",
       x= "Tranche d'âge",
       y="Embauches POEC relatif à l'emploi total")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

ggsave("Embauches relatives POEC selon l'âge de l'entreprise.png",my_plot,
       width=6, height=4, units="in")













#stats d'effectifs
stat_des_2 <- etab_macro_2 %>% 
  group_by(EFF_TR_ET) %>% 
  summarise(eff_poec = sum(effectif_poec),
            eff_poec_rel = mean(effectif_poec_relatif))


stat_des_2 <- merge(stat_des_2, my_labels, by.x="EFF_TR_ET", by.y="code_label")

stat_des_2$labels <- factor(stat_des_2$labels, levels= level_legend)

my_plot <- ggplot(data=stat_des_2, aes(x = code_label , y=eff_poec, fill= labels))+
  geom_bar(position="dodge", stat="identity")+ 
  labs(title= "Embauches POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Embauches POEC bruts")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

ggsave("Embauches POEC selon la tranche d'entreprise.png",my_plot,
       width=10, height=8, units="in")


my_plot <- ggplot(data=stat_des_2, aes(x = code_label , y=eff_poec_rel, fill= labels))+
  geom_bar(position="dodge", stat="identity")+ 
  labs(title= "Recours au POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Embauches POEC relatif à l'emploi total")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

ggsave("Embauches POEC relatif à l'emploi total.png",my_plot,
width=10, height=8, units="in")


# résultat mitigés
#il ne semble pas y avoir une pénétration plus grande du POEC
#parmi les grosses entreprises
#on regarde si c'est la même chose une fois ajusté par secteur
#on regarde typiquement un seul secteur

stat_des_robus_2 <- etab_macro_2 %>% 
  group_by(EFF_TR_ET, NAS129) %>% 
  summarise(eff_poec = sum(effectif_poec), eff_poec_rel = mean(effectif_poec_relatif))


stat_des_robus_2 <-  stat_des_robus_2 %>% 
  arrange(NAS129)

stat_count <- stat_des_robus_2 %>% 
  group_by(NAS129) %>% 
  summarise(count=sum(eff_poec))

#on sélectionne les secteurs avec le plus de POEC
stat_count %>% 
  filter(count>2500) %>% 
  select(NAS129)

stat_des_robus_2$NAS129 <- factor(stat_des_robus_2$NAS129)

my_plot <- ggplot(data=stat_des_robus_2, aes(x = EFF_TR_ET, y=eff_poec, group=NAS129, color = NAS129))+
  geom_point(shape =3)+
  geom_line(linetype = "dashed")+
  labs(title= "Recours au POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Embauches POEC brutes")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

#cela permet d'identifier les secteurs où le POEC
# est une véritable moyen d'embauches

print(unique(stat_des_robus_2$NAS129))

my_plot <- ggplot(data=stat_des_robus_2 %>% 
                    filter(NAS129 %in%
                             c( "F43Z" ,"G46Z",  "G47Z", "H49B",  
                                "H49C", "I56Z", "J62Z", "M71Z",  
                                "N82Z", "Q88Z"))
                  , aes(x = EFF_TR_ET, y=eff_poec_rel, group=NAS129, color = NAS129))+
  geom_point(shape =3)+
  geom_line(linetype = "dashed")+
  labs(title= "Recours au POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Embauches POEC relatif à l'emploi total")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

ggsave("Embauches POEC relatif à l'emploi total par secteur d'acitivité NAS129.png",my_plot,
       width=6, height=4, units="in")









#Estimation de la first stage regression


# attention maintenant on regarde bien par FAP87_found et région
# réagrège selon ces catégories les POEC counts

etab_macro_final <- etab_macro_2 %>% 
  filter(effectif_poec >0)

etab_macro_final <- merge(etab_macro_final, final_poec_transition_data_2, 
                          by= "SIRET")



colnames(etab_macro_2)


View(etab_macro_2 %>% 
  filter(NAS129=="N" & effectif_poec>0) %>% 
    top_n(100))




m_taille <- lm(data= etab_macro, 
               effectif_poec  ~ EFF_ET)

summary(m_taille)

library(ggplot2)

ggplot(data=etab_macro, aes(y= effectif_poec , x=EFF_ET))+
  geom_point()+
  geom_smooth(method="lm", se=FALSE)+
  labs(title="Scatterplot avec droite de régression",
       x= "taille de l'entreprise",
       y="recours poec")


m_taille_relative <- lm(data= etab_macro, 
               effectif_poec  ~ EFF_ET)

ggplot(data=etab_macro, aes(y= effectif_poec_relatif , x=EFF_ET))+
  geom_point()+
  geom_smooth(method="lm", se=FALSE)+
  labs(title="Scatterplot avec droite de régression",
       x= "taille de l'entreprise",
       y="recours poec")


summary(m_taille_relative)


