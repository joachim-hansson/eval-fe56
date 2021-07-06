#!/usr/bin/env Rscript

# Performs all the steps in directory eval-fe56/script
# which are part of the exemplary Fe56 evaluation.
filename = as.character(commandArgs(trailingOnly=TRUE)[1])


setwd("/home/joape785/eval-fe56")
filedir <- file.path("script")

print(filename)
# test if there is at least one argument: if not, return an error
if (length(filename)!=1) {
  stop("Exactly one argument must be supplied (input file).n", call.=FALSE)
} else if(!file.exists(file.path("script", filename))){
  stop(paste0("The specified input file ", filename," does not exist"), call.=FALSE)
}

run_step <- function(filename) {
  Sys.sleep(1)
  filepath <- file.path(filedir, filename)
  Rscript <- paste0("Rscript --vanilla --no-save --no-restore")
  cmdstr <- paste0(Rscript," ",filepath)
  cat("###################################\n")
  cat("Starting execution of step: '", filename, "\n")
  cat("###################################\n\n")
  Sys.sleep(3)
  system(cmdstr)
  cat("###################################\n")
  cat("Finished execution of step: '", filename, "\n")
  cat("###################################\n\n\n")
}

run_step(filename)
