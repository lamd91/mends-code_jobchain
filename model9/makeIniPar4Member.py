#!/usr/bin/python3.5

# import python modules
import sys
# indicate path to python modules
sys.path.insert(0,"/home/lamd/testPython/lib/python3.5/site-packages")
import numpy as np
import scipy as sp
import matplotlib as mpl
import sklearn as skl
from mpi4py import MPI
# import written functions from python file
from myFunctions import makeMultigaussian, makeFlowParFileForGW

comm = MPI.COMM_WORLD
# Variance on hydraulic conductivities
K_variance = float(sys.argv[1]) # variance is given as script command line argument
makeFlowParFileForGW(makeMultigaussian(K_variance), comm.rank) # comm.rank is the rank of the process




