#!/usr/bin/python3

import sys
import numpy as np
import scipy
from scipy.stats import norm
from scipy.interpolate import interp1d
from numpy.linalg import inv
from scipy.sparse import eye, csr_matrix


# Functions used to run MENDS on the test cases 'A' (model9) and 'B' (model10)

def assignDataToNearestCellCentroidCoordinates(xcoord_cellCentroids, ycoord_cellCentroids, dataset):

	x_data = dataset[:, 0]
	y_data = dataset[:, 1]
	x_data2nearestCell = np.zeros(dataset.shape[0])
	y_data2nearestCell = np.zeros(dataset.shape[0])

	i=0
	for data in zip(x_data, y_data):
		x_data2nearestCell[i] = xcoord_cellCentroids[np.abs(xcoord_cellCentroids - data[0]).argmin()]
		y_data2nearestCell[i] = ycoord_cellCentroids[np.abs(ycoord_cellCentroids - data[1]).argmin()]
		i=i+1

	return x_data2nearestCell, y_data2nearestCell


def findDataCellCoordinates(x_data, y_data, XX, YY):
	
	nbOfData = x_data.shape[0]
	cellData_lin_index = np.zeros(nbOfData)
	cellData_col_index = np.zeros(nbOfData)

	for k in np.arange(nbOfData): # get cell coordinates of data
		cellData_lin_index[k] = np.intersect1d(np.where(XX == x_data[k])[0], np.where(YY == y_data[k])[0])
		cellData_col_index[k] = np.intersect1d(np.where(XX == x_data[k])[1], np.where(YY == y_data[k])[1])

	return cellData_lin_index.astype(int), cellData_col_index.astype(int)


def sampleLocations(x_min, x_max, y_min, y_max, nbSamples_x, nbSamples_y):

	x_all = np.arange(x_min, x_max)
	y_all = np.arange(y_min, y_max)
	xx, yy = np.meshgrid(x_all, y_all)

	nlines = xx.shape[0]
	ncols = xx.shape[1]

	dc = x_max / nbSamples_x
	dl = y_max / nbSamples_y
	dl_all = np.arange(0, nlines, dl)
	dc_all = np.arange(0, ncols , dc)

	ni = dl_all.shape[0]
	nj = dc_all.shape[0]
	x_locSamples = np.zeros((ni, nj))
	y_locSamples = np.zeros((ni, nj))

	for i in np.arange(ni):
		for j in np.arange(nj):
			rn = np.random.uniform(dc)
			x_locSamples[i, j] = rn + dc_all[j] - 1
			rn = np.random.uniform(dl)
			y_locSamples[i, j] = rn + dl_all[i] - 1

	x_allSamples = np.reshape(x_locSamples+x_min, (-1, 1))
	y_allSamples = np.reshape(y_locSamples+y_min, (-1, 1))

	return x_allSamples, y_allSamples


def computeEnsMean(pathToFile):
	
	ens = np.loadtxt(pathToFile)
	ensSize = ens.shape[1]
	ensMean = np.dot(ens, np.ones((ensSize, 1))/ensSize)

	return ensMean
	

# Interpolate simulated data by GW

def interpData(filename, timestep):

	interpPoints = np.arange(0, 3660, timestep)
	timeseries = np.loadtxt(filename)
	time = timeseries[:, 0]
#	data = timeseries[:, 1]
	dataByObsPts = timeseries[:, 1:15] # all columns of timeseries except first one
#	interpFunc = interp1d(time, data)
	interpFunc = interp1d(time, dataByObsPts, axis=0)

	#return np.reshape(interpFunc(interpPoints), (-1, 1))
	return interpFunc(interpPoints)



# Normal Score Transform (NST) function

# For data transformation
def nscore_bis(vectorArray):  
 
	n = vectorArray.shape[0] # sample size
	nbOfLocs = vectorArray.shape[1] # number of locations
	ID = np.reshape(np.arange(1, n+1), (-1, 1)) # rank of data
	pk = (ID - 0.5)/n # vector of probabilities
	normscore = norm.ppf(pk) # inverse of the normal cdf
	vectorArray_sorted = np.sort(vectorArray, axis=0) 
	indices_sortedVectorArray = vectorArray.argsort(axis=0)
	normscoreArray_org = np.empty((normscore.shape[0], nbOfLocs))
	for i in range(nbOfLocs):
		normscoreArray_org[np.reshape(indices_sortedVectorArray[:, i],(-1,1)), i] = np.reshape(normscore, (-1,1))


	# Declare struct 
	class struct:
		def __init__(self):
			self.sd = 0
			self.pk = 0
			self.d = 0
			self.normscore = 0

	o_nscore = struct()
	o_nscore.sd = vectorArray_sorted
	o_nscore.pk = pk
	o_nscore.d = vectorArray
	o_nscore.normscore = normscore

