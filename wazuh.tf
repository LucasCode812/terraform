resource "aws_instance" "Wazuh" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "c4.large"
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = true
  private_ip                  = "10.0.2.10"

  vpc_security_group_ids = [aws_security_group.private_sg.id]

  tags = {
    Name = "WazuhInstance"
  }

  user_data = data.template_file.WazuhData.rendered

  depends_on = [
    aws_route_table_association.private_route_association,
  ]
}

data "template_file" "WazuhData" {
  template = file("${path.module}/scripts/wazuh.sh")
}
