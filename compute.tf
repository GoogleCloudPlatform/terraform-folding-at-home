# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

####
## Data Sources
####
data "google_compute_image" "image" {
  family = "cos-stable"
  project = "cos-cloud"
}

data "template_file" "cloud-config" {
  vars = {
    fah_worker_image = var.fah_worker_image
    fah_user_name = var.fah_user_name
    fah_passkey = var.fah_passkey
    fah_team_id = var.fah_team_id
    fah_worker_gpu = var.fah_worker_gpu
  }

  template = var.fah_worker_gpu != "" ? file("${path.module}/assets/cloud-config.yaml") : file("${path.module}/assets/cloud-config-no-gpu.yaml")

  
}

####
## Locals
####
locals {
  boot_disk = [
    {
      source_image = data.google_compute_image.image.self_link
      disk_size_gb = "50"
      disk_type    = "pd-standard"
      auto_delete  = true
      boot         = true
    },
  ]

  additional_disks = []

  all_disks = concat(local.boot_disk, local.additional_disks)
}

####
## Instance Template
####
resource "google_compute_instance_template" "mig_template" {
  name_prefix             = "${var.network}-"
  machine_type            = var.fah_worker_type

  can_ip_forward          = false
  metadata_startup_script = ""

  labels                  = {
    "container-vm" = data.google_compute_image.image.name
  }

  metadata = merge(
    var.additional_metadata,
    map("cos-gpu-installer-env", file("${path.module}/cos-gpu-installer/scripts/gpu-installer-env")),
    map("user-data", data.template_file.cloud-config.rendered),
    map("run-installer-script", file("${path.module}/cos-gpu-installer/scripts/run_installer.sh")),
    map("run-cuda-test-script", file("${path.module}/cos-gpu-installer/scripts/run_cuda_test.sh")),
  )

  tags                    = ["fah-worker"]

  dynamic "disk" {
    for_each = local.all_disks
    content {
      auto_delete  = lookup(disk.value, "auto_delete", null)
      boot         = lookup(disk.value, "boot", null)
      device_name  = lookup(disk.value, "device_name", null)
      disk_name    = lookup(disk.value, "disk_name", null)
      disk_size_gb = lookup(disk.value, "disk_size_gb", null)
      disk_type    = lookup(disk.value, "disk_type", null)
      interface    = lookup(disk.value, "interface", null)
      mode         = lookup(disk.value, "mode", null)
      source       = lookup(disk.value, "source", null)
      source_image = lookup(disk.value, "source_image", null)
      type         = lookup(disk.value, "type", null)

      dynamic "disk_encryption_key" {
        for_each = lookup(disk.value, "disk_encryption_key", [])
        content {
          kms_key_self_link = lookup(disk_encryption_key.value, "kms_key_self_link", null)
        }
      }
    }
  }

  dynamic "service_account" {
    for_each = [var.service_account]
    content {
      email  = lookup(service_account.value, "email", null)
      scopes = lookup(service_account.value, "scopes", null)
    }
  }

  network_interface {
    network            = var.create_network ? google_compute_network.default[0].self_link : var.network
    subnetwork         = var.create_network ? google_compute_subnetwork.default[0].self_link : var.subnetwork
    subnetwork_project = var.project
  }

  lifecycle {
    create_before_destroy = true
  }

  scheduling {
    preemptible = true
    on_host_maintenance = "TERMINATE"
    automatic_restart = false
  }

  guest_accelerator {
    type = var.fah_worker_gpu
    count = trimspace(var.fah_worker_gpu) != "" ? 1 : 0
  }
}

####
## Managed Instance Group
####
module "mig" {
  source                    = "terraform-google-modules/vm/google//modules/mig"
  version                   = "~> 2.0.0"
  instance_template         = google_compute_instance_template.mig_template.self_link
  subnetwork_project        = var.project
  region                    = var.region
  distribution_policy_zones = var.zones
  hostname                  = var.network
  target_size               = var.fah_worker_count

  network    = var.create_network ? google_compute_network.default[0].self_link : var.network
  subnetwork = var.create_network ? google_compute_subnetwork.default[0].self_link : var.subnetwork
}
