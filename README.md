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

<img width="1397" height="788" alt="picture" src="https://github.com/user-attachments/assets/b4c42d32-32a3-4cda-b193-8e8f4eccc902" />
