#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# EC2インスタンスの状態を取得。
get_ec2_instance_state() {
  echo $( \
    aws ec2 describe-instances \
      --instance-ids $EC2_INSTANCE_ID \
      --query "Reservations[*].Instances[*].State.Name" \
      --output text \
  )
}

# EC2のパブリックIPアドレスを取得。
get_public_ip_address() {
  echo $( \
    aws ec2 describe-instances \
      --instance-id $EC2_INSTANCE_ID \
      --query "Reservations[*].Instances[*].PublicIpAddress" \
      --output text \
  )
}

# RDSインスタンスの状態を取得。
get_rds_instance_state() {
  echo $( \
    aws rds describe-db-instances \
    --db-instance-identifier $DB_INSTANCE_ID \
    --query "DBInstances[0].DBInstanceStatus" \
    --output text
  )
}

# S3バケット名を検証。
validate_s3_bucket_name() {
  # S3バケット名の使用可能文字および文字数を守っているか
  IS_FOLLOW_NAMING_CONVENTIONS=`echo $1 | grep -cwE '^[a-z0-9][a-z0-9\.\-]{1,61}[a-z0-9]$'`

  if [ ${IS_FOLLOW_NAMING_CONVENTIONS} -eq 0 ];then
    echo "半角小文字英数字とハイフン以外の文字を使っている、バケット名の先頭または末尾が小文字の英数字でない、または3文字以上63文字以下になってない可能性があります" 
    return
  fi

  # S3バケット名がIPアドレス形式(XXX.XXX.XXX.XXX)でないかを検証
  IS_IP_ADRESS_FORMAT=`echo $1 | grep -cwE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`

  if [ $IS_IP_ADRESS_FORMAT -eq 1 ];then
    echo "S3バケット名にIPアドレス形式は使用できません"
    exit
  fi

  # S3バケット名にピリオドが連続していないか
  IS_PERIOD_CONTINUOUS=`echo $1 | grep -cE '\.{2,}'`

  if [ $IS_PERIOD_CONTINUOUS -eq 1 ];then
    echo "ピリオドが連続しています"
    exit
  fi

  # 命名規則に則った上での404エラーはバケットが存在しなくて作成可能だとみなす
  IS_UNIQUE=`aws s3api head-bucket --bucket $1 2>&1 | grep -cE '404'`

  if [ $IS_UNIQUE -eq 0 ];then
    echo "重複するS3バケット名が存在しています"
    exit
  fi

  # ピリオドが含まれている場合に警告する
  DOES_IT_CONTAIN_A_PERIOD=`echo $1 | grep -cE '\.'`

  if [ $DOES_IT_CONTAIN_A_PERIOD -eq 1 ]; then
    echo "$1はユニークなS3バケット名ですがピリオドが含まれているとSSLワイルドカード証明書が使えなくなる為、ピリオド抜きに変更をお勧めします"
    exit
  fi
}
