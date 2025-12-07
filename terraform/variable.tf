
variable "region" {
  description = "AWS region to deploy EKS and VPC"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "endhunger-eks"
}
