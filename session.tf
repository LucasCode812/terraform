# Create a Traffic Filter
resource "aws_ec2_traffic_mirror_filter" "my_filter" {
  description      = "My Traffic Mirror Filter"
  network_services = ["amazon-dns"]

  tags = {
    Name = "MyFilter"
  }
}

# Set Snort as the Traffic Target
resource "aws_ec2_traffic_mirror_target" "snort_target" {
  network_interface_id = aws_instance.snort_instance.primary_network_interface_id

  tags = {
    Name = "SnortTarget"
  }

  depends_on = [
    aws_route_table_association.private_route_association,
  ]
}

# ActiveDirectory --> Snort Session
resource "aws_ec2_traffic_mirror_session" "ad_snort" {
  network_interface_id     = aws_instance.ActiveDirectory.primary_network_interface_id
  session_number           = 1
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.my_filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.snort_target.id

  tags = {
    Name = "AD-Snort"
  }
}

# NagiosXI --> Snort Session
resource "aws_ec2_traffic_mirror_session" "nagios_snort" {
  network_interface_id     = aws_instance.Nagios.primary_network_interface_id
  session_number           = 2
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.my_filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.snort_target.id

  tags = {
    Name = "Nagios-Snort"
  }
}

# Wazuh-Manager --> Snort Session
resource "aws_ec2_traffic_mirror_session" "wazuh_snort" {
  network_interface_id     = aws_instance.Wazuh.primary_network_interface_id
  session_number           = 3
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.my_filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.snort_target.id

  tags = {
    Name = "Wazuh-Snort"
  }
}

# WebServer --> Snort Session
resource "aws_ec2_traffic_mirror_session" "webserver_snort" {
  network_interface_id     = aws_instance.webserver.primary_network_interface_id
  session_number           = 4
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.my_filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.snort_target.id

  tags = {
    Name = "Webserver-Snort"
  }
}
