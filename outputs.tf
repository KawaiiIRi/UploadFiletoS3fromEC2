output "region" {
  value = var.region
}

output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_id" {
  value = aws_subnet.private.id
}

output "instance_id" {
  value = aws_instance.win.id
}

output "instance_private_ip" {
  value = aws_instance.win.private_ip
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}

output "kms_key_arn" {
  value = aws_kms_key.s3.arn
}
