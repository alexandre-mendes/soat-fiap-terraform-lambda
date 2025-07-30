variable "jwt_secret" {
  type        = string
  description = "JWT secret used to sign tokens"
  default     = "T8xXUW3GFo6gyUpzP5Mn0PkdrVXugBnQ"
}

variable "clients_table_name" {
  type        = string
  description = "Name of the DynamoDB table for clients"
  default     = "clientes"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "soat-cluster"
}
