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
## VPC
####
resource "google_compute_network" "default" {
  count                   = var.create_network ? 1 : 0
  name                    = var.network
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  count                    = var.create_network ? 1 : 0
  name                     = var.subnetwork
  ip_cidr_range            = var.subnetwork_cidr
  region                   = var.region
  network                  = var.create_network ? google_compute_network.default[0].self_link : var.network
  private_ip_google_access = true
}

####
## Router & Cloud NAT
####
resource "google_compute_router" "default" {
  name    = "${var.network}-nat-router"
  network = var.create_network ? google_compute_network.default[0].self_link : var.network
  region  = var.region
}
module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.2"
  name       = "${var.network}-cloud-nat-gw"
  router     = google_compute_router.default.name
  project_id = var.project
  region     = var.region
}

####
## Firewall Rules
####
resource "google_compute_firewall" "allow_internal" {
  name    = "network-allow-internal"
  network = var.create_network ? google_compute_network.default[0].self_link : var.network

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnetwork_cidr]
}

resource "google_compute_firewall" "allow_iap" {
  name    = "network-allow-iap"
  network = var.create_network ? google_compute_network.default[0].self_link : var.network

  allow {
    protocol = "tcp"
    ports    = ["22", "7396"]
  }

  source_ranges = ["35.235.240.0/20"] # IAP's TCP forwarding IP addresses
}
