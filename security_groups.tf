/* a security group would be a nice thing to have ... i think .. */

resource "aws_security_group" "basic" {
  name        = "basic"
  description = "basic sec profile"

  // These are for internal traffic
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    self      = true
  }
  

  // fully open udp ingress for internal traffic (meaning hosts in the same sec group)
  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "udp"
    self      = true
  }

  // These are for maintenance
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // This is for outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//ambari specific ports
resource "aws_security_group" "ambari" {
  name        = "ambari"
  description = "ambari sec profile"
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8440
    to_port   = 8441
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
