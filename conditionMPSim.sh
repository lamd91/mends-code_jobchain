#! /bin/bash

#-----------------------------------------------------------------------------

# #SBATCH -J test              # job name
# #SBATCH -o test.out          # output file, redirection of stdout (and stderr (merged))
# #SBATCH -c 4                 # number of cpu(s) per task (var: SLURM_CPUS_PER_TASK)

# #SBATCH --mem-per-cpu=4G     # required memory per CPU (in MB or specified unit)
                             #    (default:DefMemPerCPU / type: scontrol show config |grep DefMemPerCPU)
#SBATCH -t 00:20:00        # limit for total run time
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

homeDirPath=$(pwd) # path to folder from which script of chained jobs has been executed

mkdir -p /tmp/$USER/es/${modelName}/member_${SLURM_ARRAY_TASK_ID} # creates local working directory on node
cd /tmp/$USER/es/${modelName}/member_${SLURM_ARRAY_TASK_ID}
rm -f *.gslib mpsim_* pyr_*
cp ${homeDirPath}/mp-pyr/${modelName}/testCondDeessePyr_savePyr.in ${homeDirPath}/mp-pyr/${modelName}/ti.gslib ${homeDirPath}/pyr4deesse_${SLURM_ARRAY_TASK_ID}.txt .  # copy necessary files from master to run DeeSse
sed -i 's/nan/-9999999/g' pyr4deesse_${SLURM_ARRAY_TASK_ID}.txt # for masked values
cat ${homeDirPath}/mp-pyr/${modelName}/header4UpdatedPyrGSLIBFile.txt pyr4deesse_${SLURM_ARRAY_TASK_ID}.txt > pyr_${SLURM_ARRAY_TASK_ID}.gslib
cp pyr_${SLURM_ARRAY_TASK_ID}.gslib pyr_${SLURM_ARRAY_TASK_ID}_beforeDS.gslib
sed -i 's/prefix4mpSimOutputFile/mpsim_'${SLURM_ARRAY_TASK_ID}'/g' testCondDeessePyr_savePyr.in
sed -i 's/updatedPyr.gslib/pyr_'${SLURM_ARRAY_TASK_ID}'.gslib/g' testCondDeessePyr_savePyr.in
sed -i 's/prefix4PyrOutputFile/pyr_'${SLURM_ARRAY_TASK_ID}'/g' testCondDeessePyr_savePyr.in
seedNumber=888
#seedNumber=666
sed -i 's/S33D/'${seedNumber}'/g' testCondDeessePyr_savePyr.in

#-----------------------------------------

EXEC="/home/mastraubhaar/public/deesse_HDinPyramid_2/bin/deesseHDinPyrOMP"

INPUTFILE="testCondDeessePyr_savePyr.in"


# Run conditional DeeSse simulation  
#-----------------------------------------
while ! [ -s mpsim_${SLURM_ARRAY_TASK_ID}_*.gslib ] ||  ! [ -s pyr_${SLURM_ARRAY_TASK_ID}_*lev0000${nbLevels}.gslib ] # until file is not empty
do
	${EXEC} ${SLURM_CPUS_PER_TASK} ${INPUTFILE}
	wait
done

mv mpsim_${SLURM_ARRAY_TASK_ID}_*.gslib mpsim_${SLURM_ARRAY_TASK_ID}.gslib
sed -n '4,$p' mpsim_${SLURM_ARRAY_TASK_ID}.gslib > mpsim_${SLURM_ARRAY_TASK_ID}.txt  # remove gslib header
sed -n '4,$p' pyr_${SLURM_ARRAY_TASK_ID}_*lev0000${nbLevels}.gslib > pyr_${SLURM_ARRAY_TASK_ID}.txt # remove gslib header
sed -n '5,$p' pyr_${SLURM_ARRAY_TASK_ID}_*lev00001.gslib | awk '{print $2}' > lev1pyr_${SLURM_ARRAY_TASK_ID}.txt

# Make parameter file for flow simulation
rm -f flowPar_${SLURM_ARRAY_TASK_ID}.dat 
${homeDirPath}/makeFlowParFile4GW_mp.py ${SLURM_ARRAY_TASK_ID} 
wait
while [ ! -f flowPar_${SLURM_ARRAY_TASK_ID}.dat ]; do sleep 0.25; done


rm -f ${homeDirPath}/flowPar_${SLURM_ARRAY_TASK_ID}.dat ${homeDirPath}/mpsim_${SLURM_ARRAY_TASK_ID}.txt
cp flowPar_${SLURM_ARRAY_TASK_ID}.dat mpsim_${SLURM_ARRAY_TASK_ID}.txt pyr_${SLURM_ARRAY_TASK_ID}_beforeDS.gslib pyr_${SLURM_ARRAY_TASK_ID}.txt lev1pyr_${SLURM_ARRAY_TASK_ID}.txt ${homeDirPath}


