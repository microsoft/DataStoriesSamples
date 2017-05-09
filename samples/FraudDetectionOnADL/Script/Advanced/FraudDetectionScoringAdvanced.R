# January 2017
# for questions: esin.saka@microsoft.com or yiwsun@microsoft.com

library(RevoScaleR)

modelFilename <- "trainedmodel-rxbtree-100000-ntree100.rds"
 
processedData = inputFromUSQL[, !(colnames(inputFromUSQL) %in% c("Par"))]

trainedModel <- readRDS(modelFilename)

# scoring: use RevoR 
Scores <- rxPredict(modelObject = trainedModel,  
				  data = processedData,
				  type = "response",
				  extraVarsToWrite=c("accountID", "transactionDateTime", "transactionAmountUSD")) 
				  
outputdata <- data.frame(accountID=Scores$accountID, transactionDateTime=Scores$transactionDateTime, transactionAmountUSD=Scores$transactionAmountUSD,score=Scores$Label_prob)

outputToUSQL <- outputdata