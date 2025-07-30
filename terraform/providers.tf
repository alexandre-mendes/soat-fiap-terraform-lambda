
provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.soat_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.soat_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.soat_cluster.token
}


data "aws_eks_cluster" "soat_cluster" {
  name = var.project_name
}

data "aws_eks_cluster_auth" "soat_cluster" {
  name = var.project_name
}