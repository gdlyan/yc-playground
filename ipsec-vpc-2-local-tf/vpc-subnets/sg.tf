resource "yandex_vpc_security_group" "vpn" {
    name        = "vpn-sg-tf"
    description = "Security group for VPN gateway (Terraform managed)"
    network_id  = yandex_vpc_network.vpc.id

    ingress {
        protocol       = "ANY"
        description    = "Allow traffic between networks on both sides of VPN"
        v4_cidr_blocks = [var.web_front_subnets[0].v4_cidr_blocks.0, var.local_subnet]
        from_port      = 1
        to_port        = 65535
    }

    ingress {
        protocol       = "UDP"
        description    = "UDP on 500 port from 192.168.. network public IP"
        v4_cidr_blocks = ["${var.local_public_ip}/32"]
        port           = 500
    }

    ingress {
        protocol       = "UDP"
        description    = "UDP on 4500 port from 192.168.. network public IP"
        v4_cidr_blocks = ["${var.local_public_ip}/32"]
        port           = 4500
    } 

    ingress {
        protocol       = "TCP"
        description    = "Allow ssh to upload config files"
        v4_cidr_blocks = ["0.0.0.0/0"]
        port           = 22
    }      

    egress {
        protocol       = "ANY"
        description    = "Allow traffic between networks on both sides of VPN"
        v4_cidr_blocks = [var.web_front_subnets[0].v4_cidr_blocks.0, var.local_subnet]
        from_port      = 1
        to_port        = 65535
    }

    egress {
        protocol       = "UDP"
        description    = "UDP on 500 port to 192.168.. network public IP"
        v4_cidr_blocks = ["${var.local_public_ip}/32"]
        port           = 500
    }

    egress {
        protocol       = "UDP"
        description    = "UDP on 4500 port to 192.168.. network public IP"
        v4_cidr_blocks = ["${var.local_public_ip}/32"]
        port           = 4500
    }      
}

#######################################
resource "yandex_vpc_security_group" "app" {
    name        = "app-sg-tf"
    description = "Security group for app (Terraform managed)"
    network_id  = yandex_vpc_network.vpc.id

    ingress {
        protocol       = "TCP"
        description    = "Allow http traffic from within the VPN"
        v4_cidr_blocks = ["0.0.0.0/0"]
        port           = 80
    }

    ingress {
        protocol       = "TCP"
        description    = "Allow https traffic from within the VPN"
        v4_cidr_blocks = ["0.0.0.0/0"]
        port           = 443
    }  

    ingress {
        protocol       = "TCP"
        description    = "Allow ssh from within the VPN"
        v4_cidr_blocks = [var.web_front_subnets[0].v4_cidr_blocks.0, var.local_subnet]
        port           = 22
    }   

    ingress {    
        description       = "Allow any ingress traffic from VMs in this security group"
        protocol          = "ANY"  
        from_port         = 0
        to_port           = 65535    
        predefined_target = "self_security_group" 
    }  

    ingress {    
        description       = "Allow load balancer health checks"
        port              = 80
        protocol          = "ANY"
        predefined_target = "loadbalancer_healthchecks"
    }   

    egress {    
        description       = "Allow egress traffic to Postgres MDB"
        port              = 6432
        protocol          = "TCP"
        security_group_id = yandex_vpc_security_group.postgres.id
    }   

    egress {    
        description       = "Allow http access to Dockerhub "
        port              = 80
        protocol          = "TCP"
        v4_cidr_blocks    = ["0.0.0.0/0"]
    }   

    egress {    
        description       = "Allow https access to Dockerhub "
        port              = 443
        protocol          = "TCP"
        v4_cidr_blocks    = ["0.0.0.0/0"]
    }   

    egress {    
        description       = "Allow any egress traffic to VMs in this security group"
        protocol          = "ANY"  
        from_port         = 0
        to_port           = 65535    
        predefined_target = "self_security_group" 
    }   

}


#######################################
resource "yandex_vpc_security_group" "postgres" {
    name        = "pgmdb-sg-tf"
    description = "Security group for Postgres MDB (Terraform managed)"
    network_id  = yandex_vpc_network.vpc.id

    ingress {    
        description       = "Postgress allows incoming traffic from app on 6432"
        port              = 6432
        protocol          = "TCP"
        v4_cidr_blocks    = [for s in var.webapp_subnets: s.v4_cidr_blocks[0]]
    }
}

#######################################
resource "yandex_vpc_security_group" "proxy" {
    name        = "proxy-sg-tf"
    description = "Security group for app (Terraform managed)"
    network_id  = yandex_vpc_network.vpc.id

    ingress {
        protocol       = "TCP"
        description    = "Allow http traffic from outside"
        v4_cidr_blocks = ["0.0.0.0/0"]
        port           = 80
    }

    ingress {
        protocol       = "TCP"
        description    = "Allow https traffic from outside"
        v4_cidr_blocks = ["0.0.0.0/0"]
        port           = 443
    }  

    ingress {
        protocol       = "TCP"
        description    = "Allow ssh to upload config files"
        v4_cidr_blocks = ["0.0.0.0/0"]
        port           = 22
    }  
    egress {    
        description       = "Allow http access to Dockerhub "
        port              = 80
        protocol          = "TCP"
        v4_cidr_blocks    = ["0.0.0.0/0"]
    }   

    egress {    
        description       = "Allow https access to Dockerhub"
        port              = 443
        protocol          = "TCP"
        v4_cidr_blocks    = ["0.0.0.0/0"]
    }   

    egress {    
        description       = "Allow any egress traffic to VMs inside VPN"
        protocol          = "ANY"  
        from_port         = 0
        to_port           = 65535    
        v4_cidr_blocks    = [var.web_front_subnets[0].v4_cidr_blocks.0, var.local_subnet]
    }    
}