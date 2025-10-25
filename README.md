# 🚀 Terraform AWS EKS Application

![Terraform](https://img.shields.io/badge/Terraform-AWS%20EKS-brightgreen)
![GitHub](https://img.shields.io/badge/GitHub-terraform--aws--eks--application-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

Welcome to the **Terraform AWS EKS Application** repository! This project provides a complete solution for deploying a Kubernetes infrastructure on AWS using Terraform. It includes an ALB ingress controller and a sample application deployment, making it easier to get started with Kubernetes on AWS.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Getting Started](#getting-started)
- [Deployment](#deployment)
- [Usage](#usage)
- [Sample Application](#sample-application)
- [Contributing](#contributing)
- [License](#license)
- [Links](#links)

## Overview

This repository helps you set up a robust Kubernetes environment on AWS Elastic Kubernetes Service (EKS) using Infrastructure as Code (IaC) principles. By using Terraform, you can manage your infrastructure with version control, making it easier to maintain and scale.

The project includes:

- Configuration for AWS EKS
- Setup for the ALB ingress controller
- Sample application deployment to demonstrate functionality

## Features

- **Infrastructure as Code**: Define your infrastructure using Terraform.
- **Scalable Architecture**: Easily scale your application based on demand.
- **ALB Ingress Controller**: Manage traffic routing to your services.
- **Sample Application**: A simple application to test your setup.
- **Modular Design**: Easily extend or modify the setup as needed.

## Getting Started

To get started with this project, follow these steps:

1. **Clone the repository**:

   ```bash
   git clone https://github.com/Nekit666/terraform-aws-eks-application.git
   cd terraform-aws-eks-application
   ```

2. **Install Terraform**: Make sure you have Terraform installed. You can download it from the [official Terraform website](https://www.terraform.io/downloads.html).

3. **Configure AWS Credentials**: Ensure your AWS credentials are set up. You can do this by creating a `~/.aws/credentials` file or by using environment variables.

4. **Initialize Terraform**: Run the following command to initialize the Terraform configuration:

   ```bash
   terraform init
   ```

5. **Plan your deployment**: Before applying the configuration, review what will be created:

   ```bash
   terraform plan
   ```

6. **Apply the configuration**: Deploy the infrastructure with:

   ```bash
   terraform apply
   ```

   Review the changes and type `yes` to confirm.

## Deployment

Once the infrastructure is set up, you can deploy your application. The sample application is included in this repository. Follow these steps to deploy it:

1. **Configure your application**: Edit the `sample-app.yaml` file to set any necessary environment variables or configurations.

2. **Deploy the application**: Use `kubectl` to apply the configuration:

   ```bash
   kubectl apply -f sample-app.yaml
   ```

3. **Check the status**: Verify that the application is running:

   ```bash
   kubectl get pods
   ```

4. **Access the application**: After deployment, access the application using the ALB URL. You can find this URL in the AWS console under the EC2 section, or you can set up a custom domain.

## Usage

This repository is designed for developers looking to deploy applications on AWS EKS. It provides a starting point for building more complex applications and infrastructures. You can modify the Terraform files to suit your needs.

### Example Configuration

Here’s a brief example of what the Terraform configuration looks like:

```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_eks_cluster" "my_cluster" {
  name     = "my-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.my_subnet.*.id
  }
}
```

This snippet sets up an EKS cluster in the specified region. You can add more resources as needed.

## Sample Application

The sample application included in this repository is a simple web app. It serves as a demonstration of how to deploy an application on EKS. You can modify it to fit your requirements.

### Application Features

- **Basic CRUD operations**: The application supports Create, Read, Update, and Delete operations.
- **Dockerized**: The application runs in a Docker container, making it easy to deploy and manage.
- **Lightweight**: Designed to be simple and efficient, suitable for testing and learning.

### Running the Sample Application

1. Build the Docker image:

   ```bash
   docker build -t my-sample-app .
   ```

2. Push the image to your container registry:

   ```bash
   docker push my-sample-app
   ```

3. Update the deployment YAML file to use the new image.

4. Redeploy the application using `kubectl`.

## Contributing

We welcome contributions to this project! If you would like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them.
4. Push your branch to your forked repository.
5. Create a pull request.

Please ensure your code adheres to the project's coding standards and includes appropriate tests.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Links

For releases, visit the [Releases section](https://github.com/Nekit666/terraform-aws-eks-application/releases). Download the necessary files and execute them to get started.

For further updates and features, keep an eye on the [Releases section](https://github.com/Nekit666/terraform-aws-eks-application/releases).

---

Thank you for checking out the **Terraform AWS EKS Application** repository! We hope this project helps you deploy your applications on AWS with ease. If you have any questions or need support, feel free to reach out. Happy coding!