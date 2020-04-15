#!/usr/bin/python3.5

# import python modules
import sys
# indicate path to python modules
sys.path.insert(0,"/home/lamd/testPython/lib/python3.5/site-packages")
import numpy as np
import scipy as sp
import matplotlib as mpl
# import written functions from python file
from myFunctions import makeMultigaussian, makeFlowParFileForGW, nscore

rank = int(sys.argv[2])

# Variance on hydraulic conductivities
K_variance = float(sys.argv[1]) # variance is given as script command line argument

# Generate GW input parameter file with multigaussian log K 
makeFlowParFileForGW(makeMultigaussian(K_variance), rank) # comm.rank is the rank of the process






