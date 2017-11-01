variable "aws_region" { default = "eu-central-1" }


variable "width" {
  default = {
    "master" = "3"
    "hdp" = "3"
    "ambari" = "1"
  }
}

variable "size" {
  default = {
    "ansible" = "t2.micro"
    "ambari" = "t2.medium"
    "hdp" = "t2.medium"
    "master" = "t2.medium"
  }
}

variable "root_disk_size" {
  default = {
    "ansible" = "8"
    "ambari" = "8"
    "hdp" = "80"
    "master" = "80"
  }
}
