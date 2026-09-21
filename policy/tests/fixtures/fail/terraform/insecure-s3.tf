resource "aws_s3_bucket" "insecure_test" {
  bucket = "policy-test-insecure-bucket"
}

resource "aws_s3_bucket_public_access_block" "insecure_test" {
  bucket = aws_s3_bucket.insecure_test.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
