#!/bin/bash

# 環境変数を再定義
eval "$(shdotenv)"

# VPC生成、返り値のVPCIDを変数に格納、envファイルに追記。
vpc_id=$(
  aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specification "ResourceType=vpc,Tags=[{Key=Name,Value=$VPC_NAME}]" \
  --query Vpc.VpcId \
  --output text \
) && echo "VPC ID: ${vpc_id}" \
&& sed -i "/VPC_NAME/i VPC_ID=$vpc_id" .env

# サブネット生成、返り値のサブネットIDを変数に格納、envファイルに追記。
public_subnet_id=$( \
  aws ec2 create-subnet \
  --vpc-id ${vpc_id} \
  --cidr-block 10.0.10.0/24 \
  --tag-specification "ResourceType=subnet,Tags=[{Key=Name,Value=$PUBLIC_SUBNET_NAME}]" \
  --availability-zone ${PRIMARY_ZONE_NAME} \
  --query Subnet.SubnetId \
  --output text \
) && echo "Public Subnet ID: ${public_subnet_id}" \
&& sed -i "/PUBLIC_SUBNET_NAME/i PUBLIC_SUBNET_ID=$public_subnet_id" .env

primary_private_subnet_id=$( \
  aws ec2 create-subnet \
  --vpc-id ${vpc_id} \
  --cidr-block 10.0.20.0/24 \
  --tag-specification "ResourceType=subnet, Tags=[{Key=Name,Value=$PRIMARY_PRIVATE_SUBNET_NAME}]" \
  --availability-zone ${PRIMARY_ZONE_NAME} \
  --query Subnet.SubnetId \
  --output text \
) && echo "Primary Private Subnet ID: ${primary_private_subnet_id}" \
&& sed -i "/PRIMARY_PRIVATE_SUBNET_NAME/i PRIMARY_PRIVATE_SUBNET_ID=$primary_private_subnet_id" .env

secondary_private_subnet_id=$( \
  aws ec2 create-subnet \
  --vpc-id ${vpc_id} \
  --cidr-block 10.0.21.0/24 \
  --tag-specification "ResourceType=subnet, Tags=[{Key=Name,Value=$SECONDARY_PRIVATE_SUBNET_NAME}]" \
  --availability-zone ${SECONDARY_ZONE_NAME} \
  --query Subnet.SubnetId \
  --output text \
) && echo "Secondary Private Subnet ID: ${secondary_private_subnet_id}" \
&& sed -i "/SECONDARY_PRIVATE_SUBNET_NAME/i SECONDARY_PRIVATE_SUBNET_ID=$secondary_private_subnet_id" .env

# インターネットゲートウェイを作成しつつ、
# 返り値のインターネットゲートウェイIDを変数に格納、envファイルに追記。
internet_gateway_id=$( \
  aws ec2 create-internet-gateway \
  --tag-specification "ResourceType=internet-gateway, Tags=[{Key=Name,Value=$INTERNET_GATEWAY_NAME}]" \
  --query InternetGateway.InternetGatewayId \
  --output text \
) && echo "Internet Gateway ID: ${internet_gateway_id}" \
&& sed -i "/INTERNET_GATEWAY_NAME/i INTERNET_GATEWAY_ID=$internet_gateway_id" .env

# インターネットゲートウェイをVPCに接続。
aws ec2 attach-internet-gateway \
  --vpc-id ${vpc_id} \
  --internet-gateway-id ${internet_gateway_id}

# カスタムルートテーブルを作成しつつ、返り値のルートテーブルIDを変数に格納、envファイルに追記。
route_table_id=$( \
  aws ec2 create-route-table \
  --vpc-id ${vpc_id} \
  --tag-specification "ResourceType=route-table,Tags=[{Key=Name,Value=$ROUTE_TABLE_NAME}]" \
  --query RouteTable.RouteTableId \
  --output text \
) && echo "Route Table ID: ${route_table_id}" \
&& sed -i "/ROUTE_TABLE_NAME/i ROUTE_TABLE_ID=$route_table_id" .env

# すべてのトラフィック（0.0.0.0/0）がインターネットゲートウェイを指すルートをルートテーブルに作成。
aws ec2 create-route \
  --route-table-id ${route_table_id} \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id ${internet_gateway_id}

# カスタムルートテーブルに公開用サブネットとを関連付ける。
aws ec2 associate-route-table \
  --subnet-id ${public_subnet_id} \
  --route-table-id ${route_table_id}

# 公開用サブネットに起動されたインスタンスが自動的にパブリックIPアドレスを付与するよう変更。
aws ec2 modify-subnet-attribute \
  --subnet-id ${public_subnet_id} \
  --map-public-ip-on-launch
