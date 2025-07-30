data "aws_vpc" "vpc" {
  id = "vpc-064f34389d4223b02"
}

data "aws_subnets" "subnets" {
  filter {
    name  = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(data.aws_subnets.subnets.ids)
  id       = each.value
}

data "aws_security_group" "vpc_link_sg" {
  name  = "SG-${var.project_name}"
  vpc_id = data.aws_vpc.vpc.id
}

data "kubernetes_service" "customer_ms_service" {
  metadata {
    name      = "soat-fiap-costumer-application-ms"
    namespace = "default"
  }
}

data "kubernetes_service" "order_ms_service" {
  metadata {
    name      = "soat-fiap-order-application-ms"
    namespace = "default"
  }
}

data "kubernetes_service" "product_ms_service" {
  metadata {
    name      = "soat-fiap-product-application-ms"
    namespace = "default"
  }
}