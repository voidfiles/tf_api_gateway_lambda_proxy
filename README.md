# A module that creates an API Gateway Proxy to your VPC.

## Call me like this:

```hcl
module "lambda_proxy" {
  source             = "github.com/voidfiles/tv_api_gateway_lambda_proxy"
  region             = "${var.region}"
  name               = "proxy"
}

output "invoke_url" {
  value = "${module.lambda_proxy.invoke_url}"
}
```
