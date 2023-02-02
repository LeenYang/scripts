#!/bin/bash -e

baseName=$RANDOM
clusterName="cluster-$baseName"
nodeGroup="group-$baseName"
nodeNum=2
nodeType=t3.medium
region=us-east-2
imaNum=155939011630
usage()
{
    set +x
    if [ "$1" == error ]; then
        shift
        echo "Exiting on ERROR: $*"
        EXIT_CODE=1
    else
        EXIT_CODE=0
    fi

    echo "Usage:
    
    $0 -n <cluster_name> -t <node_type> -c <node_count>

    options:
     -h  print this help
     -n  set your cluster name
     -t  set your node type
     -c  set your node number
     -r  set the region to create your cluster
     -i  set your ima number, default is lyang's number: 155939011630
"
    exit $EXIT_CODE
}

while getopts n:j:c:h OPTION
do
     case $OPTION in
         h)
             usage ok ;;

         n)
             echo "Setting cluset name: $OPTARG"
             baseName=$OPTARG
             clusterName="cluster-$baseName"
             nodeGroup="group-$baseName"
             ;;

         t)
             nodeType=$OPTARG
             ;;
         c)
             nodeNum=$OPTARG
             ;;
         r)
             region=$OPTARG
             ;;
         i)
             imaNum=$OPTARG
             ;;
     esac
done

# Uncomment below to configure the access credential
# aws configure

echo "create role: AmazonEKSClusterRole-$baseName"
aws iam create-role --role-name "AmazonEKSClusterRole-$baseName" --assume-role-policy-document file://"eks-cluster-role-trust-policy.json"

echo "attach role policy ..."
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --role-name "AmazonEKSClusterRole-$baseName"

echo "on $region"
echo "creating vpc"
aws eks create-cluster --region $region \
                       --name $clusterName  \
                       --kubernetes-version 1.24 \
                       --role-arn arn:aws:iam::$imaNum:role/AmazonEKSClusterRole-$baseName \
                       --resources-vpc-config subnetIds=subnet-0c61f6ba14aac0434,subnet-06e66b5cb15a6912a,securityGroupIds=sg-0d981bf3f2fb437bc

# Set /home/username/.kube/config
aws eks update-kubeconfig --region $region --name $clusterName


# Create node group
aws iam create-role --role-name  AmazonEKSNodeRole-$baseName --assume-role-policy-document file://"node-role-trust-policy.json"

# attach policy to role
aws iam attach-role-policy --policy-arn   arn:aws:iam::aws:policy/AWSAppRunnerServicePolicyForECRAccess --role-name AmazonEKSNodeRole-$baseName
#aws iam attach-role-policy --policy-arn   arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess --role-name AmazonEKSNodeRole-$baseName
#aws iam attach-role-policy --policy-arn   arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds --role-name AmazonEKSNodeRole-$baseName

aws iam attach-role-policy   --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly   --role-name AmazonEKSNodeRole-$baseName

# Create node group for cluster
aws eks create-nodegroup --cluster-name $clusterName --nodegroup-name $nodeGroup --disk-size 20 --subnets "subnet-0c61f6ba14aac0434" "subnet-06e66b5cb15a6912a" --instance-types $nodeType --node-role arn:aws:iam::155939011630:role/AmazonEKSNodeRole-$baseName --scaling-config minSize=$nodeNum,maxSize=$nodeNum,desiredSize=$nodeNum
