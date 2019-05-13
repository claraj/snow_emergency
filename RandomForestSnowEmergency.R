# Using Random Forest prediction on sample snow emergency data 

library("randomForest")
library("raster")

setwd("/Users/student1/Development/r/snow_proj/data")

dataframe <- read.csv(file="SNOW_TAG_TOW_TYPES_TESTING_R_SCRIPT_FAKE_FAKE_FAKE_DATA.csv")
head(dataframe)

# Ward (1, 2, 3....), Tow_Zone (1 - 6), Day (1, 2, 3) are numerical and interpreted as numeric type. 
# But here, they should be treated as categorical data, so convert to factors 
dataframe$Ward <- factor(dataframe$Ward)
dataframe$Tow_Zone <- factor(dataframe$Tow_Zone)
# dataframe$Day <- factor(dataframe$Day)

# Create categories for driving distance and driving duration 
# Help from http://rcompanion.org/handbook/E_05.html categorizing data 
per_00 <- min(dataframe$distance)
per_25 <- quantile(dataframe$distance, 0.25)
per_50 <- quantile(dataframe$distance, 0.5)
per_75 <- quantile(dataframe$distance, 0.55)
per_100 <- max(dataframe$distance)

RB_DI <- rbind(per_00, per_25, per_50, per_75, per_100)
dimnames(RB_DI)[[2]] <- "Value"

dataframe$distanceCat[dataframe$distance >= per_00 & dataframe$distance < per_25] = "1"
dataframe$distanceCat[dataframe$distance >= per_25 & dataframe$distance < per_50] = "2"
dataframe$distanceCat[dataframe$distance >= per_50 & dataframe$distance < per_75] = "3"
dataframe$distanceCat[dataframe$distance >= per_75 & dataframe$distance <= per_100] = "4"

dataframe$distanceCat <- factor(dataframe$distanceCat)

# Repeat for duration. Todo look up if there's a built-in way to do this in R
per_00 <- min(dataframe$duration)
per_25 <- quantile(dataframe$duration, 0.25)
per_50 <- quantile(dataframe$duration, 0.5)
per_75 <- quantile(dataframe$duration, 0.55)
per_100 <- max(dataframe$duration)

RB_DU <- rbind(per_00, per_25, per_50, per_75, per_100)
dimnames(RB_DU)[[2]] <- "Value"

dataframe$durationCat[dataframe$duration >= per_00 & dataframe$duration < per_25] = 1
dataframe$durationCat[dataframe$duration >= per_25 & dataframe$duration < per_50] = 2
dataframe$durationCat[dataframe$duration >= per_50 & dataframe$duration < per_75] = 3
dataframe$durationCat[dataframe$duration >= per_75 & dataframe$duration <= per_100] = 4

# Convert to factor 
dataframe$durationCat <- factor(dataframe$durationCat)

# Save categories 
summary(dataframe)
write.csv(dataframe, "categorize_snow_emergency.csv")

# Create coordinates for dataframe, which converts dataframe to a SpatialPointsDataFrame
coordinates(dataframe) <- ~Longitude+Latitude

# Run the random forest model with the columns given 

random_forest <- randomForest( Type ~ Ward + Community + Day + Tow_Zone + STREET_TYPE + distanceCat + durationCat, data=dataframe, ntree=500, importance=TRUE, proximity=TRUE)
importance(random_forest)
# dev.off()
# varImpPlot(random_forest)

############### Creating predictive raster layer ###############

## Create rasters for each column of interest 

# Extent of points in Minneapolis
lonMin <- -93.3275270000000035
lonMax <- -93.2050569999999965
latMin <- 44.8912320000000022
latMax <- 45.0509410000000017

cell_size <- 0.0005
ncols <- (( lonMax - lonMin) / cell_size) + 1
nrows <- (( latMax - latMin) / cell_size) + 1

# Works
r_d <- raster(ncols=ncols, nrows=nrows, xmn=lonMin, xmx=lonMax, ymn=latMin, ymx=latMax)
day_raster = rasterize(dataframe, r_d, "Day", fun="min", filename="Day.tif", overwrite=TRUE)

r_di <- raster(ncols=ncols, nrows=nrows, xmn=lonMin, xmx=lonMax, ymn=latMin, ymx=latMax)
distance_raster = rasterize(dataframe, r_di, "distanceCat", fun=mean, filename="distanceCat.tif", overwrite=TRUE)

r_du <- raster(ncols=ncols, nrows=nrows, xmn=lonMin, xmx=lonMax, ymn=latMin, ymx=latMax)
duration_raster = rasterize(dataframe, r_du, "durationCat", fun=mean, filename="durationCat.tif", overwrite=TRUE)

# Everything else is a factor - how to convert to Raster? What value to write for factor's levels? 
r_w <- raster(ncols=ncols, nrows=nrows, xmn=lonMin, xmx=lonMax, ymn=latMin, ymx=latMax)
ward_raster = rasterize(dataframe, r_w, "Ward", fun=function(x, na.rm) { max(as.numeric(x)) }, filename="ward.tif", overwrite=TRUE)

r_t <- raster(ncols=ncols, nrows=nrows, xmn=lonMin, xmx=lonMax, ymn=latMin, ymx=latMax)
tow_zone_raster = rasterize(dataframe, r_t, "Tow_Zone", fun=function(x, na.rm) { max(as.numeric(x)) }, filename="Tow_Zone.tif", overwrite=TRUE)

r_c <- raster(ncols=ncols, nrows=nrows, xmn=lonMin, xmx=lonMax, ymn=latMin, ymx=latMax)
community_raster = rasterize(dataframe, r_c, "Community", fun=function(x, na.rm) { max(as.numeric(x)) }, filename="Community.tif", overwrite=TRUE)

r_s <- raster(ncols=ncols, nrows=nrows, xmn=lonMin, xmx=lonMax, ymn=latMin, ymx=latMax)
street_type_raster = rasterize(dataframe, r_s, "STREET_TYPE", fun=function(x, na.rm) { max(as.numeric(x)) },  filename="STREET_TYPE.tif", overwrite=TRUE)
raster_combo <- c(ward_raster, community_raster, day_raster, tow_zone_raster, street_type_raster, distance_raster, duration_raster)
raster_stack <- stack(raster_combo)

# set names 
names(raster_stack) <- c("Ward", "Community", "Day", "Tow_Zone", "STREET_TYPE", "distanceCat", "durationCat")

predict_raster_layer <- predict(raster_stack, random_forest, "predictive_snow_emergency_raster.img", overwrite=TRUE)
#dev.off()
plot(predict_raster_layer)





