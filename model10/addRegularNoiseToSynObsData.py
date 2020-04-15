#!/usr/bin/python3

# Load libraries
import sys
import numpy as np
from numpy.linalg import inv

dataType = sys.argv[1]

# Load simulated data file 
if dataType == "h":
	data = np.loadtxt('headObsData_withoutNoise.txt') 
	nbOfData = len(data) # size of vector of observations
	varOfData = 0.05**2
	varVector = np.ones((nbOfData, 1))*varOfData
#	varVector_st = np.repeat(0.05**2, 1)
#	varVector_tr1 = np.repeat(0.05**2, 15)
#	varVector_tr2 = np.repeat(0.05**2, 21)
#	varVector = np.reshape(np.tile(np.concatenate((varVector_st, varVector_tr1, varVector_tr2)), 10), (-1,1))

elif dataType == "dh":
	data = np.loadtxt('deltaHeadObsData_withoutNoise.txt')
	varOfData = 5e-4
	nbOfData = len(data)
	varVector = np.ones((nbOfData, 1))*varOfData

elif dataType == "vdh":
	data = np.loadtxt('vertHeadDiffObsData_withoutNoise.txt')
	varOfData = 5e-4
	nbOfData = len(data)
	varVector = np.ones((nbOfData, 1))*varOfData

elif dataType == "q":
	data = np.loadtxt('flowrateObsData_withoutNoise.txt') 
	varVector = (0.25*data)**2
	varVector[varVector <= 1e-8] = 2.5e-19
	nbOfData = len(data) # size of vector of perturbed observations
	
# Generate vector of white noise     
obsErr = np.zeros((nbOfData, 1)) # vector to store random gaussian pertubations on observations accounting for measurement errors
obsErrCovar = np.zeros((nbOfData, nbOfData))
obsErrCovar[:nbOfData, :nbOfData] = np.diag(np.reshape(varVector, nbOfData)) # argument of np.diag must be 1D !!!

mean = np.zeros(nbOfData)
cov = np.eye(nbOfData, dtype=int)
valFromMultiNormalDist = np.reshape(np.random.multivariate_normal(mean, cov), (-1,1))

obsErr = np.dot(obsErrCovar**(1/2), valFromMultiNormalDist)

# Add white noise to synthetic data
perturbedData = np.zeros((nbOfData, 1))	# perturbed observations vector 
perturbedData[:, 0] = data # initialize the vector  of perturbed observation matrix with the calibration data
perturbedData = perturbedData + obsErr

if dataType == "h":
	np.savetxt('headObsData.txt', perturbedData, fmt='%.4e')
elif dataType == "dh":
	np.savetxt('deltaHeadObsData.txt', perturbedData, fmt='%.4e')
elif dataType == "vdh":
	np.savetxt('vertHeadDiffObsData.txt', perturbedData, fmt='%.4e')
elif dataType == "q":
	np.savetxt('flowrateObsData.txt', perturbedData, fmt='%.4e')



