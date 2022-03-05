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

module "ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "4.8.0"

  name        = "target-instance-sg"
  description = "Security group for Target Instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [local.dx_vpc_cidr]
}

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
