# Routing through a NAT instance
Terraform  config for automation of [Routing through a NAT instance](https://cloud.yandex.com/en-ru/docs/tutorials/routing/nat-instance) tutorial @ Yandex Cloud

## Requirements
- Linux / MacOS / Windows with WSL2 machine connected to Internet
- Docker and optionally Compose
- A pair of ssh keys whereas a public key would be uploaded to the provisioned virtual machinesNAT instance 
- Yandex Cloud account that has a payment method activated, [see how-to](https://cloud.yandex.com/en-ru/docs/billing/operations/create-new-account)
- Yandex cloud CLI installed with `curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash` and initialized with `yc init` as explained in the [Getting started with the YC CLI manual](https://cloud.yandex.com/en-ru/docs/cli/quickstart). 
- You will need to create a file `./terraform.tfvars` with the following content:
```
token             = "<Yandex Cloud OAuth token, available from `yc config list` command>"
cloud_id          = "<ID of the cloud where the VPC would be spawned, available from `yc config list` command"
folder_id         = "<ID of the folder where the VPC would be spawned, available from `yc config list` command>"
default_user      = "non-root user to be created on the target VMs, defaulted to `ubuntu`"
private_key_file  = "not passphrase-encrypted private key file located in `~./ssh` directory, defaulted to `id_rsa`"
```

## Directory content
- `.terraformrc` directing Terraform registry requests to [Yandex mirror](https://terraform-mirror.yandexcloud.net/) 
- `./dterraform` shell file that spawns a container from Terraform image available on Docker Hub. Thus one does not have to install Terraform locally as the Docker wrapper will do the job 
- `*.tf` infrastructure blueprint itself

## Basic usage
### 1. On a first run execute
```
./dterraform init
```
This will pull Terraform image from Docker Hub, spawn the Terraform container and install the required Terraform providers
### 2. To create infrastructure such as VPC, subnets, VMs and their network interfaces run
```
./dterraform apply -auto-approve
```
This will create a Virtual Private Cloud (VPC) and two subnets - the public and the private ones. In each of those subnets a low-tier Ubuntu VM will be spawned. 
- The instance provisioned in the public subnet will be assigned with a dynamic public IP address and be accessible via `ssh -i ~/.ssh/<private_key_file> <default_user>@<public IP>`. This is NAT Instance which also serves as bastion host that allows `ssh` access to the instances isolated from the public internet within a VPC, such as the following one
- The instance provisioned in the private subnet will not have any public IP address and will only be accessible via `ssh` from NAT instance. However this instance would allow internet traffic via NAT instance, for example, to install packages from package managers and test connections.   This is test instance 

The result would look like the one below if it worked:
```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

Outputs:

nat_instance_public_ip = "<public IP>"
test_instance_private_ip = "<private IP>"
vpc_name = "nat-instance-vpc-tf"
```
> **!!! PLEASE DON'T FORGET TO DESTROY THE INFRASTRUCTURE WHEN YOU ARE DONE !!!**
> 
> *Note that since this very moment the platform starts charging you for the provisioned infrastructure. The amount should not be dramatic as the VMs are provisioned preemptible and at minimal configuration. Still be sure to destroy the infrastructure when you figure out you no longer need it for your experiments (see the last step with `./dterraform destroy -auto-approve` command).*

### 4. Explore the provisioned infrastructure  
- Run `./dterraform output` to view once again the public IP of the provisioned virtual machines
- Ssh into the NAT Instance using `ssh -i ~/.ssh/<private_key_file> <default_user>@<public IP>`
- From the NAT instance ssh into test instance using `ssh <private IP>`, use the password `nobodyknows`
- On the test instance run `curl ifconfig.co`. ou should get the `<Public IP>` as the outcome
- Use `exit` command to eit both test an NAT instances

### 5. Destroy infrastructure if you no longer need it
Run `./dterraform destroy -auto-approve` and look into [cloud console](https://console.cloud.yandex.ru/) to ensure that no unnecessary infrastructure is causing unexpected charges 

Also time to time run `docker container prune` command to remove the exited containers 


