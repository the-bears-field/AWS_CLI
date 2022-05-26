#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 関数をインポート。
. /aws/shell_scripts/functions.sh

# EC2インスタンスの状態を取得。
ec2_instance_state=`get_ec2_instance_state`

# EC2インスタンスがすでに停止していれば終了。
if [ ${ec2_instance_state} = "stopped" ]; then
  echo "EC2インスタンス(インスタンスID: ${EC2_INSTANCE_ID})は停止しています。"
  echo "EC2インスタンスを起動して下さい。"
  return
fi

ssh -oStrictHostKeyChecking=no -i ${HOME}/.ssh/${SSH_KEY_NAME}.pem ec2-user@${ELASTIC_IP_ADDRESS}
