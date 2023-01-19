output "k8s_cluster" {
    value = yandex_kubernetes_cluster.k8s_cluster
}

output "k8s_node_group" {
    value = yandex_kubernetes_node_group.node-group-nano-autoscale-1-5
}