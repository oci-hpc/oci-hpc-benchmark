#!/bin/bash
#####################################################
#
# MPI Test Suite based on Alex Loddoch's Test Suite  3/27/2017
#
# Intended to be run as a root user, pass directory to install in as an argument
# taylor newill, taylor.newill@oracle.com, 2018-03-12
#
#####################################################

if [ -z "$1" ]
  then
    SHARE_DIR=~
  else
    SHARE_DIR=$1
fi

cd $SHARE_DIR
#MPI TestSuite
mkdir MPI_testsuite
cd $SHARE_DIR/MPI_testsuite
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/ByfEf27rYjwnR4AtE70xbgsZ7KWmn91vIr9RWvCruqQ/n/hpc/b/HPC_BENCHMARKS/o/MPI_testsuite.tgz -O - | tar zx
