# Load required packages
library(plumber)
library(caret)
library(dplyr)

# Load the dataset
dat <- read.csv("diabetes_binary_health_indicators_BRFSS2015.csv")

# Factor conversion for response and selected predictors that are categorical
dat$Diabetes_binary <- factor(dat$Diabetes_binary, levels = c(0, 1), labels = c("No.Diabetes", "Diabetes"))
dat$HighBP <- factor(dat$HighBP, levels = c(0, 1), labels = c("No High BP", "High BP"))
dat$HighChol <- factor(dat$HighChol, levels = c(0, 1), labels = c("No High Cholesterol", "High Cholesterol"))
dat$Smoker <- factor(dat$Smoker, levels = c(0, 1), labels = c("Non-Smoker", "Smoker"))
dat$HvyAlcoholConsump <- factor(dat$HvyAlcoholConsump, levels = c(0, 1), labels = c("Non-Heavy Drinker", "Heavy Drinker"))
dat$PhysActivity <- factor(dat$PhysActivity, levels = c(0, 1), labels = c("Has Not Exercised Outside of Work", "Has Exercised Outside of Work"))
dat$Sex <- factor(dat$Sex, levels = c(0, 1), labels = c("Female", "Male"))
dat$Age <- factor(dat$Age, 
                  levels = c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13), 
                  labels = c("18-24", "25-29", "30-34", "35-39", "40-44", 
                             "45-49", "50-54", "55-59", "60-64", "65-69", 
                             "70-74", "75-79", "80 or older"))

# Rename response variable for simplicity
dat <- rename(dat, Diabetes = Diabetes_binary)
cols_to_keep <- c("Diabetes", "HighBP", "HighChol", "BMI", "Smoker", "PhysActivity", "HvyAlcoholConsump", "Sex", "Age")
dat <- dat[, cols_to_keep]

# Split the data into training and test sets
set.seed(123)
trainIndex <- createDataPartition(dat$Diabetes, p = 0.7, list = FALSE)
trainData <- dat[trainIndex, ]
testData <- dat[-trainIndex, ]

# Train the Logistic Regression model
train_control <- trainControl(method = "cv", 
                              number = 5, 
                              summaryFunction = mnLogLoss, 
                              classProbs = TRUE)
logistic_model <- train(Diabetes ~ HighBP + HighChol + BMI + Smoker + Sex + Age,
                        data = trainData,
                        method = "glm",
                        family = "binomial",
                        trControl = train_control,
                        metric = "logLoss")

# Define the API
#* @apiTitle Diabetes Prediction API
#* @apiDescription An API for predicting diabetes risk based on various health indicators.

#* Predict diabetes risk
#* @param HighBP Factor. Default "No High BP".
#* @param HighChol Factor. Default "No High Cholesterol".
#* @param BMI Numeric. Default 30 (mean value from training set).
#* @param Smoker Factor. Default "Non-Smoker".
#* @param Sex Factor. Default "Female".
#* @param Age Factor. Default "45-49".
#* @post /pred
function(HighBP = "No High BP", HighChol = "No High Cholesterol", BMI = 30, Smoker = "Non-Smoker", Sex = "Female", Age = "45-49") {
  # Create a new data frame for prediction
  new_data <- data.frame(
    HighBP = factor(HighBP, levels = levels(trainData$HighBP)),
    HighChol = factor(HighChol, levels = levels(trainData$HighChol)),
    BMI = as.numeric(BMI),
    Smoker = factor(Smoker, levels = levels(trainData$Smoker)),
    Sex = factor(Sex, levels = levels(trainData$Sex)),
    Age = factor(Age, levels = levels(trainData$Age))
  )
  
  # Predict using the trained Logistic Regression model
  prediction <- predict(logistic_model, newdata = new_data, type = "prob")
  return(list(prediction = prediction$Diabetes))
}

#* Info about the API
#* @get /info
function() {
  list(
    name = "Charlie Armentrout",
    url = "https://charlie-trout.github.io/predictive-model-api-docker/"
  )
}

# Example function calls (for testing)
# 1. Testing the /pred endpoint with default parameters
# curl -X POST "http://localhost:8000/pred" -H "Content-Type: application/json" -d '{"HighBP": "No High BP", "HighChol": "No High Cholesterol", "BMI": 30, "Age": "50-54"}'

# 2. Testing the /pred endpoint with custom parameters
# curl -X POST "http://localhost:8000/pred" -H "Content-Type: application/json" -d '{"HighBP": "High BP", "HighChol": "High Cholesterol", "BMI": 28, "Age": "40-44"}'

# 3. Testing the /info endpoint
# curl "http://localhost:8000/info"