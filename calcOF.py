#!/usr/bin/python3

import sys
modelName = sys.argv[1]
import myFunctions as myFun
import numpy as np
import math
import scipy
from numpy.linalg import svd, inv
from scipy.sparse.linalg import svds # to test
from scipy.sparse import eye, csr_matrix, issparse, isspmatrix_csr
from os import system


processRank = sys.argv[2]
rank = int(processRank)
objFun_min = float(sys.argv[3]) # minimum objective function value before current iteration 
dataTypes = sys.argv[4]

## Compare the objective function value before and after parameter update

# Load new simulated data file in variable	
simData_new = np.reshape(np.loadtxt('simData_' + processRank + '.txt'), (-1, 1))

## Compute the ensemble of measurement error covariance matrix

ensOfOrigObsData = np.loadtxt('ens_of_origObsData_withRegularNoise.txt') # original ensemble
obsData = np.reshape(ensOfOrigObsData[:, rank], (-1, 1))
nbOfData = obsData.shape[0]

# Assuming uncorrelated observation data noise
inv_obsErrCovar = np.eye(nbOfData)
varVector = np.reshape(np.var(ensOfOrigObsData, axis=1), (-1,1))
inv_obsErrCovar[range(nbOfData), range(nbOfData)] = np.reshape(1/varVector, nbOfData)

objFun = myFun.computeObjFun(obsData, inv_obsErrCovar, simData_new, dataTypes)

objFun_new = float(format(objFun[0], '.3e'))

# Append list of objective function values in file
with open('objFunValues_' + processRank + '.txt', 'a') as g:
	g.write("%e\n" % objFun_new)
	g.close()

if dataTypes == "h+q":
	OF_h = float(format(objFun[1], '.4e'))
	OF_q = float(format(objFun[2], '.4e'))

	# Write OF values computed using head data only
	with open('objFun_h_' + processRank + '.txt', 'a') as p:
		p.write("%e\n" % OF_h)
		p.close()
	# Write OF values computed using flowrate data only
	with open('objFun_q_' + processRank + '.txt', 'a') as q:
		q.write("%e\n" % OF_q)
		q.close()

elif dataTypes == "h":
	OF_h = float(format(objFun[1], '.4e'))

	# Write OF values computed using head data only
	with open('objFun_h_' + processRank + '.txt', 'a') as g:
		g.write("%e\n" % OF_h)
		g.close()
	
if objFun_new <= objFun_min: 	

	# Update the minimum objective function value
	with open('objFunMin_' + processRank + '.txt', 'w') as m:
		m.flush()
		m.write("%e" % objFun_new)
		m.close()


