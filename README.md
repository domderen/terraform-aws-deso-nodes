# Terraform AWS DeSo blockchain nodes

Create your own [DeSo Blockchain](https://www.deso.org/) feed in minutes.

Everything that you need to run your own [DeSo Blockchain](https://www.deso.org/) nodes on AWS. This module is intended as a simple and easy initialization of your own nodes, that are automatically exposed to the world on a DNS hostname that you specify.

- Configure DeSo deployment to your liking via terraform variables,
- You can specify your own forks of DeSo Backend & Frontend docker images to run your own custom deployment;

This terraform module deploys [DeSo Blockchain](https://www.deso.org/) nodes as an AWS Auto Scaling Group, and exposes them via an AWS Application Load Balancer as a DNS hostname in AWS Route53. In addition it creates AWS IAM Role & AWS IAM Instance Profile with permissions to manage autoscaling of the AWS ASG, and with ability to put logs to AWS CloudWatch Logs. Finally it creates 2 AWS CloudWatch Log Groups:

- `${var.name}/backend`
- `${var.name}/frontend`

That will contain logs for the three containers that are deployed on each DeSo node.

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
