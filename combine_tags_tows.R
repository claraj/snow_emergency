## Read in tags, tows, combine with some flag to represent tag vs. tow  

tags <- read.csv("data/Snow_Emergency_Westminster_Tags_2019.csv")  # all ~3400 tags 
tows <- read.csv("data/Snow_Emergency_Westminster_Tows_2019.csv")  # all ~900 tows 

summary(tags)
summary(tows)
                 