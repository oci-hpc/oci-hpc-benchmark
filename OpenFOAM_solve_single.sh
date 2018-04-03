#!/bin/bash


#git clone https://github.com/tanewill/motorBike
#cd motorBike


#runApplication surfaceFeatureExtract
#runApplication blockMesh
#runApplication decomposePar

#echo Running snappyHexMesh > results
##{ time(runParallel snappyHexMesh -overwrite) } 2>> results
#mpirun -np 6 checkMesh -parallel | grep cells: >> results


#- For parallel running
#runApplication decomposePar
#ls -d processor* | xargs -I {} rm -rf ./{}/0
#ls -d processor* | xargs -I {} cp -r 0.orig ./{}/0

#runParallel patchSummarysd 
#runParallel potentialFoam
#mpirun -np 50 simpleFoam -parallel

decomp_run()
{
    echo Divisons: $2
    echo Iteration: $3

    cd /mnt/share/scratch/benchmarks/motorBike_40M
    . $WM_PROJECT_DIR/bin/tools/RunFunctions
    sed "s/50;/$2;/g" system/decomposeParDict -i
    sed "s/(10/($1/g" system/decomposeParDict -i
    
    echo #### DECOMPOSING MESH ####
    runApplication decomposePar
    ls -d processor* | xargs -I {} rm -rf ./{}/0
    ls -d processor* | xargs -I {} cp -r 0.orig ./{}/0

    runParallel patchSummary
    runParallel potentialFoam

    echo #### RUNNING SIMPLEFOAM ####
    echo Running simpleFoam $2>> results
    { time(runParallel simpleFoam) } 2>> results

    echo #### REMOVING OLD FILES ####
    rm -rf processor*
    rm -rf log.*
    rm -rf postProcessing
    sed "s/($1/(10/g" system/decomposeParDict -i
    sed "s/$2;/50;/g" system/decomposeParDict -i
}


decomp_run 2 10
decomp_run 4 20
decomp_run 10 50


#runApplication reconstructParMesh -constant
#runApplication reconstructPar -latestTime

#------------------------------------------------------------------------------