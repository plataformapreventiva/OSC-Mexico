rm(list=ls())
source("./utils.R")

###################
# Download
###################
# Descarga Directorio actualizado del SAT 
# Obtenido de http://www.sat.gob.mx/terceros_autorizados/donatarias_donaciones/Paginas/directorio_2017.aspx
con <- "http://www.sat.gob.mx/terceros_autorizados/donatarias_donaciones/Documents/dir163.xls"
organizaciones <- load(con,"directorio_donatarias")

###################
# Clean/Recode
###################
organizaciones <- clean(organizaciones)
#summary(organizaciones)
#glimpse(organizaciones)

###################
# Create Denominaciones Sociales
###################

organizaciones <- organizaciones %>% 
  mutate(razon_social=str_to_lower(razon_social)) %>%
  mutate(tipo_social = str_extract(razon_social,"a(\\s)*(\\.|\\,)*(\\s)*c(\\s)*[(\\.|\\,|:)*(\\s)*]*+$|a(\\s)*(\\.|\\,)*(\\s)*b(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*$|i(\\s)*(\\.|\\,)*(\\s)*a(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*$|f(\\s)*(\\.|\\,)*(\\s)*b(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*$|i(\\s)*(\\.|\\,)*(\\s)*a(\\s)*(\\.|\\,)*(\\s)*s(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*$|s(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*L(\\s)*(\\.|\\,)*(\\s)*$|s(\\s)*(\\.|\\,)*(\\s)*c(\\s)*(\\.|\\,)*(\\s)*$|s(\\s)*(\\.|\\,)*(\\s)*c(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*$")) %>%
  mutate(tipo_social = ifelse(is.na(tipo_social)==T,yes=0,no=tipo_social)) %>%
  mutate(iasp = ifelse(str_detect(razon_social,"i(\\s)*(\\.|\\,)*(\\s)*a(\\s)*(\\.|\\,)*(\\s)*s(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*"),1,0))  %>% 
  mutate(fideicomiso = ifelse(str_detect(razon_social,"[f|f]ideicomiso"),1,0)) %>%
  mutate(ac = ifelse(str_detect(tipo_social,"a(\\s)*(\\.|\\,)*(\\s)*c(\\s)*[(\\.|\\,|\\:)*(\\s)*]*"),1,0)) %>%
  mutate(sc = ifelse(str_detect(tipo_social,"s(\\s)*(\\.|\\,)*(\\s)*c(\\s)*(\\.|\\,)*(\\s)*"),1,0))%>% 
  mutate(scp = ifelse(str_detect(tipo_social,"s(\\s)*(\\.|\\,)*(\\s)*c(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*"),1,0)) %>%
  mutate(abp = ifelse(str_detect(tipo_social,"a(\\s)*(\\.|\\,)*(\\s)*b(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*"),1,0)) %>%
  mutate(fbp = ifelse(str_detect(tipo_social,"f(\\s)*(\\.|\\,)*(\\s)*b(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*"),1,0)) %>%
  mutate(iap = ifelse(str_detect(tipo_social,"i(\\s)*(\\.|\\,)*(\\s)*a(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*"),1,0))  %>% 
  mutate(ibp = ifelse(str_detect(razon_social,"i(\\s)*(\\.|\\,)*(\\s)*b(\\s)*(\\.|\\,)*(\\s)*p(\\s)*(\\.|\\,)*(\\s)*"),1,0))  %>% 
  mutate(banco = ifelse(str_detect(razon_social,"banco"),1,0)) %>%
  mutate(fundacion = ifelse(str_detect(razon_social,"fundaci[o|ó]n"),1,0))

#glimpse(organizaciones)
#summary(organizaciones)

###################
# Batch Geocode
###################
domicilios = organizaciones$domicilio_fiscal
domicilios = paste0(domicilios, ", México")
infile <- "input"

geocode_vector_process(infile,domicilios)
geocoded <- readRDS("input_temp_geocoded.rds")

# Add the latitude and longitude to the main data
organizaciones$lat <- geocoded$lat
organizaciones$long <- geocoded$lat
organizaciones$accuracy <- geocoded$accuracy














