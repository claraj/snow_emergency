df <- read.csv("scratch/example.csv")
head(df)

# Split - number must be 
parts = split(df, sample(rep(1:4, 13)))
