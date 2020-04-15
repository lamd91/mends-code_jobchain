#!/bin/bash


# Deleting useless lines from synthetic head output file
#sed -n '/0.3000000000000000E+03/,$p' ref_flow_obs_H_xyz.dat > temp.txt  # starting from this line
sed -n '/0.0000000000000000E+00/,$p' ref_flow_obs_H_xyz.dat > temp.txt  # starting from this line
sed -n '1~4p' temp.txt > temp2.txt
cut -c25-263 temp2.txt > synDataByObsPts_2.txt # without the first column with times
cut -c1-23 temp2.txt > assimTimes.txt  # only the first column with times

# Preparing flowrate observations
i=1
nbLayers=5 
while [ $i -le $nbLayers ]
do
	#deleting useless lines from synthetic flowrate output file
#	sed -n '/0.3000000000000000E+03/,$p' ref_flow_fluid_budget_$i.dat > temp_$i.txt
	sed -n '8,27p' ref_flow_fluid_budget_$i.dat > temp_$i.txt	
#	cut -c49-71 temp_$i.txt | awk '{ if($1>=0) {printf("%.4e\n",$1)} else {printf("%.4e\n",$1*-1)} }' > gwSynFlowrates$i.txt
	cut -c49-71 temp_$i.txt | awk '{printf("%.4e\n",$1)}' > gwSynFlowrates$i.txt
	((i=i+1))
done
cat $(printf gwSynFlowrates%d".txt " $(seq 1 $nbLayers)) > temp_synFlowrates.txt
awk -F, '{printf("%.4e\n",$1)}' temp_synFlowrates.txt > synFlowrates.txt # reformat flowrates output value
cp synFlowrates.txt flowrateObsData_withoutNoise.txt
./addRegularNoiseToSynObsData.py q

# Preparing head observations

rm temp* # removing temporary files

nbObsPts=10
ini_index=1
fin_index=24
i=1
rm -f synHeads.txt
while [ $i -le $nbObsPts ]
do
	cut -c$ini_index-$fin_index synDataByObsPts_2.txt >> temp_synHeads.txt # contains synthetic heads only		
	((ini_index=ini_index+24))
	((fin_index=fin_index+24))
	((i=i+1))
done
awk -F, '{printf("%.4e\n",$1)}' temp_synHeads.txt > synHeads.txt
rm temp*
cp synHeads.txt headObsData_withoutNoise.txt
./addRegularNoiseToSynObsData.py h

# Preparing temporal head difference observations
ini_index=1
fin_index=24
i=1
while [ ${i} -le ${nbObsPts} ]
do
	cut -c${ini_index}-${fin_index} synDataByObsPts_2.txt | awk -F, '{printf("%.2f\n",$1)}' > temp
	sed '1d' temp > headAfter_${i}.dat # delete first line
	sed '$d' temp > headBefore_$i.dat # delete last line
	paste -d' ' headAfter_${i}.dat headBefore_${i}.dat > headsForDiff_${i}.dat
	awk '{ headDiff = $1 - $2; printf "%.4e\n", headDiff }' headsForDiff_${i}.dat > tempHeadDiffs_${i}.dat
	((ini_index=ini_index+24))
	((fin_index=fin_index+24))
	((i=i+1))
done
cat $(printf "tempHeadDiffs_%d.dat " $(seq 1 ${nbObsPts})) > synDeltaHeads.txt  # Concatenate temporal head differences files
rm headsForDiff* temp* headAfter* headBefore*
cp synDeltaHeads.txt deltaHeadObsData_withoutNoise.txt
./addRegularNoiseToSynObsData.py dh

# Preparing vertical head difference observations
i=1 # counter for while loop; counter for vertHeadDiffs_*.dat files
j=1 # counter of columns in synDataByObsPts_2.txt
((nbOfVerticalHeadDiffTimeSeries=nbObsPts-2)) # number of columns in future synVerticalHeadDiffs.txt file 
while [ ${i} -le ${nbOfVerticalHeadDiffTimeSeries} ]
do
	((k=j+1))
	if [ ${j} -eq 5 ] 
	then
		((j=j+1))
	else
		awk -F ' ' '{ print $'${k}' }' synDataByObsPts_2.txt > headAbove_${i}.dat
		awk -F ' ' '{ print $'${j}' }' synDataByObsPts_2.txt > headBelow_${i}.dat	
		paste -d' ' headAbove_${i}.dat headBelow_${i}.dat > headsForDiff_${i}.dat
		awk '{ headDiff = $1 - $2; printf "%.4e\n", headDiff }' headsForDiff_${i}.dat > vertHeadDiffs_${i}.dat
		((i=i+1))
		((j=j+1))
	fi
done
cat $(printf "vertHeadDiffs_%d.dat " $(seq 1 ${nbOfVerticalHeadDiffTimeSeries})) > synVerticalHeadDiffs.txt  # Concatenate vertical head differences files
rm headsForDiff* headAbove* headBelow* vertHeadDiffs*
cp synVerticalHeadDiffs.txt vertHeadDiffObsData_withoutNoise.txt
./addRegularNoiseToSynObsData.py vdh

# Make file of head observations by location
./makeHeadObsByLocFile.py ${nbObsPts} # creates hObs_byLoc.txt
./makeFlowrateObsByLocFile.py ${nbLayers} # creates qObs_byLoc.txt
#cp hObs_byLoc.txt qObs_byLoc.txt ~/gwes # copy to main working directory
