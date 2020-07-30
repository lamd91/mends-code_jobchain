#!/usr/bin/python3

# Import python modules
import sys
import numpy as np
from myFunctions import bnscore_pyr 


processRank = sys.argv[1] # string
iteration = int(sys.argv[2])
homeDirPath = sys.argv[3]
modelName = sys.argv[4]
rank = int(processRank)

# Load initial ensemble of pyramid coarsest values before normal-score transformation
origPyr_perLoc = np.transpose(np.loadtxt(homeDirPath + '/iniOrigPyrEns.txt'))

# Load ensemble of transformed values (i.e. parameters updated by ES-MDA)
updatedNormalScoresOfPar_perLoc = np.transpose(np.loadtxt(homeDirPath + '/ens_of_parameters.txt'))

# Compute Back Transform of Normal-Score values and save in text file
pyr = bnscore_pyr(updatedNormalScoresOfPar_perLoc, homeDirPath)[rank, :]

pyrDim_0 = 13
pyrDim_1 = 125
#pyrDim_0 = 9
#pyrDim_1 = 84
maskMatrix = np.ones((pyrDim_0, pyrDim_1))
maskMatrix[:, :] = np.nan

# Load file of coordinates of already sampled hard conditioning points
i_samples = np.loadtxt(homeDirPath + '/' + modelName + '/sampledCells_xCoord.txt').astype(int) 
j_samples = np.loadtxt(homeDirPath + '/' + modelName + '/sampledCells_yCoord.txt').astype(int)
maskMatrix[i_samples, j_samples] = 1

pyr4deesse = np.reshape(np.multiply(np.reshape(pyr, (pyrDim_0, pyrDim_1)), maskMatrix), (-1,)) # input for Deesse

with open('pyr_' + processRank + '.txt', 'w') as g:
    for i in range(len(pyr)):
        g.write("%.2e\n" % pyr[i])

with open('pyr4deesse_' + processRank + '.txt', 'w') as h:
    for i in range(len(pyr4deesse)):
        h.write("%.2e\n" % pyr4deesse[i])



