data "aws_ami" "example" {
  most_recent      = true
#  name_regex       = "RHEL-9-DevOps-Practice"
#  owners           = ["973714476881"]
  name_regex  = "golden-ami-*"
  owners      = ["self"]
}

data "vault_generic_secret" "ssh" {
  path = "common/common"
}