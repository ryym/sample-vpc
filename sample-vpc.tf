variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "ap-northeast-1"
}

# VPC

resource "aws_vpc" "sample" {
    cidr_block = "10.0.0.0/16"

    tags {
        Name = "sample-vpc2"
    }
}

# Subnets

resource "aws_subnet" "sample_web" {
    vpc_id = "${aws_vpc.sample.id}"
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-northeast-1a"

    tags {
        Name = "sample-vpc2:public:web"
    }
}

resource "aws_subnet" "sample_db1" {
    vpc_id = "${aws_vpc.sample.id}"
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-1a"

    tags {
        Name = "sample-vpc2:private:db1"
    }
}

resource "aws_subnet" "sample_db2" {
    vpc_id = "${aws_vpc.sample.id}"
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-northeast-1c"

    tags {
        Name = "sample-vpc2:private:db2"
    }
}
