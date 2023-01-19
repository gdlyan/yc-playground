resource "yandex_iam_service_account" "k8s_resources_sa" {
  name        = "k8s-resources-sa"
  description = "service account with the editor role for creating resources"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor_account_iam" {
  folder_id   = var.folder_id
  role        = "editor"
  members     = [
    "serviceAccount:${yandex_iam_service_account.k8s_resources_sa.id}",
  ]
}

resource "yandex_iam_service_account" "k8s_nodes_sa" {
  name        = "k8s-nodes-sa"
  description = "service account with the container-registry.images.puller role that nodes will use to access the Docker image registry"
}

resource "yandex_resourcemanager_folder_iam_binding" "image_puller_account_iam" {
  folder_id   = var.folder_id
  role        = "container-registry.images.puller"
  members     = [
    "serviceAccount:${yandex_iam_service_account.k8s_nodes_sa.id}",
  ]
}