module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.70.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags

  manage_default_security_group  = true
  default_security_group_ingress = [
    {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = "0.0.0.0/0"
    }
  ]
  default_security_group_egress  = [
    {
      description      = "All traffic outbound"
      from_port        = 0
      to_port          = 65535
      protocol         = "tcp"
      cidr_blocks      = "0.0.0.0/0"
    }
  ]
}



resource "aws_iam_role" "ec2codedeploy" {
  name = "ec2codedeploy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2codedeploy" {
  name = "ec2codedeploy"
  role = "${aws_iam_role.ec2codedeploy.name}"
}

resource "aws_iam_role_policy" "ec2codedeploy" {
  name = "ec2codedeploy"
  role = aws_iam_role.ec2codedeploy.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:ListBucket"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"

  name           = "cyera-ec2"
  instance_count = 1

  ami                    = "ami-07eb93de0d6b49e40"
  instance_type          = "t2.xlarge"
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  subnet_id              = module.vpc.public_subnets[0]
  key_name               = "dbogatyr"
  iam_instance_profile   = aws_iam_role.ec2codedeploy.name

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
