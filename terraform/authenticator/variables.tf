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

variable "existing_lambda_role_arn" {
  type        = string
  description = "ARN da role já existente com permissões para DynamoDB e execução de Lambda"
  default     = "arn:aws:iam::590422439565:role/LabRole"
}
