#!/bin/bash

# 環境変数を再定義。
eval "$(shdotenv)"

# 関数をインポート。
. /aws/shell_scripts/functions.sh

# RDSインスタンスのステータスを取得。
db_instance_state=`get_rds_instance_state`

# EC2インスタンスが停止中または停止していれば終了。
if [ ${db_instance_state} = "stopped" ]; then
  echo "RDS2インスタンス(インスタンスID: ${DB_INSTANCE_ID})は停止済です。"
  return
fi

# EC2インスタンスが稼働中であれば、EC2インスタンスを停止するコマンドを実行。
if [ ${db_instance_state} = "available" ]; then
  $( \
    aws rds stop-db-instance \
      --db-instance-identifier $DB_INSTANCE_ID \
  )
fi

echo "RDSインスタンス(DBインスタンスID: ${DB_INSTANCE_ID})を停止中です…"

while [ ${db_instance_state} != "stopped" ]
do
  sleep 2s
  db_instance_state=`get_rds_instance_state`
done

echo "RDSインスタンス(DBインスタンスID: ${DB_INSTANCE_ID})を停止しました。"
