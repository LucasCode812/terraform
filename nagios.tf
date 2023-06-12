# Deploy NagiosXI Inside PrivateSubnet
resource "aws_instance" "Nagios" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "c4.large"
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = true
  private_ip                  = "10.0.2.11"

  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "NagiosInstance"
  }

  user_data = data.template_file.nagios_data.rendered

  depends_on = [
    aws_route_table_association.private_route_association,
  ]
}

# Define Bashscript
data "template_file" "nagios_data" {
  template = file("${path.module}/scripts/nagios.sh")
}
