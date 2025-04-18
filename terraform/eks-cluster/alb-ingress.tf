provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# IAM Policy for ALB Controller Service Account
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.project_name}-${var.cluster_name}-alb-controller-policy"
  description = "Policy for AWS Load Balancer Controller"

  # Policy document (you can find the latest recommended policy from AWS docs)
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:CreateServiceLinkedRole",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeInstances",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeTags",
          "ec2:GetCoipPoolUsage",
          "ec2:DescribeCoipPools",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerCertificates",
          "elasticloadbalancing:DescribeSSLPolicies",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "iam:ListServerCertificates",
          "iam:GetServerCertificate",
          "waf-regional:GetWebACLForResource",
          "waf-regional:GetWebACL",
          "waf-regional:AssociateWebACL",
          "waf-regional:DisassociateWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:GetWebACL",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:DescribeProtection",
          "shield:GetSubscriptionState",
          "shield:DeleteProtection",
          "shield:CreateProtection",
          "shield:DescribeSubscription",
          "shield:ListProtections"
        ],
        Resource = "*"
      },
      # Modify resources based on ALB actions
      {
        Effect = "Allow",
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface"
        ],
        Condition = {
          StringEquals = {
            "ec2:Subnet" = formatlist("arn:aws:ec2:%s:%s:subnet/%s", var.aws_region, data.aws_caller_identity.current.account_id, var.public_subnets[*]) # Use public subnets
            # "ec2:Subnet" = formatlist("arn:aws:ec2:%s:%s:subnet/%s", var.aws_region, data.aws_caller_identity.current.account_id, var.private_subnets[*]) # Or private if needed
          }
        },
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:network-interface/*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DeleteNetworkInterface",
          "ec2:ModifyNetworkInterfaceAttribute"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:AddListenerCertificates",
          "elasticloadbalancing:RemoveListenerCertificates"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:CreateTargetGroup",
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:DeleteRule",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:ModifyRule",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:SetWebAcl",
            "elasticloadbalancing:RemoveTags",
            "elasticloadbalancing:DeleteTargetGroup"
        ],
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# Service Account for ALB Controller
module "alb_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.30"

  role_name                              = "${var.project_name}-alb-controller"
  attach_load_balancer_controller_policy = false # We attach our custom policy

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"] # Namespace:ServiceAccount
    }
  }

  role_policy_arns = {
    alb_policy = aws_iam_policy.alb_controller_policy.arn
  }

  tags = {
    Project = var.project_name
  }
}

# Install AWS Load Balancer Controller using Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.1" # Specify chart version

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false" # We created it above with IRSA
  }
  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  set {
    name  = "serviceAccount.annotations.eks.amazonaws.com/role-arn"
    value = module.alb_controller_irsa.iam_role_arn
  }
  set {
    name = "region"
    value = var.aws_region
  }
  set {
    name = "vpcId"
    value = var.vpc_id
  }

  # Add other configurations if needed
  # e.g., enable shield, waf, etc.

  depends_on = [
    module.eks,
    module.alb_controller_irsa
  ]
}

# ACM Certificate for the domain - Only created if use_domain_name is true
resource "aws_acm_certificate" "app_cert" {
  count = var.use_domain_name ? 1 : 0
  
  domain_name       = var.domain_name
  validation_method = "DNS"

  # Optional: Add Subject Alternative Names (SANs) if needed
  # subject_alternative_names = ["www.${var.domain_name}"]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project = var.project_name
  }
}

# Route 53 record for ACM DNS validation - Only created if use_domain_name is true
locals {
  domain_validation_options = var.use_domain_name ? aws_acm_certificate.app_cert[0].domain_validation_options : []
}

resource "aws_route53_record" "cert_validation" {
  count = var.use_domain_name ? length(local.domain_validation_options) : 0
  
  zone_id = var.hosted_zone_id
  name    = local.domain_validation_options[count.index].resource_record_name
  type    = local.domain_validation_options[count.index].resource_record_type
  records = [local.domain_validation_options[count.index].resource_record_value]
  ttl     = 60
}

# Wait for ACM certificate validation to complete - Only created if use_domain_name is true
resource "aws_acm_certificate_validation" "cert" {
  count = var.use_domain_name ? 1 : 0
  
  certificate_arn         = aws_acm_certificate.app_cert[0].arn
  validation_record_fqdns = var.use_domain_name ? [for record in aws_route53_record.cert_validation : record.fqdn] : []
}

# Route 53 Record for the domain pointing to the ALB - Only created if use_domain_name is true
# Data source to get the Kubernetes Service associated with the Ingress

data "kubernetes_service_v1" "ingress_service" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
  }
  depends_on = [helm_release.aws_load_balancer_controller]
}

# If available, it identifies the ALB created by the controller.
# It uses tags automatically applied by the ALB controller based on cluster name and ingress name.
data "aws_lb" "ingress_alb" {
  name = element(split("/", kubernetes_ingress_v1.app_ingress.status.0.load_balancer.0.ingress.0.hostname), 1)

  depends_on = [
    kubernetes_ingress_v1.app_ingress, # Wait for ingress to be created
    # Wait for the controller and potentially the ingress resource (if managed here)
    helm_release.aws_load_balancer_controller,
    # kubernetes_ingress_v1.app_ingress # Add if ingress is managed here
  ]
}

# Route 53 record for the domain - Only created if use_domain_name is true
resource "aws_route53_record" "app" {
  count = var.use_domain_name ? 1 : 0
  
  zone_id = var.hosted_zone_id
  name    = var.domain_name # e.g., justeasylearn.com
  type    = "A"

  alias {
    name                   = data.aws_lb.ingress_alb.dns_name
    zone_id                = data.aws_lb.ingress_alb.zone_id
    evaluate_target_health = true
  }
}

# Optional: Add alias for www subdomain if desired and included in ACM cert SANs
# depends_on = [aws_acm_certificate_validation.cert] # Ensure cert is valid before creating DNS record
# resource "aws_route53_record" "www" {
#   count = var.use_domain_name ? 1 : 0
#   
#   zone_id = var.hosted_zone_id
#   name    = "www.${var.domain_name}"
#   type    = "A"
#
#   alias {
#     name                   = data.aws_lb.ingress_alb.dns_name
#     zone_id                = data.aws_lb.ingress_alb.zone_id
#     evaluate_target_health = true
#   }
# }

# Manage the Kubernetes Ingress resource directly via Terraform
resource "kubernetes_ingress_v1" "app_ingress" {
  metadata {
    name = "${var.project_name}-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class": "alb"
      "alb.ingress.kubernetes.io/scheme": "internet-facing"
      "alb.ingress.kubernetes.io/target-type": "ip"
      # Use the validated certificate if use_domain_name is true
      "alb.ingress.kubernetes.io/certificate-arn": var.use_domain_name ? aws_acm_certificate_validation.cert[0].certificate_arn : ""
      # Redirect HTTP to HTTPS if use_domain_name is true
      "alb.ingress.kubernetes.io/actions.ssl-redirect": var.use_domain_name ? "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}" : ""
      # Configure the listener ports - include HTTPS if use_domain_name is true
      "alb.ingress.kubernetes.io/listen-ports": var.use_domain_name ? "[{\"HTTP\": 80}, {\"HTTPS\":443}]" : "[{\"HTTP\": 80}]"
      # Health check configuration
      # "alb.ingress.kubernetes.io/healthcheck-path": "/health"
      # "alb.ingress.kubernetes.io/healthcheck-port": "service-port"
    }
  }
  
  spec {
    # Only include host if using domain name
    dynamic "rule" {
      for_each = var.use_domain_name ? [1] : []
      content {
        host = var.domain_name
        http {
          path {
            path = "/"
            path_type = "Prefix"
            backend {
              service {
                name = "frontend-service"
                port {
                  number = 80
                }
              }
            }
          }
          path {
            path = "/api"
            path_type = "Prefix"
            backend {
              service {
                name = "backend-service"
                port {
                  number = 80
                }
              }
            }
          }
          # Redirect path for SSL if use_domain_name is true
          dynamic "path" {
            for_each = var.use_domain_name ? [1] : []
            content {
              path = "/*"
              path_type = "ImplementationSpecific"
              backend {
                service {
                  name = "ssl-redirect"
                  port {
                    name = "use-annotation" 
                  }
                }
              }
            }
          }
        }
      }
    }
    
    # Use a ruleless configuration when not using domain name
    dynamic "rule" {
      for_each = var.use_domain_name ? [] : [1]
      content {
        http {
          path {
            path = "/"
            path_type = "Prefix"
            backend {
              service {
                name = "frontend-service"
                port {
                  number = 80
                }
              }
            }
          }
          path {
            path = "/api"
            path_type = "Prefix"
            backend {
              service {
                name = "backend-service"
                port {
                  number = 80
                }
              }
            }
          }
        }
      }
    }
  }
  
  # Make sure to apply after the controller is running
  depends_on = [
    helm_release.aws_load_balancer_controller
  ]
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = data.aws_lb.ingress_alb.dns_name
} 