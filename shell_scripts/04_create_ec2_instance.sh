#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# EC2起動に必要なイメージIDを定義。
ec2_image_id=$(
  aws ssm get-parameter \
  --name /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
  --region ${REGION} \
  --query "Parameter.Value" \
  --output text \
) && echo "EC2 Image ID: ${ec2_image_id}"

# EC2インスタンス起動し、インスタンスIDをenvファイルに追記。
ec2_instance_id=$( \
  aws ec2 run-instances \
  --image-id ${ec2_image_id} \
  --count 1 \
  --instance-type t2.micro \
  --key-name ${SSH_KEY_NAME} \
  --security-group-ids ${WEB_SECURITY_GROUP_ID} \
  --subnet-id ${PUBLIC_SUBNET_ID} \
  --private-ip-address 10.0.10.10 \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$EC2_INSTANCE_NAME}]" \
  --query Instances[0].InstanceId \
  --output text \
) && echo "EC2 Instance ID: ${ec2_instance_id}" \
&& sed -i "/EC2_INSTANCE_NAME/i EC2_INSTANCE_ID=${ec2_instance_id}" .env
