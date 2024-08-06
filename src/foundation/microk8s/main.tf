provider "aws" {
  region = var.aws_region
  access_key = var.access_key
  secret_key = var.secret_key

}

resource "aws_instance" "master" {
  ami           = var.aws_ami
  instance_type = var.aws_instance
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id =  var.aws_subnet_id
  user_data = <<-EOF
              #!/bin/bash
              sudo su
              apt update -y >> microk8s_install.log
              apt install snapd -y >> microk8s_install.log
              snap install core >> microk8s_install.log
              export PATH=$PATH:/snap/bin
              snap install microk8s --classic --channel=1.21 >> microk8s_install.log
              microk8s status --wait-ready
              microk8s enable dns >> microk8s_install.log
              microk8s enable storage >> microk8s_install.log
              microk8s add-node > microk8s.join_token
              microk8s config > configFile-master
              EOF
  key_name = "terraform"
  tags = {
    Name = "master"
  }
  provisioner "remote-exec" {
  inline = ["until [ -f /microk8s.join_token ]; do sleep 5; done; cat /microk8s.join_token",
            "sudo sed -i 's/#MOREIPS/IP.7 = ${self.public_ip}\\n#MOREIPS/g' /var/snap/microk8s/current/certs/csr.conf.template",
            "sudo sleep 1m",
            "sudo microk8s stop",
            "sudo microk8s start",
           ]
  }

  connection {
    host = self.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = ""
    private_key = "${file("terraform.pem")}"
  }

  provisioner "local-exec" {
    command = <<EOT
               touch token
               mkdir /root/.ssh && chmod 0700 /root/.ssh
               ssh-keyscan -H ${self.public_dns} >> ~/.ssh/known_hosts
               scp -i terraform.pem ubuntu@${self.public_dns}:/microk8s.join_token .
               tail -n1 microk8s.join_token >> token
               scp -i terraform.pem ubuntu@${self.public_dns}:/configFile-master .
              EOT
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name = "master_microk8s"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

data "local_file" "tokenContent" {
  filename = "token"
  depends_on = [
    aws_instance.master,
  ]
}


locals {
    public_dns = aws_instance.master.public_dns
    join = data.local_file.tokenContent.content
}


resource "aws_instance" "worker" {
  ami           = var.aws_ami
  instance_type = var.aws_instance
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id =  var.aws_subnet_id
  user_data = templatefile("worker_user_data.tmpl", { token = local.join } )
  key_name = "terraform"
  tags = {
    Name = "worker"
  }

  provisioner "remote-exec" {
  inline = ["until [ -f /microk8s.complete ]; do sleep 5; done"]
  }

  connection {
    host = self.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = ""
    private_key = "${file("terraform.pem")}"
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_instance.master,
  ]
}


resource "null_resource" "cluster" {
  provisioner "remote-exec" {
  inline = ["sudo microk8s kubectl get no >> kubectl.info"]
  }

  connection {
    host = aws_instance.master.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = ""
    private_key = "${file("terraform.pem")}"
  }

  provisioner "local-exec" {
  command = <<EOT
               echo ${aws_instance.master.private_ip}
               export privateIP=${aws_instance.master.private_ip}
               export publicIP=${aws_instance.master.public_ip}
               ssh-keyscan -H ${aws_instance.worker.public_dns} >> ~/.ssh/known_hosts
               scp -i terraform.pem ubuntu@${aws_instance.worker.public_dns}:/configFile-worker .
              EOT
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_instance.worker,
  ]
}

output "public_ip" {
  value         = aws_instance.master.public_ip
}

output "private_ip" {
  value = aws_instance.master.private_ip
}

