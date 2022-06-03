#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 共通関数ファイル読込。
. /aws/shell_scripts/functions.sh

# EC2インスタンスとRDSインスタンスの状態を取得し、
# どちらか片方が起動していなければ処理を終了する。
ec2_instance_state=`get_ec2_instance_state`
rds_instance_state=`get_rds_instance_state`

if [ $ec2_instance_state != "running" ] && [ $rds_instance_state != "available" ]; then
  echo "EC2インスタンスとRDSインスタンスが起動していません。"
  echo "EC2インスタンスとRDSインスタンスを起動して下さい。"
  return
elif [ $ec2_instance_state != "running" ]; then
  echo "EC2インスタンスが起動していません。"
  echo "EC2インスタンスを起動して下さい。"
  return
elif [ $rds_instance_state != "available" ]; then
  echo "RDSインスタンスが起動していません。"
  echo "RDSインスタンスを起動して下さい。"
  return
fi

# EC2インスタンスへssh接続し、WordPressの初期設定を実行。
expect -c "
set timeout 10
spawn ssh -oStrictHostKeyChecking=no -i ${HOME}/.ssh/${SSH_KEY_NAME}.pem ec2-user@${ELASTIC_IP_ADDRESS}
expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo /usr/local/bin/wp config create --dbname=$DB_DATABASE --dbuser=$DB_USER --dbpass=$DB_PASSWORD --dbhost=$DB_ENDPOINT_ADDRESS --dbcharset=utf8mb4 --path=$WP_PATH\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo /usr/local/bin/wp core install --url=$ELASTIC_IP_ADDRESS --title='ゼロから実践するAWS' --admin_user=$WP_USER --admin_password=$WP_PASSWORD --admin_email=$WP_EMAIL --path=$WP_PATH\n\"
  }
}

expect {
  -regexp "\n.*\r" {
    send \"exit\n\"
    exit 0
  }
}
"
