output "nlb_instance_private_ip" {
   description = "Private IP of network load balancer"
   value       = [for s in yandex_lb_network_load_balancer.nlb.listener: s.internal_address_spec.*.address].0[0]
}

output "nocodb_instances" {
  value = [for s in yandex_compute_instance_group.nocodb_instances.instances: {"ip_address": s.network_interface.0.ip_address,
                                                                               "id": s.instance_id, 
                                                                               "zone": s.zone_id}] 
}