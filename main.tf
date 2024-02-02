provider "aws" {
    region = "us-east-1"
}

#--------------------------------STATE FILE------------------------------------------
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket-portfolio"
    key    = "backend/terraform.tfstate"
    region = "us-east-1"
  }
}

#---------------------------------LAMBDA-----------------------------------------------

# IAM Trust Policy Document for Lambda
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Create IAM Role with Trust Relationship for Lambda
resource "aws_iam_role" "dynamo_full_access_2" {
  name               = "DynamoFullAccess2"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# Attach AmazonDynamoDBFullAccess Managed Policy to the Role
resource "aws_iam_role_policy_attachment" "dynamodb_full_access_attachment" {
  role       = aws_iam_role.dynamo_full_access_2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}



resource "aws_lambda_function" "update_visits" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "lambda_update_visits.zip"
  function_name = "update_visits2"
  role          = aws_iam_role.dynamo_full_access_2.arn
  handler       = "lambda_update_visits.lambda_handler"
  runtime = "python3.12"

  environment {
    variables = {
      foo = "bar"
    }
  }
}


#----------------------------------API GATEWAY------------------------------------------

resource "aws_api_gateway_rest_api" "MyPortfolioAPI" {
  name        = "humza-resume-api2"
  description = "This is a sample API"
}

resource "aws_api_gateway_method" "MyPortfolioMethod" {
  rest_api_id   = aws_api_gateway_rest_api.MyPortfolioAPI.id
  resource_id   = aws_api_gateway_rest_api.MyPortfolioAPI.root_resource_id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "MyPortfolioIntegration" {
  rest_api_id = aws_api_gateway_rest_api.MyPortfolioAPI.id
  resource_id = aws_api_gateway_rest_api.MyPortfolioAPI.root_resource_id
  http_method = aws_api_gateway_method.MyPortfolioMethod.http_method

  type                    = "AWS_PROXY"
  integration_http_method = "PUT"
  uri                     = aws_lambda_function.update_visits.arn # Replace with your actual backend URI, if applicable
}

resource "aws_api_gateway_deployment" "my_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.MyPortfolioIntegration
  ]
  
  rest_api_id = aws_api_gateway_rest_api.MyPortfolioAPI.id
  
  # A unique string that changes on each redeployment
  stage_name  = "v1"
  
  # Optionally, include a description and/or stage description
  description = "Deployment for the MyPortfolioAPI"
  
  # Triggers redeployment when the Swagger file or a method changes
  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.MyPortfolioAPI.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------DynamoDB---------------------------------------------
resource "aws_dynamodb_table" "db_visit_count" {
  name           = "db_visit_count2"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "ref_id"

  attribute {
    name = "ref_id"
    type = "N"
  }
}

resource "aws_dynamodb_table_item" "add_visit_entry" {
  table_name = aws_dynamodb_table.db_visit_count.name
  hash_key   = aws_dynamodb_table.db_visit_count.hash_key

  item = <<ITEM
{
  "ref_id": {"N": "100"},
  "visits": {"N": "0"}
}
ITEM
}