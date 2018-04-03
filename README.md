# OpenFOAM Motorbike Example
Benchmark files used for testing OCI HPC clusters

## Introduction ##
OpenFOAM is an open source Computation Fluid Dynamics (CFD) solver. It is a C++ toolbox with a large library, allowing for complex models and simulations to be carried out. It also comes with packages to allow parallel computation functionality, which you are able to do easily on Rescale.

This job uses OpenFOAM to calculate the steady flow around a motorcycle and rider. This case changes the number of parallel subdomains based on the number of cores selected for the job. It then decomposes the mesh into parts for each parallel process to solve using decomposePar. simpleFoam is used as the solver for this case, performing steady-state, incompressible RANS calculations over the mesh. After the solve is complete, the mesh and solution is recomposed into a single domain with reconstructPar.

This case runs on 18 cores, with each core solving approximately 20K cells. The solution is run for 2000 steps.

![motorBike mesh](/images/motorbike_mesh.jpg)<!-- .element height="50%" width="50%" -->

## Running ##

## Expected Results ##
These are the results of an unoptimized run, your tests should be significantly better

| Cores         |Nodes  | Mesh Size     | Iterations | Solve Time   |
| ------------- |:-----:|:-------------:|:----------:|------:       |
| 10            |   1   |40M            |  100       | 00:41:15     |
| 20            |   1   |40M            |  100       | 00:25:42     |
| 50            |   1   |40M            |  100       | 00:17:14     |
| 150           |   3   |40M            |  100       | 00:00:00     |



