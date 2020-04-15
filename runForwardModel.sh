#!/bin/bash

echo $(hostname)

# Parse command line arguments
modelName=$1
processRank=$2
dataTypes=$3
iter=$4
nbAssimilations=$5
cpusPerProcess=$6


##---- Prepare member's local working directory ----##

homeDirPath=$(pwd)

# Other variables (which change with the model selected for calibration)
nbObsPts=$(awk '/OBSERVATION POINTS/{f=1;next} /end/{f=0} f' ${homeDirPath}/$modelName/forgw/gw_tr/ref_flow.fed | wc -l) # number of head observation locations
nbOfFluidBudgets=$(grep "^[^\!]" ${homeDirPath}/$modelName/forgw/gw_tr/ref_flow.fed | grep "Layer" | wc -l) # number of flowrate measurement "locations" (group of nodes)
		
# Wait for GW input file before continuing
while [ ! -f ${homeDirPath}/flowPar_${processRank}.dat ]
do
	sleep 0.5
done

mkdir -p /tmp/$USER/es/$modelName/member_${processRank}/iniHeads
cp ${homeDirPath}/flowPar_${processRank}.dat ${homeDirPath}/$modelName/forgw/gw_st/Flow_BCs_ST.txt ${homeDirPath}/$modelName/forgw/gw_st/ref_flow.fed ${homeDirPath}/$modelName/forgw/gw_st/ref_flow.mesh ${homeDirPath}/$modelName/forgw/gw_st/gw.card ${homeDirPath}/$modelName/forgw/gw_st/gw.cmds ${homeDirPath}/$modelName/forgw/gw_st/main.sup /tmp/$USER/es/$modelName/member_${processRank}/iniHeads

cp ${homeDirPath}/flowPar_${processRank}.dat ${homeDirPath}/$modelName/forgw/gw_tr/Flow_BCs_TR.txt ${homeDirPath}/$modelName/forgw/gw_tr/ref_flow.fed ${homeDirPath}/$modelName/forgw/gw_tr/ref_flow.mesh ${homeDirPath}/$modelName/forgw/gw_tr/gw.card ${homeDirPath}/$modelName/forgw/gw_tr/gw.cmds ${homeDirPath}/$modelName/forgw/gw_tr/main.sup /tmp/$USER/es/$modelName/member_${processRank}/
#N.B.: make sure to have the right *.mesh binary file


##---- Start GW steady-state simulations ----##

cd /tmp/$USER/es/$modelName/member_${processRank}/iniHeads
sed -i 's/flowParFile/flowPar_'${processRank}'.dat/g' *.cmds # inform GW of the name of the external GW input parameter file 
sed -i 's/headOutput.txt/initialHeads_'${processRank}'.dat/g' *.cmds # will be the name of the ST simulations output files
sed -i '/OMP number of threads/!b;n;c'${cpusPerProcess}'' *.cmds # number of threads defined in GW should match number of cpus per process
sed -i 's///g' gw.card gw.cmds # delete "^M" at end of each line

LD_LIBRARY_PATH=${homeDirPath}/lib_gw/ ${homeDirPath}/gw3.6.0_Lin64
wait # until simulations are done before processing data
mv ref_flow.out ref_flow_ST.out # for convergence checking file


##---- Initialize heads for GW transient simulations ----##

cp initialHeads_${processRank}.dat .. # copy initial heads file in working directory for transient simulations

cd .. # currently in working directory for transient simulations (absolute path=/tmp/$USER/es/model#/member_#/)
sed -i 's/flowParFile/flowPar_'${processRank}'.dat/g' *.cmds # inform GW of the name of the external GW input parameter file 
sed -i 's/initialHeads/initialHeads_'${processRank}'.dat/g' *.cmds # will be the name of the ST simulations output files
sed -i '/OMP number of threads/!b;n;c'${cpusPerProcess}'' *.cmds # number of threads defined in GW should match number of cpus per process
#sed -i '/TINI/ d' gw.card # delete line containing TINI 
#sed -i '/TEND/ d' gw.card # delete line containing TEND
#sed -i '/EPSILON/ a TINI='$t_ini'\nTEND='$t_end gw.card # append the line after the line where EPISLON is found
#lastAssimTime=43200.0 # select last line of file
#sed -i "/TINI/ a TEND=${lastAssimTime}"  gw.card  # append the line after the line where TINI is found. (TEND is the last assimilation time for a data assimilation by Ensemble Smoother)
sed -i 's///g' gw.card gw.cmds # delete "^M" at end of each line


##---- Start GW transient simulation for each realization of flow parameters ----##

LD_LIBRARY_PATH=${homeDirPath}/lib_gw/ ${homeDirPath}/gw3.6.0_Lin64
wait # until simulations are done before processing data
mv ref_flow.out ref_flow_TR.out # for convergence checking file


##---- Prepare simulated heads at observation locations ----##

# Crop simulated head output file
((lastColumnIndex4HeadObs=24*${nbObsPts}+24))
((newLastColumnIndex4HeadObs=24*${nbObsPts}))	
sed '1,/ZONE/d' ref_flow_obs_H_xyz.dat > temp.txt # delete useless first lines
sed -n '1~4p' temp.txt > temp2.txt # select lines every 4 computation time steps
cut -c25-$lastColumnIndex4HeadObs temp2.txt > simulatedHeads_${processRank}.txt # without first column (time)
rm temp* # remove temporary files

