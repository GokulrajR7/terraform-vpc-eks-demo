
provider "aws"{
region="ap-south-1"
}

#VPC

resource "aws_vpc" "main"{
cidr_block="10.0.0.0/16"

enable_dns_support=true
enable_dns_hostnames=true
}

#SUBNETS 

#SUBNET1

resource "aws_subnet" "subnet1"{
vpc_id=aws_vpc.main.id
cidr_block="10.0.1.0/24"
availability_zone="ap-south-1a"
}

#SUBNET2

resource "aws_subnet" "subnet2"{
vpc_id=aws_vpc.main.id
cidr_block="10.0.2.0/24"
availability_zone="ap-south-1b"
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
aws_subnet.subnet1.id,
aws_subnet.subnet2.id
]
}

depends_on = [
  aws_iam_role_policy_attachment.eks_cluster_policy,
  aws_iam_role_policy_attachment.eks_service_policy
]

}

