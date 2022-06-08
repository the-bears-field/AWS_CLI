#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 共通関数ファイル読込。
. /aws/shell_scripts/functions.sh

# EC2インスタンスの状態を取得し、起動していなければ終了。
ec2_instance_state=`get_ec2_instance_state`

if [ $ec2_instance_state != "running" ]; then
  echo "EC2インスタンスが起動していません。 EC2インスタンスを起動して下さい。"
  return
fi

# S3操作用のIAMユーザー作成。
aws iam create-user --user-name ${S3_OPERATION_USER_NAME}

# S3操作用のIAMユーザーのアクセスキーIDとシークレットアクセスキーを取得。
set $( \
  aws iam create-access-key \
    --user-name ${S3_OPERATION_USER_NAME} \
    --query AccessKey.[AccessKeyId,SecretAccessKey] \
    --output text \
)

s3_operation_user_access_key_id=${1} \
&& echo "S3 Operation User Access Key ID: ${s3_operation_user_access_key_id}" \
&& sed -i "s/S3_OPERATION_USER_ACCESS_KEY_ID=/S3_OPERATION_USER_ACCESS_KEY_ID=${s3_operation_user_access_key_id}/g" .env

s3_operation_user_secret_access_key=${2} \
&& echo "S3 Operation User Secret Access Key: ${s3_operation_user_secret_access_key}" \
&& sed -i "s#S3_OPERATION_USER_SECRET_ACCESS_KEY=#S3_OPERATION_USER_SECRET_ACCESS_KEY=${s3_operation_user_secret_access_key}#g" .env

# S3操作用のIAMユーザーに管理ポリシーを付与。
aws iam attach-user-policy \
  --user-name ${S3_OPERATION_USER_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/AmazonS3FullAccess"
