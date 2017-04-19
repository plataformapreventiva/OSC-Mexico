.packages = c('lubridate', 'magrittr', 'ggvis', 'dplyr', 'tidyr', 'readr', 'rvest',
              'ggplot2', 'stringr', 'ggthemes', 'googleVis', 'shiny', 'tibble', 'vcd', 'vcdExtra',
              'GGally','curl','gdata','readxl','ggmap')

# Install CRAN packages (if not already installed)
.inst <- .packages %in% installed.packages()
if(length(.packages[!.inst]) > 0) install.packages(.packages[!.inst])

# Load packages into session 
lapply(.packages, require, character.only=TRUE)


load <- function(con=con,name){
  "Función que descarga si y sólo si no existe un archivo 
    Si no existe, descarga y guarda el archivo."
  #Check if exists
  if (file.exists(paste0("./",name,".csv"))){
    data <- read_csv(paste0("./",name,".csv"))}
  else{
    #Si no existe la descargamos
    system(paste0("rm", name,".xls"))
    download.file(con,paste0("./",name,".xls"),mode="wb") 
    system(paste0("ssconvert ./",name,".xls ./",name,".csv"))
    data <- read_csv(paste0("./",name,".csv"),skip = 30)
    write.csv(data, paste0("./",name,".csv"),row.names = FALSE)
    }
  return(data)
}


clean <- function(db){
  dic <- read_csv("./dir163_dic.csv")
  colnames(db) <- dic$name

  db<-remove_empty_rows(db)  
  return(db)
}

remove_empty_rows <- function(db) {
  db <- db %>% filter(Reduce(`+`, lapply(., is.na)) != ncol(.))
  return(db)
}


geocode_vector_process <- function(infile,vector){   

  #initialise a dataframe to hold the results
  geocoded <- data.frame()
  # find out where to start in the address list (if the script was interrupted before):
  startindex <- 1
  #if a temp file exists - load it up and count the rows!
  tempfilename <- paste0(infile, '_temp_geocoded.rds')
  if (file.exists(tempfilename)){
    print("Found temp file - resuming from index:")
    geocoded <- readRDS(tempfilename)
    startindex <- nrow(geocoded)
    print(startindex)
  }
  
  # Start the geocoding process - address by address. geocode() function takes care of query speed limit.
  for (ii in seq(startindex, length(vector))){
    print(paste("Working on index", ii, "of", length(vector)))
    #query the google geocoder - this will pause here if we are over the limit.
    result = getGeoDetails(vector[ii]) 
    print(result$status)     
    result$index <- ii
    #append the answer to the results file.
    geocoded <- rbind(geocoded, result)
    #save temporary results as we are going along
    saveRDS(geocoded, tempfilename)
  }
return(geocoded)
}


getGeoDetails <- function(address){   
  #use the gecode function to query google servers
  geo_reply = geocode(address, output='all', messaging=TRUE, override_limit=TRUE)
  #now extract the bits that we need from the returned list
  answer <- data.frame(lat=NA, long=NA, accuracy=NA, formatted_address=NA, address_type=NA, status=NA)
  answer$status <- geo_reply$status
  
  #if we are over the query limit - want to pause for an hour
  while(geo_reply$status == "OVER_QUERY_LIMIT"){
    print("OVER QUERY LIMIT - Pausing for 1 hour at:") 
    time <- Sys.time()
    print(as.character(time))
    Sys.sleep(60*60)
    geo_reply = geocode(address, output='all', messaging=TRUE, override_limit=TRUE)
    answer$status <- geo_reply$status
  }
  
  #return Na's if we didn't get a match:
  if (geo_reply$status != "OK"){
    return(answer)
  }   
  #else, extract what we need from the Google server reply into a dataframe:
  answer$lat <- geo_reply$results[[1]]$geometry$location$lat
  answer$long <- geo_reply$results[[1]]$geometry$location$lng   
  if (length(geo_reply$results[[1]]$types) > 0){
    answer$accuracy <- geo_reply$results[[1]]$types[[1]]
  }
  answer$address_type <- paste(geo_reply$results[[1]]$types, collapse=',')
  answer$formatted_address <- geo_reply$results[[1]]$formatted_address
  
  return(answer)
}