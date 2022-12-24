# 03 Create PostgreSQL Server
In the end of the game we plan to deploy NocoDB, which is essentially a web app that allows users to easily develop specific types of database apps. NocoDB, despite having DB letters in its name, is not a database management system (DBMS). It is rather an application that simpifies the dialog between the developer and the DBMS, and there should be some 3rd party DBMS underhood. NocoDB supports many DBMS and Postgres is one of them. Postgres is a prominent free open-source DBMS that many people are familiar with. Indeed, Postgres was chosen for this tutorial solely for this reason. Other DBMS supported by Nocodb (such as MariaDB, MySQL, Microsoft SQL Server) are also suitable for this exercise, it's just the matter of preference. 

In this tutorial we will:
- Spawn PostgreSQL Server virtual machine from a container based on the [Postgres image available on Dockerhub](https://hub.docker.com/_/postgres/). To do so we will need the private network to be connected to Internet in order to pull images from Dockerhub (and this is what we have done on the previous step ['02 Create Network'](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/02%20Create%20Network), when we deployed an *NAT instance*).
- Deploy a docker network on the same virtual machine as Postgres, pull the [pgAdmin Docker image](https://hub.docker.com/r/dpage/pgadmin4/), start another container with pgAdmin, and link it to this network. PgAdmin is a web application for managing Postgres databases.
- Create a persistent storage for the Postgres data, so that data is not lost when the Postgres virtual machine restarts or destroys
- Enable http and ssh connection  to a virtual computer that does not have a public IP address.

## Prerequisites
- You need to have the [02 Create Network](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/02%20Create%20Network) tutorial completed before starting this one
- Please copy the folder "02 Create Network" into a new project directory. You may use `cp -R  '02 Create Network' '03 Create PostgreSQL Server'` command
- Navigate to `'03 Create PostgreSQL Server'` directory and run `./dterraform init`
- During completion of [02 Create Network](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/02%20Create%20Network) tutorial you should have generated  password-less ssh keys. If not yet, use the command below as an example
```
ssh-keygen -C "tutorial"  -f ~/.ssh/tutorial_id_rsa -t rsa -b 4096
```
## Step 3.1 Prepare a dedicated module directory for our database related exercise    
### Step 3.1.1 Inside the *project* directory create a *module* directory and navigate to the same
```
mkdir "postgres" && cd "$_"
```
### Step 3.1.2 Create the `providers.tf` for the `postgres` module
On top of the `yandex` provier we will be using the `template` provider in this module. So the `./postgres/providers.tf` file content should be as follows:
```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }  
    template = {
      source = "hashicorp/template"
      version = ">= 2.2.0"
    }            
  }
  required_version = ">= 0.13"
}
```
## Step 3.2 Create a virtual disk for our PostgreSQL server to store its data
In Yandex Cloud when we create a virtual machine we must specify at least one *boot disk* that will function like a disk drive in the computer. Normally, when you destroy the machine, the boot disk is destroyed as well. It is a bad idea to store the data on the boot disk that is not detachable. Doing so we set ourselves up to lose data permanently every time the virtual machine is destroyed.

To prevent data loss we will create a persistent disk that we will attach to a Postgres virtual machine as a secondary disk that will be detachable. Once created, we will remove the disk from the list of the Terraform managed resources. Thus the disk will not be deleted on `./dterraform destroy` command. Next time we recreate the Postgres virtual machine the disk is attached again. It will only be possible to delete such a disk "manually" using either Yandex Cloud web-interface or CLI.
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
> 
> Be careful: Terraform will shoot an error if there is no disk with such a name in your folder

If the value of `var.recreate_data_disk` is *"empty"* then Terraform will create a new empty unpartitioned unformatted disk. 
> Passing "empty" as the value for `var.recreate_data_disk` is the assertion that there is no disk named *"pg-data-disk"* in the folder 
> 
> Note that if `var.recreate_data_disk` is not equal to *"none"* and  there is already a disk named "pg-data-disk" in the folder then Terraform will throw an error.

If the value of `var.recreate data disk` is anything other than *"empty"* or *"none"*, Terraform will create a disk from a snapshot named the same as the value of this variable."
> Note that passing anything other than *"none"* or to *"empty"* to `var.recreate_data_disk` asserts that there is a disk snapshot object in the Yandex Cloud folder that matches the variable value. If there is no such a snapshot object then Terraform will throw an error, too   

In the meantime, we want to set the disk size to 20GB, make it the default size, but still let it be changed. We introduce a variable `var.pg_data_disk_size` for this purpose. 

Finally we need to specify the availability zone where we create the disk in. It should be the same as the virtual machine's one. Yandex cloud will not create a virtual machine with a disk from a different availability zone. In one of the next steps we will specify the subnet where our PostgreSQL Server will be created. For a disk we will take the availability zone from this subnet, too. The line `zone = var.subnet.zone` is doing that  
  
### Step 3.2.2 In the `postgres` *module* directory create the `postgres/variables.tf` file with the following content
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

### Step 3.2.3 Edit `variables.tf` in the *root module* directory
Append the `recreate_data_disk"` variable declaration in the bottom of the file
```
variable "recreate_data_disk" {
 description = "none - use existing disk; empty - create new empty disk; snapshot - create from snapshot with the name == variable value"
 type        = string
 default     = "none"
```   
We are planning to set different values to this variable on Terraform runs. When we explicitly specify the variable value it is sent to the root module which calls the 'postgres' module with the variable passed along as an argument. Thus, a variable needs to be declared in the root module, too.
### Step 3.2.4 Edit `main.tf` in the *root module* directory
Append the following lines in the bottom of a file:
```
module "postgres" {
  source = "./postgres" 
  subnet = module.vpc_subnets.webapp_subnets[0]
  recreate_data_disk = var.recreate_data_disk
}
```
You remember that in the step 3.2.1 we promised to specify the subnet where our PostgreSQL Server will be created. This is what line `subnet = module.vpc_subnets.webapp_subnets[0]` is for.

The line `recreate_data_disk = var.recreate_data_disk` simply passes the value of the variable from `./dterraform apply --var recreate_data_disk="{argument}"` argument to the `postgres` module.



### Step 3.2.5 Navigate to the *root module* directory and run `./dterraform init` to install the `postgres` module
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
The command will stream Terraform execution ending up with a message `Apply complete! Resources: 7 added, 0 changed, 0 destroyed.` followed by a list of outputs

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
The first line shows that the disk is up and is managed by Terraform. But if we run  `./dterraform destroy` we will destroy the disk as well which is not what we want to happen. Next step is going to fix this.  
### Step 3.2.10 Run `./dterraform state rm module.postgres.yandex_compute_disk.pg_data_disk[0]`
This command will remove our new disk from the list of Terraform managed resources. Expected outcome:
```
Removed module.postgres.yandex_compute_disk.pg_data_disk[0]
Successfully removed 1 resource instance(s).
```
### Step 3.2.10 Run `./dterraform destroy --auto-approve` 
Expected outcome:
```
Destroy complete! Resources: 7 destroyed.
```
Terraform has removed from the cloud all the resources that are on its state list and have no `.data.` in their definition. Our disk is no longer on the state list after the previous step. Therefore it should not be deleted.   
### Step 3.2.11 Check that our disk still exists in the cloud/folder `yc compute disk get --name pg-data-disk`
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

## Step 3.3 Copy ssh private key to NAT instance in order to enable access to virtual machines in the private network
The virtual machine we will create in this session will be part of a private network and will not have a public IP address. We will be unable to directly ssh into this system from the outside. To enter the network, we will instead ssh into the NAT instance using its public IP address. Then, using the virtual machine's private IP address, we will ssh into it from the NAT instance, i.e. from within the network. This method is sometimes referred to as employing our NAT instance as a *bastion*.

The public part of the ssh key will be uploaded on the Postgres virtual machine during its bootstrapping. We used the `ssh-key` argument of the `metadata` section to instruct this virtual machine to permit ssh access from devices that can supply the private part of the key. NAT instance will become such a device, hence we need to upload the private key into its `~/.ssh/` folder.

### Step 3.3.1 Navigate to the `vpc-subnets` module diretory and edit the `nat_instance.tf` file
Append the following lines in the bottom of the file:
```
## Copy ssh-keys to use this NAT instance as ssh bastion
resource "null_resource" "copy_ssh_key" {
  depends_on = [yandex_compute_instance.nat_instance_tf]
# Connection Block for Provisioners to connect to VM Instance
  connection {
    type = "ssh"
    host = yandex_compute_instance.nat_instance_tf.network_interface.0.nat_ip_address
    user = var.default_user
    private_key = file("~/.ssh/${var.private_key_file}")
  }

## File Provisioner: Copies the private key file to NAT instance
  provisioner "file" {
    source      = "~/.ssh/${var.private_key_file}"
    destination = "/home/${var.default_user}/.ssh/${var.private_key_file}"
  }
## Remote Exec Provisioner: fix the private key permissions on NAT instance
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /home/${var.default_user}/.ssh/${var.private_key_file}"
    ]
  }
}
``` 
Here we use Terraform *provisioner*  blocks to copy files to and execute shell commands on the remote instance. 

> When we write a Terraform script, we are effectively specifying a list of Terraform managed *resources*. Each class of resources has a *provider*, which is a program that tells Terraform what it can do with the resources of this class. Most commonly, providers tell Terraform to manage (i.e. to create or delete) some specific piece of infrastructure in the cloud, such as a network, subnet, route table, compute instance etc. But this is not the only use case for resources.
> 
> Sometimes we presume that there is some infrastructure in the cloud that we don't want to create or delete. Still we want to read its properties in order to manage the dependent infrastructure included in the Terraform scope. Remember our persistent data disk example: when setting `recreate_data_disk` to "none" we assert that a disk named `pg-data-disk` exists in our cloud/folder, and we want to use its properties, particularly `disk_id` property, to attach the disk to a Terraform managed PostgreSQL virtual machine. We use a special kind of resource called *data source* to access properties of the infratructure external to our Terraform scope.
> 
> Finally, sometimes we need to perform some operation that has nothing to do with creation or deletion of the infrastructure, neither with reading its properties. The frequent use case is when we want to run some command locally or remotely on the newly provisioned or existing machine. This is when *null_resource* with *provisioner* blocks comes in handy.  

### Step 3.3.2  In the `vpc-subnets` module diretory edit the `providers.tf`
Add the `null` provider and make the entire ile look as follows:
```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }  
    template = {
      source = "hashicorp/template"
      version = ">= 2.2.0"
    }  
    null = {
      source = "hashicorp/null"
      version = ">= 3.0"
    }           
  }
  required_version = ">= 0.13"
}
```   
### Step 3.3.3 Navigate back to the project directory `cd ..` and run `./dterraform init`
This will install the `null` provider that we have specifed in the previous step

### Step 3.3.4 Run `./dterraform apply --auto-approve --var recreate_data_disk="empty"`
The command again will stream Terraform execution ending up with a message `Apply complete! Resources: 9 added, 0 changed, 0 destroyed.` followed by a list of outputs

### Step 3.3.5 Ssh into *nat_instance_public_ip* and explore the content of `~/.ssh` folder
`ssh -i ~/.ssh/tutorial_id_rsa tutorial@{insert the value of nat_instance_public_ip output}` 
Respond 'yes' to a "Are you sure you want to continue connecting (yes/no/\[fingerprint\])?" question.

Run `ls ~/.ssh`

There should be a `tutorial_id_rsa` file in the folder:
```
authorized_keys  tutorial_id_rsa
```
Finally press `Enter` followed by `~` and `.` to close the ssh connection.

### Step 3.3.6 Destroy the infrastructure including the disk
- Run `./dterraform destroy --auto-approve` to destroy everything but the disk
- Run `yc compute disk delete --name pg-data-disk` to delete the disk from the cloud

## Step 3.4 Create the virtual machine for the PostrgeSQL server and attach the persistent disk to the same
We will use Yandex Container Optimized Image for our virtual machine as long as we want to run PostgreSQL Server in the container. 
> Normally, if we want to attain more scalability, we would use Yandex Cloud's Managed Postgres service. The premise behind a managed service with any public cloud provider is that the cloud provider handles database availability and security while the client focuses on application development rather than database administration. This unquestionably adds value, but it is not free. 
> 
> Our toy scenario is small and does not set high availability requiremens. We only need a dead simple basic configuration, and we want to learn what this basic configuration would look like from the database administration standpoint, so there is no need to ask the cloud provider to do this job for us.       
### Step 3.4.1 Create a *docker-compose* template 
Navigate to the `postgres` module 
```
cd postgres
```
and create the file `docker-compose-pg.tpl.yaml` with the following content:
```
version: "3"

services:
    postgres:
        image: postgres:12.3-alpine
        restart: always
        environment:
            POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
            POSTGRES_USER: ${POSTGRES_USER}
        ports:
            - 5432:5432
        volumes:
            - /home/${DEFAULT_USER}/data-disk/pgdata:/var/lib/postgresql/data

    pgadmin:
        image: dpage/pgadmin4:4.23
        user: root
        environment:
            PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL}
            PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD}
            PGADMIN_LISTEN_PORT: 80
            PGADMIN_CONFIG_SERVER_MODE: 'True'
        ports:
            - 80:80
        volumes:
            - /home/${DEFAULT_USER}/data-disk/pgadmin:/var/lib/pgadmin
        depends_on:
            - postgres
        
x-yc-disks:
  - device_name: pgdata
    fs_type: ext4
    host_path: /home/${DEFAULT_USER}/data-disk
```
This compose file tells Yandex Cloud to run `postgres` and `pgadmin` containers on the same virtual machine. Docker will automatically create a network and attach these two containers to it. This will allow `pgadmin` to connect to `postgres` using the container name (which is `postgres`, too).  

The `postgres` container will listen on port 5432, while the `pgadmin` container will listen on port 80.

The expression wrapped in curly brackets pereceded with '$' symbol are the Postgres and pgAdmin credentials. They will be replaced with the values of the corresponding variables declared in the Postgres virtual machine's Terraform configuration that we define in the  steps . 

The PostgreSQL data and the pgAdmin configuration directories will be mapped to an external virtual disk `pgdata` that will be mounted to a `data-disk` directory in the home directory of the default user. This virtual disk will be exactly the persistent `pg-data-disk` that we create in the [step 3.2](https://github.com/gdlyan/yc-playground/blob/master/nocodb-pg-tf/03%20Create%20PostgreSQL%20Server/readme.md#step-32-create-a-virtual-disk-for-our-postgresql-server-to-store-its-data). The device-name for this name will be set to 'pgdata' when the disk is attached to the virtual machine, we will do this in the following step, too.

The nice thing about container optimized image is that if the device comes across the unpartitioned unformatted secondary disk then partitioning and formatting will be done out of the box. So we don't need to worry about it any further than specifying `fs_type: ext4` in the `x-yc-disks` block of the docker-compose manifest. 
### Step 3.4.2 create `pg_instance.tf` with the following content:
```
data "template_file" "docker_compose_pg_yaml" {
  template = file("${path.module}/docker-compose-pg.tpl.yaml")
  vars = {
    DEFAULT_USER             = var.default_user
    POSTGRES_USER            = var.default_user
    POSTGRES_PASSWORD        = var.postgres_password
    PGADMIN_DEFAULT_EMAIL    = var.pgadmin_credentials.email
    PGADMIN_DEFAULT_PASSWORD = var.pgadmin_credentials.password
  }
}

data "yandex_compute_image" "container_optimized_image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance" "pg_docker_instance" {
  name = "pg-docker-instance"
  zone = var.subnet.zone

  resources {
      cores  = 2
      core_fraction = 20
      memory = 1
  }

  scheduling_policy {
      preemptible  = true
  }

  boot_disk {
      initialize_params {
          image_id = data.yandex_compute_image.container_optimized_image.id
          size = 30
      }
  }

  secondary_disk {
    disk_id = var.recreate_data_disk == "none" ? data.yandex_compute_disk.pg_data_disk.0.id : yandex_compute_disk.pg_data_disk.0.id
    device_name = "pgdata"
  }

  network_interface {
      subnet_id       = var.subnet.id
      ip_address      = cidrhost(var.subnet.v4_cidr_blocks[0], 101)
  }  

  metadata = {
    docker-compose = data.template_file.docker_compose_pg_yaml.rendered
    ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
  }
}
```
This is the part of the configuration that tells Yandex Cloud to spawn the virtual machine based on the Container Optimized Image with the following  special features worth attention:
- Attach either existing or recreated data disk as a secondary disk, depending on the value of the `recreate_data_disk` variable received as an argument. Note that the device_name `pgdata` is given to a disk at this stage. Remember that we are identifying this disk by its device name (see `device-name: pgdata`)  in the `docker-compose-pg.tpl.yaml` in the  `x-yc-disks` section
- Launch `postgres` and `pgadmin` containers according to a *docker-compose* manifest that is generated from the `docker-compose-pg.tpl.yaml` template by substitution of the variables in the curly brackets with the values passed in the `vars` block of the `template_file.docker_compose_pg_yaml` resource confguration.
- We will also set a static private IP address to our PostgreSQL instance. Otherwise it would be assigned dynamically every time we recreate the instance. So we will have to ssh into the new IP address after recreation and we have to look into the Terraform outputs for this address. This might be less convenient than just remembering one address and always using it.
  > We have to ensure that the private IP address would match the `v4_cidr_blocks` mask of the subnet. Our convention would be that the first three 8-bit numbers of the IP address would come from the subnet's CIDR while the last number in the IP address would always be `101` for the PostgreSQL Server in our setup. There is a special `cidrhost` function in Terraform that implements such a trick. 
  > 
  > In the step 3.4.8 we pass the private subnet that we have created in the availability zone `ru-central1-a` as a `subnet` argument of the module `postgres` call. We do this in the line `subnet = module.vpc_subnets.webapp_subnets[0]` of the `module "postgres"` block. The `v4_cidr_blocks` of this subnet is `["10.130.0.0/24"]`. Our `cidrhost(var.subnet.v4_cidr_blocks[0], 101)` call will return `"10.130.0.101"` in this case.
### Step 3.4.3 Append the following lines in the bottom of `postgres/variables.tf`
```
variable "default_user" {
  type        = string
  default     = "tutorial"
}

variable "private_key_file" {
  type        = string
  default     = "tutorial_id_rsa"
}

```
The `default_user` and `private_key_file` variables are used in the `metadata` block of the `yandex_compute_instance.pg_docker_instance` resource configuration. The purpose of these variables is to allow ssh-connection to the PostgreSQL server instance with the username and the private key specified in these variables (which by default are `tutorial` and `tutorial_id_rsa`). Also the value of the `default_user` variable would be sent to the `docker-compose-pg.tpl.yaml` template, so that the `POSTGRES_USER` on the PostgreSQL Server would be set to `tutorial` unless we explicitly set some other value to the `default_user` variable, which we don't do in this exercise.

### Step 3.4.4 Also append the following lines in the bottom of `postgres/variables.tf`
```
variable "postgres_password" {
  description = "Postgres password for default_user"
  type        = string  
}

variable "pgadmin_credentials" {
  type        =  object({email = string, password = string})  
}
```
The values of these variables come from the root module as the arguments, then are sent to the `docker-compose-pg.tpl.yaml` template  .
### Step 3.4.5 For the `postgres` module create the outputs file  `postgres/outputs.tf` with the following content: 
```
output "pg_instance_private_ip" {
   description = "Private IP of virtual machine with postgres and pgadmin"
   value       = yandex_compute_instance.pg_docker_instance.network_interface.0.ip_address
}

output "pg_data_disk_id" {
   description = "Persistent data volume for postgres"
   value       = yandex_compute_instance.pg_docker_instance.secondary_disk[0].disk_id
}
```

### Step 3.4.6 Navigate to the root module directory and append the same lines to `variables.tf` as you did for `postgres/variables.tf`
```
variable "default_user" {
  type        = string
  default     = "tutorial"
}

variable "private_key_file" {
  type        = string
  default     = "tutorial_id_rsa"
}

variable "postgres_password" {
  description = "Postgres password for default_user"
  type        = string  
}

variable "pgadmin_credentials" {
  type        =  object({email = string, password = string})  
}
```

### Step 3.4.7 In the root module directory create `terraform.tfvars` file and set your Postgres and pgAdmin credentials
```
postgres_password   = "<postgres password for a default user 'tutorial'>"
pgadmin_credentials = {email: "me@example.com", password: "put_your_strong_password_here"}
```

### Step 3.4.8 In the `main.tf` add the `postgres_password` and `pgadmin_credentials` as the arguments to module `postgres` call
The `main.tf` file should look like as follows after the edit:
```
provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

module "vpc_subnets" {
  source = "./vpc-subnets" 
}

module "postgres" {
  source = "./postgres" 
  subnet = module.vpc_subnets.webapp_subnets[0]
  postgres_password = var.postgres_password
  pgadmin_credentials = var.pgadmin_credentials
  recreate_data_disk = var.recreate_data_disk
}
```  

Note these two lines added in the `module "postgres"` block:
```
  pgadmin_credentials = var.pgadmin_credentials
  recreate_data_disk = var.recreate_data_disk
```
### Step 3.4.9 Update the `outputs.tf` file in the root module directory
```
output "pg_data_disk_id" {
   value = module.postgres.pg_data_disk_id
}

output "ssh_command" {
   value = "ssh -L 31080:${module.postgres.pg_instance_private_ip}:80 -i ~/.ssh/${var.private_key_file}  ${var.default_user}@${module.vpc_subnets.nat_instance_public_ip}"
}
```
The last output is interesting: it will print out the ssh command that we would use to be able to access pgAdmin web-interface from the outside of the private network
### Step 3.4.10 In the root module directory run `./dterraform apply --auto-approve --var recreate_data_disk="empty"`
The outcome should be as follows:
```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

nat_instance_private_ip = "10.129.0.100"
nat_instance_public_ip = {sanitized}
network_id = {sanitized}
pg_data_disk_id = {sanitized}
ssh_command = "ssh -L 31080:10.130.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@{sanitized}"
webfront_subnet = {sanitized}
```  
### Step 3.4.11 Run the command from `ssh_command` output
In the example below:
```
ssh -L 31080:10.130.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@{sanitized}
```
This command pretty much gives you an access to the NAT instance shell. But there is one extra argument -L in the command  that tells the tunnel to forward all the requests on port localhost:31080 to the port 80 on the private IP address of PostgreSQL server. And this is exactly where pgAdmin is listening
### Step 3.4.12 Now in your browser go to `localhost:31080`  
You will get to the pgAdmin login page

Enter the credentials that you have put in the step 3.4.7 into `pgadmin_credentials` variable. This will bring you to main pgAdmin interface
> If you are working from the Yandex Cloud Toolbox machine, you have no browser there. You can instead install the `tutorial_id_rsa` provate key into ~/.ssh folder on your local machine that does have a browser and run the same command locally
### Step 3.4.13 Connect to PostgreSQL Server with pgAdmin
- In the *"Browser"* pane on the left hand side click on the  "Servers" tree element. It's not going to expand since we have not yet created a connection
- In the top menu select *Object -> Create -> Server...*. The server connection form will pop up
- In the *"General"* tab of the server connection form in the *"Name"* edit box type in `postgres` and switch to the *"Connection"* tab
- In the *"Host name / address"* edit box type in `postgres`
- Keep `5432` in the *"Port"* and `postgres` in `Maintenance database` edit boxes 
- In the *"Username"* edit box type in `tutorial` as long as it is what you specified in the `default_user` variable that has been further passed to the `${POSTGRES_USER}` variable of the docker-compose template
- In the *"Password"* edit box enter the password that you have assigned at the step 3.4.7 to the `postgres_password` variable  
- Check *"Save the password"* box and click *"Save*" button in the bottom of the form

Now the tree in the *"Browser"* pane on the left hand side is expandable. Play around with pgAdmin and explore what you have on the server out of the box.
### Step 3.4.14 Remove the data disk from the list of Terraform managed resources to make it persistent
Every time we recreate the disk from Terraform using `--var recreate_data_disk="empty"` or `--var recreate_data_disk="pg-data-disk-snapshot"` the disk gets back to the Terraform state. We have to remove it from there, otherwise it is going to be destroyed next time we recreate the infrastructure  
```
`./dterraform state rm module.postgres.yandex_compute_disk.pg_data_disk[0]`
```
### Step 3.4.15 Destroy and apply Terraform again without disk recreation
```
./dterraform destroy --auto-approve
```
Expected result:
```
./dterraform destroy --auto-approve
```
Then 
```
./dterraform apply --auto-approve
```
Expected result:
```
Apply complete! Resources: 9 added, 0 changed, 0 destroyed.

Outputs:

nat_instance_private_ip = "10.129.0.100"
nat_instance_public_ip = {sanitized}
network_id = {sanitized}
pg_data_disk_id = {sanitized but same as of the step 3.4.10}
ssh_command = "ssh -L 31080:10.130.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@{sanitized}"
webfront_subnet = {sanitized}
```
### Step 3.4.16 Check that your data has not gone away
Run the ssh command from the Terraform output
```
ssh_command = "ssh -L 31080:10.130.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@{sanitized}"
``` 
In your browser go to `localhost:31080` and check that your pgAdmin connection is still there

### Step 3.4.17 SSH from you NAT instance into PostgreSQL
The previous ssh command `ssh_command = "ssh -L 31080:10.130.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@{sanitized}"` should have connected you to an NAT instance. Now from this shell run:
```
ssh -i ~/.ssh/tutorial_id_rsa tutorial@10.130.0.101
``` 
This should give you access to the PostgreSQL Server

### Step 3.4.18 Explore the PostgreSQL virtual machine
Run the following commands:
- `docker ps` to get the list of running containers
- `docker logs <container id>` to review the container logs
- `sudo tail -n 25 /var/log/syslog` to review the host system log (last 25 rows). This command is also helpful when something is going wrong and containers don't start. Syslog is the first instance to get information about the possible failures

Click `ENTER` followed by `~` and `.` to exit ssh connection

## Step 3.5 Experiment with data disk snapshots
### Step 3.5.1 Create a data disk snapshot
```
yc compute snapshot create --name pg-data-disk-snapshot --disk-name "pg-data-disk
```
### Step 3.5.2 Restore from disk snapshot
- `./dterraform destroy --auto-approve` to destroy everything but the data disk
- `yc compute disk delete --name pg-data-disk` to remove the data disk
- `./dterraform apply --auto-approve --var recreate_data_disk="pg-data-disk-snapshot"` to restore from the snapshot
- `./dterraform state rm module.postgres.yandex_compute_disk.pg_data_disk[0]` to remove the restored disk from the list of Terraform managed resources
### Step 3.5.3 Delete the outdated snapshot
```
yc compute snapshot delete --name pg-data-disk-snapshot
``` 

## _Congratulations! You have completed this module!_
