This repository contains an implementation of an ensemble-based data assimilation approach called "mends" which can run on a HPC cluster that uses the scheduler SLURM. For more information on this approach, check the paper "Multi-resolution approach to condition categorical multiple-point realizations to dynamic data with iterative ensemble smoothing" (https://doi.org/10.1029/2019WR025875). 

The implementation consists in executing a "job chain" i.e. a series of job submissions with dependencies, expressed in the file mends.sh. Note that only the SLURM commands in mends.sh should be adapted in order to run the code on a cluster that uses another job scheduler (e.g. PBS, UGE, etc.)

In addition to the files provided in this repository, you will need to acquire the executable "deesseHDinPyrOMP" from the RandLab research group (more info on http://www.randlab.org/). This executable is necessary to run generateMPSim_savePyr.sh and conditionMPSim.sh.

To run this job chain-based implementation, simply execute the bash script mends.sh by typing ./mends.sh in the repository.

