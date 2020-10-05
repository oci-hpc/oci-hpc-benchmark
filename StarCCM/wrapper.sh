#!/bin/bash
# User Prompt 

# STACK VARIABLES
stack=ClusterNetwork
nodes=2
region=eu-amsterdam-1
compartment=ocid1.compartment.oc1..aaaaaaaauwpnmrdq3jtsimys7ner4mwpyizozdn67ln33yeasarg6kmivuaq
private_key_path=~/.ssh/id_rsa

echo "getting user input"
# Get user input
while getopts "n:p:c:v:d:t:b:f:" flag; do
    case ${flag} in
        n) nodes=${OPTARG};;
        p) ppn=${OPTARG};;
        c) comment=${OPTARG};;
        v) mpiVersion=${OPTARG};;
        d) podKey=${OPTARG};;
        t) testType=${OPTARG};;
        b) benchITS=${OPTARG};;
        f) conf=${OPTARG};;
    esac
done
shift $((OPTIND -1))

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
  scp -i $private_key_path -rp ./bench $ip:~/
  
  # Run CFD playbook
  ssh $ip -i $private_key_path 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ~/bench/cfd.yml'
  
  # Run Star CCM playbook
  ssh $ip -i $private_key_path 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ~/bench/starccm.yml'

}

benchmarks() {
  local ip=$(ocihpc get ip | grep opc@ | cut -d " " -f2)

  if [ $testType == "large" ]; then
    ssh -T $ip -i $private_key_path << EOF
    scp -p bench/starccmLarge.sh hpc-node-1:~/
    ssh -T hpc-node-1
    chmod +x starccmLarge.sh
    ./starccmLarge.sh $nodes $ppn $mpiVersion $podKey 15.04.008 129.146.97.41 joboyle +ocihpc123456 https://objectstorage.us-ashburn-1.oraclecloud.com/p/pk4d4RaWnwqKQ9BNxOgdK_f4eGAWDhk-HV0psXibBVc/n/hpc_limited_availability/b/TestBucket/o/ $comment
EOF
  else
    ssh -T $ip -i $private_key_path << EOF
    scp -p bench/starccmRun.sh hpc-node-1:~/
    ssh -T hpc-node-1
    chmod +x starccmRun.sh
    ./starccmRun.sh $ppn $benchITS $mpiVersion $podKey 15.04.008 129.146.97.41 joboyle +ocihpc123456 https://objectstorage.us-ashburn-1.oraclecloud.com/p/pk4d4RaWnwqKQ9BNxOgdK_f4eGAWDhk-HV0psXibBVc/n/hpc_limited_availability/b/TestBucket/o/ $comment
EOF
  fi 
}

log_results() {
  echo "pass log results"
}


################################################################################

main() {
  #getFoamMpi

  #echo "Launching Cluster"
  #launch_cluster
  if [ $conf == "no" ]; then
    echo "not configuring..."
  else
    echo "Configuring"
    config_cluster
    echo "Configuration Complete"
  fi

  echo "Benchmarking"
  benchmarks
  echo "Benchmaking Complete"

  #log_results

  #echo "Teardown"
  #teardown
}

main
