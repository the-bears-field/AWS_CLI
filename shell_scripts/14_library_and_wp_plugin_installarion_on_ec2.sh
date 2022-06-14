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

insert_constant="define( 'AS3CF_SETTINGS', serialize( array('provider' => 'aws', 'access-key-id' => '$S3_OPERATION_USER_ACCESS_KEY_ID', 'secret-access-key' => '$S3_OPERATION_USER_SECRET_ACCESS_KEY',)));"

expect -c "
set timeout 10
spawn ssh -oStrictHostKeyChecking=no -i ${HOME}/.ssh/${SSH_KEY_NAME}.pem ec2-user@${ELASTIC_IP_ADDRESS}
expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo yum install -y php-xml\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo systemctl restart httpd.service\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"cd $WP_PATH\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo /usr/local/bin/wp plugin install amazon-s3-and-cloudfront --activate\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo sed -i \\\"/Add any custom values between this line and the/a $insert_constant\\\" wp-config.php\n\"
  }
}

expect {
  -regexp "\n.*\r" {
    send \"exit\n\"
    exit 0
  }
}
"
