# Using Random Forest prediction on sample snow emergency data 

library("randomForest")
library("raster")

setwd("/Users/student1/Development/r/snow_proj/data")

dataframe <- read.csv(file="SNOW_TAG_TOW_TYPES_TESTING_R_SCRIPT_FAKE_FAKE_FAKE_DATA.csv")
head(dataframe)

dataframe <- na.omit(dataframe)

extent = c(-93.3275270000000035,44.8912320000000022, -93.2050569999999965,45.0509410000000017)

# Ward (1, 2, 3....), Tow_Zone (1 - 6), Day (1, 2, 3) are numerical and interpreted as numeric type. 
# But here, they should be treated as categorical data, so convert to factors 
dataframe$Ward <- factor(dataframe$Ward)
dataframe$Tow_Zone <- factor(dataframe$Tow_Zone)
dataframe$Day <- factor(dataframe$Day)

# Create categories for drivng distance and driving duration 
# Help from http://rcompanion.org/handbook/E_05.html categorizing data 
per_00 <- min(dataframe$distance)
per_25 <- quantile(dataframe$distance, 0.25)
per_50 <- quantile(dataframe$distance, 0.5)
per_75 <- quantile(dataframe$distance, 0.55)
per_100 <- max(dataframe$distance)

RB_DI <- rbind(per_00, per_25, per_50, per_75, per_100)
dimnames(RB_DI)[[2]] <- "Value"

dataframe$distanceCat[dataframe$distance >= per_00 & dataframe$distance < per_25] = "Q1"
dataframe$distanceCat[dataframe$distance >= per_25 & dataframe$distance < per_50] = "Q2"
dataframe$distanceCat[dataframe$distance >= per_50 & dataframe$distance < per_75] = "Q3"
dataframe$distanceCat[dataframe$distance >= per_75 & dataframe$distance <= per_100] = "Q4"

dataframe$distanceCat <- factor(dataframe$distanceCat)

# Repeat for duration. Todo look up if there's a built-in way to do this in R
per_00 <- min(dataframe$duration)
per_25 <- quantile(dataframe$duration, 0.25)
per_50 <- quantile(dataframe$duration, 0.5)
per_75 <- quantile(dataframe$duration, 0.55)
per_100 <- max(dataframe$duration)

RB_DU <- rbind(per_00, per_25, per_50, per_75, per_100)
dimnames(RB_DU)[[2]] <- "Value"

dataframe$durationCat[dataframe$duration >= per_00 & dataframe$duration < per_25] = "Q1"
dataframe$durationCat[dataframe$duration >= per_25 & dataframe$duration < per_50] = "Q2"
dataframe$durationCat[dataframe$duration >= per_50 & dataframe$duration < per_75] = "Q3"
dataframe$durationCat[dataframe$duration >= per_75 & dataframe$duration <= per_100] = "Q4"

# Convert to factor 
dataframe$durationCat <- factor(dataframe$durationCat)

# Save categories 
summary(dataframe)
write.csv(dataframe, "categorize_snow_emergency.csv")

# Create coordinates for dataframe, converts dataframe to a SpatialPointsDataFrame
coordinates(dataframe) <- ~Longitude+Latitude

###### TODO FIGURE OUT CREATING RASTERS 

r <- raster(ncols=200, nrows=400)
ward_raster = rasterize(dataframe, r, "Ward", filename="ward.tif")
community_raster = rasterize(dataframe, r, "Community", filename="community.tif")
tow_zone_raster = rasterize(dataframe, r, "Tow_Zone", filename="tow_zone.tif")
day_raster = rasterize(dataframe, r, "Day", filename="day.tif")
street_type_raster = rasterize(dataframe, r, "STREET_TYPE", filename="street.tif")
distance_raster = rasterize(dataframe, r, "distanceCat", filename="distance.tif")
duration_raster = rasterize(dataframe, r, "durationCat", filename="duration.tif")

ward_raster
plot(ward_raster)


# Run the random forest model with the columns given 
rf <- randomForest( Type ~ Ward + Community + Tow_Zone + Day + STREET_TYPE + distanceCat + durationCat, data=dataframe, ntree=300, importance=TRUE, distance=TRUE)
importance(rf)
dev.off()
varImpPlot(rf)


# TODO test once there are rasters ...

raster_combo <- c(ward_raster, community_raster, day_raster, tow_zone_raster, street_type_raster, distance_raster, duration_raster)
raster_stack <- stack(raster_combo)

predict_raster_layer <- predict(raster_stack, dataframe, "predictive_snow_emergency_raster.img", overwrite=TRUE)
dev.off()
plot(predict_raster_layer)





