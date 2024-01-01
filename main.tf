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
  key    = "glue-test.json"                            # Specify the desired key for the uploaded file
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

# Run Glue Crawler using local-exec provisioner
resource "null_resource" "run_crawler" {
  provisioner "local-exec" {
    command = "aws glue start-crawler --name example_crawler"
  }
  depends_on = [aws_glue_crawler.example_crawler]
}

resource "time_sleep" "wait_for_crawler" {
  depends_on      = [null_resource.run_crawler]
  create_duration = "2m"
}

# # Data source to fetch information about the table created by the Glue crawler
# data "aws_glue_catalog_table" "example_table" {
#   database_name = aws_glue_catalog_database.example_database.name
#   name          = aws_glue_crawler.example_crawler.name
# }

# Use the obtained table name in subsequent resources
resource "aws_athena_named_query" "example_named_query" {
  name        = "example_named_query"
  database    = aws_glue_catalog_database.example_database.name
  query       = "SELECT * FROM cbx_covid19_input"
  description = "Example Athena Named Query"
  workgroup   = "primary"
}

# Run Athena Query using local-exec provisioner
resource "null_resource" "run_athena_query" {
  provisioner "local-exec" {
    command = <<EOT
      aws athena start-query-execution --query-string "SELECT * FROM cbx_covid19_input" --result-configuration OutputLocation=s3://cbx-covid19-output/query_results/
    EOT
    #working_dir = path.module  # Set the working directory to the location of your Terraform script
  }
  depends_on = [aws_athena_named_query.example_named_query]
}
