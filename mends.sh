#!/bin/bash 

## This script allows the execution of a chain of jobs on a cluster of CPUs which uses SLURM to schedule job submissions.
## This chain of jobs is an implementation of a data assimilation (DA) workflow introduced in Lam et al. (2020).
## The workflow leverages multiresolution multiple-point Direct Sampling (DS) simulations to perform Ensemble Data Assimilation. 
## We named this DA workflow/approach "MEnDS" since its goal is to "mend" structures which otherwise would break with standard Ensemble DA.
## Ensemble DA is here performed by the iterative ensemble smoother ES-MDA (Emerick & Reynolds 2013) which uses a predefined number of iterations.
## The multiresolution multiple-point DS simulations described in Straubhaar et al. (2020) are here performed by a special version of DeeSse.
## This version of DeeSse allows hard data conditioning at the coarsest scale of the simulations.

###########################################

# Clean main working directory
rm -f flowPar* # delete some files in main directory
rm -f sim*
rm -f obs*.txt
rm -f h-dh*.txt mismatch*.txt iniParEns* logPar* next* out.txt devFrom* ens* param* checkC* hSim_* qSim_* 
rm -f *.out parUpgrade* iniS* objFun*.txt nbOfActiveProcesses* obs*.txt temp* LevM* hdh* transf* backTr* iniFlowPar*.dat 
rm -f gauss*.txt

# Variables to set manually before running this script 
ensembleSize=100
nbAssimilations=16 # number of predefined iterations
nbSV=99 # number of singular values used in SVD
modelName="model9"  # "model9" corresponds to test case with reference 'A', "model10" corresponds to case 'B'
dataTypes="h" # only the hydraulic heads are assimilated in test cases 'A' and 'B'
nbLevels=2 # number of levels in pyramid for multiresolution MPS simulations in test cases 'A' and 'B'

# Other required variables
((lastProcessRank=$ensembleSize-1)) 


## Initialization

# Generate ensemble of MPS simulations with DeeSse
# Save resulting pyramids
jobID_1=`sbatch --parsable -J genMP -o genMP.out -c 1 -p any -t 00:20:00  --array=0-${lastProcessRank} generateMPSim_savePyr.sh $modelName $nbLevels`

# Make ensemble of pyramid (coarsest-level) values, categorical MPS fields
jobID_2=`sbatch --parsable -J mp-pyrEns_0 -o mp-pyrEns_0.out -n 1 -c 1 -p any -t 00:10:00 --dependency=afterok:${jobID_1} makeInitialMPSimEns.sh ${lastProcessRank}`

# Compute Normal Score Transform of pyramid values (i.e. the parameters that will be updated)
jobID_3=`sbatch --parsable -J ns_0 -o ns_0.out -c 1 --mem-per-cpu=3900 -p any -t 1:00:00 --dependency=afterok:${jobID_2} --array=0-${lastProcessRank} array_normalScoreTransform_pyr.sh $modelName 0`

# Create initial ensemble of normal score transformed values 
jobID_4=`sbatch --parsable -J nsPyrEns_0 -o nsPyrEns_0.out -n 1 -c 1 -p any -t 1:00:00 --dependency=afterok:${jobID_3} makeNSPyrEns.sh $modelName $lastProcessRank $dataTypes 0`

# Sample conditioning locations from conditioning map to give to Deesse (comment this job if you want to generate a new file with hard conditioning point locations) 
jobID_5=`sbatch --parsable -J sampleCD -o sampleCD.out -p any -c 1 -n 1 -t 00:10:00 --dependency=afterok:${jobID_4} sampleConditioningLocations.sh $modelName`

# Back Transform the transformed pyramid values
jobID_6=`sbatch --parsable -J bns_0 -o bns_0.out -c 3 --mem-per-cpu=3900 -p any -t 1:00:00 --dependency=afterok:${jobID_5} --array=0-${lastProcessRank} array_backTransform_nsPyr.sh  $modelName 0`
#jobID_6=`sbatch --parsable -J bns_0 -o bns_0.out -c 3 --mem-per-cpu=3900 -p any -t 1:00:00 --dependency=afterok:${jobID_4} --array=0-${lastProcessRank} array_backTransform_nsPyr.sh $modelName 0` # comment the lines associated to jobID_5 and jobID_6 if you uncomment this line

# Make ensemble of back transformed parameters (parameters = transformed pyramid values)
# Sample values used as hard conditioning data (HD) for DeeSse
jobID_7=`sbatch --parsable -J uPyrEns_0 -o uPyrEns_0.out -n 1 -c 1 -p any -t 00:10:00 --dependency=afterok:${jobID_6} updatePyrEns.sh $modelName 0 ${lastProcessRank}`


# Optimization loop 

it=0 # counter of iterations 

