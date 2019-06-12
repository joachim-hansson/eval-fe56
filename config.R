##################################################
#
#       CONFIGURATION OF PIPELINE
#
##################################################

# root directory of the evaluation pipeline
rootpath <- "/home/user/eval-fe56"
setwd(rootpath)

source("required_packages.R")
source("required_sourcefiles.R")

# settings needed to connect to the cluster
# and run TALYS calculations in parallel
ssh_login <- "user@host.com"
ssh_pw <- "sshpassword"

# a valid path on the remote machine and the
# local machine, respectively, to store
# result files 
calcdir_rem <- "remoteCalcDir"
calcdir_loc <- "localCalcDir"

# settings to retrieve EXFOR entries from
# the MongoDb database
mongo_dbname <- "exfor"
mongo_colname <- "entries"

# energy grid for TALYS calculations and
# specification of the TALYS input file used as template
energyGrid <- seq(0.1, 30.001, length = 100)
param_template_path <- file.path(rootpath, "indata/n_Fe_056.inp")

# instantiate the transformation used for all parameters of the form ...adjust
# parameters are restricted to the interval (0.5, 1.5), in other words:
# the maximal deviation from the default values is 50%
paramTrafo <- generateTrafo(1, 0.5, 4) 

# only use experimental data in that energy range
minExpEn <- 2
maxExpEn <- 30

# set up the handlers to map TALYS results to EXFOR entries
subentHandler <- createSubentHandler(createDefaultSubentHandlerList())
exforHandler <- createExforHandler(subentHandler)
# abuAgent <- createAbuAgent("talys/structure/abundance/")
# subentHandler$getHandlerByName("handler_ntot_nat")$configure(list(abuAgent = abuAgent))

# specify the directory were status information and plots during the 
# optimization using the Levenberg-Marquardt algorithm should be stored
savePathLM <- file.path(rootpath, "log/LMalgo")

createTalysHandlers <- function() {

    # set up the connection to the cluster
    # and the functionality to run TALYS in parallel
    remHnd <- initSSH(ssh_login, ssh_pw,
                      tempdir.loc = calcdir_loc,
                      tempdir.rem = calcdir_rem)

    clustHnd <- initCluster(functions_multinode, remFun = remHnd) 

    # Important note: TMPDIR = "/dev/shm" is an important specification because /dev/shm usually
    #                 resides in main memory. TALYS produces many thousand files per run
    #                 and normal disks and shared file systems cannot deal with this load
    #                 so it is a good idea to store them in main memory.
    talysHnd <- initClusterTALYS(clustHnd, talysExe = "talys", calcsPerJob = 1000,
                                 runOpts = list(TMPDIR = "/dev/shm/talysTemp"))

    # initialize an alternative TALYS handler
    talysOptHnd <- createTalysFun(talysHnd)

    # Difference between talysHnd and talysOptHnd:
    #   talysHnd is a lower-level interface that provides
    #            the functions run, isRunning, and result.
    #            The input specification is passed as a list
    #            with input keywords and values and the output
    #            specification as a datatable enumerating the
    #            observables of interest

    #   talysOptHnd provides the functions fun and jac which 
    #               take a vector x as input and return either
    #               a vector of observables (fun) or the Jacobian 
    #               matrix (jac). Default parameter values and
    #               which values are present in x is specified
    #               via additional setter functions. Functions
    #               provided by talysOptHnd rely on those 
    #               provided by talysHnd.
    list(remHnd = remHnd,
         clustHnd = clustHnd,
         talysHnd = talysHnd,
         talysOptHnd = talysOptHnd)
}

