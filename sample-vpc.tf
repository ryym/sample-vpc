# terraform.tfvars で値をセットする。
variable "aws_profile" {}
variable "db_username" {}
variable "db_password" {}

terraform {
    backend "s3" {
        # bucket, key, region, profile
        # (use terraform init -backend-config=<config file>)
    }
}

provider "aws" {
    profile = "${var.aws_profile}"
    region = "ap-northeast-1"
}

# VPC

resource "aws_vpc" "sample" {
    cidr_block = "10.0.0.0/16"

    tags {
        Name = "sample-vpc"
    }
}

output "vpc_arn" {
    value = "${aws_vpc.sample.arn}"
}

# Subnets

resource "aws_subnet" "sample_web" {
    vpc_id = "${aws_vpc.sample.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-northeast-1d"

    tags {
        Name = "sample-vpc:public:web"
    }
}

resource "aws_subnet" "sample_db1" {
    vpc_id = "${aws_vpc.sample.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1d"

    tags {
        Name = "sample-vpc:private:db1"
    }
}

resource "aws_subnet" "sample_db2" {
    vpc_id = "${aws_vpc.sample.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-northeast-1c"

    tags {
        Name = "sample-vpc:private:db2"
    }
}

resource "aws_internet_gateway" "sample" {
    vpc_id = "${aws_vpc.sample.id}"

    tags {
        Name = "sample-vpc:igw"
    }
}

# Route table

resource "aws_route_table" "sample_public" {
    vpc_id = "${aws_vpc.sample.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.sample.id}"
    }

    tags {
        Name = "sample-vpc:public"
    }
}

resource "aws_route_table_association" "sample_web" {
    subnet_id = "${aws_subnet.sample_web.id}"
    route_table_id = "${aws_route_table.sample_public.id}"
}

# Security Groups

resource "aws_security_group" "sample_web" {
    name = "sample-vpc:web"
    vpc_id = "${aws_vpc.sample.id}"

    tags {
        Name = "sample-vpc-sg:web"
    }

    // SSH
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // HTTP
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "sample_db" {
    name = "sample-vpc:db"
    vpc_id = "${aws_vpc.sample.id}"

    tags {
        Name = "sample-vpc-sg:db"
    }

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["${aws_subnet.sample_web.cidr_block}"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

# DB

resource "aws_db_subnet_group" "sample_db_group" {
    name = "sample-vpc-db-sbg"
    subnet_ids = [
        "${aws_subnet.sample_db1.id}",
        "${aws_subnet.sample_db2.id}"
    ]
}

resource "aws_db_instance" "sample_db" {
    db_subnet_group_name = "${aws_db_subnet_group.sample_db_group.name}"
    allocated_storage = 5
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.6"
    instance_class = "db.t2.micro"
    name = "sampledb"
    identifier = "sample-db"
    parameter_group_name = "utf8mysql56"
    skip_final_snapshot = true
    vpc_security_group_ids = ["${aws_security_group.sample_db.id}"]

    # WARNING: remote backend の state にもこれらの値が記録されるらしいので注意。
    # https://www.terraform.io/docs/state/sensitive-data.html
    username = "${var.db_username}"
    password = "${var.db_password}"

    tags {
        Name = "sample-vpc:rds"
    }
}

# App Server

# https://dev.classmethod.jp/cloud/aws/launch-ec2-from-latest-ami-by-terraform/
data "aws_ami" "amazon_linux" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "architecture"
        values = ["x86_64"]
    }

    filter {
        name = "root-device-type"
        values = ["ebs"]
    }

    filter {
        name = "name"
        values = ["amzn-ami-hvm-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    filter {
        name = "block-device-mapping.volume-type"
        values = ["gp2"]
    }
}

resource "aws_instance" "sample_web" {
    ami = "${data.aws_ami.amazon_linux.id}"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.sample_web.id}"
    vpc_security_group_ids = ["${aws_security_group.sample_web.id}"]

    # Note that this key pair is not managed by Terraform.
    key_name = "sample-vpc-key-pair"

    root_block_device {
        volume_type = "gp2"
        volume_size = 8
    }

    tags {
        Name = "sample-vpc-ec2:web"
    }
}

resource "aws_eip" "sample_web_ip" {
    instance = "${aws_instance.sample_web.id}"
    vpc = true
}

output "web_public_ip" {
    value = "${aws_eip.sample_web_ip.public_ip}"
}
