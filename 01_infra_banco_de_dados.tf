//prvedor e região escolhida//

provider "aws" {
  region = "us-east-2"
}

//nuvem privada virtual, sub-redes, Internet Gateway//

resource "aws_vpc" "italo_vpc" {
  cidr_block                       = "10.0.0.0/16"
  assign_generated_ipv6_cidr_block = false
  enable_dns_support               = true
  enable_dns_hostnames             = true
  instance_tenancy                 = "default"

  tags = {
    "Name" = "Main VPC"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.italo_vpc.id

  tags = {
    "Name" = "Main Internet Gateway"
  }
}


resource "aws_route_table" "rota" {
  vpc_id = aws_vpc.italo_vpc.id

  tags = {
    "Name" = "Public Route Table"
  }
}

resource "aws_route" "route_to_igw" {
  route_table_id         = aws_route_table.rota.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.italo_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    "Name" = "public_subnet_a"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.italo_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    "Name" = "public_subnet_b"
  }
}

resource "aws_route_table_association" "rota_s_g" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.rota.id
}


resource "aws_security_group" "banco_S_G" {
  name        = "banco_psql_sg"
  description = "permitir trafego"
  vpc_id      = aws_vpc.italo_vpc.id

  tags = {
    "Name" = "SG de bancos PostgreSQL"
  }
}

resource "aws_security_group_rule" "db_sg_ingress" {
  security_group_id = aws_security_group.banco_S_G.id
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_db_subnet_group" "db_sn_group" {
  name       = "terraform db subnet group"
  subnet_ids = [aws_subnet.public_subnet_a.id, aws_subnet.private_subnet_b.id]

  tags = {
    "Name" = "terraform db subnet group"
  }
}

resource "aws_cloudwatch_log_group" "dbcldwatch_log" {
  name              = "mydb_cloudwatch_log"
  retention_in_days = 90
}

//banco de dados com suas espeficações e sua replica//
//obs: ele fica publico só até eu preencher as colunas//

resource "aws_db_instance" "banco" {
  allocated_storage               = 10
  engine                          = "postgres"
  engine_version                  = "12.5"
  instance_class                  = "db.t2.micro"
  multi_az                        = true
  performance_insights_enabled    = true
  backup_retention_period         = 10
  backup_window                   = "21:00-22:00"
  name                            = "banco"
  username                        = "admini"
  password                        = "05060708"
  db_subnet_group_name            = aws_db_subnet_group.db_sn_group.name
  enabled_cloudwatch_logs_exports = ["postgresql"]
  port                            = 5432
  publicly_accessible             = true
  skip_final_snapshot             = true
  vpc_security_group_ids          = [aws_security_group.banco_S_G.id]

  tags = {
    "Name" = "Terraform Test DB"
  }
}


resource "aws_db_instance" "postgresql-read-replica" {
  replicate_source_db    = aws_db_instance.banco.id
  name                   = "banco2"
  instance_class         = "db.t2.micro"
  publicly_accessible    = true
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.banco_S_G.id]

  tags = {
    "Name" = "Terraform Replica DB"
  }
}
