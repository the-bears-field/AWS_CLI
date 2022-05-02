#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 既存のVPCにセキュリティグループを作成し、envファイルに追記。
web_security_group_id=$( \
  aws ec2 create-security-group \
  --group-name ${WEB_SECURITY_GROUP_NAME} \
  --description "Security group for SSH access" \
  --vpc-id ${VPC_ID} \
  --output text \
) && echo "Web Security Group ID: ${web_security_group_id}" \
&& sed -i "/WEB_SECURITY_GROUP_NAME/i WEB_SECURITY_GROUP_ID=${web_security_group_id}" .env

# セキュリティグループに、あらゆる場所からのSSHアクセスを許可するルールを追加。
# SSHアクセスできるIPアドレスを指定する場合は、
# cidrオプションに特定のグローバルIPアドレスを指定し、
# サブネットマスクの値を32にすること。
# アクセスできるIPアドレスを複数指定する場合は、ip-ip-permissionsオプションを使用。
aws ec2 authorize-security-group-ingress \
  --group-id ${web_security_group_id} \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
