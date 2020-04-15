#!/usr/bin/python3

# Import python modules
import sys
import numpy as np
from myFunctions import nscore_bis, nscore_pyr # import written functions from python file


processRank = sys.argv[1] # string 
nbOfPar = int(sys.argv[2])
iteration = int(sys.argv[3])
homeDirPath = sys.argv[4]
rank = int(processRank) # integer

# Load ensemble distribution of log K parameters at current iteration
# Compute Normal Score of parameters 

if iteration == 0:
	pyrEns = np.loadtxt(homeDirPath + '/iniOrigPyrEns.txt')
	pyrEns_perLocation = np.transpose(pyrEns)
	transformed_par = nscore_bis(pyrEns_perLocation)[0][rank, :] # only valid for iteration 0 
else:
	pyrEns = np.loadtxt(homeDirPath + '/ens_of_updatedPyr.txt')
	pyrEns_perLocation = np.transpose(pyrEns)
	transformed_par = nscore_pyr(pyrEns_perLocation, homeDirPath)[rank, :] # for all other iterations
#	transformed_par = nscore_bis(pyrEns_perLocation)[0][rank, :] # for all other iterations

# Save output in text file
with open('normalScoreOfPyr1_' + processRank + '.txt', 'w') as g:
	for i in range(len(transformed_par)):
		g.write("%.5e\n" % transformed_par[i])
	g.close()





