library(tidyr)
library(dplyr)
library(readxl)
library(haven)
library(arrow)

load_data_path2 <- file.path("C:/Users/ENSAE05_T_HENNET0")
setwd(load_data_path2)

#etablissements_tot <- read_sas("work_query_for_stetab_31122017_1.sas7bdat")
etablissements_tot2 <- read_sas("table_A21.sas7bdat")

colnames(etablissements_tot2)
etablissements <- etablissements_tot2[, c("A21" ,"EFF_ET", "EFF_TR_ET" ,
  "REGION_ET", "SIRET", "AGE_ENTREPRISE")] %>% 
  filter(EFF_TR_ET!="00" & EFF_TR_ET!="NN")

# etab_gros <- etablissements[, c("A21_ET" , "EFF_TR_ET" ,"REGION_ET", "SIRET")] %>% 
#   filter(EFF_TR_ET!="01" & EFF_TR_ET!="02" & EFF_TR_ET!="03" )

#attention nous avons perdu pas mal de donn�es
# de nos 153 k; plus que 107k
#potentiellement parce que c'est le stock de 2017 d�p�t de bilans ou ouverture



load_data_poec <- file.path("C:/Users/Public/Documents/tibo_gab/data/data_output")
setwd(load_data_poec)

final_poec_transition_data <- read_parquet("poec_transitions.parquet")


#attention ici on ne regarde que les �tablissements qui ont effectivement
#recour au POEC au moins une fois
etab_poec <- merge(final_poec_transition_data, etablissements, by.x="siret_AF", by.y = "SIRET")



# EFF_TR : Taille d'effectif salari�s de l'unit� l�gale
# NN - Effectif non renseign�
# 00 - 0 salari�
# 01 - 1 � 2 salari�s
# 02 - 3 � 5 salari�s
# 03 - 6 � 9 salari�s
# 11 - 10 � 19 salari�s
# 12 - 20 � 49 salari�s
# 21 - 50 � 99 salari�s
# 22 - 100 � 199 salari�s
# 31 - 200 � 249 salari�s
# 32 - 250 � 499 salari�s
# 41 - 500 � 999 salari�s
# 42 - 1 000 � 1 999 salari�s
# 51 - 2 000 � 4 999 salari�s
# 52 - 5 000 � 9 999 salari�s
# 53 - 10 000 salari�s et plus



#on teste ce qui serait notre first stage regression

etab_macro <- etab_poec %>% 
  mutate(annee_fin = substr(date_fin,1,4)) %>% 
  #lag une annee pour l'effet
  mutate(annee_eff = as.numeric(annee_fin)+1) 


etab_macro <- etab_macro[, c("siret_AF","EFF_TR_ET", "EFF_ET", "A21")] %>% 
  group_by(siret_AF, EFF_TR_ET, EFF_ET, A21) %>% 
  summarise(effectif_poec = n(), effectif_poec_relatif = effectif_poec/(EFF_ET+1) )

etab_macro <- unique(etab_macro)


# 
# stat_des <- etab_macro %>% 
#   group_by(EFF_TR_ET) %>% 
#   summarise(eff_poec = sum(effectif_poec), eff_poec_rel = mean(effectif_poec_relatif))
# 
# 
# labels <- c("1 � 2 salari�s","3 � 5 salari�s", "6 � 9 salari�s","10 � 19 salari�s", "20 � 49 salari�s",
# "50 � 99 salari�s", "100 � 199 salari�s", "200 � 249 salari�s",
# "250 � 499 salari�s", "500 � 999 salari�s", "1 000 � 1 999 salari�s",
# "2 000 � 4 999 salari�s", "5 000 � 9 999 salari�s", "10 000 salari�s et plus")
# 
# code_label <- c( "01", "02",
#                  "03", "11", "12", "21",
#                 "22", "31" ,"32" ,"41", "42", "51", "52", "53")
# 
# my_labels <- data.frame(labels, code_label)
# stat_des <- merge(stat_des, my_labels, by.x="EFF_TR_ET", by.y="code_label")
# 
# stat_des_robus <- etab_macro %>% 
#   group_by(EFF_TR_ET, A21) %>% 
#   summarise(eff_poec = sum(effectif_poec), eff_poec_rel = mean(effectif_poec_relatif)) %>% 
#   arrange(A21)
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
# l'utilisent � fond car gros investissement administratif









# maintenant on regarde l'ensemble des �tablissements


#attention ici on en fat plus de diff�rence sur les ann�es
# on regarde le pourcentage par tranche qui ont fait appel au POEC
#on regarde le pourcentage relatif rapport� � la taille

colnames(etab_macro)
#je rajoute plein de z�ros � tous les �tablissements qui n'emploient pas le POEC

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


level_legend = c("0 salari�"  , "1 � 2 salari�s","3 � 5 salari�s" ,        
                "6 � 9 salari�s" ,"10 � 19 salari�s", "20 � 49 salari�s" ,      
              "50 � 99 salari�s","100 � 199 salari�s","200 � 249 salari�s"   ,  
            "250 � 499 salari�s" , "500 � 999 salari�s","1 000 � 1 999 salari�s" ,
          "2 000 � 4 999 salari�s" , "5 000 � 9 999 salari�s",  "10 000 salari�s et plus")
  
library(ggplot2)
stat_des_recours$labels <- factor(stat_des_recours$labels, levels= level_legend)
my_plot <- ggplot(data=stat_des_recours, aes(x = code_label , y=recours, fill= labels))+
  geom_bar(position="dodge", stat="identity")+ 
  labs(title= "Recours au POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Pourcentage de recours")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

