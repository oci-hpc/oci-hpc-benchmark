#!/bin/bash

# Source installpath, modelname and machinefile
source ~/.bashrc

# System Info:
INSTANCE=BM.HPC2.36
MPI_VERSION=""
MODEL_VERS="N/A"
OFED_VERS=`ofed_info -s`
KERNEL_VERS=`uname -r`
HPC_TOOLS_VERS="N/A"
HPC_IMAGE_VERS=""  ###TODO - in the terraform scripts, have one of the outputs be gather the image version details to export
dt=$( date '+%FT%H:%M:%S'.123Z )

# Command Line Input:
NODES_ITER=$1
PPN=$2
MPINAME=$3
POD=$4
StarCCM_Version=$5
MYSQL_HOST=$6
MYSQL_USER=$7
MYSQL_PWD=$8
OBJSTR_PAR=$9
COMMENT=${10}

uid=`uuidgen | cut -c-8`
BASE_EXECUTION_TIME=0
BASE_CORES=0
INIT_TEST="INIT"

for NODES in $NODES_ITER; do
	CORES=$(($NODES * $PPN))
	benchITS+=$CORES,

	#LOG EVENT
	echo `date` | tee -a ${MPINAME}.${CORES}.${uid}.log
	#RUN SIMULATION
	if [ $MPINAME == intel ]; then
    	$INSTALLPATH/star/bin/starccm+ -v -power -licpath 1999@flex.cd-adapco.com -podkey $POD -np $CORES -benchmark "-preclear -preits 20 -nits 10 -nps $benchITS" -machinefile $MACHINEFILE -rsh ssh -mpi $MPINAME -cpubind bandwidth,v -mppflags "-iface enp94s0f0 -genv I_MPI_DAPL_PROVIDER ofa-v2-cma-roe-enp94s0f0 -genv I_MPI_DAPL_UD 0 -genv I_MPI_FALLBACK 0 -genv I_MPI_DYNAMIC_CONNECTION 0 -genv I_MPI_FABRICS shm:dapl -genv I_MPI_DAT_LIBRARY /usr/lib64/libdat2.so -genv I_MPI_DEBUG 6" -load $MODELNAME | tee -a ${MPINAME}.${CORES}.${uid}.log
	elif [ $MPINAME == openmpi3 ]; then
		$INSTALLPATH/star/bin/starccm+ -v -power -licpath 1999@flex.cd-adapco.com -podkey $POD -np $CORES -benchmark "-preclear -preits 40 -nits 20 -nps $benchITS" -machinefile $MACHINEFILE -rsh ssh -mpi $MPINAME -cpubind bandwidth,v -mppflags "--display-map -mca btl self -mca UCX_TLS rc,self,sm -mca HCOLL_ENABLE_MCAST_ALL 0 -mca coll_hcoll_enable 0 -mca UCX_IB_TRAFFIC_CLASS 105 -mca UCX_IB_GID_INDEX 3 --cpu-set 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35" -load $MODELNAME | tee -a ${MPINAME}.${CORES}.${uid}.log;]
	elif [ $MPINAME == platform ]; then
		$INSTALLPATH/star/bin/starccm+ -v -power -licpath 1999@flex.cd-adapco.com -podkey $POD -np $CORES -nosuite -machinefile $MACHINEFILE -rsh ssh -mpi $MPINAME -mppflags "-intra=shm -e MPI_HASIC_UDAPL=ofa-v2-cma-roe-enp94s0f0 -UDAPL -aff=automatic:bandwidth:core -affopt=v -prot" -benchmark "-preclear -preits 40 -nits 20 -nps $benchITS" $MODELNAME | tee -a ${MPINAME}.{$CORES}.${uid}.log
	fi

	#LOG EVENT
	echo `date` | tee -a ${MPINAME}.${CORES}.${uid}.log

	# Get the name of the xml file
	XML=`cat ${MPINAME}.${CORES}.${uid}.log | grep 'Benchmark::Output file name :' | cut -d ' ' -f 5`

	# Get the data from the xml
	MPI_VERSION=`xmllint --xpath '//MpiType/text()' $XML`
	StarCCM_Version=`xmllint --xpath '//Version/text()' $XML`
	CMD_LINE=`xmllint --xpath '//ServerCommand/text()' $XML`
	MODELNAME=`xmllint --xpath '//Name/text()' $XML`
	RUNDATE=`xmllint --xpath '//RunDate/text()' $XML`
	OS_VERS=`xmllint --xpath '//OS/text()' $XML | cut -d '(' -f 1`
	HOSTNAME=`xmllint --xpath '//HostName/text()' $XML`
	NODES=`xmllint --xpath '//NumberOfHosts/text()' $XML`
	MPI_NAME=$(echo $MPI_VERSION | cut -d ' ' -f 1)
	MPI_VERSION_NUMBER=$(echo $MPI_VERSION | cut -d ' ' -f 2)
	AVERAGE_ELAPSED_TIME=`xmllint --xpath '//AverageElapsedTime/text()' $XML`
	CELLS=`xmllint --xpath '//NumberOfCells/text()' $XML`
	CELLSCORE=`echo "scale=2;$CELLS/$CORES" | bc`
	# Check if this is the first run
	if [ "$INIT_TEST" == "INIT" ]
    then
        BASE_EXECUTION_TIME=$AVERAGE_ELAPSED_TIME
        BASE_CORES=$CORES
    fi
    INIT_TEST="DONE"
    # Perform the calculations
    SPEEDUP=`echo "scale=2;($BASE_EXECUTION_TIME/$AVERAGE_ELAPSED_TIME)*$BASE_CORES" | bc`
	SCALING=`echo "scale=2;$SPEEDUP/$CORES" | bc`

	# Send the data to the databases
	mysql -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PWD -e "USE testdb;INSERT INTO kristen_test VALUES ('$uid','starccm','$MODELNAME','$StarCCM_Version','$INSTANCE','$HOSTNAME',$NODES,$CORES,$CORES,$CELLS,$TIME,$SPEEDUP,$CELLSCORE,$SCALING,'$COMMENT',NOW(),'$MPI_VERSION','$OFED_VERS','$OS_VERS','$KERNEL_VERS','$HPC_TOOLS_VERS','$HPC_IMAGE_VERS','$CMD_LINE', '$MODEL_VERS');"
	curl -i -X POST -H "Content-Type:application/json" -d '{"uniqueid": "'$uid'", "application": "starccm" , "model": "'$MODELNAME'", "vers": "'$StarCCM_Version'", "instance": "'$INSTANCE'", "hostname": "'$HOSTNAME'", "nodes": "'$NODES'", "ppn": "'$CORES'", "cores": "'$CORES'", "cells": "'$CELLS'", "metric": "'$TIME'", "speedup": "'$SPEEDUP'", "cellscore": "'$CELLSCORE'", "scaling": "'$SCALING'", "network": "RDMA", "notes": "'$COMMENT'", "rundate": "'"$dt"'", "mpi_vers": "'"$MPI_VERSION"'", "mpi_name": "'$MPI_NAME'", "mpi_version_number": "'$MPI_VERSION_NUMBER'", "ofed_vers": "'"$OFED_VERS"'", "os_vers": "'"$OS_VERS"'", "kernel_vers": "'"$KERNEL_VERS"'", "hpc_tools_vers": "'$HPC_TOOLS_VERS'", "hpc_image_vers": "'$HPC_IMAGE_VERS'", "cmd_line": "cmd_line_not_working", "model_vers": "'$MODEL_VERS'"}' "https://trceontjwuiabrm-benchmarkdb.adb.us-ashburn-1.oraclecloudapps.com/ords/benchmark/benchmark_runs/benchmark/"

	# Kill the processes 
	ssh bastion 'ansible-playbook ~/bench/killstar.yml'

done

# capture logs
RESULTS_FOLDER=StarCCM_Results_${MPINAME}_${CORES}_${uid}
mkdir $RESULTS_FOLDER
sudo mv ${MPINAME}.${CORES}.${uid}.log $XML $RESULTS_FOLDER/

#write logs to object storage
echo "Uploading logs to Object Storage"
for file in $RESULTS_FOLDER/*; do
    FILENAME=$file
    curl -X PUT --data-binary ''@$FILENAME'' $OBJSTR_PAR$FILENAME
done