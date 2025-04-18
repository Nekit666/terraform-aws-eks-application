# AWS EKS Infrastructure Project

[![Release](https://img.shields.io/github/v/release/bharats487/aws-ek-app-without-domain)](https://github.com/bharats487/aws-ek-app-without-domain/releases)
[![License](https://img.shields.io/github/license/bharats487/aws-ek-app-without-domain?color=blue)](LICENSE)
[![AWS](https://img.shields.io/badge/AWS-EKS-orange)](https://aws.amazon.com/eks/)
[![Terraform](https://img.shields.io/badge/Terraform-1.2+-blueviolet)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28-blue)](https://kubernetes.io/)

This project contains Infrastructure as Code (IaC) for deploying a Kubernetes cluster on AWS using Amazon EKS (Elastic Kubernetes Service).

**GitHub Repository**: [aws-ek-app-without-domain](https://github.com/bharats487/aws-ek-app-without-domain)

## Architecture Overview

The infrastructure includes:

- Amazon EKS Cluster (v1.28)
- Managed Node Groups with t3.medium instances
- AWS Load Balancer Controller for ingress
- VPC with public and private subnets
- Security groups for cluster and node access
- IAM roles and policies with least privilege access

## Project Structure

```
.
├── terraform/               # Terraform configuration files
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output definitions
│   ├── existing-vpc.tfvars  # Variable values for existing VPC config
│   ├── eks-cluster/         # EKS cluster module
│   └── cicd/                # CI/CD pipeline configuration (optional)
├── application/             # Application source code
│   ├── k8s/                 # Kubernetes manifests
│   │   ├── deployment.yaml  # Deployment configurations
│   │   ├── service.yaml     # Service configurations
│   │   ├── ingress.yaml     # Ingress configurations
│   │   └── lb-manifest.yaml # Load balancer configurations
│   ├── frontend/            # Frontend application code
│   ├── backend/             # Backend application code
│   ├── buildspec.yml        # AWS CodeBuild specification
│   └── Dockerfile           # Dockerfile for container build
└── README.md                # This file
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform v1.2.0 or newer
- kubectl installed (for Kubernetes interaction)
- AWS IAM permissions to create required resources

## Deployment Instructions

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Configure Variables

Modify `existing-vpc.tfvars` or create your own `.tfvars` file to customize your deployment.

### 3. Plan the Deployment

```bash
terraform plan -var-file=existing-vpc.tfvars
```

### 4. Apply the Configuration

```bash
terraform apply -var-file=existing-vpc.tfvars
```

### 5. Configure kubectl

After the cluster is created, configure kubectl to connect to your cluster:

```bash
aws eks update-kubeconfig --name justeasylearn-eks-cluster --region us-east-1
```

### 6. Deploy the Application

Apply the Kubernetes manifests to deploy the application:

```bash
kubectl apply -f ../application/k8s/
```

## Accessing the Application

Once deployed, the application can be accessed through the ALB (Application Load Balancer) endpoint that's created by the AWS Load Balancer Controller.

You can get the endpoint using:

```bash
kubectl get ingress -n default
```

## Infrastructure Components

### EKS Cluster

- Kubernetes v1.28
- Private endpoint access for security
- KMS encryption for secrets

### Node Groups

- General purpose node group with t3.medium instances
- Autoscaling enabled (min: 1, max: 3, desired: 2)
- Using Amazon Linux 2 (AL2_x86_64)

### Networking

- Using existing VPC with provided subnet IDs
- Private subnets for worker nodes
- Security groups configured for least privilege access

### Add-ons

- CoreDNS for DNS resolution
- kube-proxy for network proxying
- vpc-cni for pod networking
- AWS Load Balancer Controller for ingress

## Application Architecture

The application consists of:

- Frontend: A web interface built with NGINX
- Backend: A Node.js API server
- Ingress: AWS ALB for routing traffic to services

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy -var-file=existing-vpc.tfvars
```

## Security Considerations

- Cluster endpoint is private for enhanced security
- IAM roles follow least privilege principle
- Secrets are encrypted with KMS
- Network security groups restrict traffic flow

## Troubleshooting

- If nodes fail to join the cluster, check the VPC subnets and security group configurations
- For Load Balancer issues, check the ALB Controller logs in the kube-system namespace
- For authorization issues, verify IAM roles and aws-auth ConfigMap configuration 

## Keywords

aws, eks, kubernetes, terraform, infrastructure-as-code, devops, alb, containers, aws-load-balancer, k8s, iac, aws-eks, eks-cluster, terraform-aws-modules, aws-application-load-balancer, aws-alb-controller, eks-managed-node-group, kubernetes-deployment, aws-vpc, aws-security-groups, aws-iam-roles, aws-kms 