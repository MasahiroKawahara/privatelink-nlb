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

module "vpce_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "4.8.0"

  name        = "vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

  tags = {
    Name = "s3-endpoint"
  } 
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    module.vpce_sg.security_group_id
  ]
  subnet_ids = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name = "ssm-endpoint"
  } 
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type = "Interface"
 
  security_group_ids = [
    module.vpce_sg.security_group_id
  ]
  subnet_ids = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name = "ec2messages-endpoint"
  } 
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type = "Interface"
 
  security_group_ids = [
    module.vpce_sg.security_group_id
  ]
  subnet_ids = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name = "ssmmessages-endpoint"
  } 
}
