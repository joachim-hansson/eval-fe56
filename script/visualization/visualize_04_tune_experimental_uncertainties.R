source("config.R")
library(ggplot2)

origSysDt <- read_object(4, "origSysDt")
updSysDt <- read_object(4, "updSysDt")
expDt <- read_object(3, "expDt")

normHandler <- createSysCompNormHandler("DATAREF")
normHandler$addSysUnc("EXPID", "", 0, 0, TRUE)

sysCompHandler <- createSysCompHandler()
sysCompHandler$addHandler(normHandler)

S <- sysCompHandler$map(expDt, origSysDt, ret.mat = TRUE)
origX <- sysCompHandler$cov(origSysDt, ret.mat = TRUE)
updX <- sysCompHandler$cov(updSysDt, ret.mat = TRUE)
statUnc <- getDt_UNC(expDt)

origUnc <- sqrt(statUnc^2 + diag(S %*% origX %*% t(S))) 
updUnc <- sqrt(statUnc^2 + diag(S %*% updX %*% t(S)))

setkey(expDt, IDX)
expDt[, ORIGUNC := origUnc]
expDt[, UPDUNC := updUnc]

library(ggplot2)

# reactions <- c("(26-FE-56(N,2N)26-FE-55,,SIG)",
#                "(26-FE-56(N,P)25-MN-56,,SIG)")
reactions <- c("(26-FE-56(N,2N)26-FE-55,,SIG)")

for (curReac in reactions) {

    curExpDt <- expDt[REAC == curReac]
    ggp <- ggplot(curExpDt) + theme_bw() + guides(col = FALSE)
    ggp <- ggp + xlab("energy [MeV]") + ylab("cross section [mbarn]")
    ggp <- ggp + ggtitle(curReac)

    ggp <- ggp + geom_errorbar(aes(x = L1, ymin = DATA - UPDUNC, ymax = DATA + UPDUNC), col = "green", size = 1)
    ggp <- ggp + geom_errorbar(aes(x = L1, ymin = DATA - ORIGUNC, ymax = DATA + ORIGUNC, col = EXPID), size = 1)
    ggp <- ggp + geom_point(aes(x = L1, y = DATA, col = EXPID))

    print(ggp)
    dir.create(plotPath, recursive=TRUE, showWarnings=FALSE)
    filepath <- file.path(plotPath, 'plot_example_MLO_correction.png')
    ggsave(filepath, ggp, width = 15, height = 10, units = "cm", dpi = 300)
}

