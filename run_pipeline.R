# Performs all the steps in directory eval-fe56/script
# which are part of the exemplary Fe56 evaluation.

run_step <- function(filename) {
  setwd("/home/user/eval-fe56")
  filepath <- file.path("script", filename)
  Rscript <- paste0("Rscript --vanilla --no-save --no-restore")
  cmdstr <- paste0(Rscript," ",filepath)
  cat("###################################\n")
  cat("Starting execution of step: '", filename, "\n")
  cat("###################################\n\n")
  system(cmdstr)
  cat("###################################\n")
  cat("Finished execution of step: '", filename, "\n")
  cat("###################################\n\n\n")
}

run_step("01_prepare_experimental_data.R")
run_step("02_create_reference_calculation.R")
run_step("03_extract_experimental_uncertainties.R")
run_step("04_tune_experimental_uncertainties.R")
run_step("05_create_reference_jacobian.R")
run_step("06_tune_endep_hyperpars.R")
run_step("07_tune_talyspars.R")
run_step("08_calculate_posterior_approximation.R")
run_step("09_create_randomfiles.R")




