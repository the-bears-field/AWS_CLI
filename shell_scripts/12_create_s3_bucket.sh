#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 共通関数ファイル読込。
. /aws/shell_scripts/functions.sh

# S3バケット名を定義。
hashed_date=($( \
  echo -n `TZ='Asia/Tokyo' date` | shasum \
)) \
&& s3_bucket_name=s3-bucket-${hashed_date}

validated_message=`validate_s3_bucket_name ${s3_bucket_name}`

# S3バケット名の検証の結果、変数に値が入っていれば
# メッセージを表示して処理を終了。
if [ -n "$validated_message" ]; then
  echo $validated_message
  return
fi

# S3バケット生成。
aws s3api create-bucket \
  --bucket ${s3_bucket_name} \
  --create-bucket-configuration "LocationConstraint=${REGION}"

# S3バケット名をenvファイルに追記。
sed -i "/# S3/a S3_BUCKET_NAME=${s3_bucket_name}" .env

echo "S3_BUCKET_NAME: ${s3_bucket_name}"
