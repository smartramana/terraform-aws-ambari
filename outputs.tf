# this defines the outputs rendered by terraform if all is set and done
output "Master_public_dns" {
  value = ["${aws_instance.master.*.public_dns}"]
}
output "HDP_public_dns" {
  value = ["${aws_instance.hdp.*.public_dns}"]
}

output "ansible_public_dns" {
  value = ["${aws_instance.ansible.public_dns}"]
}

output "ambari_public_dns" {
  value = ["${aws_instance.ambari.*.public_dns}"]
}

