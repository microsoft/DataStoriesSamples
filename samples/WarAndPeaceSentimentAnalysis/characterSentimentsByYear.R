# Load libs
library (dplyr)
library(d3heatmap)
library(tidyr)
library(stringr)
library(reshape)

# Read the war and peace dataset, with key phrase and sentimenet extracted
warpeace <- read.csv(file="./data/warandpeaceSentimentKeyPhrase.csv",header=FALSE, sep=",")

# Specify the characters in War and Peace
bookCharacters <- c("Cyril", "Bezúkhov",  "Pierre",  "Nicholas",
        "Rostóva", "RostÃ³va","Natalie","Natasha","NatÃ¡sha",
        "Catiche", "Ilyá","Nikolenka",  "Pétya","Véra","Sónya", 
        "Nicholas","Andrew","Mary", "Hélène", "Mikháylovna", "Tikhon","Alpatych", "Vasíli", 
        "Anatole",  "Leyla",  "Prince","Anna Pávlovna", 
        "Kutúzov", "Dólokhov","Borís","Mitenka","Márya Dmítrievna","Shinshín", 
        "Berg", "Bourienne", "Lorrain", "Michael Ivánovich",
        "Timókhin","Kozlovski", "Nesvítski",
        "Kirsten",  "Bilibin",  "Bagration",  "Murat",  "Tushin","Alpatych",  
        "Dolgorukov","Alexander","Tolstóy","Mary Bogdanovna"
)

# Create an initial data frame 
wpBase <- warpeace[grep("Mack",warpeace$V5),]
wpBase$character <- "Mack"

# For each character in the book, find the rows with the specific book character
for (person in bookCharacters) {
  wpNew <- warpeace[grep(person,warpeace$V5),]
  if ( nrow(wpNew) > 0 ) {
    wpNew$character <- person
    wpBase <- rbind(wpBase,wpNew)
  }
}

# Resolve to same-name references
wpBase$character[wpBase$character=="NatÃ¡sha"] <- " Natasha"
wpBase$character[wpBase$character=="Natalie"] <- " Natasha"
wpBase$character[wpBase$character=="RostÃ³va"] <- " Natasha"
wpBase$character[wpBase$character=="Rostóva"] <- " Natasha"

wpBase$character[wpBase$character=="Monsieur Pierre" ] <- " Pierre"
wpBase$character[wpBase$character=="BezÃºkhov"] <- "Pierre"
wpBase$character[wpBase$character=="Count BezÃºkhov"] <- " Pierre"
wpBase$character[wpBase$character=="Pierre"] <- " Pierre"

wpBase$character[wpBase$character=="Prince Andrew"] <- " Andrey"
wpBase$character[wpBase$character=="Andrew"] <- " Andrey"
wpBase$character[wpBase$character=="Andrey"] <- " Andrey"

wpBase$character[wpBase$character=="Mary Bogdar"] <- "Mary"


# Aggregate by character, and then order by book
warpeaceG <- wpBase %>% group_by(V2,character) %>% summarize(sentimentOverall=sum(V6))
warpeaceOrderByBook <- warpeaceG[order(warpeaceG$V2),]

md <- melt(warpeaceOrderByBook, id = (c("V2", "character")))
castd <- cast(md, character ~ V2)

# Replace all NA with 0
castd[is.na(castd)] <- 0


d3heatmap(castd,scale = "column", colors = "Spectral",
          dendrogram = "none", Rowv = FALSE, Colv = FALSE)