#	normscoreArray_org = np.transpose(normscoreArray_org)
	return [normscoreArray_org, o_nscore]



def nscore_pyr(parEnsDistPerLoc, homeDirPath): 
	
	### Normal Score Transform Function for parameters which takes as argument an array of log K parameters to transform by interpolation based on the initial anamorphosis function (from iteration 0)
 
	# Create the empirical anamorphosis function based on initial parameter ensemble distribution

	priorParEnsDistPerLoc = np.transpose(np.loadtxt(homeDirPath + '/iniOrigPyrEns.txt'))
	n = priorParEnsDistPerLoc.shape[0] # sample size
	nbOfLocs = priorParEnsDistPerLoc.shape[1] # number of locations
	ID = np.reshape(np.arange(1, n+1), (-1, 1)) # rank of data
	pk = (ID - 0.5)/n # vector of probabilities
	normscore = norm.ppf(pk) # inverse of the normal cdf
	priorParEnsDistPerLoc_sorted = np.sort(priorParEnsDistPerLoc, axis=0) 
	indices_sortedPriorParEnsDistPerLoc = priorParEnsDistPerLoc.argsort(axis=0)

	normscoreArrayOfParameters = np.empty((normscore.shape[0], nbOfLocs)) # array to store the normal scores of parameter ensemble per gridblock for current iteration

	# Build the interpolation function of the empirical anamorphosis function (one per gridblock)
	for i in range(nbOfLocs):

		# For values within boundaries: linearly interpolate
		interpFunctionPerLoc = interp1d(priorParEnsDistPerLoc_sorted[:, i], normscore, kind='linear', axis=0) # interpolation method to call at the interpolation points
	
		# Call interpolation function at values within boundaries	
		normscoreOfParametersPerLoc = interpFunctionPerLoc(parEnsDistPerLoc[:, i][np.where((parEnsDistPerLoc[:, i] > priorParEnsDistPerLoc_sorted[:, i][0]) & (parEnsDistPerLoc[:, i] < priorParEnsDistPerLoc_sorted[:, i][-1]))]) # interpolated normal score values
		
		normscoreArrayOfParameters[np.where((parEnsDistPerLoc[:, i] > priorParEnsDistPerLoc_sorted[:, i][0]) & (parEnsDistPerLoc[:, i] < priorParEnsDistPerLoc_sorted[:, i][-1])), i] = np.reshape(normscoreOfParametersPerLoc, -1)

		# For values outsides boundaries: linearly extrapolate
		# Build an extrapolation function
		x_min = priorParEnsDistPerLoc_sorted[:, i][0]
		x_max = priorParEnsDistPerLoc_sorted[:, i][-1]
		x = np.array([x_min, x_max])
		y_min = normscore[0]
		y_max = normscore[-1]
		y = np.reshape(np.array([y_min, y_max]), -1)
		extrapFunctionPerLoc = interp1d(x, y, kind='linear', bounds_error=False, fill_value="extrapolate")
		
		# Call extrapolation function for values outside boundaries of the empirical anamorphosis function
		normscoreOfParametersPerLoc = extrapFunctionPerLoc(parEnsDistPerLoc[:, i][np.where((parEnsDistPerLoc[:, i] <= priorParEnsDistPerLoc_sorted[:, i][0]) | (parEnsDistPerLoc[:, i] >= priorParEnsDistPerLoc_sorted[:, i][-1]))])
		normscoreArrayOfParameters[np.where((parEnsDistPerLoc[:, i] <= priorParEnsDistPerLoc_sorted[:, i][0]) | (parEnsDistPerLoc[:, i] >= priorParEnsDistPerLoc_sorted[:, i][-1])), i] = np.reshape(normscoreOfParametersPerLoc, -1) # extrapolated normal score values
		
	return normscoreArrayOfParameters 


