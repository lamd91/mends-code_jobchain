#!/usr/bin/python3

# python modules
import sys
import numpy as np

nbZones = 5

# Format output flowrates from GW
flowrateObsList = np.loadtxt('flowrateObsData_withoutNoise.txt')
flowrateObsByLoc = np.reshape(flowrateObsList, (-1, nbZones), 'F')
np.savetxt('qObs_byLoc.txt', flowrateObsByLoc, fmt="%.4e") # format values


