utilpath <- "script/utils" 

# functions to read and save objects in the
# different steps of the evaluation pipeline
source(file.path(utilpath, "pipelinefuns.R"))

# function to generate a wrapper to run TALYS
# calculations and retrieve results
source(file.path(utilpath, "talys_wrapper.R"))

# functions to transform TALYS parameters using
# a logistic function to ensure TALYS parameters
# are bounded in a specific interval
source(file.path(utilpath, "trafofun.R"))

# collection of short function that are useful
# and not easy to group in broader categories
source(file.path(utilpath, "otherfuns.R"))

# a generator function create a logger function
# for the Levenberg-Marquardt optimization
source(file.path(utilpath, "LM_logger.R"))

# a generator function to create an object with
# functions to calculate the logarithmized posterior density
source(file.path(utilpath, "logPosterior_wrapper.R"))
