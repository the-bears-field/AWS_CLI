#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 関数をインポート。
. /aws/shell_scripts/functions.sh

# RDSインスタンスのステータスを取得。
db_instance_state=`get_rds_instance_state`

if [ ${db_instance_state} = "available" ]; then
  echo "RDS2インスタンス(インスタンスID: ${DB_INSTANCE_ID})は起動済です。"
  return
fi

# EC2インスタンスが停止状態であれば、
# EC2インスタンスを起動するコマンドを実行。
if [ ${db_instance_state} = "stopped" ]; then
  $( \
    aws rds start-db-instance \
      --db-instance-identifier $DB_INSTANCE_ID \
  )
fi

echo "RDSインスタンス(DBインスタンスID: ${DB_INSTANCE_ID})を起動中です…"

while [ ${db_instance_state} != "available" ]
do
  sleep 2s
  db_instance_state=`get_rds_instance_state`
done

echo "RDSインスタンス(DBインスタンスID: ${DB_INSTANCE_ID})を起動しました。"
