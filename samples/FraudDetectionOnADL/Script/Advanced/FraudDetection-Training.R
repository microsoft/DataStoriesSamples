library(RevoScaleR)

data_train <- inputFromUSQL[, !(colnames(inputFromUSQL) %in% c("accountID","transactionID","transactionDateTime","transactionScenario","transactionType", "Par"))]

# Fill missing values
data_train[ data_train == "" | data_train == " " | data_train == "na" | data_train == "NA"] <- NA
numcol <- sapply(data_train, is.numeric)
data_train[,numcol][is.na(data_train[,numcol])] <- 0

# Convert string columns to factors
data_train <- as.data.frame(unclass(data_train))  
data_train$Label <- as.factor(data_train$Label)

names <- colnames(data_train)[which(colnames(data_train) != "Label")]
equation <- paste("Label ~ ", paste(names, collapse = "+", sep=""), sep="")

boosted_fit <- rxBTrees(formula = as.formula(equation),
                        data = data_train,
                        learningRate = 0.2,
                        minSplit = 10,
                        minBucket = 10,
                        nTree = 100,
                        seed = 5,
                        lossFunction = "bernoulli")

# Save the model locally
filename_model <- "F:/USQL/USQLDataRoot/Samples/Output/training/trainedmodel-rxbtree.rds"
saveRDS(boosted_fit, filename_model)

outputToUSQL <- summary(boosted_fit)