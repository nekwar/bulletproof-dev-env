# https://github.com/kubernetes/cloud-provider-aws/blob/master/docs/prerequisites.md
resource "aws_iam_policy" "ccm_controller_iam_policy" {
  name        = "${var.name}_ccm_controller_iam_policy"
  path        = "/"
  description = "Policy to provide permission to EC2"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
         {
           Effect = "Allow",
           Action = [
             "autoscaling:DescribeAutoScalingGroups",
             "autoscaling:DescribeLaunchConfigurations",
             "autoscaling:DescribeTags",
             "ec2:DescribeInstances",
             "ec2:DescribeRegions",
             "ec2:DescribeRouteTables",
             "ec2:DescribeSecurityGroups",
             "ec2:DescribeSubnets",
             "ec2:DescribeVolumes",
             "ec2:DescribeAvailabilityZones",
             "ec2:CreateSecurityGroup",
             "ec2:CreateTags",
             "ec2:CreateVolume",
             "ec2:ModifyInstanceAttribute",
             "ec2:ModifyVolume",
             "ec2:AttachVolume",
             "ec2:AuthorizeSecurityGroupIngress",
             "ec2:CreateRoute",
             "ec2:DeleteRoute",
             "ec2:DeleteSecurityGroup",
             "ec2:DeleteVolume",
             "ec2:DetachVolume",
             "ec2:RevokeSecurityGroupIngress",
             "ec2:DescribeVpcs",
             "elasticloadbalancing:AddTags",
             "elasticloadbalancing:AttachLoadBalancerToSubnets",
             "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
             "elasticloadbalancing:CreateLoadBalancer",
             "elasticloadbalancing:CreateLoadBalancerPolicy",
             "elasticloadbalancing:CreateLoadBalancerListeners",
             "elasticloadbalancing:ConfigureHealthCheck",
             "elasticloadbalancing:DeleteLoadBalancer",
             "elasticloadbalancing:DeleteLoadBalancerListeners",
             "elasticloadbalancing:DescribeLoadBalancers",
             "elasticloadbalancing:DescribeLoadBalancerAttributes",
             "elasticloadbalancing:DetachLoadBalancerFromSubnets",
             "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
             "elasticloadbalancing:ModifyLoadBalancerAttributes",
             "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
             "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
             "elasticloadbalancing:AddTags",
             "elasticloadbalancing:CreateListener",
             "elasticloadbalancing:CreateTargetGroup",
             "elasticloadbalancing:DeleteListener",
             "elasticloadbalancing:DeleteTargetGroup",
             "elasticloadbalancing:DescribeListeners",
             "elasticloadbalancing:DescribeLoadBalancerPolicies",
             "elasticloadbalancing:DescribeTargetGroups",
             "elasticloadbalancing:DescribeTargetHealth",
             "elasticloadbalancing:ModifyListener",
             "elasticloadbalancing:ModifyTargetGroup",
             "elasticloadbalancing:RegisterTargets",
             "elasticloadbalancing:DeregisterTargets",
             "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
             "iam:CreateServiceLinkedRole",
             "kms:DescribeKey"
           ],
           Resource = [
             "*"
           ]
         }
       ]
         
  })
}

resource "aws_iam_role" "controller_iam_role" {
  name = "${var.name}_controller_iam_role"

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

#Attach role to policy
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "ccm_controller_iam_role_policy_attach" {
  role       = aws_iam_role.controller_iam_role.name
  policy_arn = aws_iam_policy.ccm_controller_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "csi_controller_iam_role_policy_attach" {
  role       = aws_iam_role.controller_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}
#Attach role to an instance profile
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "controller_iam_instance_profile" {
  name = "${var.name}_controller_iam_instance_profile"
  role = aws_iam_role.controller_iam_role.name
}

### workers

resource "aws_iam_policy" "ccm_worker_iam_policy" {
  name        = "${var.name}_ccm_worker_iam_policy"
  path        = "/"
  description = "Policy to provide permission to EC2"
  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
  Version = "2012-10-17",
  Statement = [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
  })
}

resource "aws_iam_role" "worker_iam_role" {
  name = "${var.name}_worker_iam_role"

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

#Attach role to policy
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment
resource "aws_iam_role_policy_attachment" "ccm_worker_iam_role_policy_attach" {
  role       = aws_iam_role.worker_iam_role.name
  policy_arn = aws_iam_policy.ccm_worker_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "csi_worker_iam_role_policy_attach" {
  role       = aws_iam_role.worker_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

#Attach role to an instance profile
#https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile
resource "aws_iam_instance_profile" "worker_iam_instance_profile" {
  name = "${var.name}_worker_iam_instance_profile"
  role = aws_iam_role.worker_iam_role.name
}

