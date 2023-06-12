resource "aws_instance" "webserver" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "c4.large"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  private_ip                  = "10.0.1.20"

  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = {
    Name = "WebserverInstance"
  }

  user_data = data.template_file.webserver_data.rendered

  depends_on = [
    aws_route_table_association.private_route_association,
  ]

}

data "template_file" "webserver_data" {
  template = file("${path.module}/scripts/webserver.sh")
}
