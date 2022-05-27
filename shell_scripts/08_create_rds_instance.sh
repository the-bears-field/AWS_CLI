#!/bin/bash

# 環境変数を再定義
eval "$(shdotenv)"

# DBサブネットグループを作成。
aws rds create-db-subnet-group \
  --db-subnet-group-name ${DB_SUBNET_GROUP_NAME} \
  --db-subnet-group-description aws-and-infra-subnet-group \
  --subnet-ids ${PRIMARY_PRIVATE_SUBNET_ID} ${SECONDARY_PRIVATE_SUBNET_ID}

# DBパラメータグループ作成
aws rds create-db-parameter-group \
  --db-parameter-group-family mysql8.0 \
  --db-parameter-group-name ${DB_PARAMETER_GROUP_NAME} \
  --description aws-and-infra-mysql80

# DBオプショングループ作成
aws rds create-option-group \
  --option-group-name ${OPTION_GROUP_NAME} \
  --option-group-description aws-and-infra-mysql80 \
  --engine-name mysql \
  --major-engine-version 8.0

# RDSインスタンス起動
db_instance_state=$( \
  aws rds create-db-instance \
    --db-instance-identifier ${DB_INSTANCE_ID} \
    --allocated-storage 20 \
    --db-instance-class db.t2.micro \
    --engine MySQL \
    --master-username root \
    --master-user-password password \
    --engine-version 8.0.28 \
    --vpc-security-group-ids ${DB_SECURITY_GROUP_ID} \
    --availability-zone ${PRIMARY_ZONE_NAME} \
    --db-subnet-group-name ${DB_SUBNET_GROUP_NAME} \
    --preferred-maintenance-window sun:20:00-sun:20:30 \
    --db-parameter-group-name ${DB_PARAMETER_GROUP_NAME} \
    --backup-retention-period 30 \
    --preferred-backup-window 19:00-19:30 \
    --no-multi-az \
    --auto-minor-version-upgrade \
    --license-model general-public-license \
    --option-group-name ${OPTION_GROUP_NAME} \
    --no-publicly-accessible \
    --storage-type gp2 \
    --no-storage-encrypted \
    --copy-tags-to-snapshot \
    --no-enable-iam-database-authentication \
    --no-deletion-protection \
    --no-enable-customer-owned-ip \
    --backup-target region \
    --query DBInstance[0].DBInstanceStatus \
) && echo "RDSインスタンス(DBインスタンスID: ${DB_INSTANCE_ID})を作成中です…"

while [ ${db_instance_state} != "available" ]
do
  sleep 2s
  db_instance_state=`get_rds_instance_state`
done

echo "RDSインスタンス(DBインスタンスID: ${DB_INSTANCE_ID})を作成しました。"

# RDSインスタンスのエンドポイントを取得し、envファイルに追記。
db_endpoint_address=$( \
  aws docdb describe-db-instances \
    --region ${REGION} \
    --db-instance-identifier ${DB_INSTANCE_ID} \
    --query 'DBInstances[*].Endpoint.Address' \
    --output text
) && echo "RDS Endpoint Address: ${db_endpoint_address}" \
&& sed -i "/# RDB/a DB_ENDPOINT_ADDRESS=${db_endpoint_address}" .env