# If they exist, crop simulated flowrate output file
if [ ${nbOfFluidBudgets} -ne 0 ]
then
	# Make file with all simulated flowrate data (concatenated in one single column or by columns corresponding to each layer)
	rm -f temp_simFlowrates_${processRank}.txt
	j=1
	while [ ${j} -le ${nbOfFluidBudgets} ]
	do
		#sed '1,/ZONE/d' ref_flow_fluid_budget_${j}.dat > temp_${j}.txt
        	sed -n '8,27p' ref_flow_fluid_budget_${j}.dat > temp_${j}.txt
		cut -c49-71 temp_${j}.txt | awk '{printf("%.4e\n",$1)}' > simulatedFlowrates${j}.txt # select "OUT" flowrates
		cut -c49-71 temp_${j}.txt | awk '{printf("%.4e\n",$1)}' >> temp_simFlowrates_${processRank}.txt # absolute values of "OUT" flowrates
		((j=j+1))
	done

	# Add gaussian noise to simulate the error of the measurement process
	${homeDirPath}/addInflatedNoiseToSimData.py $modelName q ${processRank} $nbAssimilations ${nbObsPts} ${homeDirPath}
	
	#awk -F, '{printf("%.4e\n",$1)}' temp_simFlowrates_${processRank}.txt > simFlowrates_${processRank}.txt # reformat flowrates output value
	cat temp_simFlowrates_${processRank}.txt > simFlowrates_${processRank}.txt # reformat flowrates output value

	cp simulatedHeads_${processRank}.txt simulatedDataAtObsPts2_${processRank}.txt
else
	cp simulatedHeads_${processRank}.txt simulatedDataAtObsPts2_${processRank}.txt
fi

rm -f temp* simulatedF* simulatedHeads.txt simulatedF* # remove temporary files


# Make file of simulated head data
rm -f temp_simHeads_${processRank}.txt # delete preexisting files

ini_index=1
fin_index=24
k=1

while [ $k -le ${nbObsPts} ]
do
	cut -c${ini_index}-${fin_index} simulatedDataAtObsPts2_${processRank}.txt | awk -F, '{printf("%.6f\n",$1)}' >> temp_simHeads_${processRank}.txt
        ((ini_index=ini_index+24))
	((fin_index=fin_index+24))
       ((k=k+1))
done

# Add gaussian noise to simulate the error of the measurement process
${homeDirPath}/addInflatedNoiseToSimData.py $modelName h ${processRank} $nbAssimilations ${nbObsPts} ${homeDirPath}

# Prepare simulated data file according to the type of observations assimilated (calibration dataset)
rm -f simData_${processRank}.txt simDataWithNoise_${processRank}.txt
while [ ! -f simHeads_${processRank}.txt ] && [ ! -f simHeadsWithNoise_${processRank}.txt ] && [ ! -f simFlowrates_${processRank}.txt ] && [ ! -f simFlowratesWithNoise_${processRank}.txt ]; do sleep 0.5; done	

if [ $dataTypes == "h" ]
then
	cat simHeads_${processRank}.txt > simData_${processRank}.txt
	cat simHeadsWithNoise_${processRank}.txt > simDataWithNoise_${processRank}.txt

elif [ $dataTypes == "h+q" ]
then
	cat simHeads_${processRank}.txt simFlowrates_${processRank}.txt > simData_${processRank}.txt
	cat simHeadsWithNoise_${processRank}.txt simFlowratesWithNoise_${processRank}.txt > simDataWithNoise_${processRank}.txt
fi


# Create files of simulated data per location (and data type)
i=1
line_start4heads=1
line_start4deltaHeads=1
line_end4heads=37 
rm -f simHeadsWithNoise_${processRank}_* simHeads_${processRank}_* 

while [ ${i} -le ${nbObsPts} ] #TODO: change for model5
do
	sed -n ${line_start4heads},${line_end4heads}p simHeadsWithNoise_${processRank}.txt > simHeadsWithNoise_${processRank}_${i}.txt
	sed -n ${line_start4heads},${line_end4heads}p simHeads_${processRank}.txt > simHeads_${processRank}_${i}.txt
	((line_start4heads=line_start4heads+37))
	((line_end4heads=line_end4heads+37))
	((i=i+1))
	
	while [ -f simHeadsWithNoise_${processRank}_${i}.txt ] && [ -f simHeads_${processRank}_${i}.txt ]; do sleep 0.25; done
done

j=1
line_start4heads=1
line_end4flowrates=20
rm -f simFlowratesWithNoise_${processRank}_* simFlowrates_${processRank}_*

while [ ${j} -le ${nbOfFluidBudgets} ] 
do
	sed -n ${line_start4heads},${line_end4heads}p simFlowratesWithNoise_${processRank}.txt > simFlowratesWithNoise_${processRank}_${j}.txt
	sed -n ${line_start4heads},${line_end4heads}p simFlowrates_${processRank}.txt > simFlowrates_${processRank}_${j}.txt
	((line_start4flowrates=line_start4flowrates+20))
	((line_end4flowrates=line_end4flowrates+20))
	((j=j+1))
	
	while [ -f simFlowratesWithNoise_${processRank}_${j}.txt ] && [ -f simFlowrates_${processRank}_${j}.txt ]; do sleep 0.25; done
done	


# Copy files of simulated data to main working directory 
cp simHeadsWithNoise_${processRank}.txt simFlowratesWithNoise_${processRank}.txt simDataWithNoise_${processRank}.txt simData_${processRank}.txt simHeads_${processRank}.txt simFlowrates_${processRank}.txt simulatedDataAtObsPts2_${processRank}.txt simHeadsWithNoise_${processRank}_* simHeads_${processRank}_* simFlowratesWithNoise_${processRank}_* simFlowrates_${processRank}_* ${homeDirPath} 
wait 


# Delete first line of parameter input file
cd ${homeDirPath}
sed -i '1d' flowPar_${processRank}.dat

