variable "name" {
  description = "This can be defined when calling module so you can avoid creating duplicates if you want to call the module multiple times"
  default     = "microservice_api"
}

variable "region" {
  description = "The aws region"
}

variable "lambda_path" {
  description = "Path to bundled lambda"
  default     = ""
}

variable "handler" {
  default = "simple.handler"
}

variable "runtime" {
  default = "python3.6"
}

variable "timeout" {
  default = 10
}
