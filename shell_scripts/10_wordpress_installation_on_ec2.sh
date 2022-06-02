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

# EC2インスタンスへssh接続し、環境を構築した上でWordPressを導入。
expect -c "
set timeout 10
spawn ssh -oStrictHostKeyChecking=no -i ${HOME}/.ssh/${SSH_KEY_NAME}.pem ec2-user@${ELASTIC_IP_ADDRESS}
expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo amazon-linux-extras install -y php7.2\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    sleep 2
    log_user 1
    send \"sudo yum -y install php php-mbstring\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    sleep 2
    log_user 1
    send \"curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    sleep 2
    log_user 1
    send \"chmod +x wp-cli.phar\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    sleep 2
    log_user 1
    send \"sudo mv wp-cli.phar /usr/local/bin/wp\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    sleep 2
    log_user 1
    send \"sudo /usr/local/bin/wp core download --locale=ja --path=$WP_PATH\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    sleep 2
    log_user 1
    send \"sudo systemctl restart httpd.service\n\"
  }
}

expect {
  -regexp "\n.*\r" {
    send \"exit\n\"
    exit 0
  }
}
"