def nscore_perturbedSimData(allSimDataWithNoisePerLocArray):
 
	dataList = allSimDataWithNoisePerLocArray.flatten('F')
	n = dataList.shape[0] # sample size
	ID = np.reshape(np.arange(1, n+1), (-1, 1)) # rank of data
	pk = (ID - 0.5)/n # vector of probabilities
	normscore = norm.ppf(pk) # inverse of the normal cdf
	data_sorted = np.sort(dataList) 
	indices_sortedData = dataList.argsort(axis=0)
	normscore_org = np.empty((normscore.shape[0], 1))
	normscore_org[np.reshape(indices_sortedData,(-1,1)), 0] = np.reshape(normscore, (-1,1))
	nbOfLocs = allSimDataWithNoisePerLocArray.shape[1]	
	allNormscoresPerLoc = np.reshape(normscore_org, (-1, nbOfLocs), order='F')

	return allNormscoresPerLoc


def nscore(vector):
 
	n = len(vector) # size of vector x
	ID = np.reshape(np.arange(1, n+1), (-1, 1))
	pk = (ID - 0.5)/n # vector probabilities
	normscore = norm.ppf(pk) # inverse of the normal cdf
	vector_sorted = np.sort(vector, axis=0) # x is a column vector
	indices_vector_sorted = vector.argsort(axis=0)
	normscore_org = np.empty(normscore.shape)
	normscore_org[indices_vector_sorted, 0] = normscore

	# Declare struct 
	class struct:
		def __init__(self):
			self.sd = 0
			self.pk = 0
			self.d = 0
			self.normscore = 0

	o_nscore = struct()
	o_nscore.sd = vector_sorted
	o_nscore.pk = pk
	o_nscore.d = vector
	o_nscore.normscore = normscore

	return [normscore_org, o_nscore]

# Back Normal Score Transform (BNST) function

def bnscore(normscore_org, o_nscore, rank):

	x=np.reshape(o_nscore.normscore, o_nscore.normscore.shape[0])
	y=np.reshape(o_nscore.sd[:, rank], o_nscore.sd.shape[0])
	f=interp1d(x_bis, y_bis)

	return f(normscore_org) 


def bnscore_bis(normscorePerLoc, logParPerLoc):

	n = normscorePerLoc.shape[0] # sample size
	nbOfLocs = normscorePerLoc.shape[1] # number of locations
	ID = np.arange(1, n+1) # rank of data
	pk = (ID - 0.5)/n # vector of probabilities
	normscore = norm.ppf(pk) # inverse of the normal cdf
	logParPerLoc_sorted = np.sort(logParPerLoc, axis=0)
	backTransformedNSPerLocArray = np.empty((normscore.shape[0], nbOfLocs))

	for i in range(nbOfLocs):
		# For values within boundaries: linearly interpolate 

		# Build interpolation function of the empirical anamorphosis function
		interpFunctionPerLoc = interp1d(normscore, logParPerLoc_sorted[:, i], kind='linear', axis=0) # interpolation method to call at the interpolation points
		
		# Interpolate function at values within boundaries
		backTransformedNSPerLoc = interpFunctionPerLoc(normscorePerLoc[:, i][np.where((normscorePerLoc[:, i] >= normscore[0]) & (normscorePerLoc[:, i] <= normscore[-1]))]) # values to interpolate

		backTransformedNSPerLocArray[np.where((normscorePerLoc[:, i] >= normscore[0]) & (normscorePerLoc[:, i] <= normscore[-1])), i] = np.reshape(backTransformedNSPerLoc, -1)

		# For values outsides boundaries: linearly extrapolate 

		# Build an extrapolation function 
		x_min = normscore[0]
		x_max = normscore[-1]
		x = np.array([x_min, x_max])
		y_min = logParPerLoc_sorted[:, i][0]
		y_max = logParPerLoc_sorted[:, i][-1]
		y = np.reshape(np.array([y_min, y_max]), -1)
