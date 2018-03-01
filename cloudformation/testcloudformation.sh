#!/bin/bash

set -e

ecstemplate=$1
container=$2
image=$3
vpcname=$4


aws cloudformation package --template-file vpc.yml --output-template-file vpc-output.yml --s3-bucket moodle-deployables
aws cloudformation deploy --template-file vpc-output.yml --capabilities CAPABILITY_IAM --stack-name "${vpcname}" \
--parameter-overrides VPCName="${vpcname}" Tenant=amazonian

AppSubnet1=`aws cloudformation describe-stacks --stack-name "${vpcname}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'APPSubnet1')]][0][*].{OutputValue:OutputValue}" --output text`
AppSubnet2=`aws cloudformation describe-stacks --stack-name "${vpcname}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'APPSubnet2')]][0][*].{OutputValue:OutputValue}" --output text`
AppSubnet3=`aws cloudformation describe-stacks --stack-name "${vpcname}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'APPSubnet3')]][0][*].{OutputValue:OutputValue}" --output text`

WSSubnet1=`aws cloudformation describe-stacks --stack-name "${vpcname}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'WSSubnet1')]][0][*].{OutputValue:OutputValue}" --output text`
WSSubnet2=`aws cloudformation describe-stacks --stack-name "${vpcname}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'WSSubnet2')]][0][*].{OutputValue:OutputValue}" --output text`
WSSubnet3=`aws cloudformation describe-stacks --stack-name "${vpcname}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'WSSubnet3')]][0][*].{OutputValue:OutputValue}" --output text`

aws cloudformation package --template-file cloudformation/ecs.yml --output-template-file ecs-output.yml --s3-bucket circleci.deployables
aws cloudformation deploy --template-file ecs-output.yml --capabilities CAPABILITY_IAM --stack-name "${ecstemplate}" --parameter-overrides KeyName="" VpcId=vpc-c7aa77be WSSubnetId="${WSSubnet1},${WSSubnet2},${WSSubnet1}" ClusterSubnetId="${AppSubnet1},${AppSubnet2},${AppSubnet3}" InstanceType=t2.medium DomainName=vssdevelopment.com

#Get output values, this is a soemwhat naive approach since it is a lot of api calls
ecscluster=`aws cloudformation describe-stacks --stack-name "${ecstemplate}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'ecscluster')]][0][*].{OutputValue:OutputValue}" --output text`
ecslbarn=`aws cloudformation describe-stacks --stack-name "${ecstemplate}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'ecslbarn')]][0][*].{OutputValue:OutputValue}" --output text`
ecslbdnsname=`aws cloudformation describe-stacks --stack-name "${ecstemplate}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'ecslbdnsname')]][0][*].{OutputValue:OutputValue}" --output text`
ecslbhostedzoneid=`aws cloudformation describe-stacks --stack-name "${ecstemplate}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'ecslbhostedzoneid')]][0][*].{OutputValue:OutputValue}" --output text`
alblistener=`aws cloudformation describe-stacks --stack-name "${ecstemplate}" --query "Stacks[0].[Outputs[? starts_with(OutputKey, 'alblistener')]][0][*].{OutputValue:OutputValue}" --output text`

#package and deploy an instance
aws cloudformation package --template-file cloudformation/containertemplate.yml --output-template-file containertemplate-output.yml --s3-bucket circleci.deployables
aws cloudformation deploy --template-file containertemplate-output.yml --capabilities CAPABILITY_IAM --stack-name "${container}" --parameter-overrides VpcId=vpc-c7aa77be Priority=1 ecscluster="${ecscluster}" ecslbarn="${ecslbarn}" ecslbdnsname="${ecslbdnsname}"	 ecslbhostedzoneid="${ecslbhostedzoneid}" alblistener="${alblistener}" HostedZoneName=vssdevelopment.com  ServiceName=hello ContainerName=hello image="${image}"
#just send basic test
sleep 15
curl --fail https://hello.vssdevelopment.com/
