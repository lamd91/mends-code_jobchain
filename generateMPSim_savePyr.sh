#!/bin/bash

#-----------------------------------------------------------------------------

# NB: The command line arguments prevails over the following defined arguments in the header of job script (if uncommented)

# #SBATCH -J test              # job name
# #SBATCH -o test.out          # output file, redirection of stdout (and stderr (merged))
# #SBATCH -c 4                 # number of cpu(s) per task (var: SLURM_CPUS_PER_TASK)

# #SBATCH --mem-per-cpu=4G     # required memory per CPU (in MB or specified unit)
                             #    (default:DefMemPerCPU / type: scontrol show config |grep DefMemPerCPU)
# #SBATCH -t 00:20:00        # limit for total run time
                             #    format: "minutes", "minutes:seconds", "hours:minutes:seconds",
                             #    "days-hours", "days-hours:minutes" and "days-hours:minutes:seconds"
                             #    (default: partition DEFAULTTIME / type: sinfo -o "%P %L")

#-----------------------------------------------------------------------------
# * sbatch submits a batch script to Slurm (and exit).
# * srun run a parallel job on cluster managed by Slurm.
#      - srun command in a batch script submitted by sbatch define a job step and inherits pertinent options given by #SBATCH.
#      - Option --exclusive passed to srun ensure that distinct CPU(s) are used for each job step.
#=============================================================================

echo -n "Process ${SLURM_ARRAY_TASK_ID} running on:"
hostname

modelName=$1
iteration=$2
nbLevels=$3

homeDirPath=$(pwd)

mkdir -p /tmp/$USER/es/${modelName}/member_${SLURM_ARRAY_TASK_ID}
cd /tmp/$USER/es/${modelName}/member_${SLURM_ARRAY_TASK_ID}
rm -f *.txt *gslib
cp ${homeDirPath}/mp-pyr/${modelName}/testDeessePyr.in ${homeDirPath}/mp-pyr/${modelName}/ti.gslib .
sed -i 's/prefix4mpSimOutputFile/mpsim_'${SLURM_ARRAY_TASK_ID}'/g' testDeessePyr.in
sed -i 's/prefix4PyrOutputFile/pyr_'${SLURM_ARRAY_TASK_ID}'/g' testDeessePyr.in
((seedNumber=SLURM_ARRAY_TASK_ID+777))
sed -i 's/S33D/'${seedNumber}'/g' testDeessePyr.in

#-----------------------------------------

EXEC="/home/mastraubhaar/public/deesse_HDinPyramid_2/bin/deesseHDinPyrOMP"
#EXEC="/home/mastraubhaar/public/deesse_HDinPyramid_2/bin/deesseHDinPyr"

INPUTFILE="testDeessePyr.in"
#-----------------------------------------

while ! [ -s mpsim_${SLURM_ARRAY_TASK_ID}_*.gslib ] ||  ! [ -s pyr_${SLURM_ARRAY_TASK_ID}_*lev0000${nbLevels}.gslib ] # until file is not empty
do
	${EXEC} ${SLURM_CPUS_PER_TASK} ${INPUTFILE}
	wait
done


sed -n '4,$p' mpsim_${SLURM_ARRAY_TASK_ID}_*.gslib > mpsim_${SLURM_ARRAY_TASK_ID}.txt  # remove gslib header
sed -n '4,$p' pyr_${SLURM_ARRAY_TASK_ID}_*lev0000${nbLevels}.gslib > pyr_${SLURM_ARRAY_TASK_ID}.txt # remove gslib header
cp pyr_${SLURM_ARRAY_TASK_ID}.txt sim_pyrLev2_${SLURM_ARRAY_TASK_ID}.txt
sed -n '5,$p' pyr_${SLURM_ARRAY_TASK_ID}_*lev00001.gslib | awk '{print $2}' > sim_pyrLev1_${SLURM_ARRAY_TASK_ID}.txt # remove gslib header
sed -n '5,$p' pyr_${SLURM_ARRAY_TASK_ID}_*lev00001.gslib | awk '{print $1}' > sim_expanded_pyrLev1_${SLURM_ARRAY_TASK_ID}.txt # remove gslib header
sed -n '5,$p' pyr_${SLURM_ARRAY_TASK_ID}_*lev00000.gslib | awk '{print $1}' > sim_expanded_pyrLev0_${SLURM_ARRAY_TASK_ID}.txt # remove gslib header
#while [ ! -f mpsim_${SLURM_ARRAY_TASK_ID}.txt ] || [ ! -f pyr_${SLURM_ARRAY_TASK_ID}.txt ]; do sleep 0.25; done

rm -f flowPar_${SLURM_ARRAY_TASK_ID}.dat 
${homeDirPath}/makeFlowParFile4GW_mp.py ${SLURM_ARRAY_TASK_ID} 
wait
while [ ! -f flowPar_${SLURM_ARRAY_TASK_ID}.dat ]; do sleep 0.25; done

rm -f ${homeDirPath}/flowPar_${SLURM_ARRAY_TASK_ID}.dat  ${homeDirPath}/mpsim_${SLURM_ARRAY_TASK_ID}.txt ${homeDirPath}/pyr_${SLURM_ARRAY_TASK_ID}.txt
cp flowPar_${SLURM_ARRAY_TASK_ID}.dat mpsim_${SLURM_ARRAY_TASK_ID}.txt pyr_${SLURM_ARRAY_TASK_ID}.txt pyr_${SLURM_ARRAY_TASK_ID}_*lev0000${nbLevels}.gslib sim_pyrLev1_${SLURM_ARRAY_TASK_ID}.txt sim_expanded_pyrLev1_${SLURM_ARRAY_TASK_ID}.txt sim_expanded_pyrLev0_${SLURM_ARRAY_TASK_ID}.txt sim_pyrLev2_${SLURM_ARRAY_TASK_ID}.txt ${homeDirPath}

cd ${homeDirPath}
while [ ! -f flowPar_${SLURM_ARRAY_TASK_ID}.dat ] || [ ! -f mpsim_${SLURM_ARRAY_TASK_ID}.txt ] || [ ! -f pyr_${SLURM_ARRAY_TASK_ID}.txt ]; do sleep 0.25; done




