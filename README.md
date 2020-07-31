This repository contains an implementation of an ensemble-based data assimilation approach called "MEnDS" for a HPC cluster using SLURM. For more information on this approach, check the paper "Multi-resolution approach to condition categorical multiple-point realizations to dynamic data with iterative ensemble smoothing" (https://doi.org/10.1029/2019WR025875). 

This implementation leverages functionalities the HPC scheduler and corresponds to the execution of multiple jobs with dependencies or a "job chain" which is expressed in the file mends.sh. Note that only the SLURM commands of mends.sh should be modified to be run on clusters using other types of scheduler such as PBS, UGE, etc.

In addition to the files provided in this repository, you will need to acquire the executable "deesseHDinPyrOMP" from the RandLab research group (more info on http://www.randlab.org/). This executable is necessary to run generateMPSim_savePyr.sh and conditionMPSim.sh.

Then, to run this job chain implementation, execute the bash script mends.sh by simply typing ./mends.sh in the repository.

