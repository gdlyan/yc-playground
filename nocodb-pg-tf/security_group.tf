resource "yandex_vpc_security_group" "vpn_sg" {
  name        = "web-service-vpn-sg"
  description = "Security group for tunelling between remote site and isolated subnets of ${yandex_vpc_network.web_service_vpc_tf.name}"
  network_id  = "${yandex_vpc_network.web_service_vpc_tf.id}"

  egress {    
    description    = "Egress UDP traffic from port 500"
    port           = 500
    protocol       = "UDP"
    v4_cidr_blocks = ["${yandex_compute_instance.ipsec_instances.0.network_interface.0.nat_ip_address}/32"]    
  }

  egress {    
    description    = "Egress UDP traffic from port 4500"
    port           = 4500
    protocol       = "UDP"
    v4_cidr_blocks = ["${yandex_compute_instance.ipsec_instances.0.network_interface.0.nat_ip_address}/32"]    
  }

  egress {    
    description    = "Allow all egress traffic between VPC and remote site"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8", "192.168.100.0/24"]    
  }  

  ingress {    
    description    = "Ingress UDP traffic to port 500"
    port           = 500
    protocol       = "UDP"
    v4_cidr_blocks = ["${yandex_compute_instance.ipsec_instances.0.network_interface.0.nat_ip_address}/32"]    
  }

  ingress {    
    description    = "Ingress UDP traffic to port 4500"
    port           = 4500
    protocol       = "UDP"
    v4_cidr_blocks = ["${yandex_compute_instance.ipsec_instances.0.network_interface.0.nat_ip_address}/32"]    
  }

  ingress {    
    description    = "Allow all ingress traffic between VPC and remote site"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.0.0.0/8", "192.168.100.0/24"]    
  }  
}

resource "yandex_vpc_security_group" "web_service_sg" {
  name        = "web-service-sg"
  description = "Security group for restriction of traffic in ${yandex_vpc_network.web_service_vpc_tf.name}"
  network_id  = "${yandex_vpc_network.web_service_vpc_tf.id}"

  egress {    
    description       = "Allow any egress traffic to VMs in this security group"
    protocol          = "ANY"   
    predefined_target = "self_security_group"
  }

  ingress {    
    description       = "Allow any ingress traffic from VMs in this security group"
    protocol          = "ANY"  
    predefined_target = "self_security_group" 
  }  

  ingress {    
    description    = "Allow http from anywhere"
    port           = 80
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]    
  }

  ingress {    
    description    = "Allow https from anywhere"
    port           = 443
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]    
  }  

  ingress {    
    description    = "Allow ssh from anywhere"
    port           = 443
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]    
  }

  ingress {    
    description       = "Allow load balancer health checks"
    port              = 80
    protocol          = "ANY"
    predefined_target = "loadbalancer_healthchecks"
       
  }

}