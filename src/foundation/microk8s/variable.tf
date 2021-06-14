variable "aws_region" {
  description = "aws_region"
  default     = "us-east-2"
}

variable "aws_instance" {
  description = "instance_type"
  default     = "t2.small"
}

variable "aws_ami" {
  description = "aws_ami"
  default     = "ami-026141f3d5c6d2d0c"
}

variable "aws_subnet_id" {
  description = "subnet_id"
  default     = "<insertsubnetID>"
}

variable "vpc_id" {
  description = "vpc_id"
  default     = "<insertVpcID>"
}

variable "access_key" {
  description = "access_key"
  default     = "<insertAccessKey>"
}

variable "secret_key" {
  description = "secret_key"
  default     = "<insertSecretKey>"
}