#		extrapFunctionPerLoc = interp1d(x, y, kind='linear', bounds_error=False, fill_value="extrapolate")
		extrapFunctionPerLoc = interp1d(x, y, kind='linear', bounds_error=False, fill_value=(y_min, y_max))
	
		# Call extrapolation function for values outside boundaries of the empirical anamorphosis function 
		backTransformedNSPerLoc = extrapFunctionPerLoc(normscorePerLoc[:, i][np.where((normscorePerLoc[:, i] < normscore[0]) | (normscorePerLoc[:, i] > normscore[-1]))]) # WRONG

		backTransformedNSPerLocArray[np.where((normscorePerLoc[:, i] < normscore[0]) | (normscorePerLoc[:, i] > normscore[-1])), i] = np.reshape(backTransformedNSPerLoc, -1) # values to extrapolate

#		backTransformedNSPerLoc = extrapFunctionPerLoc(normscorePerLoc[:, i][np.where(normscorePerLoc[:, i] < normscore[0])])
#
#		backTransformedNSPerLocArray[np.where(normscorePerLoc[:, i] < normscore[0]), i] = np.reshape(backTransformedNSPerLoc, -1) # values to extrapolate
#		backTransformedNSPerLoc = extrapFunctionPerLoc(normscorePerLoc[:, i][np.where(normscorePerLoc[:, i] > normscore[1])])
#
#		backTransformedNSPerLocArray[np.where(normscorePerLoc[:, i] > normscore[1]), i] = np.reshape(backTransformedNSPerLoc, -1) # values to extrapolate
		
	return backTransformedNSPerLocArray


def bnscore_pyr(normscorePerLoc, path):

	priorParEnsDistPerLoc = np.transpose(np.loadtxt(path + '/iniOrigPyrEns.txt')) # the back normal score function is based on the inverse of the gaussian anamorphosis of the prior parameter ensemble distribution 

	n = normscorePerLoc.shape[0] # sample size
	nbOfLocs = normscorePerLoc.shape[1] # number of locations
	ID = np.arange(1, n+1) # rank of data
	pk = (ID - 0.5)/n # vector of probabilities
	normscore = norm.ppf(pk) # inverse of the normal cdf
	priorParEnsDistPerLoc_sorted = np.sort(priorParEnsDistPerLoc, axis=0)
	backTransformedNSPerLocArray = np.empty((normscore.shape[0], nbOfLocs)) # array to store the back normal score values of updated transformed parameter ensemble per gridblock for current iteration

	for i in range(nbOfLocs):

		# For values within boundaries: linearly interpolate 

		# Build interpolation function of the empirical anamorphosis function
		interpFunctionPerLoc = interp1d(normscore, priorParEnsDistPerLoc_sorted[:, i], kind='linear', axis=0) # interpolation method to call at the interpolation points
		
		# Call interpolation function for values within boundaries
		backTransformedNSPerLoc = interpFunctionPerLoc(normscorePerLoc[:, i][np.where((normscorePerLoc[:, i] >= normscore[0]) & (normscorePerLoc[:, i] <= normscore[-1]))]) # interpolated values

		backTransformedNSPerLocArray[np.where((normscorePerLoc[:, i] >= normscore[0]) & (normscorePerLoc[:, i] <= normscore[-1])), i] = np.reshape(backTransformedNSPerLoc, -1)

		# For values outsides boundaries: linearly extrapolate 

		# Build an extrapolation function 
		x_min = normscore[0]
		x_max = normscore[-1]
		x = np.array([x_min, x_max])
		y_min = priorParEnsDistPerLoc_sorted[:, i][0]
		y_max = priorParEnsDistPerLoc_sorted[:, i][-1]
		y = np.reshape(np.array([y_min, y_max]), -1)
		#extrapFunctionPerLoc = interp1d(x, y, kind='linear', bounds_error=False, fill_value="extrapolate")
		extrapFunctionPerLoc = interp1d(x, y, kind='linear', bounds_error=False, fill_value=(y_min, y_max))
	
		# Call extrapolation function for values outside boundaries of the empirical anamorphosis function 
		backTransformedNSPerLoc = extrapFunctionPerLoc(normscorePerLoc[:, i][np.where((normscorePerLoc[:, i] < normscore[0]) | (normscorePerLoc[:, i] > normscore[-1]))]) 

		backTransformedNSPerLocArray[np.where((normscorePerLoc[:, i] < normscore[0]) | (normscorePerLoc[:, i] > normscore[-1])), i] = np.reshape(backTransformedNSPerLoc, -1) # extrapolated values
		
	return backTransformedNSPerLocArray


