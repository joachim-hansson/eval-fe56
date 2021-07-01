### Evaluation pipeline for Fe56 - version 0.1.0

This repository contains a pipeline that has
been created for the evaluation of neutron-induced
reactions of the isotope Fe56 using the nuclear models
code TALYS.

It features several innovations in evaluation methodology,
such as the automatic correction of experimental uncertainties
using marginal likelihood optimization, Gaussian process priors
on energy-dependent model parameters, and the application of
the Levenberg-Marquardt algorithm to optimize more than
hundred TALYS model parameters exploiting parallelization
on a computer cluster.

The pipeline can also be regarded as an example of 
how the functionality of R packages available on
this github account can be combined for the purpose of
an evaluation.
Noteworthy packages are:

* [MongoEXFOR](https://github.com/gschnabel/MongoEXFOR):
  Search and retrieve data from EXFOR subentries in a
  MongoDB database.
* [talysExforMapping](https://github.com/gschnabel/talysExforMapping):
  Convert TALYS results to quantities that are comparable with the data
  in EXFOR subentries (e.g., energy interpolation).
* [nucdataBaynet](https://github.com/gschnabel/nucdataBaynet):
  Allows the flexible specification of uncertainties for a variety 
  of quantities, such as experimental data and model parameters, either as 
  multivariate normal distributions or Gaussian processes, and
  solving the resulting Bayesian update equations.

The pipeline has some dependencies, such as a MongoDB database 
with EXFOR subentries, the R interpreter, and some Linux command line
tools for communication via SSH.
To facilitate the use and exploration of the pipeline, 
a Docker file has been created which takes care of assembling
a Docker image with all the mentioned dependencies.
It can be found at <https://github.com/gschnabel/eval-fe56-docker>
together with a manual that contains installation instructions
and more details about the structure of the pipeline.
