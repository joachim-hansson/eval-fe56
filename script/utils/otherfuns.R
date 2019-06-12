##############################################################
# TODO: These functions should go somewhere else in the future
##############################################################

getThresEn <- function(reac, expDt) {
  
  expDt[REAC == reac, L1[which(DATA[order(L1)] != 0)[1]]]
}


createSubentStub <- function(exforReacStr, en, xs=NULL) {                                                                                                                                                                                                                                                                                                                             
  require(digest)
  list(
    ID = paste0("MOD_", digest(exforReacStr, algo="crc32", serialize=FALSE)),
    BIB = list(REACTION = exforReacStr),
       DATA = list(DESCR = c("EN", "DATA"),
                   UNIT = c("MEV", "MB"),
                   TABLE = {
                     tmpTable <- data.table(EN = en)
                     if (!is.null(xs)) tmpTable[, DATA:=xs]
                     tmpTable[]
                   }))
}


