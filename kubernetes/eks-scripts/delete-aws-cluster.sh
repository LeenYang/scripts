#!/bin/bash 

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

echo "delete role: AmazonEKSClusterRole-$baseName"
aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --role-name "AmazonEKSClusterRole-$baseName"
aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds --role-name AmazonEKSNodeRole-$baseName
aws iam detach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly   --role-name AmazonEKSNodeRole-$baseName


aws iam delete-role --role-name "AmazonEKSClusterRole-$baseName"
aws iam delete-role --role-name  AmazonEKSNodeRole-$baseName 

# delete node group for cluster
aws eks delete-nodegroup --cluster-name $clusterName --nodegroup-name $nodeGroup
sleep 200

echo "delete cluster"
aws eks delete-cluster --region $region \
                       --name $clusterName  \


