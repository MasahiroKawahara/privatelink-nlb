module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.12.0"

  name = "target-vpc"
  cidr = "10.0.0.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true

  azs             = ["ap-northeast-1a"]
  private_subnets = ["10.0.0.0/26"]
}
