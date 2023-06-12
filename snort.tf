# Deploy Snort Inside PublicSubnet
resource "aws_instance" "snort_instance" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "c4.large"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  private_ip                  = "10.0.1.10"

  vpc_security_group_ids = [aws_security_group.public_sg.id]

  tags = {
    Name = "SnortInstance"
  }

  user_data = data.template_file.snort_data.rendered

  depends_on = [
    aws_route_table_association.private_route_association,
  ]
}

# Define Bashscript
data "template_file" "snort_data" {
  template = file("${path.module}/scripts/snort.sh")
}
