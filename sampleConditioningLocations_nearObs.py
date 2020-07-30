#!/usr/bin/python3

# Import python modules
import sys
import numpy as np
from myFunctions import assignDataToNearestCellCentroidCoordinates, findDataCellCoordinates, sampleLocations  # import written functions from python file


# Sample conditioning locations

pyrDim_0 = 13
pyrDim_1 = 125
nbSamples_y = 6
nbSamples_x = 41

#pyrDim_0 = 9
#pyrDim_1 = 84
#nbSamples_y = 4
#nbSamples_x = 28

x_nodes = np.linspace(0, 5000, pyrDim_1+1)
y_nodes = np.linspace(0, 500, pyrDim_0+1)
x_centroids = np.zeros(pyrDim_1) # 1D vector
y_centroids = np.zeros(pyrDim_0)
for i in np.arange(pyrDim_1):
    x_centroids[i] = (x_nodes[i] + x_nodes[i+1])/2
for i in np.arange(pyrDim_0):
    y_centroids[i] = (y_nodes[i] + y_nodes[i+1])/2
XX, YY = np.meshgrid(x_centroids, y_centroids) # coordinates of small grid

x_rand_1, y_rand_1 = sampleLocations(0, 1600, 0, 500, 13, nbSamples_y)
x_rand_2, y_rand_2 = sampleLocations(2800, 5000, 0, 500, 18, nbSamples_y)
x_rand = np.concatenate((x_rand_1, x_rand_2), axis=0)
y_rand = np.concatenate((y_rand_1, y_rand_2), axis=0)
xy_rand = np.concatenate((x_rand, y_rand), axis=1)
x_grid, y_grid = assignDataToNearestCellCentroidCoordinates(x_centroids, y_centroids, xy_rand)
i_samples, j_samples = findDataCellCoordinates(x_grid, y_grid, XX, YY)
np.savetxt('sampledCells_xCoord.txt', i_samples, fmt="%d")
np.savetxt('sampledCells_yCoord.txt', j_samples, fmt="%d")

