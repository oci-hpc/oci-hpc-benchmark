#!/bin/bash
#Specify cluster specs

numProcs=10
processesPerNode=10
hostlist=hostfile.3
linpack_N=69120
linpack_P=1
linpack_Q=2
linpack_NB=192


#Get Intel MPI
mkdir /tmp/intel
cd /tmp/intel
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/dB-x9RA2y5oOdx1zk-zJfdfljjRkr3kVjq6gjyfwebw/n/hpc/b/HPC_BENCHMARKS/o/intel_mpi_2018.1.163.tgz -O - | tar zx
./install.sh --silent=silent.cfg
echo export PATH=/opt/intel/compilers_and_libraries_2018.1.163/linux/mpi/intel64/bin:'$PATH' >> ~/.bashrc


SHARE_DIR=/mnt/blk/share/
mkdir -p $SHARE_DIR
#HPCG
mkdir $SHARE_DIR/hpcg
cd $SHARE_DIR/hpcg
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/zptF4eHuxCyS5UsBjiiIIegTzySAXdf4BOdy_HGGWYQ/n/hpc/b/HPC_BENCHMARKS/o/hpcg-bin.tgz -O - | tar zx
cd hpcg-bin
#mpirun -np 3 -ppn 3 -hostfile $hostlist ./xhpcg
#GFLOPS
grep VALID HPCG-Benchmark* | awk '{ print $10 }'

#HPL
mkdir $SHARE_DIR/hpl
cd $SHARE_DIR/hpl
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/QL7Bbs7G1OqPM5i4nHTxn7FzCZh2xuPC2H3eebzGCMg/n/hpc/b/HPC_BENCHMARKS/o/hpl.tgz -O - | tar zx
cd $SHARE_DIR/hpl/hpl
#mpirun -np 2 -perhost 2 -hostfile $hostlist ./xhpl_intel64_static -n $linpack_N -p $linpack_P -q $linpack_Q -nb $linpack_NB > hpl_output.out 
#GFLOPS
#grep WC00C2R2 *.out | awk '{ print $7 }'

#STREAM
mkdir $SHARE_DIR/stream
cd $SHARE_DIR/stream
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/Aa4DtCkuLXVw7oc1d2oirEcHJ13UWjSeMPlilKobnBU/n/hpc/b/HPC_BENCHMARKS/o/stream.96GB
chmod +x stream.96GB
#KMP_AFFINITY=scatter ./stream.96GB > stream_output.out
#BEST RATE MB/s
grep Triad *.out | awk '{ print $2 }'
: '
#AGGREGATE RESULTS
#Quantum Espresso
mkdir ~/qe
cd ~/qe
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/6ACXXrKHqHO4iZofoDv7WtzRGju2vFxHmDPzw2ywWrw/n/hpc/b/HPC_BENCHMARKS/o/espresso-5.4.0-impi.tgz -O - | tar zx
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/qwRyCrmsrNv8pr8BiGgfhuxwgxpTmu8Qc0SBqFhNaIs/n/hpc/b/HPC_BENCHMARKS/o/espresso_input.tgz -O - | tar zx
#mpirun -np $numProcs -ppn $processesPerNode -genv LD_LIBRARY_PATH qe:\$LD_LIBRARY_PATH -hostfile \$HOME/bin/hostlist qe/pw.x -input input/pw_1.in

#NAMD
mkdir ~/namd
cd ~/namd
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/BoNe4vX_jcn3YcWBRd8kLsYvkgqBwsBwmHM5s-bHNMU/n/hpc/b/HPC_BENCHMARKS/o/namd2
wget https://objectstorage.us-phoenix-1.oraclecloud.com/p/dNrmuN2aryTg2WRQ1uLWO1zdOJjZN4fhNGnm7zG9G6Q/n/hpc/b/HPC_BENCHMARKS/o/namd_stmv_benchmark.tgz -O - | tar zx
'
