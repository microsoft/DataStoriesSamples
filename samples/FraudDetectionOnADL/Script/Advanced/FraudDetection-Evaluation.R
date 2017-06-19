.libPaths(c(.libPaths(), getwd()))
# unzip and install the external package
if (require(pROC)==FALSE)
{
    unzip('pROC_1.10.0.zip')
    require(pROC)
}

library(RevoScaleR)

data_input <- inputFromUSQL[, !(colnames(inputFromUSQL) %in% c("accountID","transactionID","transactionDateTime","transactionScenario","transactionType", "Par"))]
data_train <- head(data_input,7000)
data_test <- tail(data_input,3000)
rm(data_input) # save REM

# Training
data_train[ data_train == "" | data_train == " " | data_train == "na" | data_train == "NA"] <- NA
numcol <- sapply(data_train, is.numeric)
data_train[,numcol][is.na(data_train[,numcol])] <- 0

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


rm(data_train)
# Evaluation
data_test[ data_test == "" | data_test == " " | data_test == "na" | data_test == "NA"] <- NA
numcol <- sapply(data_test, is.numeric)
data_test[,numcol][is.na(data_test[,numcol])] <- 0

data_test <- as.data.frame(unclass(data_test))

Scores <- rxPredict(modelObject = boosted_fit,  
                    data = data_test,
                    type = "response") 

# Calculate accuracy
confusion <- function(a, b){
  tbl <- table(a, b)
  acc <- sum(diag(tbl))/sum(tbl)
  return(acc)
}
accuracy <- confusion(Scores > 0.6, data_test$Label > 0)

# calculate AUC
pred <- as.integer(as.logical(Scores > 0.6))
roc_obj <- roc(data_test$Label, pred)
auc <- auc(roc_obj)

outputToUSQL <- data.frame(accuracy=c("accuracy",accuracy),auc=c("AUC",auc))