#recours selon l'�ge de l'entreprise
# plut�t que sur le crit�re de la taille
# intuition il faut �tre d�j� bien install� administrativement

#on peut construire des tranches d'�ge ou bins d'histogramme

stat_des_recours_age <- etab_macro_2 %>% 
  group_by(AGE_ENTREPRISE) %>% 
  summarise(recours = mean(effectif_poec>1))

unique(stat_des_recours_age$AGE_ENTREPRISE)
level_age = c("- 1 an","1 an"  ,  "2 ans"  , "3 ans",
              "4 ans","5 ans","6 � 9 ans", "10 ans et +")

stat_des_recours_age$AGE_ENTREPRISE <- 
  factor(stat_des_recours_age$AGE_ENTREPRISE, levels= level_age)
my_plot <- ggplot(data=stat_des_recours_age, aes(x = AGE_ENTREPRISE , y=recours))+
  geom_bar(position="dodge", stat="identity")+ 
  labs(title= "Recours au POEC selon la tranche d'entreprise",
       x= "Age de l'entreprise",
       y="Pourcentage de recours")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot


setwd(load_data_poec)
ggsave("Recours au POEC selon la tranche d'entreprise.png",my_plot)


#stats d'effectifs
stat_des_2 <- etab_macro_2 %>% 
  group_by(EFF_TR_ET) %>% 
  summarise(eff_poec = sum(effectif_poec), eff_poec_rel = mean(effectif_poec_relatif))

stat_des_2 <- merge(stat_des_2, my_labels, by.x="EFF_TR_ET", by.y="code_label")

stat_des_2$labels <- factor(stat_des_2$labels, levels= level_legend)

my_plot <- ggplot(data=stat_des_2, aes(x = code_label , y=eff_poec, fill= labels))+
  geom_bar(position="dodge", stat="identity")+ 
  labs(title= "Embauches POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Embauches POEC bruts")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

ggsave("Embauches POEC selon la tranche d'entreprise.png",my_plot)


my_plot <- ggplot(data=stat_des_2, aes(x = code_label , y=eff_poec_rel, fill= labels))+
  geom_bar(position="dodge", stat="identity")+ 
  labs(title= "Recours au POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Embauches POEC relatif � l'emploi total")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

ggsave("Embauches POEC relatif � l'emploi total.png",my_plot)


# r�sultat mitig�s
#il ne semble pas y avoir une p�n�tration plus grande du POEC
#parmi les grosses entreprises
#on regarde si c'est la m�me chose une fois ajust� par secteur
#on regarde typiquement un seul secteur

stat_des_robus_2 <- etab_macro_2 %>% 
  group_by(EFF_TR_ET, A21) %>% 
  summarise(eff_poec = sum(effectif_poec), eff_poec_rel = mean(effectif_poec_relatif))


stat_des_robus_2 <-  stat_des_robus_2 %>% 
  arrange(A21)

stat_count <- stat_des_robus_2 %>% 
  group_by(A21) %>% 
  summarise(count=sum(eff_poec))

#on s�lectionne les secteurs avec le plus de POEC
stat_count %>% 
  filter(count>5000) %>% 
  select(A21)

stat_des_robus_2$A21 <- factor(stat_des_robus_2$A21)

my_plot <- ggplot(data=stat_des_robus_2, aes(x = EFF_TR_ET, y=eff_poec, group=A21, color = A21))+
  geom_point(shape =3)+
  geom_line(linetype = "dashed")+
  labs(title= "Recours au POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Embauches POEC brutes")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

#cela permet d'identifier les secteurs o� le POEC
# est une v�ritable moyen d'embauches

print(unique(stat_des_robus_2$A21))

my_plot <- ggplot(data=stat_des_robus_2 %>% 
                    filter(A21 %in%
                             c( "C" , "I", "Q",   
                                "N", "G", "H","J"))
                  , aes(x = EFF_TR_ET, y=eff_poec_rel, group=A21, color = A21))+
  geom_point(shape =3)+
  geom_line(linetype = "dashed")+
  labs(title= "Recours au POEC selon la tranche d'entreprise",
       x= "Tranche d'entreprise",
       y="Embauches POEC relatif � l'emploi total")+
  theme(axis.text.x=element_text(angle= 45, hjust=1))

my_plot

ggsave("Embauches POEC relatif � l'emploi total par secteur d'acitivit� A21.png",my_plot)


#Estimation de la first stage regression


# attention maintenant on regarde bien par FAP87_found et r�gion
# r�agr�ge selon ces cat�gories les POEC counts

etab_macro_final <- etab_macro_2 %>% 
  filter(effectif_poec >0)

etab_macro_final <- merge(etab_macro_final, final_poec_transition_data_2, 
                          by= "SIRET")



colnames(etab_macro_2)


View(etab_macro_2 %>% 
  filter(A21=="N" & effectif_poec>0) %>% 
    top_n(100))




m_taille <- lm(data= etab_macro, 
               effectif_poec  ~ EFF_ET)

summary(m_taille)

library(ggplot2)

ggplot(data=etab_macro, aes(y= effectif_poec , x=EFF_ET))+
  geom_point()+
  geom_smooth(method="lm", se=FALSE)+
  labs(title="Scatterplot avec droite de r�gression",
       x= "taille de l'entreprise",
       y="recours poec")


m_taille_relative <- lm(data= etab_macro, 
               effectif_poec  ~ EFF_ET)

ggplot(data=etab_macro, aes(y= effectif_poec_relatif , x=EFF_ET))+
  geom_point()+
  geom_smooth(method="lm", se=FALSE)+
  labs(title="Scatterplot avec droite de r�gression",
       x= "taille de l'entreprise",
       y="recours poec")


summary(m_taille_relative)




