variable "aws-region" {
  type        = string
  description = "AWS Region"
  default     = "sa-east-1"
}

terraform {
  backend "s3" {
    bucket  = "tfstate-6soat"
    key     = "terraform-redis/terraform.tfstate"
    region  = "sa-east-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws-region
}

resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name       = "redis-subnet-group"
  subnet_ids = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]

  tags = {
    Name = "Redis Subnet Group"
  }
}

resource "aws_elasticache_replication_group" "redis_replication_group" {
  replication_group_id          = "my-redis-replication-group"
  description                   = "Redis Replication Group"
  engine                        = "redis"
  engine_version                = "7.0"
  node_type                     = "cache.t3.micro"
  num_cache_clusters            = 2
  automatic_failover_enabled    = true
  multi_az_enabled              = true
  preferred_cache_cluster_azs   = ["sa-east-1a", "sa-east-1b"]
  parameter_group_name          = "default.redis7"
  subnet_group_name             = aws_elasticache_subnet_group.redis_subnet_group.id
  security_group_ids            = [aws_security_group.redis_sg.id]

  tags = {
    Name = "Redis Replication Group"
  }
}

resource "aws_security_group" "redis_sg" {
  name        = "redis-sg"
  description = "Allow Redis access"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.redis_replication_group.primary_endpoint_address
}

output "redis_port" {
  value = aws_elasticache_replication_group.redis_replication_group.port
}

