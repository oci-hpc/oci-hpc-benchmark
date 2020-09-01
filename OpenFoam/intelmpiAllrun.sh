#!/bin/bash

#GENERAL VARIABLES
OpenFOAM_VERSION="OpenFOAM 8"
INSTANCE=BM.HPC2.36
MPI_VERSION=""
MODEL_VERS="N/A"


#GET BASIC SYSTEM INFO
OFED_VERS=`ofed_info -s`
OS_VERS=`cat /etc/*-release | grep "PRETTY_NAME" | cut -d= -f2`
KERNEL_VERS=`uname -r`
HPC_TOOLS_VERS=N/A
HPC_IMAGE_VERS=""  ###TODO - in the terraform scripts, have one of the outputs be gather the image version details to export
HOSTNAME=`hostname`


#COMMAND LINE VARIABLES:
MODEL=$1
NODES_ITER=$2
PPN=$3
COMMENT=$4
MACHINEFILE=$5
MYSQL_HOST=$6
MYSQL_USER=$7
MYSQL_PWD=$8
OBJSTR_PAR=$9


#MPI FLAGS VARIABLES:
#Note: It appears that OpenFOAM gets hung up at snappyhexmesh and patchsummary when mpi flags are specified for intelmpi. Suggest not declaring mpi flags for best performance.
#MPI_FLAGS="-iface enp94s0f0 -genv I_MPI_FABRICS=shm:dapl -genv DAT_OVERRIDE=/etc/dat.conf -genv I_MPI_DAT_LIBRARY=/usr/lib64/libdat2.so -genv I_MPI_DAPL_PROVIDER=ofa-v2-cma-roe-enp94s0f0 -genv I_MPI_FALLBACK=0 -genv I_MPI_PIN_PROCESSOR_LIST=0-35 -genv I_MPI_PROCESSOR_EXCLUDE_LIST=36-71"
#I_MPI_PIN_PROCESSOR_LIST=allcores:map=spread
MPI_FLAGS=""

MPI_VERSION=`mpirun -version | awk 'NR==1'`


uid=`uuidgen | cut -c-8`
BASE_EXECUTION_TIME=0
BASE_CORES=0
INIT_TEST="INIT"

