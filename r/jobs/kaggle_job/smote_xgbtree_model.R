set.seed(1234)

# packages ######################################
library(tidyverse) # data
library(caret) # ml
library(ranger) # rf
library(randomForest) # rf
library(gmodels) # CrossTable
library(data.table) # import
library(FactoMineR) 
library(factoextra)
library(ModelMetrics)
library(PRROC)
library(DMwR)
library(plotROC)
library(klaR)
library(gbm)
library(kernlab)
library(MLmetrics)
library(mlbench)
library(rpart)
library(ada)
library(xgboost)
select = dplyr::select

normalizedGini <- function(aa, pp) {
    Gini <- function(a, p) {
        if (length(a) !=  length(p)) stop("Actual and Predicted need to be equal lengths!")
        temp.df <- data.frame(actual = a, pred = p, range=c(1:length(a)))
        temp.df <- temp.df[order(-temp.df$pred, temp.df$range),]
        population.delta <- 1 / length(a)
        total.losses <- sum(a)
        null.losses <- rep(population.delta, length(a)) # Hopefully is similar to accumulatedPopulationPercentageSum
        accum.losses <- temp.df$actual / total.losses # Hopefully is similar to accumulatedLossPercentageSum
        gini.sum <- cumsum(accum.losses - null.losses) # Not sure if this is having the same effect or not
        sum(gini.sum) / length(a)
    }
    Gini(aa,pp) / Gini(aa,aa)
}

giniSummary <- function (data, lev = "Yes", model = NULL) {
    levels(data$obs) <- c('0', '1')
    out <- normalizedGini(as.numeric(levels(data$obs))[data$obs], data[, lev[2]])  
    names(out) <- "NormalizedGini"
    out
}

load("./../input//bases29var/bases_29features.RData")

train_id = train$id
train_XY = train %>% select(-id)

test_id = test$id
test_X = test %>% select(-id, -target)
test_Y = test$target %>% as.numeric()
test_Y = test_Y - 1

tune_control <- trainControl(method = "cv", 
                             number = 5, 
                             summaryFunction = giniSummary, 
                             classProbs = T, 
                             savePredictions = T, 
                             verboseIter = T, 
                             sampling = "smote")

######################################################################################


tune_grid = expand.grid(
    nrounds = seq(100, 500, 100),
    eta = c(0.05, 0.1),
    max_depth = c(4, 5, 6),
    gamma = 0,
    colsample_bytree = 0.7,
    min_child_weight = 0,
    subsample = 0.7
)

smote_xgbtree_model = train(
    target ~ .,
    data = train_XY,
    metric = "NormalizedGini",
    trControl = tune_control,
    tuneGrid = tune_grid,
    method = "xgbTree",
)

######################################################################################

save(smote_xgbtree_model, file = "./smote_xgbtree_model.RData")