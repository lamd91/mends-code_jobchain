#!/usr/bin/python3

import numpy as np
import sys
from myFunctions import makeFlowParFileForGW

processRank = sys.argv[1]

faciesSim = np.reshape(np.flipud(np.reshape(np.loadtxt('mpsim_' + processRank + '.txt'), (50, 500))), (-1,))

# Populate facies with log K values
logK = np.zeros(faciesSim.shape)
logK[np.where(faciesSim==0)[0]] = -6
logK[np.where(faciesSim==1)[0]] = -4
#np.savetxt('logK_' + processRank + '.txt', logK)

# Create parameter files for flow simulation with GW
makeFlowParFileForGW(logK, int(processRank))
