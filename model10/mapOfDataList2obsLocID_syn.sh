#!/bin/bash

# valid only if we consider only heads and flowrates in dataset (in this order)

rm -f mapOfDataList2obsID_syn_ALLDATA.txt

i=0
while [ ${i} -le 9 ]
do
	printf "${i}\n"%.s $(seq 1 37) >> mapOfDataList2obsID_syn_ALLDATA.txt
	((i=i+1))
done

while [ ${i} -le 14 ]
do
	printf "${i}\n"%.s $(seq 1 20) >> mapOfDataList2obsID_syn_ALLDATA.txt
	((i=i+1))
done

