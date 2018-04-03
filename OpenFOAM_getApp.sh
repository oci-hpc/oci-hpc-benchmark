#!/bin/bash

get_application()
{
    echo "Downloading OpenFOAM"
    mkdir -p /mnt/share/scratch/applications
    cd /mnt/share/scratch/applications
    wget -q https://objectstorage.us-phoenix-1.oraclecloud.com/p/O8oDn9Lmc3fi4ZW_Z7elFStud47LAzHfvZ4wAHxXF3g/n/hpc/b/HPC_BENCHMARKS/o/OpenFOAM-4.x_gcc48.tgz
    tar -xzf OpenFOAM-4.x_gcc48.tgz
    echo source /mnt/share/scratch/applications/OpenFOAM/OpenFOAM-4.x/etc/bashrc >> ~/.bashrc
    source ~/.bashrc
}

get_model()
{
    echo "Downloading Model"
    mkdir -p /mnt/share/scratch/benchmarks
    cd /mnt/share/scratch/benchmarks
    wget -q https://objectstorage.us-phoenix-1.oraclecloud.com/n/hpc/b/HPC_BENCHMARKS/o/motorBike_40M.tgz
    tar -xzf motorBike_40M.tgz
    sed "s/50/100/g" motorBike_40M/system/controlDict -i
}

get_application
get_model