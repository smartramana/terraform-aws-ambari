/* this module is aimed at installing nodes needed to setup hortonworks ambari and hdp nodes on aws (for now) */
/* setup the aws provider */
terraform {
  backend "s3" {
    bucket = "tf-merc-1"
    key    = "test1"
  }
}

provider "aws" {
  region     = "${var.aws_region}"
  shared_credentials_file = ".aws/credentials"
}



/* create the keypair */
resource "aws_key_pair" "basic" {
  key_name   = "basic"
  public_key = "${file("./ssh_keys/rsa.pub")}"
}

/* get the ami for the region we want to use */
data "aws_ami" "centos" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["410186602215"] 
}



/* spin up the utility host that is going to host ansible and ambari */
resource "aws_instance" "ansible" {

  ami               = "${data.aws_ami.centos.id}"
  key_name          = "${aws_key_pair.basic.id}"
  security_groups   = ["${aws_security_group.ambari.name}","${aws_security_group.basic.name}"]
  instance_type     = "${var.size["ansible"]}"
  source_dest_check = false

  root_block_device {
    delete_on_termination = true
    volume_size = "${var.root_disk_size["ansible"]}"
  }

  tags {
    Name = "ansible"
  }
  
  connection {
        type        = "ssh"
        user        = "centos"
        private_key = "${file("ssh_keys/rsa")}"
        timeout     = "1m"
        agent       = false
    }

  /* aftermath */
  provisioner "file" {
    source = "./ssh_keys/rsa"
    destination = "/home/centos/.ssh/mykey"
  }

  provisioner "file" {
    source = "files/playbooks"
    destination = "/home/centos/playbooks"
  }

  provisioner "file" {
    source = "files/blueprints"
    destination = "/home/centos/blueprints"
  }


  provisioner "file" {
      source = "scripts/install_ansible_centos7.sh"
      destination = "/tmp/install_ansible_centos7.sh"
  }
 
  provisioner "file" {
        content = "${data.template_file.ansible_hosts.rendered}"
        destination = "/tmp/hosts"
  }

  provisioner "file" {
      source = "files/ansible.cfg"
      destination = "/tmp/ansible.cfg"
  }


  
  provisioner "remote-exec"{
      inline = [
          "sudo chmod 0400 /home/centos/.ssh/mykey",
          "chmod +x /tmp/install_ansible_centos7.sh",
          "sudo /tmp/install_ansible_centos7.sh",
          "sudo cp /tmp/ansible.cfg /etc/ansible/ansible.cfg",
          "sudo cp /tmp/hosts /etc/ansible/hosts",
          "ansible --private-key $HOME/.ssh/mykey all -m ping",
          "echo ${aws_instance.ambari.private_dns} > ambariserver.txt",
          "mkdir /home/centos/roles",
          "git clone https://github.com/cinqict/ansible-hortonworks.git /home/centos/roles/ansible-hortonworks",
          "ansible-playbook --key-file .ssh/mykey playbooks/site.yaml"
        ]
  }

  
 
}

/* spin up the HDP nodes */
resource "aws_instance" "hdp" {
  

  

  ami               = "${data.aws_ami.centos.id}"
  key_name          = "${aws_key_pair.basic.id}"
  security_groups   = ["${aws_security_group.basic.name}"]
  count             = "${var.width["hdp"]}"
  instance_type     = "${var.size["hdp"]}"

  source_dest_check = false

  tags {
    Name = "HDP-${count.index}"
  }
  root_block_device {
    delete_on_termination = true
    volume_size = "${var.root_disk_size["hdp"]}"
  }


}

/* spin up the HDP nodes */
resource "aws_instance" "master" {
  

  ami               = "${data.aws_ami.centos.id}"
  key_name          = "${aws_key_pair.basic.id}"
  security_groups   = ["${aws_security_group.basic.name}"]
  count             = "${var.width["master"]}"
  instance_type     = "${var.size["master"]}"

  source_dest_check = false

  tags {
    Name = "Master-${count.index}"
  }
  root_block_device {
    delete_on_termination = true
    volume_size = "${var.root_disk_size["master"]}"
  }

}

resource "aws_instance" "ambari" {
 
  

  ami               = "${data.aws_ami.centos.id}"
  key_name          = "${aws_key_pair.basic.id}"
  security_groups   = ["${aws_security_group.ambari.name}","${aws_security_group.basic.name}"]
  count             = "${var.width["ambari"]}"
  instance_type     = "${var.size["ambari"]}"

  source_dest_check = false

  tags {
    Name = "Ambari-${count.index}"
  }
  root_block_device {
    delete_on_termination = true
    volume_size = "${var.root_disk_size["ambari"]}"
  }
  tags {
    name = "Ambari"
  }


}

data "template_file" "ansible_hosts" {
  template = "${file("templates/hosts")}"
  
  vars {
    hdp_addresses = "${join("\n", aws_instance.hdp.*.public_dns)}"
    master_addresses = "${join("\n", aws_instance.master.*.public_dns)}"
    ambari_addresses = "${join("\n", aws_instance.ambari.*.public_dns)}"

  }
}

resource "local_file" "foo" {
    content = "${data.template_file.ansible_hosts.rendered}"
    filename = "./ansible/hosts.txt"
}

/* output all the things */

