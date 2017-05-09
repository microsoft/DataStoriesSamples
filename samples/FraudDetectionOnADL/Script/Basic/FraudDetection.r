library(dplyr)
library(RevoScaleR)

# Add extra features      
inputData <- inputFromUSQL %>%
  mutate(
    is_highAmount=ifelse(transactionAmountUSD >150,'TRUE', 'FALSE'),
    shipping_billing_postalCode_mismatchFlag = ifelse(shippingPostalCode==paymentBillingPostalCode,'FALSE', 'TRUE'),
    shipping_billing_country_mismatchFlag = ifelse(shippingCountry==paymentBillingCountryCode,'FALSE', 'TRUE')
  ) %>%
  ungroup


# Handle missing values
inputData[ inputData == "" | inputData == " " | inputData == "na" | inputData == "NA"] <- NA
numCol <- sapply(inputData, is.numeric)
inputData[,numCol][is.na(inputData[,numCol])] <- 0

# Convert string columns to factors for rxBTrees model
inputData <- as.data.frame(unclass(inputData))  

# Score
modelFilename <- "trainedmodel.rds"

trainedModel <- readRDS(modelFilename)
scores <- rxPredict(modelObject = trainedModel,  
                    data = inputData,
                    type = "response") 

outputToUSQL <- data.frame(LabelPredicted=as.integer(scores$Label_prob>0.6))