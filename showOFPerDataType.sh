#!/bin/bash

dataTypes=$1
ensembleSize=$2
((lastProcessRank=ensembleSize-1))
memberIndices=$(for i in $(seq 0 $lastProcessRank); do printf "$i "; done)

if [ $# -ne 2 ]; then echo "Illegal number of arguments"; exit 1; fi

if [ $dataTypes == "h+dh" ]
then
	for i in ${memberIndices}; do echo "${i}:  OF tot  |  OF steady-state head  |  OF transient heads  |  OF head temporal differences" ; paste objFunValues_${i}.txt objFun_ssH_${i}.txt objFun_h_${i}.txt objFun_dh_${i}.txt; echo;  done

elif [ $dataTypes == "h+q" ]
then
	for i in ${memberIndices}; do echo "${i}:  OF tot  |  heads  |  flowrates" ; paste objFunValues_${i}.txt objFun_h_${i}.txt objFun_q_${i}.txt; echo;  done
#	for i in ${memberIndices}; do echo "${i}:  Mismatch tot  |  heads  |  flowrates" ; paste DmismValues_${i}.txt Dmism_h_${i}.txt Dmism_q_${i}.txt; echo;  done

elif [ $dataTypes == "h+vdh" ]
then
	for i in ${memberIndices}; do echo "${i}:  OF tot  |  OF heads  |  OF vertical head differences" ; paste -d' ' objFunValues_${i}.txt objFun_h_${i}.txt objFun_vdh_${i}.txt; echo;  done

elif [ $dataTypes == "h+vdh+q" ]
then
	for i in ${memberIndices}; do echo "${i}:  OF tot  |  OF heads  |  OF vertical head differences  |  OF flowrates" ; paste -d' ' objFunValues_${i}.txt objFun_h_${i}.txt objFun_vdh_${i}.txt objFun_q_${i}.txt; echo;  done

elif [ $dataTypes == "h" ]
then
	for i in ${memberIndices}; do echo "${i}:  OF tot" ; paste objFunValues_${i}.txt; echo;  done
#	for i in ${memberIndices}; do echo "${i}:  OF tot" ; paste DmismValues_${i}.txt; echo;  done

elif [ $dataTypes == "dh" ] 
then
	for i in ${memberIndices}; do echo "${i}:  OF temporal head differences" ; paste objFunValues_${i}.txt ; echo;  done

elif [ $dataTypes == "vdh" ]
then
	for i in ${memberIndices}; do echo "${i}:  OF vertical head differences" ; paste objFunValues_${i}.txt ; echo;  done

elif [ $dataTypes == "q" ]
then
	for i in ${memberIndices}; do echo "${i}: OF flowrates" ; paste objFunValues_${i}.txt ; echo;  done
fi




