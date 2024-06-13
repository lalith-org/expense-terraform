resource "aws_instance" "vm" {
  ami           = data.aws_ami.example.id
  instance_type = var.instance_type
  vpc_security_group_ids = [data.aws_security_group.selected.id]
  
  tags = {
  Name = var.component
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
      user     = var.os_user
      password = var.os_pass
      host     = aws_instance.vm.public_ip
    }

    inline = [
      "sudo pip3.11 install ansible",
      "sudo ansible-pull -u https://github.com/lalith2211/expense-ansible.git ansible.sh -i localhost, -e env=${var.env} -e role_name=${var.component}",
    ]
  }
}
