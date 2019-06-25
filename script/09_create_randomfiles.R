#
# DESCRIPTION OF STEP
#
# Use the 2nd order Taylor approximation of
# the posterior to create a sample of 
# TALYS parameter sets. Perform the respective
# calculations and save the results.
#

source("config.R")

#################################################
#       SCRIPT PARAMETERS
##################################################

scriptnr <- 9L
overwrite <- FALSE

##################################################
#       OUTPUT FROM PREVIOUS STEPS
##################################################

extNeedsDt <- read_object(2, "extNeedsDt")
optParamDt <- read_object(7, "optParamDt")
Sexp <- read_object(7, "Sexp")
mask <- read_object(7, "mask")
finalPars <- read_object(8, "finalPars")
finalParCovmat <- read_object(8, "finalParCovmat")

##################################################
#       START OF SCRIPT
##################################################

# define objects to be returned
outputObjectNames <- c("allParsets")
check_output_objects(scriptnr, outputObjectNames)

# if LM algorithm did not sufficiently converge
# in step 07, we cannot create the covariance matrix
stopifnot(all(finalParCovmat > 0))

# see step 07_tune_talyspars.R for more explanation
# about setting up the talys handler
talysHnds <- createTalysHandlers()
talys <- talysHnds$talysOptHnd
talys$setPars(optParamDt)
talys$setParTrafo(paramTrafo$fun, paramTrafo$jac)
talys$setNeeds(extNeedsDt)
talys$setSexp(Sexp)
talys$setMask(mask)
talys$setEps(0.01)

# create a sample of parameter sets
numPars <- length(finalPars)
variedParsets <- matrix(rnorm(numPars*numTalysFiles, 
                              rep(0,numPars*numTalysFiles),
                              rep(sqrt(finalParCovmat), numTalysFiles)),
                        nrow = numPars, ncol = numTalysFiles)
allParsets <- cbind(finalPars, variedParsets)

# perform calculations and save the result
talysHnds$remHnd$ssh$execBash(paste0("mkdir -p '", savePathTalys, "'; echo endofcommand"))
talys$fun(allParsets, applySexp = FALSE, saveDir = savePathTalys)

# save the needed files for reference
save_output_objects(scriptnr, outputObjectNames, overwrite)
