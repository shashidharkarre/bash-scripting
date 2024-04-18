#!/bin/bash 

# This script creates servers and the associated route53 internal hosted zone records.
# AMI_ID="ami-0aa718de62aea6fbe"
# Throw an error if the input is null 
# Disclaimer: This script works on CENTOS7 Only

if [ "$1" = "" ] | [ "$2" = "" ] ; then 
    echo -e "\e[31m \n Valid options are component -name or all and env \e[0m \n \e[33m Ex: \n\t bash create-server.sh payment dev \n \e[0m "
    exit 1
fi 

COMPONENT=$1
ENV=$2
SGID="sg-0bf27dd0bb525e6b9"
AMI_ID="ami-052d9bac7baef4290"
# AMI_ID=$(aws ec2 describe-images  --filters "Name=name,Values=CloudDevOps-LabImage-CentOS7" | jq '.Images[].ImageId' | sed -e 's/"//g')
echo $AMI_ID 

create_server() {
    echo "$COMPONENT Server Creation in progress"
    PRIVATE_IP=$(aws ec2 run-instances --security-group-ids $SGID --image-id  $AMI_ID --instance-type t2.micro --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${COMPONENT}-${ENV}}]" | jq '.Instances[].PrivateIpAddress' | sed -e 's/"//g')

    # # Changing the IP Address and DNS Name as per the component
    sed -e "s/IPADDRESS/${PRIVATE_IP}/" -e "s/COMPONENT/${COMPONENT}-${ENV}/" route53.json > /tmp/record.json 
    aws route53 change-resource-record-sets --hosted-zone-id Z09626353E72G6GNQ0R5A --change-batch file:///tmp/record.json | jq 
}

if [ "$1" == "all" ]; then 
    for component in catalogue cart user shipping payment frontend mongodb mysql rabbitmq redis ; do 
        COMPONENT=$component
        create_server 
    done 
else 
    create_server # Calling a function 
fi