# Make parameter file for GW with K input

def makeFlowParFileForGW(log_k, process_rank):

	## Format for GW
	err = np.seterr(over='ignore')
#	k = np.power(10, log_k, dtype=float) # Hydraulic conductivities (K) # doesn't work
	A = np.array([10])
	A_float = A.astype(float)
	try:
		k = A_float**log_k
	finally:
		np.seterr(**err)
	nelem = k.shape[0]
	a = np.linspace(1,nelem,nelem)
	kgw = np.column_stack((a, np.ones((nelem,1),dtype=np.int)*0.2, k, np.zeros((nelem,1),dtype=np.int), k, np.zeros((nelem,1),dtype=np.int), np.zeros((nelem,1),dtype=np.int), k, np.ones((nelem,1),dtype=np.int)*10**(-6)))
#	np.set_printoptions(threshold=np.inf)	
#	print(' '.join(map(str, kgw)))

	## Write temporary GW input file
	gwInputFilename = "flowPar_" + str(process_rank) + ".dat" 
	open(gwInputFilename,"w").close() # empty content of file
	myFile = open(gwInputFilename,"w")
	myFile.write("%d\n" % nelem) # write number of elements on first line of file
	myFile = open(gwInputFilename,"ab")
	np.savetxt(myFile,kgw,fmt="%.8e")
	myFile.close()

	return 


def computeObjFun(observedData, inv_obsErrCovar, simulatedData, dataTypes):

	## Compute the Objective Function as the sum of Weighted least squares (each weight is inversely proportional to the variance of the measurement)
	objFun= [] # list of objective function values (total, per type)
	
	# Total OF i.e. based on all the calibration data
	objFun_tot = np.dot(np.dot(np.transpose(simulatedData-observedData), inv_obsErrCovar), (simulatedData-observedData))[0,0]
	objFun.append(objFun_tot)

	# Partial OF i.e. based on observation types
	if dataTypes == "h":
		objFun.append(objFun_tot)
	
	elif dataTypes == "h+q":	
		headsSize = np.loadtxt('simHeads_0.txt').shape[0]
		objFun_h = np.dot(np.dot(np.transpose(simulatedData-observedData)[0, 0:headsSize], inv_obsErrCovar[0:headsSize, 0:headsSize]), (simulatedData-observedData)[0:headsSize, 0])
		objFun_q = np.dot(np.dot(np.transpose(simulatedData-observedData)[0, headsSize:], inv_obsErrCovar[headsSize:, headsSize:]), (simulatedData-observedData)[headsSize:, 0])
		objFun.append(objFun_h)
		objFun.append(objFun_q) 

	return objFun


def computeDevFromEnsMean(nbOfMembers, nbOfElements, oldMember, oldEnsArray, scalingMatrix):

	#devFromEnsMean = np.dot(csr_matrix(scalingMatrix).toarray(), (oldMember - np.dot(oldEnsArray, np.ones((nbOfMembers,1))/nbOfMembers)))/(nbOfMembers-1)**(1/2) # slower
	devFromEnsMean = csr_matrix(scalingMatrix).dot(oldMember - np.dot(oldEnsArray, np.ones((nbOfMembers,1))/nbOfMembers))/(nbOfMembers-1)**(1/2) # faster

	return devFromEnsMean


def computeDevFromEnsMean_withoutscaling(nbOfMembers, nbOfElements, oldMember, oldEnsArray):

	#devFromEnsMean = np.dot(csr_matrix(scalingMatrix).toarray(), (oldMember - np.dot(oldEnsArray, np.ones((nbOfMembers,1))/nbOfMembers)))/(nbOfMembers-1)**(1/2) # slower
	devFromEnsMean = (oldMember - np.dot(oldEnsArray, np.ones((nbOfMembers,1))/nbOfMembers))/(nbOfMembers-1)**(1/2) # faster

	return devFromEnsMean



