resource "aws_key_pair" "AWS_KEY" {
  key_name   = "RDPKEY"
  public_key = file("C:/Users/lucas/Desktop/TerraformAWS/sshkey/RDPKEY.pub")
}

resource "aws_instance" "ActiveDirectory" {
  ami                         = "ami-0d86c69530d0a048e"
  instance_type               = "c4.large"
  key_name                    = "RDPKEY"
  subnet_id                   = aws_subnet.private_subnet.id
  associate_public_ip_address = true
  private_ip                  = "10.0.2.12"

  vpc_security_group_ids = [aws_security_group.private_sg.id]

  user_data = data.template_file.ad_data.rendered

  depends_on = [
    aws_route_table_association.private_route_association,
  ]

  tags = {
    Name = "ADInstance"
  }

}

data "template_file" "ad_data" {
  template = file("${path.module}/scripts/ad.sh")
}
