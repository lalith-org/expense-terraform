resource "aws_instance" "vm" {
  ami           = data.aws_ami.example.id
  instance_type = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.selected.id]
  
  tags = {
  Name = var.component
  Monitor = "true"
  env = var.env
  }
}

resource "aws_route53_record" "domain" {
  zone_id = var.zone_id
  name    = "${var.component}-${var.env}"
  type    = "A"
  ttl     = 30
  records = [aws_instance.vm.private_ip]
}

resource "null_resource" "null1" {
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = jsondecode(data.vault_generic_secret.ssh_creds.data_json).ansible_username
      password = jsondecode(data.vault_generic_secret.ssh_creds.data_json).ansible_password
      host     = aws_instance.vm.public_ip
    }

    inline = [
      "sudo pip3.11 install ansible hvac",
      "sudo pip3.11 install ansible-core",
      "ansible-pull -i localhost, -U https://github.com/lalith2211/expense-ansible.git get-secrets.yml -e env=${var.env} -e role=${var.component}  -e vault_token=${var.vault_token}",
      "ansible-pull -i localhost, -U https://github.com/lalith2211/expense-ansible.git ansible.yml -e env=${var.env} -e role=${var.component} -e @secrets.json -e @app.json",
      "sudo rm -rf *"
      #"ansible-pull -U https://github.com/lalith2211/expense-ansible.git ansible.yml -i localhost, -e env=${var.env} -e role=${var.component}",
    ]
  }
}
