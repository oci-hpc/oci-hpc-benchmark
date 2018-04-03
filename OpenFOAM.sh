#!/bin/bash

mkdir -p /mnt/share/scratch/applications
cd /mnt/share/scratch/applications
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/O8oDn9Lmc3fi4ZW_Z7elFStud47LAzHfvZ4wAHxXF3g/n/hpc/b/HPC_BENCHMARKS/o/OpenFOAM-4.x_gcc48.tgz
tar -xzf OpenFOAM-4.x_gcc48.tgz
echo source /mnt/share/scratch/applications/OpenFOAM/OpenFOAM-4.x/etc/bashrc >> ~/.bashrc
source ~/.bashrc

mkdir -p /mnt/share/scratch/benchmarks
cd /mnt/share/scratch/benchmarks
git clone https://github.com/tanewill/motorBike
cd motorBike

. $WM_PROJECT_DIR/bin/tools/RunFunctions
runApplication surfaceFeatureExtract
runApplication blockMesh
runApplication decomposePar

echo Running snappyHexMesh > results
{ time(runParallel snappyHexMesh -overwrite) } 2>> results
mpirun -np 6 checkMesh -parallel | grep cells: >> results


#- For parallel running
ls -d processor* | xargs -I {} rm -rf ./{}/0
ls -d processor* | xargs -I {} cp -r 0.orig ./{}/0

runParallel patchSummary
runParallel potentialFoam
echo Running simpleFoam >> results
{ time(runParallel simpleFoam) } 2>> results

runApplication reconstructParMesh -constant
runApplication reconstructPar -latestTime

#------------------------------------------------------------------------------