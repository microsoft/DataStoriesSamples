library(RevoScaleR)

# Load pre-trained model
filename_model <- "trainedmodel-rxbtree.rds"
boosted_fit <- readRDS(filename_model)

data_test <- inputFromUSQL[, !(colnames(inputFromUSQL) %in% c("Par"))]

# Fill missing values
data_test[ data_test == "" | data_test == " " | data_test == "na" | data_test == "NA"] <- NA
numcol <- sapply(data_test, is.numeric)
data_test[,numcol][is.na(data_test[,numcol])] <- 0

# Convert string columns to factors
data_test <- as.data.frame(unclass(data_test))

scores <- rxPredict(
			modelObject = boosted_fit,  
            data = data_test,
            type = "response",
			extraVarsToWrite=c("accountID", "transactionID", "transactionAmountUSD")) 

outputdata <- data.frame(accountID=scores$accountID, transactionID=scores$transactionID, transactionAmountUSD=scores$transactionAmountUSD,score=scores$Label_prob) 
outputToUSQL <- outputdata