# For each iteration, for each member 
for it in `seq ${it} $nbAssimilations`
do
	# Update perturbed observation file for each member of the ensemble
	jobID_8a=`sbatch --parsable -J makeObsEns_${it} -o makeObsEns_${it}.out -c 1 -p any -t 00:05:00 --dependency=afterok:${jobID_7} prepInflatedObsDataEns.sh $modelName $dataTypes $nbAssimilations $ensembleSize`

	jobID_8b=`sbatch --parsable -J prepObs_${it} -o prepObs_${it}.out -c 3 -p any -t 00:05:00 --dependency=afterok:${jobID_8a} --array=0-${lastProcessRank} array_prepInflatedObsData.sh $modelName $dataTypes $nbAssimilations`
	
	# Condition previous MP simulation using the updated gaussian pyramid as hard data (DeeSse)
	# Populate facies simulations with constant K values
	jobID_9=`sbatch --parsable -J condMP_${it} -o condMP_${it}.out -c 3 -p any -t 01:00:00 --dependency=afterok:${jobID_8b} --array=0-${lastProcessRank} conditionMPSim.sh $modelName ${nbLevels}`
	
	# Run forward model with the updated MP simulations 
	jobID_10=`sbatch --parsable -J fwd_${it} -o fwd_${it}.out -c 1 -p any -c 1 -t 01:00:00  --dependency=afterok:${jobID_9} --array=0-${lastProcessRank} array_runForwardModel.sh $modelName $dataTypes ${it} $nbAssimilations`

	# Update ensemble of K parameters and Normal-Score Transformed simulated data
	jobID_11=`sbatch --parsable -J ens-mp_simD_${it} -o ens-mp_nsD_${it}.out -n 1 -c 1 -p any -t 00:05:00 --dependency=afterok:${jobID_10} makeEns_mpsim_simData.sh ${modelName} ${it} ${lastProcessRank}`

	# Compute objective function
	jobID_12=`sbatch --parsable -J OF_${it} -o OF_${it}.out -p any -c 1 -t 00:10:00 --dependency=afterok:${jobID_11} --array=0-${lastProcessRank} array_calcOF.sh $modelName $dataTypes ${it}`

	# Create output files from the current iteration for later analysis 
	jobID_13=`sbatch --parsable -J interFiles_${it} -o interFiles_${it}.out -n 1 -c 1 -p any -t 00:05:00 --dependency=afterok:${jobID_12} makeFiles4IntermediateFigs.sh $modelName $ensembleSize ${it} $dataTypes`

	# Compute deviations of parameter and simulated data from ensemble mean 		
	jobID_14=`sbatch --parsable -J calcDev_${it} -o calcDev_${it}.out -p any  -c 1 -t 00:10:00 --dependency=afterok:${jobID_13} --array=0-${lastProcessRank} array_calcDevFromMean.sh $ensembleSize $modelName $dataTypes`

	# Concatenate files into one ensemble file of parameter or simulated data deviations from their mean
	jobID_15=`sbatch --parsable -J devEns_${it} -o simDataDevEns_ParDevEns_${it}.out -p any -c 1 -n 1 -t 00:05:00 --dependency=afterok:${jobID_14} makeEnsOfDeviations.sh $ensembleSize`

	# Calculate parameter update (ES-MDA update equation)
	jobID_16=`sbatch --parsable -J gain_${it} -o gain_${it}.out -p any -c 3 -t 00:10:00 --dependency=afterok:${jobID_15} --array=0-${lastProcessRank} array_computeGain_esmda-loc_updateNSPyr.sh $ensembleSize $modelName ${nbSV} $dataTypes $nbAssimilations`

	# Update ensemble of parameters (i.e. the normal score transformed values of pyramid coarsest level values)
	jobID_17=`sbatch --parsable -J u_nsPyrEns_${it} -o u_nsPyrEns_${it}.out -n 1 -c 1 --mem-per-cpu=3900 -p any -t 1:00:00 --dependency=afterok:${jobID_16} updateNSPyrEns.sh $modelName $lastProcessRank $dataTypes ${it}`

	# Back Transform the transformed pyramid values (so that the values are bounded between 0 and 1)
	jobID_18=`sbatch --parsable -J bns_${it} -o bns_${it}.out -c 3 --mem-per-cpu=3900 -p any -t 1:00:00 --dependency=afterok:${jobID_17} --array=0-${lastProcessRank} array_backTransform_nsPyr.sh $modelName ${it}`
	 
	# Make ensemble of updated back transformed parameters (i.e. the updated "pyramid values" to be used as hard conditioning data for the next iteration)
	jobID_19=`sbatch --parsable -J uPyrEns_${it} -o uPyrEns_${it}.out -n 1 -c 1 -p any -t 00:10:00 --dependency=afterok:${jobID_18} updatePyrEns.sh $modelName ${it} ${lastProcessRank}`

	jobID_7=${jobID_19}

done


