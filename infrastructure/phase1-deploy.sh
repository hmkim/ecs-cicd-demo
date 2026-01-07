#!/bin/bash

# Deploy infrastructure using CloudFormation
STACK_NAME="ci-cd-demo-infrastructure"
TEMPLATE_FILE="phase1-infrastructure.yaml"
REGION="ap-northeast-2"

echo "Deploying infrastructure stack: $STACK_NAME"

aws cloudformation deploy \
  --template-file $TEMPLATE_FILE \
  --stack-name $STACK_NAME \
  --parameter-overrides \
    ProjectName=ci-cd-demo \
    Environment=dev \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

if [ $? -eq 0 ]; then
  echo "Infrastructure deployment completed successfully!"
  
  # Get outputs
  echo "Getting stack outputs..."
  aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table
else
  echo "Infrastructure deployment failed!"
  exit 1
fi
