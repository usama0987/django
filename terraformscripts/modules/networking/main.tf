
data "aws_vpc" "default" {
  id = "vpc-07e4dc87f8b69913c"
}

data "aws_route_table" "main" {
  vpc_id = data.aws_vpc.default.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

locals {
  public_subnet_ids = [
    "subnet-05d597fbdd1614161",
    "subnet-0483c2456c0c2111b",
    "subnet-02b584c3dd6215fc3",
    "subnet-0659d8fe8512a8bb4"
  ]
}

# VPC Endpoint for DynamoDB
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id             = data.aws_vpc.default.id
  service_name       = "com.amazonaws.us-west-2.dynamodb"
  vpc_endpoint_type  = "Gateway"
  route_table_ids    = [data.aws_route_table.main.id]

  tags = {
    Name = "dynamodb-endpoint"
  }
}

# VPC Endpoint for SNS
resource "aws_vpc_endpoint" "sns" {
  vpc_id             = data.aws_vpc.default.id
  service_name       = "com.amazonaws.us-west-2.sns"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = local.public_subnet_ids
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "vpc-endpoints-sg"
  }
}

output "vpc_id" {
  value = data.aws_vpc.default.id
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}
