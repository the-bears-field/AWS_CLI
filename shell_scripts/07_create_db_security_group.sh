#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# データベース用のセキュリティグループを作成し、envファイルに追記。
db_security_group_id=$( \
  aws ec2 create-security-group \
    --group-name ${DB_SECURITY_GROUP_NAME} \
    --description "Security group for SSH access" \
    --vpc-id ${VPC_ID} \
    --output text \
) && echo "BD Security Group ID: ${db_security_group_id}" \
&& sed -i "/DB_SECURITY_GROUP_NAME/i DB_SECURITY_GROUP_ID=${db_security_group_id}" .env

# データベース用のセキュリティグループのインバウンドルールを追加し、
# MySQLのリクエストを受け付けるよう設定。
db_security_group_rule_id=$( \
  aws ec2 authorize-security-group-ingress \
  --group-id ${db_security_group_id} \
  --protocol tcp \
  --port 3306 \
  --source-group ${WEB_SECURITY_GROUP_ID} \
  --query SecurityGroupRules[0].SecurityGroupRuleId \
  --output text \
) && echo "DB Security Group Rule ID: ${db_security_group_rule_id}" \
&& sed -i "/# Security Group Rule/a DB_SECURITY_GROUP_RULE_ID=${db_security_group_rule_id}" .env
