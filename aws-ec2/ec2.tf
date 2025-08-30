# key pair
resource "aws_key_pair" "my_key_tf" {
  key_name   = "my_key_tf"
  public_key = file("~/.ssh/my_key_tf.pub")
}

# vpc & security group
resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "my_sg_tf" {
    name        = "my_sg_tf"
    description = "My security group for EC2 instances"
    vpc_id      = aws_default_vpc.default.id
    tags = {
        Name = "my_sg_tf"
    }

    # Inbound rules
    ingress {
        from_port=22
        to_port=22
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
        description = "Allow SSH access"
    }
    ingress{
        from_port=80
        to_port=80
        protocol="tcp"
        cidr_blocks=["0.0.0.0/0"]
        description="allow http access"
    }
    ingress{
        from_port = 8080
        to_port= 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow jenkins access"
    }

    # Outbound rules
    egress {
        from_port=0
        to_port=0
        protocol="-1"
        cidr_blocks=["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }
}

# ec2 instance
resource "aws_instance" "my_ec2_tf" {
    key_name = aws_key_pair.my_key_tf.key_name
    security_groups=[aws_security_group.my_sg_tf.name]
    instance_type = var.ec2_instance_type
    ami = var.ec2_ami_id
    root_block_device {
        volume_size = var.ec2_root_storage_size
        volume_type = "gp3"
    }
    tags = {
        Name = "my_ec2_tf"
    }
}