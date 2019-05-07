# Provides %<-% operator for unpacking multiple return values from a function into multiple variables 
install.packages("zeallot")

# Install openrouteservice-r for getting driving distances between tow and impound lot. Not on CRAN 
install.packages("remotes")
remotes::install_github("GIScience/openrouteservice-r")  

# Import these libraries into the project
library(zeallot)
library(openrouteservice)

# Configure API key. 
open_route_service_token <- "5b3ce3597851110001cf6248631d33bc3be843d9a10ef59e4653b0b8" 
ors_api_key(open_route_service_token) # Set the API key 

# The open route service makes calls to APIs of this format 
# https://api.openrouteservice.org/v2/directions/driving-car?api_key=KEY&start=-93.681495,45.41461&end=-94.687872,46.420318

impound_lot <- c(-93.291796, 44.977125)  # longitude and latitude of 51 Colfax Ave N, Minneapolis 

tows <- read.csv("data/Snow_Emergency_Westminster_Tows_2019.csv")  # all ~900 tows 
# tows = read.csv("data/Subset_Snow_Emerg.csv")  # 2 rows of tows for testing

head(tows)  # How's the data looking? 

# Example call to openrouteservice 
# coordinates <- list( c(-93.288021, 45.013111), impound_lot )
# directions <- ors_directions(coordinates)
# distance_m <- directions$features[[1]]$properties$summary$distance 
# duration_s <- directions$features[[1]]$properties$summary$duration 

# Need to perform this operation on every row of dataframe, so write in a function

# When this is used with appply() start will be one row from the dataframe, the apply function 
# will provide the end parameter. In this code, end will be the impound lot. 
driving <- function(start, end=end) {
  start_loc <- c(start[7], start[6])   # TODO can access by column name? 
  coordinates <- list (start_loc, end )
  directions <- ors_directions(coordinates)
  distance_m <- directions$features[[1]]$properties$summary$distance
  duration_s <- directions$features[[1]]$properties$summary$duration
  return( c(distance_m, duration_s) )
}

result %<-% apply(tows, 1, FUN=driving, end=impound_lot) # Calculate driving distance and times for each tow location, to the impound lot. Returns a matrix

# result looks like this 
# [
#   [ distance1, time1 ]
#   [ distance2, time2 ]
#   [ distance3, time3 ]
# ]
# So need all the values from the first column to make a new distance column in the tows dataframe 
# So need all the values from the second column to make a new distance column in the tows dataframe 

tows$distances_m <- result[1,]  # Column 1 of the matrix
tows$time_s <- result[2, ]   # Column 2 of the matrix

head(tows)

write.csv(tows, "tows_distances.csv")  # Save to a new file 



