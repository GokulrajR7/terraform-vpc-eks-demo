
provider "aws"{
region="ap-south-1"
}


# -------------------------------
# Terraform Backend (S3 + DynamoDB)
# -------------------------------
terraform {
  backend "s3" {
    bucket         = "terraform-vpc-eks-statefile-bucket-gokul" # must be globally unique
    key            = "eks/terraform.tfstate"
    region         = "ap-south-1"
    use_lockfile   = true
    encrypt        = true
  }
}




# DynamoDB Table for Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Locks"
  }
}


#VPC

resource "aws_vpc" "main"{
cidr_block="10.0.0.0/16"

enable_dns_support=true
enable_dns_hostnames=true
tags={
  Name="main-vpc"}
}

#SUBNETS 

#SUBNET1

resource "aws_subnet" "public"{
vpc_id=aws_vpc.main.id
cidr_block="10.0.1.0/24"
availability_zone="ap-south-1a"
map_public_ip_on_launch=true
tags={ Name="public-subnet"}

}

#SUBNET2

resource "aws_subnet" "private"{
vpc_id=aws_vpc.main.id
cidr_block="10.0.2.0/24"
availability_zone="ap-south-1b"
tags={Name="private-subnet"}

}

# Internet Gateway

resource "aws_internet_gateway" "igw"{
  vpc_id=aws_vpc.main.id
  tags={Name="main-igw"}
}


# Nat Gateway

resource "aws_eip" "nat_eip"{
  tags={ Name="nat-eip"}
}

resource "aws_nat_gateway" "nat"{
  allocation_id=aws_eip.nat_eip.id
  subnet_id=aws_subnet.public.id
  tags={ Name="main-nat"}
}


# Route Tables

resource "aws_route_table" "public_rt"{
  vpc_id=aws_vpc.main.id
  route{
    cidr_block="0.0.0.0/0"
    gateway_id=aws_internet_gateway.igw.id
  }
  tags={ Name="public-rt"}
}

resource "aws_route_table_association" "public_assoc"{
  subnet_id=aws_subnet.public.id
  route_table_id=aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt"{
  vpc_id=aws_vpc.main.id
  route{
    cidr_block="0.0.0.0/0"
    nat_gateway_id=aws_nat_gateway.nat.id
  }
  tags={ Name="private-rt" }
}


resource "aws_route_table_association" "private_assoc"{
  subnet_id=aws_subnet.private.id
  route_table_id=aws_route_table.private_rt.id
}


#IAM ROLE FOR EKS

resource "aws_iam_role" "eks_cluster_role"{
name="eks-cluster-role"

assume_role_policy=jsonencode({
Version="2012-10-17"
Statement=[{
Effect="Allow"
Principal={
Service="eks.amazonaws.com"
}
Action="sts:AssumeRole"
}]
})
}

#attach Cluster policy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy"{
role=aws_iam_role.eks_cluster_role.name
policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach EKS Service Policy
resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}


#EKS Cluster Wihtout nodes

resource "aws_eks_cluster" "eks"{
name="test-cluster-no-nodes"
role_arn=aws_iam_role.eks_cluster_role.arn

vpc_config{
subnet_ids=[
aws_subnet.private.id,
aws_subnet.public.id
]
}

depends_on = [
  aws_iam_role_policy_attachment.eks_cluster_policy,
  aws_iam_role_policy_attachment.eks_service_policy
]

}

