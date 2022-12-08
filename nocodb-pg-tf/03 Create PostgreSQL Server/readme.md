# 03 Create PostgreSQL Server
In the end of the game we plan to deploy NocoDB, which is essentially a web app that allows users to easily develop specific types of database apps. NocoDB, despite having DB letters in its name, is not a database management system (DBMS). It is rather an application that simpifies the dialog between the developer and the DBMS, and there should be some 3rd party DBMS underhood. NocoDB supports many DBMS and Postgres is one of them. Postgres is a prominent free open-source DBMS that many people are familiar with. Indeed, Postgres was chosen for this tutorial solely for this reason. Other DBMS supported by Nocodb (such as MariaDB, MySQL, Microsoft SQL Server) are also suitable for this exercise, it's just the matter of preference. 

In this tutorial we will:
- Spawn PostgreSQL Server virtual machine from a container based on the [Postgres image available on Dockerhub](https://hub.docker.com/_/postgres/). To do so we will need the private network to be connected to Internet in order to pull images from Dockerhub (and this is what we have done on the previous step ['02 Create Network'](), when we deployed an *NAT instance*).
- Deploy a docker network on the same virtual machine as Postgres, pull the [pgAdmin Docker image](https://hub.docker.com/r/dpage/pgadmin4/), start another container with pgAdmin, and link it to this network. PgAdmin is a web application for managing Postgres databases.
- Create a persistent storage for the Postgres data, so that data is not lost when the Postgres virtual machine restarts or destroys
- Enable http and ssh connection  to a virtual computer that does not have a public IP address.

## Prerequisites
- You need to have the [02 Create Network]() tutorial completed before starting this one
- Please copy the folder "02 Create Network" into a new project directory. You may use `cp -R  '02 Create Network' '03 Create PostgreSQL Server'` command
- Navigate to `03 Create PostgreSQL Server` directory and run `./dterraform init`
- During completion of [02 Create Network]() tutorial you should have generated  password-less ssh keys. If not yet, use the command below as an example
```
ssh-keygen -C "tutorial"  -f ~/.ssh/tutorial_id_rsa -t rsa -b 4096
```
## Step 3.1 Prepare a dedicated module directory for our database related exercise    
### Step 3.1.1 Inside the *project* directory create a *module* directory and navigate to the same
```
mkdir "postgres" && cd "$_"
```
### Step 3.1.2 Copy the providers.tf file from the project directory to the module directory
```
cp ../providers.tf .
```
## Step 3.2 Create a virtual disk for our PostgreSQL server to store its data
In Yandex Cloud when we create a virtual machine we must specify at least one *boot disk* that will function like a disk drive in the computer. Normally, when you destroy the machine, the boot disk is destroyed as well. It is a bad idea to store the data on the boot disk that is not detachable. Doing so we set ourselves up to lose data permanently every time the virtual machine is destroyed.

To prevent data loss we will create a persistent disk that we will attach to a Postgres virtual machine as a secondary disk that will be detachable. Once created, we will remove the disk from the list of the Terraform managed resources. Thus the disk will not be deleted on `./dterraform destroy` command. Next time we recreate the Postgres virtual machine the disk is attached again. It will only be possible to delete such a disk "manually" using ether Yandex Cloud web-interface or CLI.
### Step 3.2.1 In the module directory create the `pg_data_disk.tf` file with the following content
```
data "yandex_compute_disk" "pg_data_disk" {
  count = var.recreate_data_disk == "none" ? 1 : 0
  name  = "pg-data-disk"
}

data "yandex_compute_snapshot" "pg_data_disk_snapshot" {
  count          = (var.recreate_data_disk == "none" || var.recreate_data_disk == "empty") ? 0 : 1
  name           = var.recreate_data_disk
}

resource "yandex_compute_disk" "pg_data_disk" {
  count       = var.recreate_data_disk == "none" ? 0 : 1
  name        = "pg-data-disk"
  snapshot_id = (var.recreate_data_disk == "none" || var.recreate_data_disk == "empty") ? null : data.yandex_compute_snapshot.pg_data_disk_snapshot.0.id
  type        = "network-hdd"
  size        = var.pg_data_disk_size
  zone        = var.subnet.zone  
} 
```
If the value passed to the module with the variable `var.recreate_data_disk` is equal to *"none"* (which is a default value) then Terraform will look your cloud/folder for a compute disk named "pg-data-disk" and import the same into Terraform state. 
> Passing "empty" as the value for `var.recreate_data_disk` is the assertion that there is a disk named *"pg-data-disk"* in the folder
> Be careful: Terraform will shoot an error if there is no disk with such a name in your folder

If the value of `var.recreate_data_disk` is *"empty"* then Terraform will create a new empty unpartitioned unformatted disk. 
> Passing "empty" as the value for `var.recreate_data_disk` is the assertion that there is no disk named *"pg-data-disk"* in the folder 
> Note that if `var.recreate_data_disk` is not equal to *"none"* and  there is already a disk named "pg-data-disk" in the folder then Terraform will through an error.

If the value of `var.recreate data disk` is anything other than *"empty"* or *"none"*, Terraform will create a disk from a snapshot named the same as the value of this variable."
> Note that passing anything other than *"none"* or to *"empty"* to `var.recreate_data_disk` asserts that there is a disk snapshot object in the YC folder that matches the variable value. If there is no such a snapshot object then Terraform will throw an error   

In the meantime, we want to set the disk size to 20GB, make it the default size, but still let it be changed. We introduce a variable `var.pg_data_disk_size` for this purpose. 

Finally we need to specify the availability zone where we create the disk in. It should be the same as the virtual machine's one. Yandex cloud will not create a virtual machine with a disk from a different availability zone. In one of the next steps we will specify the subnet where our PostgreSQL Server will be created. For a disk we will take the availability zone from this subnet, too. The line `zone = var.subnet.zone` is doing that  
  
### Step 3.2.2 In the *module* directory create the `variables.tf` file with the following content
```
variable "subnet" {
  type = object({id = string, zone = string, v4_cidr_blocks = list(string)})
}

variable "pg_data_disk_size" {
 description = "max size of postgres database and pgadmin data disk"
 type        = number
 default     = 20
}

variable "recreate_data_disk" {
 description = "none - use existing disk; empty - create new empty disk; snapshot - create from snapshot with the name == variable value"
 type        = string
 default     = "none"
}
```
This is a declaration of the two new variables used in `pg_data_disk.tf` as well as setting  "none" as a default value for `recreate_data_disk` variable.

### Step 3.2.3 Edit `variables.tf` in the *project* directory
Append the `recreate_data_disk"` variable declaration in the bottom of the file
```
variable "recreate_data_disk" {
 description = "none - use existing disk; empty - create new empty disk; snapshot - create from snapshot with the name == variable value"
 type        = string
 default     = "none"
```   
We are planning to set different values to this variable on Terraform runs. When we explicitly specify the variable value it is sent to the root module which calls the 'postgres' module with the variable passed along as an argument. Thus, a variable needs to be declared in the root module, too.
### Step 3.2.4 Edit `main.tf` in the *project* directory
Append the following lines in the bottom of a file:
```
module "postgres" {
  source = "./postgres" 
  subnet = module.vpc_subnets.webapp_subnets[0]
  recreate_data_disk = var.recreate_data_disk
}
```
You remember that in the step 3.2.1 we promised to specify the subnet where our PostgreSQL Server will be created. This is what line `subnet = module.vpc_subnets.webapp_subnets[0]` is for.

The line `recreate_data_disk = var.recreate_data_disk` simply passes the value of the variable from `./dterraform apply --var` argument to the `postgres` module.



### Step 3.2.5 Navigate to the project directory and run `./dterraform init` to install the `postgres` module
### Step 3.2.6 Run `./dterraform validate` to check for syntax errors
### Step 3.2.7 Run `yc compute disk get --name pg-data-disk` to check if you already have the disk named *pg-data-disk*
Expeced outcome:
```
ERROR: disk with name "pg-data-disk" not found


client-trace-id: {sanitised}

Use client-trace-id for investigation of issues in cloud support
If you are going to ask for help of cloud support, please send the following trace file: /home/{sanitised}/.config/yandex-cloud/logs/{sanitised}-yc_compute_disk_get.txt
```
### Step 3.2.8 Run `./dterraform apply --auto-approve --var recreate_data_disk="empty"`
The command will return Terraform execution log and a message `Apply complete! Resources: 7 added, 0 changed, 0 destroyed.` followed by a list of outputs

### Step 3.2.9 Run `./dterraform state list`
Expected result:
```
module.postgres.yandex_compute_disk.pg_data_disk[0]
module.vpc_subnets.data.template_file.cloud_config_yaml
module.vpc_subnets.data.yandex_compute_image.nat_instance_ubuntu_image
module.vpc_subnets.yandex_compute_instance.nat_instance_tf
module.vpc_subnets.yandex_vpc_network.vpc
module.vpc_subnets.yandex_vpc_route_table.nat_route_table_tf
module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0]
module.vpc_subnets.yandex_vpc_subnet.webapp_subnets[0]
module.vpc_subnets.yandex_vpc_subnet.webapp_subnets[1]
module.vpc_subnets.yandex_vpc_subnet.webapp_subnets[2]
```
### Step 3.2.10 Run `./dterraform state rm module.postgres.yandex_compute_disk.pg_data_disk[0]`
This command will remove our new disk from the list of Terraform managed resources. Expected outcoe:
```
Removed module.postgres.yandex_compute_disk.pg_data_disk[0]
Successfully removed 1 resource instance(s).
```

### Step 3.2.10 Run `./dterraform destroy --auto-approve` 
Expected outcome:
```
Destroy complete! Resources: 7 destroyed.
```
### Step 3.2.11 Check that our disk still exists in the cloud-folder `yc compute disk get --name pg-data-disk`
Expected outcome:
```
id: {sanitised}
folder_id: {sanitised}
created_at: {sanitised}
name: pg-data-disk
type_id: network-hdd
zone_id: ru-central1-a
size: "21474836480"
block_size: "4096"
status: READY
disk_placement_policy: {}
```
### Step 3.2.10 Run `./dterraform apply --auto-approve`
Here we don't pass any value to `recreate_data_disk` and the module uses the default value which is "none". This time, Terraform will skip the "resource" block and only use the "data" block of the disk configuration (pg_data_disk.tf) to only read information from the existing disk, use its attributes to manage other resources, but never change or destroy the disk itself.

### Step 3.2.11 Run again `./dterraform state list`
Expected result (note that the first line has changed having `.data.` inserted in the middle of the resource reference):
```
module.postgres.data.yandex_compute_disk.pg_data_disk[0]
module.vpc_subnets.data.template_file.cloud_config_yaml
module.vpc_subnets.data.yandex_compute_image.nat_instance_ubuntu_image
module.vpc_subnets.yandex_compute_instance.nat_instance_tf
module.vpc_subnets.yandex_vpc_network.vpc
module.vpc_subnets.yandex_vpc_route_table.nat_route_table_tf
module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0]
module.vpc_subnets.yandex_vpc_subnet.webapp_subnets[0]
module.vpc_subnets.yandex_vpc_subnet.webapp_subnets[1]
module.vpc_subnets.yandex_vpc_subnet.webapp_subnets[2]
```
### Step 3.2.12 Destroy the infrastructure including the disk
We have created an empty unformatted and unpartitioned disk. We have made it persistent, yet it is not enough. What we truly require is a formatted, partitioned disk connected to a PostgreSQL server.

This time, we will destroy everything of our infrastructure, including the disk. In the next steps, we will recreate the disk alongside the PostgreSQL Server virtual machine. 
- Run `./dterraform destroy --auto-approve` to destroy everything but the disk
- Run `yc compute disk delete --name pg-data-disk` to delete the disk from the cloud

### DRAFT PART 


### Step 3.2.3 In the *module* directory create the `outputs.tf` file with the following content
```
output "pg_data_disk_id" {
   description = "Persistent data volume for postgres"
   value       = yandex_compute_instance.pg_docker_instance.secondary_disk[0].disk_id
}
```

### Step 3.2.6 Edit `outputs.tf` in the *project* directory
Append the following lines in the bottom of a file:
```
output "pg_data_disk_id" {
   value = module.postgres.pg_data_disk_id
}
```


## Step 3.2 Copy ssh private key to NAT instance in order to enable access to virtual machines in the private network
The virtual machine we will create in this session will be part of a private network and will not have a public IP address. As a result, we will be unable to immediately ssh into this system from the outside. To enter the network, we will instead ssh into the NAT instance using its public IP address. Then, using the virtual machine's private IP address, we will ssh into it from the NAT instance, i.e. from within the network. This method is sometimes referred to as employing our NAT instance as a *bastion*.

The public part of the ssh key will be uploaded on the Postgres virtual machine during its bootstrapping. We used the `ssh-key` argument of the `metadata` section to instruct this virtual machine to permit ssh access from devices that can supply the private part of the key. NAT instance will become such a device, hence we need to upload the private key into its `~/.ssh/` folder.     
### Step  
     
- `/dterraform apply --auto-approve --var recreate_data_disk="empty"`
- `./dterraform state rm module.postgres.yandex_compute_disk.pg_data_disk[0]`
- `./dterraform destroy --auto-approve`
- `./dterraform apply --auto-approve`
- `ssh -L 31080:10.130.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@<nat_instance_public_ip>`
- browse to http://localhost:31080
- Login and do something in pgadmin
- `yc compute snapshot create --name pg-data-disk-snapshot --disk-name "pg-data-disk`
- `./dterraform destroy --auto-approve`
- `yc compute disk delete --name pg-data-disk`
- `./dterraform apply --auto-approve --var recreate_data_disk="pg-data-disk-snapshot"`
- `ssh -L 31080:10.130.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@<nat_instance_public_ip>`
- browse to http://localhost:31080
- `./dterraform destroy --auto-approve`
- `yc compute snapshot delete --name pg-data-disk-snapshot` 