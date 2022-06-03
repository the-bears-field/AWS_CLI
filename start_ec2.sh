#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 関数をインポート。
. /aws/shell_scripts/functions.sh

# EC2インスタンスの状態を取得。
ec2_instance_state=`get_ec2_instance_state`

# EC2インスタンスが稼働していれば終了。
if [ ${ec2_instance_state} = "running" ]; then
  echo "EC2インスタンス(インスタンスID: ${EC2_INSTANCE_ID})は起動済です。"
  return
fi

# EC2インスタンスを起動。
ec2_instance_state=$( \
  aws ec2 start-instances \
    --instance-ids $EC2_INSTANCE_ID \
    --query StartingInstances[0].CurrentState.Name \
    --output text \
)

echo "EC2インスタンス(インスタンスID: ${EC2_INSTANCE_ID})を起動中です。"
sleep 2s

# EC2インスタンスの起動が確認できるまでループ処理。
while [ ${ec2_instance_state} != "running" ]
do
  sleep 2s
  ec2_instance_state=`get_ec2_instance_state`
done

echo "EC2インスタンス(インスタンスID: ${EC2_INSTANCE_ID})を起動しました。"

# Elastic IPアドレスとAllocation IDを取得
set $( \
  aws ec2 allocate-address \
    --query [PublicIp,AllocationId] \
    --output text \
)

# Elastic IPアドレスを変数に格納、envファイル追記
elastic_ip_address=${1}
echo "Elastic IP Address: ${elastic_ip_address}"
sed -i "/# Elastic IP/a ELASTIC_IP_ADDRESS=${elastic_ip_address}" .env

# Allocation IDを変数に格納、envファイル追記
allocation_id=${2}
echo "Allocation ID: ${allocation_id}"
sed -i "/# Elastic IP/a ALLOCATION_ID=${allocation_id}" .env

# ElasticIPアドレスとインスタンスとを関連付けし、Association IDを取得、envファイル追記
association_id=$( \
  aws ec2 associate-address \
    --allocation-id ${allocation_id} \
    --instance-id ${EC2_INSTANCE_ID} \
    --query "AssociationId" \
    --output text \
) && echo "Association Id: ${association_id}" \
&& sed -i "/# Elastic IP/a ASSOCIATION_ID=${association_id}" .env

# EC2インスタンスへssh接続し、WordPressのURLを変更。
# ドメインを取得し、EC2インスタンスと連携済である場合はこの処理は不要。
expect -c "
set timeout 10
spawn ssh -oStrictHostKeyChecking=no -i ${HOME}/.ssh/${SSH_KEY_NAME}.pem ec2-user@${elastic_ip_address}
expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"cd $WP_PATH\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo /usr/local/bin/wp option update home http://$elastic_ip_address\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"sudo /usr/local/bin/wp option update siteurl http://$elastic_ip_address\n\"
  }
}

expect {
  -glob \"ec2-user@*\" {
    log_user 1
    send \"exit\n\"
    exit 0
  }
}
"
