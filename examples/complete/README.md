# Complete Example

An example presenting how to deploy DeSo Blockchain. This application will be available at https://${var.name}.${var.deso_public_hosted_zone}/ after deployment.

This example assumes that you have an existing Route53 Hosted Zone which name you provide as `var.deso_public_hosted_zone`.

This example creates two additional resources:

- AWS EC2 Key Pair that can be used to SSH into DeSo nodes,
- AWS VPC where your DeSo nodes will exist.

## How to SSH

```bash
terraform output --raw ssh_private_key_pem > key.pem
chmod 600 key.pem
# You can find the node ip address in AWS EC2 console.
ssh -i key.pem ec2-user@${DESO_NODE_PUBLIC_IP}
```

<!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->