def makeTaperMatrix_smallGrid(homeDirPath, modelDirPath, range_x, pyrDim_0, pyrDim_1, L_x, L_y): # for synthetic case (model1, model4)
	
	# Calculate parameter centroids
	x_nodes = np.linspace(0, L_x, pyrDim_1+1)
	z_nodes = np.linspace(0, L_y, pyrDim_0+1)
	x_centroids = np.zeros(pyrDim_1) # 1D vector
	z_centroids = np.zeros(pyrDim_0)

	for i in np.arange(pyrDim_1):
		x_centroids[i] = (x_nodes[i] + x_nodes[i+1])/2
	x_par = np.reshape(np.tile(x_centroids, pyrDim_0), (-1,))

	for i in np.arange(pyrDim_0):
		z_centroids[i] = (z_nodes[i] + z_nodes[i+1])/2
	z_par = np.reshape(np.repeat(z_centroids, pyrDim_1), (-1,))

	# Load Data coordinates 
	hObsCoord = np.loadtxt(modelDirPath + '/headObsLocations.txt') # coordinates of the 10 head observation locations
	qObsCoord = np.loadtxt(modelDirPath + '/flowrateObsLocations.txt') # coordinates of the 5 head observation locations
	x_hObs = hObsCoord[:, 0] # x coordinates in meter of head observations
	z_hObs = hObsCoord[:, 2] # z
	x_qObs = qObsCoord[:, 0] # x coordinates in meter of flowrate observations (mean of element centroids)
	z_qObs = qObsCoord[:, 1] # z
	x_allObs = np.concatenate((x_hObs, x_qObs), axis=0)
	z_allObs =  np.concatenate((z_hObs, z_qObs), axis=0)
 	
	nbOfPar = x_par.shape[0]
	nbOfData = np.loadtxt(homeDirPath + '/simHeads_0.txt').shape[0] + np.loadtxt(homeDirPath + '/simFlowrates_0.txt').shape[0] # #obs = heads + flowrates
	taperMatrix = np.zeros((nbOfPar, nbOfData)) # define taper matrix of dimensions (nbOfPar, nbOfData)
	
	obsIDList = np.loadtxt(modelDirPath + '/mapOfDataList2obsID_syn_ALLDATA.txt') 

	k=0
	for l in range(0, nbOfData):

		# Compute the values of taperMatrix using the distance-based Gaspari-Cohn function
		obsID = int(obsIDList[l])	
		dist_allPar2oneObs = np.reshape(np.sqrt((x_par - np.repeat(x_allObs[obsID], nbOfPar))**2 + (z_par - np.repeat(z_allObs[obsID], nbOfPar))**2), (-1,1)) # column vector of distances from each parameter to one data

		taperVector = np.zeros(nbOfPar) # define taperVector in order to fill taperMatrix column by column
		taperVector[np.where(dist_allPar2oneObs <= range_x)[0]] = -1/4*(dist_allPar2oneObs[dist_allPar2oneObs <= range_x]/range_x)**5 + 1/2*(dist_allPar2oneObs[dist_allPar2oneObs <= range_x]/range_x)**4 + 5/8*(dist_allPar2oneObs[dist_allPar2oneObs <= range_x]/range_x)**3 - 5/3*(dist_allPar2oneObs[dist_allPar2oneObs <= range_x]/range_x)**2 + 1

		taperVector[np.where((dist_allPar2oneObs > range_x) & (dist_allPar2oneObs <= 2*range_x))[0]] = 1/12*(dist_allPar2oneObs[(dist_allPar2oneObs > range_x) & (dist_allPar2oneObs <= 2*range_x)]/range_x)**5 - 1/2*(dist_allPar2oneObs[(dist_allPar2oneObs > range_x) & (dist_allPar2oneObs <= 2*range_x)]/range_x)**4 + 5/8*(dist_allPar2oneObs[(dist_allPar2oneObs > range_x) & (dist_allPar2oneObs <= 2*range_x)]/range_x)**3 + 5/3*(dist_allPar2oneObs[(dist_allPar2oneObs > range_x) & (dist_allPar2oneObs <= 2*range_x)]/range_x)**2 - 5*(dist_allPar2oneObs[(dist_allPar2oneObs > range_x) & (dist_allPar2oneObs <= 2*range_x)]/range_x) + 4 - 2/3*range_x/dist_allPar2oneObs[(dist_allPar2oneObs > range_x) & (dist_allPar2oneObs <= 2*range_x)] # taperVector[np.where(dist_allPar2oneObs > 2*range_x)[0], np.where(dist_allPar2oneObs > 2*range_x)[1]] is equal to 0

		taperMatrix[:, l] = taperVector	
	
	return taperMatrix	



