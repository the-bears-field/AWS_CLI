# AWS CLI
AWSの勉学目的で作成したポートフォリオです。

## 使用技術
- Bash: version 5.0.3(1)-release (x86_64-pc-linux-gnu)
- Shell Script
- AWS CLI: version 2.5.6 Python/3.9.11 Linux/5.10.47-linuxkit exe/x86_64.debian.10 prompt/off

## 必要要件
- Docker

## インストール
必要要件に記載している環境を整えた上で、ターミナルで下記コマンドを実行して下さい。

1. 当該リポジトリを複製。
    ```
    git clone https://github.com/the-bears-field/aws_cli.git
    ```
2. ディレクトリ移動。
    ```
    cd aws_cli
    ```
3. envファイル作成。
    ```
    cp .env.example .env
    ```
4. 作成したenvファイルを編集し、アクセスキーIDとシークレットアクセスキーを定義する。
    ```
    # AWS CLI Options
    AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
    AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ```
5. コンテナ生成用のシェルスクリプト実行。
    ```
    sh create_container.sh
    ```
6. コンテナにログインした状態でAWS初期設定用のシェルスクリプトを実行。
    ```
    sh initialize_aws_cli_options.sh
    ```
