# Performs all the steps in directory eval-fe56/script
# which are part of the exemplary Fe56 evaluation.

# Example usage:
# nohup Rscript --vanilla run_pipeline.R "config/config.R" &
#################################################
#       SCRIPT SETUP
##################################################

args = commandArgs(trailingOnly=TRUE)

if (length(args)==0) {
  print("No config file supplied, using default file:")
  config <- file.path("config", "config.R")
  source(config)
} else if (length(args) != 1) {
  stop("run_script only accepts one config file", call.=FALSE)
} else {
  print(paste0("Setting as config file: ", args[1]))
  config <- args[1]
  source(config)
}

##################################################
#       SETUP RUN SCRIPTS
##################################################

create_run_step <- function(config){
  run_step <- function(filename) {
    Sys.sleep(1)
    filepath <- file.path("script", filename)
    Rscript <- paste0("Rscript --vanilla --no-save --no-restore")
    script_n <- substr(filename, 1, 2)
    logPath <- file.path(outdataPath, script_n)
    dir.create(file.path(logPath), showWarnings = FALSE)
    logfile <- file.path(logPath, paste0(script_n,"_run.log"))
    cmdstr <- paste0(Rscript," ",filepath," ",config," 2>&1 | tee ", logfile)
    cat("###################################\n")
    cat("Starting execution of step: '", filename, "\n")
    cat("###################################\n\n")
    print(cmdstr)
    system(paste0("mkdir -p ", file.path(getwd(), outdataPath) ))
    system(cmdstr)
    cat("###################################\n")
    cat("Finished execution of step: '", filename, "\n")
    cat("###################################\n\n\n")
  }
}

#################################################
#       RUN SCRIPTS
##################################################

run_step <- create_run_step(config=config)

#run_step("01_prepare_experimental_data.R")
#run_step("02_create_reference_calculation.R")
#run_step("03_extract_experimental_uncertainties.R")
#run_step("04_tune_experimental_uncertainties.R")
run_step("05_create_reference_jacobian.R")
run_step("06_tune_endep_hyperpars.R")
run_step("07_tune_talyspars.R")
run_step("08_calculate_posterior_approximation.R")
run_step("09_create_randomfiles.R")




