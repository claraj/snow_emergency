df <- read.csv("scratch/example.csv")
head(df)

# Split - number 
parts = split(df, sample(rep(1:4, 13)))
