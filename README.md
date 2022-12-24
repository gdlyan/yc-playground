# yc-playground
A collection of sample [Terraform](https://www.terraform.io/) configurations &amp; [Ansible](https://github.com/ansible/ansible) playbooks for various infrastructure and application bootstrapping scenarios using Yandex Cloud platform 

## Contents
Each subdirectory in this repository contains the configuration files for a specific scenario
- [Routing through a NAT instance](https://github.com/gdlyan/yc-playground/tree/master/nat-instance-tf)
- [Swarm Routing Mesh Demo](https://github.com/gdlyan/yc-playground/tree/master/docker-swarm-tf)
- [Tutorial on Provisioning Basic NocoDB Stack](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf)

All the configurations are tailored for quickstart. The user does not need to install and configure Terraform and Ansible packages locally because each example comes with shell files, such as `./dterraform` and occasionally `./dansible-playbook`, that use "docker run" to run Terraform and Ansible within containers. To make the full setup work, you only need to have Docker installed. While aware that such a setup is not advised for use in production, this is done on purpose.

Additionally, if Terraform and Ansible are already installed locally, you can use the standard Terraform and Ansible instructions instead.

## Requirements
- Linux / MacOS / Windows with WSL2 machine connected to Internet
- Docker and optionally Compose
- Yandex Cloud account that has a payment method activated, [see how-to](https://cloud.yandex.com/en-ru/docs/billing/operations/create-new-account)
- Yandex cloud CLI installed with `curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash` and initialized with `yc init` as explained in the [Getting started with the YC CLI manual](https://cloud.yandex.com/en-ru/docs/cli/quickstart). 
- A pair of ssh keys whereas a public key would be uploaded to the provisioned virtual machines. Please note that `./dansible-playbook` will fail with passphrase protected keys, this is a known issue. The workaround is either to avoid passphrase-encrypted private keys or to have Ansible installed locally and use regular `ansible-playbook` command  
- You will need to create a file `./terraform.tfvars` with the following content:
```
token             = "<Yandex Cloud OAuth token, available from `yc config list` command>"
cloud_id          = "<ID of the cloud where the VPC would be spawned, available from `yc config list` command"
folder_id         = "<ID of the folder where the VPC would be spawned, available from `yc config list` command>"
default_user      = "non-root user to be created on the target VMs, defaulted to `ubuntu`"
private_key_file  = "not passphrase-encrypted private key file located in `~./ssh` directory, defaulted to `id_rsa`"
```

## Basic usage
### 1. Navigate to the desired subdirectory and execute the following command once
```
./dterraform init
```
This will pull Terraform image from Docker Hub, spawn the Terraform container and install the required Terraform providers
### 2. Create infrastructure such as VPC, subnets, VMs and their network interfaces run
```
./dterraform apply -auto-approve
```
### 3. Run the Ansible plays that deploy additional packages and configurations to provisioned instances, if applicable
```
./dansible-playbook -i <playbook>.yml
```
### 4. Explore and test the scenario
The details of this step are determined by the scenario 
### 5. Destroy infrastructure if you no longer need it
Run `./dterraform destroy -auto-approve` and look into [cloud console](https://console.cloud.yandex.ru/) to ensure that no unnecessary infrastructure is causing unexpected charges 

Also time to time run `docker container prune` command to remove the exited containers as you will unlikely need them any more 


