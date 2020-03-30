# Terraform Template for Folding@home on GCP

Folding@home is simulating the dynamics of COVID-19 proteins to hunt for new therapeutic opportunities.
This template is provided to easily run Folding@home on Google Cloud, and help increase number of simulations done.
You can use this Terraform script to automatically deploy one or more Folding@home clients on GCP, which is described in this step-by-step codelab (TODO link). The template creates the instance template with the Folding@home binaries, a managed instance group to uniformly deploy as many clients as specified by user, network firewall rules, and a Cloud NAT gateway for internet access without requiring public IPs, all in an existing or newly created network as specified by user.

This is not an officially supported Google product. Terraform templates for Folding@home are developer and community-supported. Please don't hesitate to open an issue or pull request.

TODO: Fix link whenever repo is approved to be moved to Github

[![button](http://gstatic.com/cloudssh/images/open-btn.png)](https://console.cloud.google.com/cloudshell/open?git_repo=https://source.cloud.google.com/arsan-dev/terraform-folding-at-home&page=shell&tutorial=README.md)

### Prerequisites
* GCP Project to deploy to.
* Optional: Existing network to deploy resources into.

### Configurable Parameters

Parameter | Description | Default
--- | --- | ---
project | Id of the GCP project to deploy to. | Default provider project.
region | Region for cloud resources | 
zones | One or more zones for cloud resources. | If not set, up to three zones in the region are used depending on number of instances
create_network | Boolean to create a new network | true
network | Network to deploy resources into. It is either: <br>1. Arbitrary Network name if create_network is set to true  <br>2. Existing network name if create_network is set to false | fah_network
subnetwork | Subnetwork to deploy resources into It is either: <br>1. Arbitrary subnetwork name if create_network is set to true  <br>2. Existing subnetwork name if create_network is set to false | fah-subnetwork
subnetwork_cidr | CIDR range of subnetwork | 192.168.0.0/16
fah_worker_image | Docker image to use for Folding@home client | stefancrain/folding-at-home:latest
fah_worker_count | Number of Folding@home clients or GCE instances | 3
fah_worker_type | Machine type to run Folding@home client on | n2-highcpu-8
fah_team_id | Team id for Folding@home client | 446
fah_user_name | User name for Folding@home client | Anonymous


### Getting Started

#### Requirements
* Terraform 0.12+

#### Setup working directory

1. Copy placeholder vars file `variables.yaml` into new `terraform.tfvars` to hold your own settings.
2. Update placeholder values in `terraform.tfvars` to correspond to your GCP environment and desired Folding@home settings. See [list of input parameters](#configurable-parameters) above.
3. Initialize Terraform working directory and download plugins by running `terraform init`.

#### Deploy Folding@home instances

```shell
$ terraform plan
$ terraform apply
```

#### Access Folding@home process

Once Terraform completes:

1. Confirm Folding@home instance group has been created with correct number of instances
  * Navigate to Compute Enginer -> Instance groups: `https://console.cloud.google.com/compute/instanceGroups/list`
  * Click on the newly created instance group to view its details
  * Confirm number of instances created. Take note of one the instances names and corresponding zone

2. Access one of the new instances via CLI.
  * First, make sure you have IAP SSH permissions for your instances by [following these instructions](https://cloud.google.com/nat/docs/gce-example#step_4_create_ssh_permissions_for_your_test_instance)
  * Type `gcloud compute ssh [INSTANCE_NAME] --zone [INSTANCE_ZONE]` to SSH to the instance you took note previously. Since instances are created without external IP, this will default to using IAP access.

3. View Folding@home container logs
  * Once logged in, retrieve container name via `docker ps`
  * Type `docker logs -tf [CONTAINER_NAME]` to tail the logs and confirm its operation
 
### TODOs

* Fix GPU passthrough. Example error: `No compute devices matched GPU #0 NVIDIA:7 TU104GL [Tesla T4].  You may need to update your graphics drivers.`
* Fix logging to Stackdriver for quick monitoring & troubleshooting
* Scale down to 1 when no jobs available
* Scale down to 0 when no jobs available for extended time. Spin back up periodically.

### Support

This is not an officially supported Google product. Terraform templates for Folding@home are developer and community-supported. Please don't hesitate to open an issue or pull request.

### Copyright & License

Copyright 2020 Google LLC

Terraform templates for Folding@home are licensed under the Apache license, v2.0. Details can be found in [LICENSE](./LICENSE) file.
