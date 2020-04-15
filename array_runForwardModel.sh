#!/bin/bash


# Display information about resource management for job
echo "Job ID: ${SLURM_JOB_ID}"
echo "Job execution node: ${SLURMD_NODENAME}"
echo "Number of nodes allocated: ${SLURM_NNODES}"
printf "List of nodes allocated: "
scontrol show hostname ${SLURM_JOB_NODELIST} | paste -d, -s
echo "Number of processes: ${SLURM_NTASKS}"
echo "Number of processes per node (if specified): ${SLURM_NTASKS_PER_NODE}"
echo "Number of CPUs on the allocated node: ${SLURM_CPUS_ON_NODE}"
echo "Number of CPUs per task (if specified, else 1 by default):  ${SLURM_CPUS_PER_TASK}"
echo "Number of CPUs allocated per node: ${SLURM_JOB_CPUS_PER_NODE}"
echo "==============="


modelName=$1
dataTypes=$2
iter=$3
nbAssimilations=$4

mpirun runForwardModel.sh $modelName ${SLURM_ARRAY_TASK_ID} $dataTypes ${iter} ${nbAssimilations} ${SLURM_CPUS_PER_TASK}



