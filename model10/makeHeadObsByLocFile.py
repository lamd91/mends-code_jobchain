#!/usr/bin/python3

# python modules
import sys
import numpy as np

nbObsPts = int(sys.argv[1])

# Format output flowrates from GW
headObsList = np.loadtxt('headObsData_withoutNoise.txt')
headObsByLoc = np.reshape(headObsList, (-1, nbObsPts), 'F')
np.savetxt('hObs_byLoc.txt', headObsByLoc, fmt="%.4e") # format values


