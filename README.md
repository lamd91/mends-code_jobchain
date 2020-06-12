This repository contains an implementation of MEnDS, a "Multi-resolution approach to condition categorical multiple-point realizations to dynamic data with iterative ensemble smoothing" (https://doi.org/10.1029/2019WR025875).

This implementation corresponds to the execution of a "job chain", i.e. the submission of multiple jobs with dependency conditions, and is meant to be run on a CPU cluster managed by SLURM.

In addition to the files provided in this repository, you will need to acquire the executable "deesseHDinPyrOMP" from the RandLab research group (more info on http://www.randlab.org/). This executable is necessary to run generateMPSim_savePyr.sh and conditionMPSim.sh.

Then, to run this job chain implementation, execute the bash script mends.sh by simply typing "./mends.sh" in the repository.