for NODES in $NODES_ITER; do
    #calculate the number of cores for the run
    CORES=$(($NODES * $PPN))

    #Clean out the previous run
    ./Allclean

    #Identify the domain decomposition in decomposeParDict based on the number of cores
    case "$CORES" in
       "36") X=6; Y=3; Z=2;;
       "72") X=6; Y=4; Z=3;;
       "108") X=6; Y=6; Z=3;;
       "144") X=6; Y=6; Z=4;;
       "180") X=6; Y=5; Z=6;;
       "216") X=6; Y=6; Z=6;;
       "288") X=8; Y=6; Z=6;;
       "360") X=6; Y=6; Z=10;;
       "432") X=9; Y=8; Z=6;;
       "504") X=9; Y=8; Z=7;;
       "576") X=9; Y=8; Z=8;;
       "648") X=9; Y=8; Z=9;;
       "720") X=10; Y=8; Z=9;;
       "792") X=11; Y=8; Z=9;;
       "864") X=12; Y=9; Z=8;;
       "936") X=13; Y=9; Z=8;;
       "1008") X=14; Y=9; Z=8;;
       "1080") X=12; Y=10; Z=9;;
       *) X=$CORES; Y=1; Z=1;;
    esac

    echo Mesh Dimensions: `cat system/blockMeshDict | grep simpleGrading | awk '{print $10, $11, $12}' `| tee -a TIME.txt
    echo Cores:$CORES: ${X}, ${Y}, ${Z} | tee -a TIME.txt

    sed "s/NP_to_replace/${CORES}/" system/decomposeParDict_tmp | sed "s/X_to_replace/${X}/" | sed "s/Y_to_replace/${Y}/" | sed "s/Z_to_replace/${Z}/" > system/decomposeParDict


    # Source tutorial run functions
    . $WM_PROJECT_DIR/bin/tools/RunFunctions

    # Copy motorbike surface from resources directory
    cp $FOAM_TUTORIALS/resources/geometry/motorBike.obj.gz constant/triSurface/


    # Run OpenFOAM
    runApplication surfaceFeatures
    runApplication blockMesh
    runApplication decomposePar -copyZero
    echo "Running snappyHexMesh"
    mpirun $MPI_FLAGS -np $CORES -ppn $PPN -hostfile $MACHINEFILE snappyHexMesh -parallel -overwrite > log.snappyHexMesh
    ls -d processor* | xargs -I {} rm -rf ./{}/0
    ls -d processor* | xargs -I {} cp -r 0 ./{}/0
    echo "Running patchsummary"
    timeout 60 mpirun $MPI_FLAGS -np $CORES -ppn $PPN -hostfile $MACHINEFILE patchSummary -parallel > log.patchSummary
    echo "Running potentialFoam"
    mpirun $MPI_FLAGS -np $CORES -ppn $PPN -hostfile $MACHINEFILE potentialFoam -parallel > log.potentialFoam
    echo "Running simpleFoam"
    mpirun $MPI_FLAGS -np $CORES -ppn $PPN -hostfile $MACHINEFILE $(getApplication) -parallel > log.simpleFoam

    runApplication reconstructParMesh -constant
    runApplication reconstructPar -latestTime

    foamToVTK > log.foamToVTK
    touch motorbike.foam

    cat log.simpleFoam | grep ExecutionTime | tail -1 | awk '{ print $3 }' | tee -a TIME.txt


    #perform postrun calculations
    EXECUTION_TIME=`cat log.simpleFoam | grep ExecutionTime | tail -1 | awk '{ print $3 }'`
    CELLS=`grep cells: log.snappyHexMesh | tail -1 | awk -F: '{ print $3 }'|awk '{print $1}'`
    CELLSCORE=`echo "scale=2;$CELLS/$CORES" | bc`
    if [ "$INIT_TEST" == "INIT" ]
    then
        BASE_EXECUTION_TIME=$EXECUTION_TIME
        BASE_CORES=$CORES
    fi
    INIT_TEST="DONE"
    SPEEDUP=`echo "scale=2;($BASE_EXECUTION_TIME/$EXECUTION_TIME)*$BASE_CORES" | bc`
    SCALING=`echo "scale=2;$SPEEDUP/$CORES" | bc`
    echo "SPEEDUP:" $SPEEDUP
    echo "SCALING:" $SCALING


    #send data to the database
    mysql -h $MYSQL_HOST --user $MYSQL_USER --password=$MYSQL_PWD -e "USE benchmarkData;INSERT INTO cae_runs VALUES ('$uid','OpenFOAM','$MODEL','$OpenFOAM_VERS','$INSTANCE','$HOSTNAME',$NODES,$PPN,$CORES,$CELLS,$EXECUTION_TIME,$SPEEDUP,$CELLSCORE,$SCALING,'$COMMENT',curdate(),'$MPI_VERSION','$OFED_VERS','$OS_VERS','$KERNEL_VERS','$HPC_TOOLS_VERS','$HPC_IMAGE_VERS', '$CMD_LINE : $MPI_FLAGS', '$MODEL_VERS');"
done

#capture logs
RESULTS_FOLDER=OpenFOAM-results_$MODEL_$CELLS'M_'`date +%Y%m%d_%H%M%S`
mkdir $RESULTS_FOLDER
mv log.* TIME.txt $RESULTS_FOLDER/

#write logs to object storage
echo "Uploading logs to Object Storage"
for file in $RESULTS_FOLDER/*; do
    FILENAME=$file
    curl -X PUT --data-binary ''@$FILENAME'' $OBJSTR_PAR$FILENAME
done

