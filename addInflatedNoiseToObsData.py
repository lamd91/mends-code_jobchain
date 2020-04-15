#!/usr/bin/python3

# Load libraries
import sys
import numpy as np
from numpy.linalg import inv

modelName = sys.argv[1]
dataType = sys.argv[2]
rank = sys.argv[3]
ensRank = int(rank)
nbAssimilations = int(sys.argv[4])
nbObsPts = int(sys.argv[5])
homeDirPath = sys.argv[6]

# Load data ensemble files
if dataType == "h":
	data = np.reshape(np.loadtxt(homeDirPath + '/' + modelName + '/headObsData_withoutNoise.txt'), (-1, nbObsPts), 'F').flatten('F') # steady state + transient heads
	inflatedDataEns = np.loadtxt(homeDirPath + '/inflatedDataEns_h.txt')
	regularlyPerturbedDataEns = np.loadtxt(homeDirPath + '/regularlyPerturbedDataEns_h.txt')
	inflatedObsErrEns = np.loadtxt(homeDirPath + '/inflatedObsErrEns_h.txt')
	np.savetxt('obsHeadsWithNoise_' + rank + '.txt', inflatedDataEns[:, ensRank], fmt='%.4e')
	np.savetxt('obsHeadsWithRegularNoise_' + rank + '.txt', regularlyPerturbedDataEns[:, ensRank], fmt='%.4e')
	np.savetxt('obsHeads_' + rank + '.txt', data, fmt='%.4e')
	np.savetxt('inflatedObsErr_h_' + rank + '.txt', inflatedObsErrEns[:, ensRank], fmt='%.8e')

elif dataType == "q":
	data = np.loadtxt(homeDirPath + '/' + modelName + '/flowrateObsData_withoutNoise.txt') # data with added noise, can contain negative values
	inflatedDataEns = np.loadtxt(homeDirPath + '/inflatedDataEns_q.txt')
	regularlyPerturbedDataEns = np.loadtxt(homeDirPath + '/regularlyPerturbedDataEns_q.txt')
	inflatedObsErrEns = np.loadtxt(homeDirPath + '/inflatedObsErrEns_q.txt')
	np.savetxt('obsFlowratesWithNoise_' + rank + '.txt', inflatedDataEns[:, ensRank], fmt='%.8e')
	np.savetxt('obsFlowratesWithRegularNoise_' + rank + '.txt', regularlyPerturbedDataEns[:, ensRank], fmt='%.8e')
	np.savetxt('obsFlowrates_' + rank + '.txt', data, fmt='%.8e')
	np.savetxt('inflatedObsErr_q_' + rank + '.txt', inflatedObsErrEns[:, ensRank], fmt='%.8e')


