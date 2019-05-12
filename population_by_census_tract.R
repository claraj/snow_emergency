population <- read.csv("data/population_and_race.csv", stringsAsFactors = FALSE)

head(population) 

# https://stackoverflow.com/questions/1660124/how-to-sum-a-variable-by-group
pop_by_tract <- aggregate(population$population, by= list(population$TRACT), FUN=sum)

colnames(pop_by_tract) <- c("tract", "population")

write.csv(pop_by_tract, "data/population_by_census_tract.csv")

veh_by_tract <- read.csv("data/acs_17_aggregate_vehicles_by_tract_hennepin.csv")

# Has total vehicles per tract
# Want density of vehicles by population or vehicles per person 

