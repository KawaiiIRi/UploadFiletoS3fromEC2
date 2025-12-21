# UploadFiletoS3fromEC2
# 設計図
経路は整合: EC2→(RTでS3宛=GW VPCE)→S3、KMSは EC2→IF VPCE(KMS)、管理は SSM/EC2Messages/SSMMessages 経由。
改善すると良い点:
ルートテーブルと「S3 GW VPCE が紐づく RT（プライベートRT）」を明示する。
IGW/NAT無し(閉域環境)
EC2 SG: no inbound/all egress
VPCE SG: 443 from EC2 SG
運用意図(簡潔)：S3 バケットポリシーではSSE-KMS + 指定キー以外は Deny
IAM ロール／インスタンスプロファイルが EC2 に紐づく

<img width="579" height="306" alt="image" src="https://github.com/user-attachments/assets/601a8e19-3cac-4da7-8b95-42581894797a" />

# 環境の構築
本リポジトリ直下で、下記コマンドを一行ずつ実行し、正常に成功することを確認する。
terraform init
terraform validate
terraform plan
terraform apply -auto-approve


# 構築完了後の確認点
対象のEC2インスタンスが作成されており、IAMロールが「….-ec2-role」が作成されていること。
<img width="1986" height="872" alt="image" src="https://github.com/user-attachments/assets/787889e4-4b11-4684-8d9c-0cbd6cb31c9a" />

# 対象環境への接続
EC2インスタンス画面にて対象のインスタンスを選択⇒接続より、セッションマネージャータブから接続を実行する。
<img width="1986" height="865" alt="image" src="https://github.com/user-attachments/assets/783afca4-40ae-48c6-8534-b02a4d8018bf" />

ブラウザ上より対象環境へ接続出来ることを確認
<img width="1980" height="339" alt="image" src="https://github.com/user-attachments/assets/6e43c141-43ef-4a79-91bd-670b6edc1d45" />

実行コマンド

デフォルトでは環境内にawsコマンドはインストールされていないため、ローカル端末より下記コマンド例に従いAWS CLIv2を対象のインスタンス内にインスタンスする。
aws s3 cp "/Local-Directory/ec2-s3-sse-kms/scripts/AWSCLIV2.msi" s3://ec2-s3-kms-vpc-qelk53cd --dryrun --sse aws:kms --sse-kms-key-id arn:aws:kms:ap-northeast-1:<Account ID>:key/66452130-8967-4941-ab2c-3c38ce1747ae
⇒期待される実行結果：(dryrun) upload: scripts/AWSCLIV2.msi to s3://ec2-s3-kms-vpc-qelk53cd/AWSCLIV2.msi

上記期待通りの実行結果ならば、dryrunを外して実行する。下記メッセージを確認し、aws s3 lsなどで対象のS3バケット上にファイルが送信されていればOK
upload: scripts/AWSCLIV2.msi to s3://ec2-s3-kms-vpc-qelk53cd/AWSCLIV2.msi

➀ファイル作成
echo "" > C:\Users\Administrator\Desktop\install-awscli.ps1

➁変数定義
$scriptPath = 'C:\Users\Administrator\Desktop\install-awscli.ps1'

➂➀のファイルでps1スクリプト作成
@'
$uri  = 'https://ec2-s3-kms-vpc-qelk53cd.s3.ap-northeast-1.amazonaws.com/AWSCLIV2.msi?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=XXXXXXXXXXXXX%2F20251217%2Fap-northeast-1%2Fs3%2Faws4_request&X-Amz-Date=20251217T192937Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=f64ae4d7a9adae235f3a9a2a03a39d82d18dfa6596f6a90c7d73d1c0d4cb9962'
$dest = 'C:\Temp\AWSCLIV2.msi'
New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
Invoke-WebRequest -Uri $uri -OutFile $dest
Start-Process msiexec.exe -Wait -ArgumentList "/i $dest /qn"
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" --version
'@ | Set-Content -Path $scriptPath -Encoding UTF8

➃スクリプト実行
powershell -ExecutionPolicy Bypass -File $scriptPath
下記の結果を得られることを確認する。
aws-cli/2.15.42 Python/3.11.8 Windows/10 exec-env/EC2 exe/AMD64 prompt/off

これで環境内へのaws cliインストールは完了。

# セッションマネージャ接続したEC2内より対象のS3バケットへ対してファイルをアップロードする。
下記でdryrun実行する。
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" s3 cp --dryrun C:\Users\Administrator\Desktop\test.zip s3://ec2-s3-kms-vpc-qelk53cd/test.zip  --sse aws:kms --sse-kms-key-id arn:aws:kms:ap-northeast-1:<Account ID>:key/66452130-8967-4941-ab2c-3c38ce1747ae --region ap-northeast-1
下記実行結果ならばOK
(dryrun) upload: .\test.zip to s3://ec2-s3-kms-vpc-qelk53cd/test.zip

& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" s3 cp C:\Users\Administrator\Desktop\test.zip s3://ec2-s3-kms-vpc-qelk53cd/test.zip  --sse aws:kms --sse-kms -key-id arn:aws:kms:ap-northeast-1:<Account ID>:key/66452130-8967-4941-ab2c-3c38ce1747ae --region ap-northeast-1
下記実行を確認できればOK
upload: .\test.zip to s3://ec2-s3-kms-vpc-qelk53cd/test.zip

マネージャーコンソールでもS3バケット内の状況を確認する。
<img width="1986" height="774" alt="image" src="https://github.com/user-attachments/assets/73bea7fe-fc81-4c61-b863-7dd089a42840" />

・aws s3 cpの経路
➀ EC2 →（サブネットのルートテーブルで S3 宛先が Gateway VPCE に向く）→ Gateway VPCE（S3）→ S3 バケット
➁ KMS 利用は EC2 → Interface VPCE（KMS）→ KMS でデータキー生成/暗号化。S3 Put 時にそのデータキーを使った SSE-KMS が行われる

・ファイル視点でのaws s3 cp時の通信挙動
EC2 上の AWS CLI が KMS に暗号化用データキーをリクエスト（Interface VPCE 経由）
取得したデータキーでローカル側でオブジェクトを暗号化（SSE-KMS）しつつ、S3 への PUT を実行
S3 宛のトラフィックはルートテーブルにより Gateway VPCE（S3）へ送られ、そこから S3 バケットに到達
バケットポリシーが SSE-KMS と指定キーを強制し、条件を満たさなければ PUT は拒否される

# 実際に実行するコマンド
aws s3 cp <EC2内ディレクトリ> s3://<送信対象のS3バケット> --sse aws:kms --sse-kms-key-id <KMSのARN> --storage-class <保存先ストレージクラス> --region <対象とするS3バケットの存在するリージョン>

ストレージクラスは下記URLから確認
https://docs.aws.amazon.com/ja_jp/AmazonS3/latest/userguide/sc-howtoset.html



