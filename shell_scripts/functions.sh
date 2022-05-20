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
