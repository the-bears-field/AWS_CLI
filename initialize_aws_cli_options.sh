#!/bin/bash

# ~/.awsディレクトリ作成
if [ ! -d ~/.aws ]; then
    mkdir ~/.aws
fi

# credentialsファイル作成
cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id = $AWS_ACCESS_KEY_ID
aws_secret_access_key = $AWS_SECRET_ACCESS_KEY
EOF

# configファイル作成
cat <<EOF > ~/.aws/config
[default]
region = $REGION
output = $OUTPUT
EOF

# 生成したファイルの権限変更
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
