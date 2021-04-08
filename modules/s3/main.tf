variable "service_name" {}
locals {
  name_list = ["${var.service_name}-ww9-image", "${var.service_name}-www-image"]
}

# img_bucket
resource "aws_s3_bucket" "images" {
  count  = length(local.name_list)
  bucket = local.name_list[count.index]
  acl    = "private"
}
resource "aws_s3_bucket_public_access_block" "acls" {
  count  = length(aws_s3_bucket.images)
  bucket = aws_s3_bucket.images[count.index].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}