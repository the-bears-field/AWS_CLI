#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 関数をインポート。
. /aws/shell_scripts/functions.sh

# EC2インスタンスの状態を取得。
ec2_instance_state=`get_ec2_instance_state`

# EC2インスタンスがすでに停止していれば終了。
if [ ${ec2_instance_state} = "stopped" ]; then
  echo "EC2インスタンス(インスタンスID: ${EC2_INSTANCE_ID})は停止済です。"
  return
fi

# ElasticIPアドレスの関連付けを解除
aws ec2 disassociate-address --association-id ${ASSOCIATION_ID}
sed -i '/ASSOCIATION_ID/d' .env
echo "Elastic IP(${ELASTIC_IP_ADDRESS})の関連付けを解除しました。"
echo "ASSOCIATION_ID(${ASSOCIATION_ID})を削除しました。"
export -n ASSOCIATION_ID

# ElasticIPアドレス解放
aws ec2 release-address --allocation-id ${ALLOCATION_ID}
sed -i '/ALLOCATION_ID/d' .env
sed -i '/ELASTIC_IP_ADDRESS/d' .env
echo "Elastic IP(${ELASTIC_IP_ADDRESS})を開放しました。"
echo "ALLOCATION_ID(${ALLOCATION_ID})を削除しました。"
echo "ELASTIC_IP_ADDRESS(${ELASTIC_IP_ADDRESS})を削除しました。"
export -n ALLOCATION_ID
export -n ELASTIC_IP_ADDRESS

# EC2インスタンスを停止しつつ、現在の状態を取得。
ec2_instance_state=$( \
  aws ec2 stop-instances \
    --instance-ids $EC2_INSTANCE_ID \
    --query StoppingInstances[0].CurrentState.Name \
    --output text \
)

echo "EC2インスタンス(インスタンスID: ${EC2_INSTANCE_ID})を停止中です。"

# EC2インスタンスの停止が確認できるまでループ処理。
while [ ${ec2_instance_state} != "stopped" ]
do
  sleep 2s
  ec2_instance_state=`get_ec2_instance_state`
done

echo "EC2インスタンス(インスタンスID: ${EC2_INSTANCE_ID})を停止しました。"
