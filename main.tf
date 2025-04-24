terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}

# ✅ Get Latest RHEL 9.x AMI
data "aws_ami" "latest_rhel" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat AWS account

  filter {
    name   = "name"
    values = ["RHEL-9.?*-x86_64-*"]
  }
}

# ✅ Elastic IPs for Search Head, Indexer, HF
resource "aws_eip" "splunk_eips" {
  count      = 3
  instance   = aws_instance.Splunk_sh_idx_hf[count.index].id
  vpc        = true
  depends_on = [aws_instance.Splunk_sh_idx_hf]
}

# ✅ Elastic IP for UF
resource "aws_eip" "uf_eip" {
  instance   = aws_instance.Splunk_uf.id
  vpc        = true
  depends_on = [aws_instance.Splunk_uf]
}


# ✅ Security Group
resource "aws_security_group" "splunk_sg" {
  name        = "splunk-security-group"
  description = "Allow Splunk ports"

  ingress { 
    from_port   = 22
    to_port     = 22 
    protocol    = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 8000
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ✅ Multiple EC2 Instances
resource "aws_instance" "Splunk_sh_idx_hf" {
  count         = 3
  ami           = data.aws_ami.latest_rhel.id
  instance_type = "t2.medium"
  key_name      = var.key_name
  security_groups = [aws_security_group.splunk_sg.name]

  root_block_device {
    volume_size = 30
  }

  user_data = file("splunk-setup.sh")

  tags = {
    Name = "${lookup({
      0 = "Search-Head"
      1 = "Indexer"
      2 = "HF"
    }, count.index)}"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host = self.public_ip
    }

    inline = [
       "echo '${var.ssh_public_key}' >> ~/.ssh/authorized_keys"
    ]
  }
}

# ✅ Single UF EC2 Instance
resource "aws_instance" "Splunk_uf" {
  ami           = data.aws_ami.latest_rhel.id
  instance_type = "t2.medium"
  key_name      = var.key_name
  security_groups = [aws_security_group.splunk_sg.name]

  root_block_device {
    volume_size = 30
  }

  user_data = file("splunk-setup-UF.sh")

  tags = {
    Name = "UF"
  }

  provisioner "remote-exec" {
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("${var.key_name}.pem")
      host = self.public_ip
    }

    inline = [
       "echo '${var.ssh_public_key}' >> ~/.ssh/authorized_keys"
    ]
  }
}

# Generate Ansible Inventory File
resource "local_file" "inventory" {
  content = <<EOT
[search_head]
${aws_eip.splunk_eips[0].public_ip != "" ? aws_eip.splunk_eips[0].public_ip : aws_instance.Splunk_sh_idx_hf[0].public_ip} ansible_user=ec2-user private_ip=${aws_instance.Splunk_sh_idx_hf[0].private_ip}

[indexer]
${aws_eip.splunk_eips[1].public_ip != "" ? aws_eip.splunk_eips[1].public_ip : aws_instance.Splunk_sh_idx_hf[1].public_ip} ansible_user=ec2-user private_ip=${aws_instance.Splunk_sh_idx_hf[1].private_ip}

[heavy_forwarder]
${aws_eip.splunk_eips[2].public_ip != "" ? aws_eip.splunk_eips[2].public_ip : aws_instance.Splunk_sh_idx_hf[2].public_ip} ansible_user=ec2-user private_ip=${aws_instance.Splunk_sh_idx_hf[2].private_ip}

[universal_forwarder]
${aws_eip.uf_eip.public_ip != "" ? aws_eip.uf_eip.public_ip : aws_instance.Splunk-uf.public_ip} ansible_user=ec2-user private_ip=${aws_instance.Splunk-uf.private_ip}

[splunk:children]
search_head
indexer
heavy_forwarder
universal_forwarder
EOT

  filename = "${path.module}/inventory.ini"
}
