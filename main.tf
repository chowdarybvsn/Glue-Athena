variable "bucket_names" {
  type    = set(string)
  default = ["cbx-covid19-input", "cbx-covid19-output", "cbx-covid19-script"]
}

resource "aws_s3_bucket" "example" {
  for_each = toset(var.bucket_names)
  bucket   = each.value
}

resource "aws_s3_object" "example_object" {
  for_each = aws_s3_bucket.example

  bucket = aws_s3_bucket.example[element(keys(aws_s3_bucket.example), 0)].bucket
  key    = "glue-test.json"             # Specify the desired key for the uploaded file
  source = "my-artifact/glue-test.json" # Replace with the local path to your file
  acl    = "private"
}

# Create a Glue Data Catalog
resource "aws_glue_catalog_database" "example_database" {
  name = "example_database"
}

# Create a Glue Crawler
resource "aws_glue_crawler" "example_crawler" {
  name          = "example_crawler"
  database_name = aws_glue_catalog_database.example_database.name
  role          = "arn:aws:iam::631231558475:role/gluerole" # Replace with the ARN of your Glue service role
  s3_target {
    path = "${aws_s3_bucket.example[element(keys(aws_s3_bucket.example), 0)].bucket}/" # Replace with the path to your data in S3 s3://cbx-covid19-input/
  }
}