#
# DESCRIPTION OF STEP
#
# 1) extract a list of subentries 'subents' to be 
#    used in the evaluation
# 2) extract a datatable 'expDt' summarizing and
#    indexing information in subents falling
#    in the energy range between 'minExpEn'
#    and 'maxExpEn'
# 3) create a datatable 'needsDt' containing the
#    information about required TALYS calculations
#    and the relevant output quantities
#

source("config.R")

#################################################
#       SCRIPT PARAMETERS
##################################################

scriptnr <- 1L
overwrite <- FALSE

#################################################
#       START OF SCRIPT
##################################################

outputObjectNames <- c("subents", "expDt", "needsDt")
check_output_objects(scriptnr, outputObjectNames)

db <- connectExfor(mongo_colname, mongo_dbname, "mongodb://localhost")

# target reaction strings matching this regular expression

reacPat <- "\\(26-FE-56\\(N,[^)]+\\)[^,]*,,SIG\\)"

# construct the query string for mongodb

queryStr <- makeQueryStr(and(
  paste0('BIB.REACTION: { $regex: "', reacPat, '", $options: ""}'),
  paste0('DATA.TABLE.DATA: { $exists: true }'),
  paste0('DATA.TABLE.EN: { $exists: true }')
))

# create a datatable with an overview of the data
# filter out reaction expressions where:
#   * subexpressions are not cross sections (not SIG) 
#   * the reaction is not a character vector of length 1

reacOverviewDt <- db$find(queryStr, {
  if (is.list(BIB$REACTION) || length(BIB$REACTION) != 1)
    NULL
  else
  {
    reacExpr <- parseReacExpr(BIB$REACTION)
    unlistedReacExpr <- unlist(reacExpr, recursive = TRUE)
    if (any(unlistedReacExpr[grepl("quantspec", names(unlistedReacExpr))] != ",SIG"))
      NULL
    else
      list(ID = ID,
           REAC = reacStrucToStr(parseReacExpr(BIB$REACTION)),
           COLS = paste0(DATA$DESCR, collapse=","))
  } 
})

# retrieve the exfor subentries corresponding to
# the IDs in the summary datatable

idsStr <- paste0(paste0('"', reacOverviewDt$ID, '"'), collapse=",") 

queryStr <- makeQueryStr(
  paste0('ID: { $in: [', idsStr, ']}')                              
)

it <- exforIterator(queryStr)
subentList <- list()
while (!is.null((curSub <- it$getNext()))) {
  if (curSub$ID %in% c("23313002", "23313003"))
    next # because measured at angles (wrong EXFOR classification)
  subentList <- c(subentList, list(curSub))
}

# just keep the subentries that can be mapped to
# TALYS predictions by package talysExforMapping
# and have valid uncertainty specifications

isMapable <- exforHandler$canMap(subentList, quiet=TRUE)
hasUncertainties <- hasValidUncertainties(subentList)

subents <- subentList[isMapable & hasUncertainties]
expDt <- exforHandler$extractData(subents, ret.values = TRUE)
expDt <- expDt[L1 >= minExpEn & L1 <= maxExpEn] 
expDt <- expDt[, IDX := seq_len(.N)]
rebuildGauss <- FALSE
##################################################################
if (any(file.exists("modelFullData.rds"))  & !rebuildGauss){
  modelFullData <- readRDS("modelFullData.rds")
} else {
  nvar <- 1
  
  modelFullData <- expDtTot[, 
                            mleHetGP(X = L1, 
                                     Z = DATA, 
                                     lower = rep(0.1, nvar), 
                                     upper = rep(50, nvar),
                                     covtype = "Gaussian",
                                     init = list(
                                       beta0 = expDtTot$DATAREF,
                                       theta = 2)
                            )
                            ]
  modelFullData <- rebuild(modelFullData, robust = TRUE)
  saveRDS(modelFullData, "modelFullData.rds")
}
##############################################################


expDtTot <- expDt[REAC=="(26-FE-56(N,TOT),,SIG)"]

n = 0
grid <- seq(min(expDtTot$L1)-0.1, max(expDtTot$L1)+0.1, length.out=ceiling(max(expDtTot$L1-min(expDtTot$L1))))
weightDt <- data.table(IDX = expDtTot$IDX)

for (i in 1:length(grid)) {
  # For each bin grid, attache a waight to the data point 
  # according to the number of data points in that bin.
  weightDt[IDX %in% expDtTot[L1 >= grid[i] & L1 < grid[i+1],  IDX ], PROBDENS:= expDtTot[L1 >= grid[i] & L1 < grid[i+1],  1/.N ] ] 
  
  # Count the bins that contain non-zero number of events
  n = n + expDtTot[L1 >= grid[i] & L1 < grid[i+1],  ifelse(.N >0, 1, 0) ]
}

# Normalize the weights accoding to the number of non-zero bins
weightDt[,PROBDENS := PROBDENS/n]
expDtSampleTmp <- expDtTot[IDX %in% expDtTot[, sample(IDX, 400, prob = weightDt$PROBDENS)]]

xgrid <- as.matrix(expDtSampleTmp$L1)
predictions <- predict(x = xgrid, object =  modelFullData)


ggr <- ggplot(NULL) + theme_bw()    
#ggr <- ggr +  ggdata(expDt[REAC=="(26-FE-56(N,TOT),,SIG)"]) 
ggr <- ggr + geom_point(data = expDtTot,   aes(x = L1, y = DATA), size = 0.1, alpha=0.5)    

#
ggr <- ggr + geom_errorbar(aes(x = xgrid, ymin = predictions$mean - sqrt(predictions$sd2+ predictions$nugs), ymax = predictions$mean + sqrt(predictions$sd2+ predictions$nugs)), color="tomato1", alpha=0.4, size=0.5)     

#ggr <- ggr + geom_errorbar(aes(x = xgrid, ymin = qnorm(0.32, predictions$mean, sqrt(predictions$sd2+ predictions$nugs)), ymax = qnorm(0.68, predictions$mean, sqrt(predictions$sd2+ predictions$nugs))), color="red", alpha=0.8, size=1)    
ggr <- ggr + geom_point(aes(x = xgrid, y = predictions$mean), color="tomato1", size = 1)  
ggr <- ggr + geom_line(aes(x = xgrid, y = predictions$mean), linetype = "dashed", color="black", size = 0.5) 
print(ggr)
plot(expDtSampleTmp$L1, expDtSampleTmp$DATA)
#expDtSampleTmp <- expDtSampleTmp[sort(L1)]
plot(expDtSampleTmp$L1, predictions$mean)
#expDtSampleTmp <- expDtSampleTmp[sort(L1)]
expDtSampleTmp[, DATA := predictions$mean]
expDtSampleTmp[, UNC := sqrt(predictions$sd2+ predictions$nugs)]

plot(expDtSampleTmp$L1, expDtSampleTmp$DATA)

expDtTmp <- rbind(expDt[REAC!="(26-FE-56(N,TOT),,SIG)", UNC := NA], expDtSampleTmp)
expDtTmp <- expDtTmp[sort(L1), .SD, by=REAC][, IDX := seq_len(.N)]
expDt <- expDtTmp
needsDt <- exforHandler$needs(expDt, subents)

# save the relevant objects for further processing
save_output_objects(scriptnr, outputObjectNames, overwrite)
