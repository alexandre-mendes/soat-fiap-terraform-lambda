data "aws_vpc" "vpc" {
  cidr_block = "172.31.0.0/16"
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
}

data "aws_subnet" "subnet" {
  for_each = toset(data.aws_subnets.subnets.ids)
  id       = each.value
}

data "aws_security_group" "vpc_link_sg" {
  name   = "SG-${var.project_name}"
  vpc_id = ""
}

data "aws_lb" "fastfood_nlb" {
  name = "a028e502d142b426f8e7fc456db8143d"
}

data "aws_lb_listener" "fastfood_nlb_listener" {
  load_balancer_arn = data.aws_lb.fastfood_nlb.arn
  port              = 80
}

