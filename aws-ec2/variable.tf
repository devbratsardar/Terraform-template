variable "ec2_instance_type" {
    default = "t2.micro"
    type = string
}
variable "ec2_ami_id" {
    default = "ami-0360c520857e3138f" #ubuntu
    type = string
}

variable "ec2_root_storage_size" {
    default = 10
    type = number
}