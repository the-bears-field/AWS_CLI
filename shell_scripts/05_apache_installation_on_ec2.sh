#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 共通関数ファイル読込。
. /aws/shell_scripts/functions.sh

# EC2インスタンスの状態を取得し、起動していなければ処理を終了する。
ec2_instance_state=`get_ec2_instance_state`

if [ $ec2_instance_state != "running" ]; then
  echo "EC2インスタンスが起動していません。 EC2インスタンスを起動して下さい。"
  return
fi

# パブリックIPアドレス取得。
public_ip_address=`get_public_ip_address`

# EC2インスタンスへssh接続し、Apacheをインストールする処理。
expect -c "
set timeout 10
spawn ssh -oStrictHostKeyChecking=no -i ${HOME}/.ssh/${SSH_KEY_NAME}.pem ec2-user@${public_ip_address}
expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo yum -y update\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    sleep 2
    log_user 1
    send \"sudo yum -y install httpd\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    sleep 2
    log_user 1
    send \"sudo systemctl start httpd.service\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    sleep 2
    log_user 1
    send \"sudo systemctl enable httpd.service\n\"
  }
}

expect {
  -regexp "\n.*\r" {
    send \"exit\n\"
    exit 0
  }
}
"
