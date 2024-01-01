terraform {
  backend "s3" {
    bucket         = "terraform-project-1-2023"
    key            = "Glue/backend.tfstate"
    region         = "us-east-1"
    dynamodb_table = "Glue"
  }
}
