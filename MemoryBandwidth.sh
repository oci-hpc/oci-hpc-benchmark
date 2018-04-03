#!/bin/bash
#####################################################
#
# Memory Bandwidth Test based on Zack Smith's Bandwidth Benchmark
# http://zsmith.co/bandwidth.html
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
wget http://zsmith.co/archives/bandwidth-1.5.1.tar.gz -O - | tar zx
cd bandwidth-1.5.1
yum install -y nasm gcc 
touch /usr/include/stropts.h
make bandwidth64
./bandwidth64