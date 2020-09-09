#!/bin/bash
# User Prompt 

# Get OpenFoam MPI Version
getFoamMpi() {
  echo 'Which mpi version would you like to run (intelmpi or openmpi):'
  read mpiVersion
  
  # Validate
  if [[ "$mpiVersion" == "intelmpi" ]]; then
    echo "intelmpi it is"
    mpiVersion=intelmpi
  elif [[ "$mpiVersion" == "openmpi" ]]; then
    echo "openmpi it is"
    mpiVersion=openmpi
  else
    echo "incorrect format... Using intelmpi as default"
    mpiVersion=intelmpi
    #statements
  fi
}

# STACK VARIABLES
stack=ClusterNetwork
nodes=2
region=eu-frankfurt-1
compartment=ocid1.compartment.oc1..aaaaaaaauwpnmrdq3jtsimys7ner4mwpyizozdn67ln33yeasarg6kmivuaq
private_key_path=~/.ssh/id_rsa



init_ocihpc() {
  [ ! -f "./ClusterNetwork.zip" ] && ocihpc init --stack ClusterNetwork
}

launch_cluster() {
  # Check if ocihpc command exists
  if command -v ocihpc >/dev/null 2>&1; then
    echo "version: $(ocihpc version)"
    init_ocihpc
    ocihpc deploy --stack $stack --node-count $nodes --compartment-id $compartment --region $region
  else
    echo "install and config ocihpc-cli"
    exit 1
  fi
}

teardown() {
  ocihpc delete --stack $stack
  # TODO: remove stack files 
}

# cleanup() {}
config_cluster() {
  local ip=$(ocihpc get ip | grep opc@ | cut -d " " -f2)
  
  # Put files on bastion
  scp -i $private_key_path -rp /Users/joboyle/oci-hpc-benchmark/OpenFoam/bench $ip:~/bench
  
  #ssh $ip -i $private_key_path 'ansible-playbook ~/playbooks/slurm.yml'
  
  # Run CFD playbook
  ssh $ip -i $private_key_path 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ~/bench/cfd.yml'
  
  # Run fluent 
  #ssh $ip -i $private_key_path 'ansible-playbook ~/bench/fluent.yml'
  
  # Check which mpi version to install
  if [[ "$mpiVersion" == "intelmpi" ]]; then
    ssh $ip -i $private_key_path 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ~/bench/intelmpiFoam.yml'
  elif [[ "$mpiVersion" == "openmpi" ]]; then
    ssh $ip -i $private_key_path 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ~/bench/openmpiFoam.yml'
  fi

}

benchmarks() {
  local ip=$(ocihpc get ip | grep opc@ | cut -d " " -f2)
  
  if [[ "$mpiVersion" == "intelmpi" ]]; then
  ssh -T $ip -i $private_key_path << EOF
    ssh -T hpc-node-1
    cd /mnt/nfs-share/OpenFOAM/models/
    ./intelmpiAllrun.sh motorbike $nodes 36 test ./hostfile_intel https://objectstorage.us-ashburn-1.oraclecloud.com/p/pk4d4RaWnwqKQ9BNxOgdK_f4eGAWDhk-HV0psXibBVc/n/hpc_limited_availability/b/TestBucket/o/
EOF
  elif [[ "$mpiVersion" == "openmpi" ]]; then
    ssh -T $ip -i $private_key_path << EOF
    ssh -T hpc-node-1
    cd /mnt/nfs-share/OpenFOAM/models/
    ./openmpiAllrun.sh motorbike $nodes 36 test ./hostfile_openmpi 129.146.97.41 joboyle +ocihpc123456 https://objectstorage.us-ashburn-1.oraclecloud.com/p/pk4d4RaWnwqKQ9BNxOgdK_f4eGAWDhk-HV0psXibBVc/n/hpc_limited_availability/b/TestBucket/o/
EOF
fi
  
}

log_results() {
  echo "pass log results"
}


################################################################################

main() {
  getFoamMpi

  #echo "Launching Cluster"
  #launch_cluster

  echo "Configuring"
  config_cluster
  echo "Configuration Complete"

  echo "Benchmarking"
  benchmarks
  echo "Benchmaking Complete"

  #log_results

  #echo "Teardown"
  #teardown
}

main
