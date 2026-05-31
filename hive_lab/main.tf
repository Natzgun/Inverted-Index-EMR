provider "aws" {
  region = "us-east-1"
}

# 1. VPC y Subred (Red Pública)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true # Obligatorio para EMR
  tags = {
    Name = "vpc-bigdeita"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "subnet-public-bigdeita"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# 2. S3 Bucket y Carpetas

# 3. Security Group (Acceso SSH)
resource "aws_security_group" "emr_ssh" {
  name        = "emr_ssh_allow"
  description = "Permitir trafico SSH al nodo maestro"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
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

# 4. Clúster AWS EMR (Hadoop Core)
resource "aws_emr_cluster" "cluster" {
  name          = "emr-cluster-bigdeita"
  release_label = "emr-7.13.0"
  applications  = ["Hadoop", "Hive", "Tez", "Hue", "Pig"]

  termination_protection            = false
  keep_job_flow_alive_when_no_steps = true

  ec2_attributes {
    subnet_id                         = aws_subnet.public.id
    key_name                          = "deitakey"
    instance_profile                  = "EMR_EC2_DefaultRole"
    additional_master_security_groups = aws_security_group.emr_ssh.id
  }

  # Configuración optimizada de hardware (max 20GB de datos) para no gastar créditos
  master_instance_group {
    instance_type  = "r8g.xlarge" 
    instance_count = 1
  }

  core_instance_group {
    instance_type  = "r8g.xlarge"
    instance_count = 3
  }

  service_role = "EMR_DefaultRole"
  log_uri      = "s3://hdfs-emr-bigdeita/logs/"
}

# 5. Outputs
output "emr_master_public_dns" {
  description = "DNS publico para conectarte por SSH"
  value       = aws_emr_cluster.cluster.master_public_dns
}
