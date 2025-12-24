terraform {
  backend "s3" {
    bucket = "atlantis-tfstate-bytetrove"
    key    = "atlantis-deployment/terraform.tfstate"
    region = "us-west-2"

    # Optional: Enable encryption and versioning
    encrypt        = true
    dynamodb_table = "terraformLock"
  }
}