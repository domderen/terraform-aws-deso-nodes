# Private key that will be used to SSH into DeSo nodes.
resource "tls_private_key" "this" {
  algorithm = "RSA"
}

# Create a key-pair that is used to SSH into DeSo nodes.
module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = var.name
  public_key = tls_private_key.this.public_key_openssh
}