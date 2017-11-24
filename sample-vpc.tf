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

resource "aws_internet_gateway" "sample" {
    vpc_id = "${aws_vpc.sample.id}"

    tags {
        Name = "igw-sample-vpc2"
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
        Name = "sample-vpc2:public"
    }
}

resource "aws_route_table_association" "sample_web" {
    subnet_id = "${aws_subnet.sample_web.id}"
    route_table_id = "${aws_route_table.sample_public.id}"
}

# Security Groups

resource "aws_security_group" "sample_web" {
    name = "sample-vpc2:web"
    vpc_id = "${aws_vpc.sample.id}"

    tags {
        Name = "sample-vpc2-sg:web"
    }
}

resource "aws_security_group_rule" "sample_web_out_all" {
    security_group_id = "${aws_security_group.sample_web.id}"
    type = "egress"
    from_port = 0
    to_port = 65535
    protocol = "all"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sample_web_in_ssh" {
    security_group_id = "${aws_security_group.sample_web.id}"
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sample_web_in_http" {
    security_group_id = "${aws_security_group.sample_web.id}"
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "sample_db" {
    name = "sample-vpc2:db"
    vpc_id = "${aws_vpc.sample.id}"

    tags {
        Name = "sample-vpc2-sg:db"
    }
}

resource "aws_security_group_rule" "sample_db_out_all" {
    security_group_id = "${aws_security_group.sample_db.id}"
    type = "egress"
    from_port = 0
    to_port = 65535
    protocol = "all"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "sample_db_in_mysql" {
    security_group_id = "${aws_security_group.sample_db.id}"
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = "${aws_security_group.sample_web.id}"
}

# DB

resource "aws_db_subnet_group" "sample_db_group" {
    name = "sample-vpc2-db-sbg"
    subnet_ids = [
        "${aws_subnet.sample_db1.id}",
        "${aws_subnet.sample_db2.id}"
    ]
}
