## Simple Microservice
## Author: Alex Kessinger
## Author: Seth Rutner

###API global configuration###

#Grabs your account number as a variable, needed for lambda permissions
data "aws_caller_identity" "current" {}

##LAMBDA CONFIG##

#Create up our Lambda function to proxy requests to our VPC
resource "aws_lambda_function" "lambda" {
  filename         = "${var.lambda_path == "" ? format("%s/%s", path.module, "proxy_api.zip") : var.lambda_path}"
  function_name    = "api_${var.name}"
  role             = "${aws_iam_role.lambda_role.arn}"
  handler          = "${var.handler}"
  runtime          = "${var.runtime}"
  source_code_hash = "${base64sha256(file("${var.lambda_path == "" ? format("%s/%s", path.module, "proxy_api.zip") : var.lambda_path}"))}"
  timeout          = "10"
}

#The role assigned to the lambda function.
#Inline policy allows lambda to assume this role.

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role_${var.name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "default"
  role = "${aws_iam_role.lambda_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

#Initialize the REST API
resource "aws_api_gateway_rest_api" "api_gw" {
  name        = "${var.name}_api"
  description = "API Gateway to talk to microservices"
}

#Set up proxy resource path
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gw.id}"
  parent_id   = "${aws_api_gateway_rest_api.api_gw.root_resource_id}"
  path_part   = "{proxy+}"
}

##########POST TO A MICROSERVICE FLOW##############

#Method to for ANY on the proxy resource
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.api_gw.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "ANY"
  authorization = "NONE"
}

#Integration to invoke lambda proxy
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id             = "${aws_api_gateway_rest_api.api_gw.id}"
  resource_id             = "${aws_api_gateway_resource.proxy.id}"
  http_method             = "${aws_api_gateway_method.proxy.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
}

#The method response after receiving the 200 passed up through lambda from the service
resource "aws_api_gateway_method_response" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gw.id}"
  resource_id = "${aws_api_gateway_resource.proxy.id}"
  http_method = "${aws_api_gateway_method.proxy.http_method}"
  status_code = "200"
}

#Give lambda a 'trigger' permission to allow this API endpoint to invoke it
resource "aws_lambda_permission" "apigw_lambda_proxy" {
  statement_id  = "AllowExecutionFromAPIGatewayPost"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api_gw.id}/*/*/*"
}

## Deploy

# Deployment for API
resource "aws_api_gateway_deployment" "v1" {
  depends_on  = ["aws_api_gateway_method.proxy", "aws_api_gateway_integration.proxy"]
  rest_api_id = "${aws_api_gateway_rest_api.api_gw.id}"
  stage_name  = "v1"
}
