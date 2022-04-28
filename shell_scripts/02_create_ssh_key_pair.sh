#!/bin/bash

# 環境変数を再定義
eval "$(shdotenv)"

# ~/.ssh/ディレクトリにキーペアを作成。
aws ec2 create-key-pair \
  --key-name ${SSH_KEY_NAME} \
  --query "KeyMaterial" \
  --output text > ${HOME}/.ssh/${SSH_KEY_NAME}.pem \

# プライベートキーファイルの権限を変更。
chmod 400 ${HOME}/.ssh/${SSH_KEY_NAME}.pem
