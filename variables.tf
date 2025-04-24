variable "key_name" {
  description = "Name of the AWS Key Pair"
  type  = string
}

variable "aws_access_key" {
  type  = string
}

variable "aws_secret_key" {
  type  = string
}

variable "region" {
  type  = string
}

variable "ssh_public_key" {
  description = "SSH public key for authentication"
  type        = string
}