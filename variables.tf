variable "region" {
  type    = string
  default = "ap-northeast-1"
}

# 付与するタグ名
variable "project" {
  type    = string
  default = "ec2-s3-kms-vpc"
}

# VPC CIDR（検証用に最小構成：public subnet1つ）
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.10.10.0/24"
}

# RDPを開けたい場合のみtrue（基本はSSM推奨）
variable "enable_rdp" {
  type    = bool
  default = false
}

# subnetをprivate化するので削除？
# enable_rdp=trueの時だけ使う
variable "allowed_rdp_cidr" {
  type        = string
  default     = "0.0.0.0/32"
  description = "例: 203.0.113.10/32（enable_rdp=true のときのみ有効）"
}

# インスタンスタイプ
variable "instance_type" {
  type    = string
  default = "t3.medium"
}
