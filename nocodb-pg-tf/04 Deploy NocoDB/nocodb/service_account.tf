resource "yandex_iam_service_account" "nocodb_manager_sa" {
  name        = "nocodb-manager-sa"
  description = "service account to manage VMs"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor_account_iam" {
  folder_id   = var.folder_id
  role        = "editor"
  members     = [
    "serviceAccount:${yandex_iam_service_account.nocodb_manager_sa.id}",
  ]
}