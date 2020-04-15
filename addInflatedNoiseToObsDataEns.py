#!/usr/bin/python3

# Load libraries
import sys
import numpy as np
from numpy.linalg import inv

modelName = sys.argv[1]
dataType = sys.argv[2]
nbAssimilations = int(sys.argv[3])
nbObsPts = int(sys.argv[4])
ensembleSize = int(sys.argv[5]) 
homeDirPath = sys.argv[6]

# Load simulated data file 
if dataType == "h":
	data = np.reshape(np.loadtxt(homeDirPath + '/' + modelName + '/headObsData_withoutNoise.txt'), (-1, nbObsPts), 'F').flatten('F') # steady state + transient heads 
	nbOfData = len(data) # size of vector of perturbed observations
	varOfData = 0.05**2
	varVector = np.ones((nbOfData, 1))*varOfData
	
elif dataType == "q":
	data = np.loadtxt(homeDirPath + '/' + modelName + '/flowrateObsData_withoutNoise.txt') 
#	data_min_exceptZero = 5e-6
	data_min_exceptZero = np.min(data[np.nonzero(data)]) 
	varVector = np.reshape((0.20*data)**2, (-1, 1)) # contains zero values # the uncertainty of flow rate data depends on the flow rate value
	varVector[np.where(varVector == 0)] = (data_min_exceptZero*0.20*0.20)**2 # no longer contains zero values
	nbOfData = len(data) # size of vector of perturbed observations


# Generate an ensemble of "inflated" noise vectors drawn from a normal distribution of specified mean and variance    
obsErrCovar = np.diag(np.reshape(varVector, nbOfData)) # argument of np.diag must be 1D 
mean = np.zeros(nbOfData)
cov = np.eye(nbOfData, dtype=int) # noises are uncorrelated
valFromMultiNormalDist = np.random.multivariate_normal(mean, cov, ensembleSize)
obsErrEns = np.dot(obsErrCovar**(1/2), valFromMultiNormalDist.T)
inflatedObsErrEns = nbAssimilations**(1/2)*obsErrEns

# Add inflated/regular noise to synthetic data
dataEns = np.tile(np.reshape(data, (-1,1)), (1, ensembleSize))	
inflatedDataEns = dataEns + inflatedObsErrEns # inflated data ensemble
regularlyPerturbedDataEns = dataEns + obsErrEns # regularly perturbed data ensemble (i.e. data perturbed with non-inflated noise)


if dataType == "h":
	np.savetxt('inflatedObsErrEns_h.txt', inflatedObsErrEns, fmt='%.8e')
	np.savetxt('inflatedDataEns_h.txt', inflatedDataEns, fmt='%.4e')
	np.savetxt('regularlyPerturbedDataEns_h.txt', regularlyPerturbedDataEns, fmt='%.4e')

elif dataType == "q":
	np.savetxt('inflatedObsErrEns_q.txt', inflatedObsErrEns, fmt='%.8e')
	np.savetxt('inflatedDataEns_q.txt', inflatedDataEns, fmt='%.8e')
	np.savetxt('regularlyPerturbedDataEns_q.txt', regularlyPerturbedDataEns, fmt='%.8e')


