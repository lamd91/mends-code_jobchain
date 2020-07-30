#!/usr/bin/python3

import sys
import myFunctions as myFun
import numpy as np
from numpy.linalg import svd, inv
from scipy.sparse.linalg import svds 
from scipy.sparse import eye, csr_matrix, issparse, isspmatrix_csr
from os import system


## Set general variables

modelName = sys.argv[1]
nbOfEnsMembers = int(sys.argv[2])  # stores the number of processes
processRank = sys.argv[4] # slurm rank in string format
rank = int(processRank)
dataTypes = sys.argv[5]
nbOfPar2Calib = int(sys.argv[6])
nbAssimilations = int(sys.argv[7])
nbObsPts = int(sys.argv[8])
homeDirPath = sys.argv[9]

# Size of coarsest resolution simulation grid 
pyrDim0=13
pyrDim1=125


## Calculate parameter update

# Create localization matrix
if dataTypes == "h":
    if modelName == 'model9':
        locMatrix = myFun.makeTaperMatrix_smallGrid(homeDirPath, homeDirPath + '/' + modelName, 1600, pyrDim0, pyrDim1, 5000, 500)[:, 0:370] 
    elif modelName == 'model10':
        locMatrix = myFun.makeTaperMatrix_smallGrid(homeDirPath, homeDirPath + '/' + modelName, 2800, pyrDim0, pyrDim1, 5000, 500)[:, 0:370]
elif dataTypes == "h+q":
    if modelName == 'model9':
        locMatrix_h = myFun.makeTaperMatrix_smallGrid(homeDirPath, homeDirPath + '/' + modelName, 1600, 13, 125, 5000, 500)[:, 0:370] 
        locMatrix_q = myFun.makeTaperMatrix_smallGrid(homeDirPath, homeDirPath + '/' + modelName, 1600, 13, 125, 5000, 500)[:, 1026:] 
        locMatrix = np.hstack((locMatrix_h, locMatrix_q))    
    elif modelName == 'model10':
        locMatrix_h = myFun.makeTaperMatrix_smallGrid(homeDirPath, homeDirPath + '/' + modelName, 2500, 13, 125, 5000, 500)[:, 0:370] 
        locMatrix_q = myFun.makeTaperMatrix_smallGrid(homeDirPath, homeDirPath + '/' + modelName, 2500, 13, 125, 5000, 500)[:, 1026:] 
        locMatrix = np.hstack((locMatrix_h, locMatrix_q))    

# Compute the covariance matrices based on the ensembles

ensOfParDevFromEnsMean = np.loadtxt(homeDirPath + '/ensOfParDevFromEnsMean.txt') 
ensOfSimDataWithInflatedNoise = np.loadtxt(homeDirPath + '/ens_of_simulatedData_withNoise.txt') # transformed ensemble
ensOfOrigObsData = np.loadtxt(homeDirPath + '/ens_of_origObsData_withRegularNoise.txt') # original ensemble
ensOfSimDataDevFromEnsMean = np.loadtxt(homeDirPath + '/ensOfSimDataDevFromEnsMean.txt') 
ensOfSimDataWithNoiseDevFromEnsMean = np.loadtxt(homeDirPath + '/ensOfSimDataWithNoiseDevFromEnsMean.txt')
nbOfData = ensOfSimDataDevFromEnsMean.shape[0]


# Define ensemble of measurement error covariance matrix

varVector = np.reshape(np.var(ensOfOrigObsData, axis=1), (-1,1))    
inv_sqrt_varVector = np.reshape(1/varVector**(1/2), -1)
scalingMatrix4SimData = np.diag(inv_sqrt_varVector)


# Compute the Truncated Singular Value Decomposition of the rescaled Ensemble of simulated data deviations from ensemble mean 

nbOfSingularValues = np.min([int(sys.argv[3]), nbOfData-1])
ensOfSimDataWithNoiseDevFromEnsMean_scaled = np.dot(scalingMatrix4SimData, ensOfSimDataDevFromEnsMean)
Ud, wd, Vd = svds(ensOfSimDataWithNoiseDevFromEnsMean_scaled, k=nbOfSingularValues, which='LM') # truncated SVD
Wd = np.zeros((Ud.shape[1], Vd.shape[0]))
Wd[:Ud.shape[1], :Vd.shape[0]] = np.diag(wd)
Wd_inv = np.zeros((Ud.shape[1], Vd.shape[0]))
Wd_inv[:np.count_nonzero(wd), :np.count_nonzero(wd)] = np.diag(1/wd[np.nonzero(wd)])

# Update from data mismatch

simDataEns = np.loadtxt(homeDirPath + '/ens_of_simulatedData.txt')
simData = np.reshape(simDataEns[:, rank],(-1, 1))
perturbedData = np.reshape(np.loadtxt(homeDirPath + '/obsDataWithNoise_' + processRank + '.txt'), (-1, 1))

innov = perturbedData - simData # innovation i.e. mismatch between observed and simulated data (CAREFUL with the sign !!))

R = nbAssimilations*(nbOfEnsMembers-1)*(np.dot(np.dot(np.dot(np.dot(Wd_inv, np.transpose(Ud)), np.eye(nbOfData)), Ud), Wd_inv))
Z, h, Zt = svd(R, full_matrices=0) # compute SVD of R
H = np.zeros((Z.shape[1], Zt.shape[0]))
H[:Zt.shape[0], :Zt.shape[0]] = np.diag(h)
X = np.dot(np.dot(np.dot(scalingMatrix4SimData, Ud), Wd_inv), Z)
L = np.zeros((H.shape[0], H.shape[1]))
L[:H.shape[0], :H.shape[0]] = np.diag(1/(1+h))

X1 = np.dot(L, np.transpose(X))
X2 = np.dot(np.transpose(ensOfSimDataDevFromEnsMean), X)
X3 = np.dot(X2, X1)


# Hence the following updated (analysed) parameters  
parEns_old = np.loadtxt(homeDirPath + '/ens_of_parameters.txt') # contains each member of NS pyramid values 
par_old = np.reshape(parEns_old[:, rank], (-1, 1))

parUpgradeFromDataMismatch = np.dot(np.multiply(locMatrix, np.dot(ensOfParDevFromEnsMean, X3)), innov)
par_new = par_old + parUpgradeFromDataMismatch

np.savetxt('parUpgradeFromDataMismatch_' + processRank + '.txt', parUpgradeFromDataMismatch, fmt="%.2e")

with open('transformedPyr1_' + processRank + '.txt', 'w') as g:
    for i in range(len(par_new)):
        g.write("%.2e\n" % par_new[i])

