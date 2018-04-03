#!/bin/bash
BENCHMARKMODEL=aircraft_wing_14m


#SingleNode
fluentbench.pl -t8 $BENCHMARKMODEL
fluentbench.pl -t16 $BENCHMARKMODEL
fluentbench.pl -t32 $BENCHMARKMODEL
fluentbench.pl -t36 $BENCHMARKMODEL
fluentbench.pl -t50 $BENCHMARKMODEL
fluentbench.pl -t52 $BENCHMARKMODEL
grep rating *.out > single_node_rating.res
rm $BENCHMARKMODEL-*

#TWO NODE
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t16 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t32 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t36 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t50 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t52 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t64 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t72 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t78 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t100 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t104 -mpi=openmpi -cnf=hostfile.2 -mpiopt="$PARA_MPIRUN_FLAGS"

grep rating *.out > two_node_rating.res
rm $BENCHMARKMODEL-*

#THREE NODE
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t24 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t32 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t48 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t64 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t72 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t78 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t96 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t100 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t104 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t108 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t150 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"
fluentbench.pl -ssh -noloadchk -norm $BENCHMARKMODEL -t156 -mpi=openmpi -cnf=hostfile.3 -mpiopt="$PARA_MPIRUN_FLAGS"

grep rating *.out > three_node_rating.res
rm $BENCHMARKMODEL-*



