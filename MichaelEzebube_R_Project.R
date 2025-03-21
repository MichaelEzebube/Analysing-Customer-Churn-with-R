# Install and load required packages
install.packages("openxlsx")
install.packages("dplyr")
install.packages("ggplot2")
install.packages("caret")
install.packages("pROC")
library(openxlsx)
library(dplyr)
library(ggplot2)
library(caret)
library(pROC)

# Load the CSV file
df <- read.csv("churn-bigml-20.csv")

# Save as Excel file for edits
write.xlsx(df, "churn-bigml-20.xlsx")

# State abbreviation mapping
state_mapping <- c(
  'AL' = 'Alabama', 'AK' = 'Alaska', 'AZ' = 'Arizona', 'AR' = 'Arkansas',
  'CA' = 'California', 'CO' = 'Colorado', 'CT' = 'Connecticut', 'DE' = 'Delaware',
  'DC' = 'District of Columbia', 'FL' = 'Florida', 'GA' = 'Georgia', 'HI' = 'Hawaii',
  'ID' = 'Idaho', 'IL' = 'Illinois', 'IN' = 'Indiana', 'IA' = 'Iowa', 'KS' = 'Kansas',
  'KY' = 'Kentucky', 'LA' = 'Louisiana', 'ME' = 'Maine', 'MD' = 'Maryland',
  'MA' = 'Massachusetts', 'MI' = 'Michigan', 'MN' = 'Minnesota', 'MS' = 'Mississippi',
  'MO' = 'Missouri', 'MT' = 'Montana', 'NE' = 'Nebraska', 'NV' = 'Nevada',
  'NH' = 'New Hampshire', 'NJ' = 'New Jersey', 'NM' = 'New Mexico', 'NY' = 'New York',
  'NC' = 'North Carolina', 'ND' = 'North Dakota', 'OH' = 'Ohio', 'OK' = 'Oklahoma',
  'OR' = 'Oregon', 'PA' = 'Pennsylvania', 'RI' = 'Rhode Island', 'SC' = 'South Carolina',
  'SD' = 'South Dakota', 'TN' = 'Tennessee', 'TX' = 'Texas', 'UT' = 'Utah',
  'VT' = 'Vermont', 'VA' = 'Virginia', 'WA' = 'Washington', 'WV' = 'West Virginia',
  'WI' = 'Wisconsin', 'WY' = 'Wyoming'
)

# Convert the State column to character type
df$State <- as.character(df$State)

# Replace abbreviations in State column
df <- df %>% mutate(State = recode(State, !!!state_mapping))

# Save updated file
write.xlsx(df, "churn-bigml-20-updated.xlsx")

# Reload updated Excel file
dff <- read.xlsx("churn-bigml-20-updated.xlsx")

# Exploratory Data Analysis (EDA)
# Filter and remove NA values
data <- dff %>% 
  filter(!is.na(Total.day.minutes)) %>%  
  distinct()

# Convert Churn column to factor
data$Churn <- as.factor(data$Churn)

# Scale numeric data for model
data_scaled <- scale(data[, sapply(data, is.numeric)])

# Split data into training and testing sets
set.seed(123)
trainIndex <- createDataPartition(data$Churn, p = 0.8, list = FALSE)
trainData <- data[trainIndex,]
testData <- data[-trainIndex,]

# Visualize distribution and boxplot
ggplot(trainData, aes(x = Total.day.minutes)) +
  geom_histogram(binwidth = 10, color = "black", fill = "lightblue")

ggplot(trainData, aes(x = Churn, y = Total.day.charge)) +
  geom_boxplot()

# Model Building
# Random Forest
model_rf <- train(Churn ~ ., data = trainData, method = "rf")

# Gradient Boosting Machine
model_gbm <- train(Churn ~ ., data = trainData, method = "gbm")

# Support Vector Machine
model_svm <- train(Churn ~ ., data = trainData, method = "svmRadial")

# Model Evaluation
# Confusion matrices for each model
confusionMatrix(predict(model_rf, testData), testData$Churn)
confusionMatrix(predict(model_gbm, testData), testData$Churn)
confusionMatrix(predict(model_svm, testData), testData$Churn)

# ROC-AUC curves for each model
roc_rf <- roc(testData$Churn, as.numeric(predict(model_rf, testData, type = "prob")[,2]))
roc_gbm <- roc(testData$Churn, as.numeric(predict(model_gbm, testData, type = "prob")[,2]))
roc_svm <- roc(testData$Churn, as.numeric(predict(model_svm, testData, type = "prob")[,2]))

# Deploy using the GBM model for new customers
new_customer <- data.frame(
  Account.length = 100, Area.code = 415, International.plan = "No", Voice.mail.plan = "No",
  Number.vmail.messages = 0, Total.day.minutes = 200, Total.day.calls = 100,
  Total.day.charge = 30, Total.eve.minutes = 150, Total.eve.calls = 80,
  Total.eve.charge = 20, Total.night.minutes = 100, Total.night.calls = 50,
  Total.night.charge = 10, Total.intl.minutes = 10, Total.intl.calls = 5,
  Total.intl.charge = 5, Customer.service.calls = 2, State = "Texas"
)

# Predict churn for the new customer
predict(model_gbm, new_customer)

# Example for a second new customer
new_customer2 <- data.frame(
  State = "Nevada", Account.length = 190, Area.code = 115, International.plan = "Yes",
  Voice.mail.plan = "Yes", Number.vmail.messages = 5, Total.day.minutes = 40,
  Total.day.calls = 11, Total.day.charge = 90, Total.eve.minutes = 8,
  Total.eve.calls = 2, Total.eve.charge = 10, Total.night.minutes = 10,
  Total.night.calls = 6, Total.night.charge = 30, Total.intl.minutes = 0,
  Total.intl.calls = 0, Total.intl.charge = 0, Customer.service.calls = 2
)

# Predict churn for the second customer
predict(model_gbm, new_customer2)
