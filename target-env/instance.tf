# ---------------------------
# VPC Endpoints for using SSM Session Manager and yum access
# ---------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

  tags = {
    Name = "s3-endpoint"
  } 
}

module "vpce_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/https-443"
  version = "4.8.0"

  name        = "vpc-endpoint-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
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

# ---------------------------
# IAM Resources for an instance
# ---------------------------
resource "aws_iam_role" "ec2_role" {
  name_prefix = "target-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name_prefix = "target-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ---------------------------
# Security Group for an instance
# ---------------------------
module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "4.8.0"

  name        = "target-instance-sg"
  description = "Security group for Target Instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [local.dx_vpc_cidr]
}

# ---------------------------
# EC2 instance
# ---------------------------
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "3.4.0"

  name = "target-instance"

  ami                    = "ami-07b4f72c4c356c19d" # Amazon Linux 2
  instance_type          = "t3.nano"
  vpc_security_group_ids = [
    module.ec2_sg.security_group_id
  ]
  subnet_id            = element(module.vpc.private_subnets, 0)
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  user_data = <<EOF
#!/bin/bash -xe
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
EOF
}
