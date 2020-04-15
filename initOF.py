#!/usr/bin/python3

import sys
modelName = sys.argv[1]
import myFunctions as myFun
import numpy as np
import scipy
import math
from scipy.sparse import eye

processRank = sys.argv[2]
rank = int(processRank)
dataTypes = sys.argv[3]

# Load simulated data
simData_ini = np.reshape(np.loadtxt('simData_' + processRank + '.txt'), (-1, 1)) # without noise

## Compute the ensemble of measurement error covariance matrix

ensOfOrigObsData = np.loadtxt('ens_of_origObsData_withRegularNoise.txt') # original ensemble
obsData = np.reshape(ensOfOrigObsData[:, rank], (-1, 1))
nbOfData = obsData.shape[0]

# Assuming uncorrelated observation data noise
inv_obsErrCovar = np.eye(nbOfData)
varVector = np.reshape(np.var(ensOfOrigObsData, axis=1), (-1,1))
inv_obsErrCovar[range(nbOfData), range(nbOfData)] = np.reshape(1/varVector, nbOfData)

#np.savetxt('inv_obsErrCovar.txt', inv_obsErrCovar, fmt="%.4e")

# Compute initial value of objective function
objFun = myFun.computeObjFun(obsData, inv_obsErrCovar, simData_ini, dataTypes) # value is a list
OF_tot = float(format(objFun[0], '.4e'))

if dataTypes == "h+q":
	OF_h = float(format(objFun[1], '.4e'))
	OF_q = float(format(objFun[2], '.4e'))

	# Write OF values computed using head data only
	with open('objFun_h_' + processRank + '.txt', 'w') as g:
		g.write("%e\n" % OF_h)
		g.close()
	# Write OF values computed using flowrate data only
	with open('objFun_q_' + processRank + '.txt', 'w') as g:
		g.write("%e\n" % OF_q)
		g.close()

elif dataTypes == "h":
	OF_h = float(format(objFun[1], '.4e'))

	# Write OF values computed using head data
	with open('objFun_h_' + processRank + '.txt', 'w') as g:
		g.write("%e\n" % OF_h)
		g.close()

# Save initial OF value as the current minimum value
with open('objFunMin_' + processRank + '.txt', 'w') as f:
	f.write("%e" % OF_tot)
	f.close()

# Write to file listing all objective function values during the optimization
with open('objFunValues_' + processRank + '.txt', 'w') as g:
	g.write("%e\n" % OF_tot)
	g.close()


