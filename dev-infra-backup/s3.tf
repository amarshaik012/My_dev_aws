resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "amar-devops-artifacts-123456"  # Use a globally unique name
  force_destroy = true

  tags = {
    Name = "artifact-bucket"
  }
}
