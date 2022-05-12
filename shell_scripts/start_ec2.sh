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
ec2_instance_state=$(
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