###################
# Shameful EDA
###################
organizaciones %>% count(actividad_o_fin,rfc) %>% ggplot(aes(x=actividad_o_fin,fill=actividad_o_fin)) + stat_count() + 
  xlab("Actividad o Fin Autorizado") + theme(legend.position='none')+ylab("Número de Organizaciones") +
  ggsave(file="../img/fin_autorizado.png")

#+ labs(fill="Actividad o Fin Autorizado") +xlab("Act") +ylab("number of subjects") 

tmp<-organizaciones %>% filter(actividad_o_fin!="M") %>% 
  count(ac,sc,scp,abp,iap,fideicomiso,banco,fundacion,iasp,ibp)
knitr::kable(tmp)

organizaciones %>% filter(actividad_o_fin!="M") %>% 
  filter(is.na(ac)==T&is.na(sc)==T&is.na(scp)==T&is.na(abp)==T&is.na(fbp)==T&
           is.na(iap)==T&fideicomiso==0&banco==0&fundacion==0&ibp==0) %>% 
  #View()
  write.csv("temp.csv")


organizaciones %>% filter(actividad_o_fin!="M") %>% count(AC,IAP)%>% View()

organizaciones %>% filter(actividad_o_fin!="M") %>% count(AC,IAPZ)%>% View()

organizaciones %>% filter(actividad_o_fin!="M") %>% count(AC)%>% View()

organizaciones %>% filter(actividad_o_fin!="M" & is.na(AC)) %>% write.csv("acs_135.csv")

# AC's con M y RFC único

data %>% dplyr::filter(`ACTIVIDAD O FIN AUTORIZADO`!="M" & AC==1) %>% count(RFC)
data %>% count(IAP) 

data <- data %>% mutate(tipo_social = str_extract(`DENOMINACIÓN O RAZÓN SOCIAL`,"A(\\s)*(\\.)*(\\s)*C(\\s)*(\\.)*(\\s)*$|A(\\s)*(\\.)*(\\s)*B(\\s)*(\\.)*(\\s)*P(\\s)*(\\.)*(\\s)*$|I(\\s)*(\\.)*(\\s)*A(\\s)*(\\.)*(\\s)*P(\\s)*(\\.)*(\\s)*$|F(\\s)*(\\.)*(\\s)*B(\\s)*(\\.)*(\\s)*P(\\s)*(\\.)*(\\s)*$|I(\\s)*(\\.)*(\\s)*A(\\s)*(\\.)*(\\s)*S(\\s)*(\\.)*(\\s)*P(\\s)*(\\.)*(\\s)*$|S(\\s)*(\\.)*(\\s)*P(\\s)*(\\.)*(\\s)*L(\\s)*(\\.)*(\\s)*$|S(\\s)*(\\.)*(\\s)*C(\\s)*(\\.)*(\\s)*$|S(\\s)*(\\.)*(\\s)*C(\\s)*(\\.)*(\\s)*P(\\s)*(\\.)*(\\s)*$")) %>% 
  mutate(AC = ifelse(str_detect(tipo_social,"A(\\s)*(\\.)*(\\s)*C(\\s)*(\\.)*(\\s)*"),1,0))%>% 
  mutate(VIVIENDA = ifelse(str_detect(`OBJETO SOCIAL AUTORIZADO`,"VIVIENDA|TECHO|CASA"),1,0))


data %>% count(tipo_social) %>% View()
data %>% filter(is.na(tipo_social)==TRUE) %>%count(`DENOMINACIÓN O RAZÓN SOCIAL`) %>% View()


# AC's
# 9866
data %>% filter(grepl("A(\\s)*\\.(\\s)*C(\\s)*\\.(\\s)*$",`DENOMINACIÓN O RAZÓN SOCIAL`,ignore.case = TRUE)) %>% 
  select(`DENOMINACIÓN O RAZÓN SOCIAL`)

# Sin M 7,329
data %>% filter(grepl("A(\\s)*\\.(\\s)*C(\\s)*\\.(\\s)*$",`DENOMINACIÓN O RAZÓN SOCIAL`,ignore.case = TRUE)) %>% 
  filter(`ACTIVIDAD O FIN AUTORIZADO`!="M")

data %>% count(RFC)

data %>% count(`DENOMINACIÓN O RAZÓN SOCIAL`) %>% arrange(-n)

# https://radishlab.com/2016/09/using-carto-for-creating-data-driven-web-pages/