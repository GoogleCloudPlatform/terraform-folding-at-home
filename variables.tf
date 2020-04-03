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

variable "project" {
  description = "Project ID for Folding@home deployment"
}

variable "region" {
  description = "Region to deploy in"
}

variable "zones" {
  description = "Which zone(s) to deploy resources in"
  type = list(string)
  default = []
}

variable "fah_team_id" {
  description = "Team id for Folding@home client"
  type        = number
  default     = 446
}

variable "fah_user_name" {
  description = "User name for Folding@home client"
  type        = string
  default     = "Anonymous"
}

variable "fah_passkey" {
    description = "Passkey for Folding@home user"
    type        = string
    default      = ""
}

variable "fah_worker_image" {
  description = "Docker image to use for Folding@home client"
  type        = string
  default     = "stefancrain/folding-at-home:latest"
}

variable "fah_worker_count" {
  description = "Number of Folding@home clients"
  type        = number
  default     = 3
}

variable "fah_worker_type" {
  description = "Machine type of Folding@home client"
  type        = string
  default     = "n1-highcpu-8"
}

variable "fah_worker_gpu" {
  description = "GPU model to be used by each Folding@home client. Empty string for none"
  type        = string
  default     = "nvidia-tesla-t4"
}

variable "network" {
  description = "Network to create resources in"
  default = "fah-network"
}
variable "subnetwork" {
  description = "Subnet to create resources in"
  default = "fah-subnetwork"
}

variable "subnetwork_cidr" {
  description = "Subnet CIDR to create resources in"
  default = "192.168.0.0/16"
}

variable "create_network" {
  description = "Create new network (true or false)"
  type = bool
  default = true
}

variable "service_account" {
  type = object({
    email  = string,
    scopes = list(string)
  })
  default = {
    email  = ""
    scopes = ["cloud-platform"]
  }
}

variable "additional_metadata" {
  type        = map
  description = "Additional metadata to attach to the instance"
  default     = {}
}
