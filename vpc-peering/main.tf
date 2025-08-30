# key pair
resource "aws_key_pair" "my_key_tf" {
  key_name   = "my_key_tf"
  public_key = file("~/.ssh/my_key_tf.pub")
}

# VPC A Configuration
resource "aws_vpc" "vpc_a" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "VPC-A"
  }
}
# Create a public subnet
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

# Create an Internet Gateway 
resource "aws_internet_gateway" "igw_a" {
  vpc_id = aws_vpc.vpc_a.id
}

# Create a route table
resource "aws_route_table" "rt_a" {
  vpc_id = aws_vpc.vpc_a.id
}

# Add route to Internet Gateway (0.0.0.0/0)
resource "aws_route" "default_route_a" {
  route_table_id         = aws_route_table.rt_a.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_a.id
}

# Associate the route table with the subnet
resource "aws_route_table_association" "rta_a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.rt_a.id
}

# Create a security group
resource "aws_security_group" "sg_a" {
  name   = "a-sg"
  vpc_id = aws_vpc.vpc_a.id

# Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Allow all traffic from VPC B
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.1.0.0/16"] # CIDR of VPC B
  }

# Allow all traffic to VPC B
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "ec2_a" {
  ami           = "ami-0c2b8ca1dad447f8a" # Amazon Linux 2 AMI in us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_a.id
  vpc_security_group_ids = [aws_security_group.sg_a.id]
  key_name      = aws_key_pair.my_key_tf.key_name

  tags = {
    Name = "EC2-A"
  }
}

# ------------------------------------------------------------------------------

# VPC B Configuration
resource "aws_vpc" "vpc_b" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "VPC-B"
  }
}

# Create a public subnet
resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.vpc_b.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw_b" {
  vpc_id = aws_vpc.vpc_b.id
}

# Create a route table
resource "aws_route_table" "rt_b" {
  vpc_id = aws_vpc.vpc_b.id
}

# Add route to Internet Gateway (0.0.0.0/0)
resource "aws_route" "default_route_b" {
  route_table_id         = aws_route_table.rt_b.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw_b.id
}

# Associate the route table with the subnet
resource "aws_route_table_association" "rta_b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.rt_b.id
}

# Create a security group
resource "aws_security_group" "sg_b" {
  name   = "b-sg"
  vpc_id = aws_vpc.vpc_b.id

# Allow SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

# Allow all traffic from VPC A
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/16"] # CIDR of VPC A
  }

# Allow all traffic to VPC A
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance
resource "aws_instance" "ec2_b" {
  ami           = "ami-0c2b8ca1dad447f8a"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_b.id
  vpc_security_group_ids = [aws_security_group.sg_b.id]
  key_name      = aws_key_pair.my_key_tf.key_name

  tags = {
    Name = "EC2-B"
  }
}

# ------------------------------------------------------------------------------

# VPC Peering
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = aws_vpc.vpc_a.id
  peer_vpc_id   = aws_vpc.vpc_b.id
  auto_accept   = true

  tags = {
    Name = "peer-vpc-a-b"
  }
}

# Add route to VPC A's route table
resource "aws_route" "route_to_b" {
  route_table_id         = aws_route_table.rt_a.id
  destination_cidr_block = aws_vpc.vpc_b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}

# Add route to VPC B's route table
resource "aws_route" "route_to_a" {
  route_table_id         = aws_route_table.rt_b.id
  destination_cidr_block = aws_vpc.vpc_a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
