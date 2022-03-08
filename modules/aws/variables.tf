variable "lambdas_input_path" {
  description = "(Required) relative location of lambdas function folder from this file"
  default     = "../../composition/dev/lambdas/"
}

variable "lambdas_output_path" {
  description = "(Required) relative location of lambdas function output folder from this file"
  default     = "../../output/lambdas/"
}
variable "bucket_prefix" {  
  type        = string  
  description = "Name of the s3 bucket to be created."
  default = "bank_bucket_react_app"
} 
variable "region" {  
  type        = string  
  default     = "us-east-1"  
  description = "Name of the s3 bucket to be created."
}