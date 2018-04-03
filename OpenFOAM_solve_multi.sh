#!/bin/bash
git update-index --chmod=+x 
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

    mpirun -np $2 -ppn 50 -hostfile ~/hostfile patchSummary -parallel
    mpirun -np $2 -ppn 50 -hostfile ~/hostfile potentialFoam -parallel

    echo #### RUNNING SIMPLEFOAM ####
    echo Running simpleFoam $2>> results
    mpirun -np $2 -ppn 50 -hostfile ~/hostfile simpleFoam -parallel

    echo #### REMOVING OLD FILES ####
    rm -rf processor*
    rm -rf log.*
    rm -rf postProcessing
    sed "s/($1/(10/g" system/decomposeParDict -i
    sed "s/$2;/50;/g" system/decomposeParDict -i
}

decomp_run 30 150
decomp_run 20 100


#------------------------------------------------------------------------------