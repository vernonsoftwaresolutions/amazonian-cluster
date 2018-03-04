#!/bin/bash
ecstemplate=$1
container=$2
image=$3
vpcname=$4

aws cloudformation delete-stack --stack-name "${container}"
aws cloudformation delete-stack --stack-name "${container}2"

aws cloudformation delete-stack --stack-name "${ecstemplate}"

aws cloudformation delete-stack --stack-name "${vpcname}"
