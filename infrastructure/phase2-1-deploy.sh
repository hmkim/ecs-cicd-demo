#!/bin/bash

# Deploy ECS Service using CloudFormation
STACK_NAME="ci-cd-demo-ecs-service"
TEMPLATE_FILE="phase2-1-ecs-service.yaml"
REGION="ap-northeast-2"

echo "Deploying ECS Service stack: $STACK_NAME"

aws cloudformation deploy \
  --template-file $TEMPLATE_FILE \
  --stack-name $STACK_NAME \
  --parameter-overrides \
    ProjectName=ci-cd-demo \
  --region $REGION

if [ $? -eq 0 ]; then
  echo "ECS Service deployment completed successfully!"
  
  # Get outputs
  echo "Getting stack outputs..."
  aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
    --output table
else
  echo "ECS Service deployment failed!"
  exit 1
fi
