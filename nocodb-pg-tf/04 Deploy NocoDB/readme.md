# 04 Deploy NocoDB on multiple instances
In this tutorial we will:
- Create a group of 3 virtual machines, one per availability zone
- On each virtual machine pull the [NocoDB image available on Dockerhub](https://hub.docker.com/r/nocodb/nocodb), to do so  we will need the private network to be connected to Internet in order to pull images from Dockerhub (and this is what we have done on the  step ['02 Create Network'](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/02%20Create%20Network), when we deployed an *NAT instance*). Once the image is pulled, run NocoDB app in the Docker container and connect it to PostgreSQL Server deployed previously on the step ['03 Create PotgreSQL Server'](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/03%20Create%20PostgreSQL%20Server)  
- Create a network load balancer that will check if the NocoDB machines are up and running as well as will serve a single point of contact for all the virtual machines in the group. It will receive connection requests and choose the best NocoDB machine to send the request to
- Because we intentionally will not assign a private IP address to the load balancer, we will setup the ssh-tunnel such that http connections to the NocoDB app can be made from the machines having the private part of the ssh key installed 
- We will also ssh into the NocoDB machines and examine its logs 

## Prerequisites
- You need to have the ['03 Create PostgreSQL Server'](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/03%20Create%20PostgreSQL%20Server) tutorial completed before starting this one
- Please copy the folder "03 Create PostgreSQL Server" into a new project directory named "04 Deploy NocoDB". We will further refer to "04 Deploy NocoDB" as to our *root module* directory or *project*  directory. You may use `cp -R  '03 Create PostgreSQL Server' '04 Deploy NocoDB'` command
- Navigate to `'04 Deploy NocoDB'` directory and run `./dterraform init`.  
- During completion of [02 Create Network](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/02%20Create%20Network) tutorial you should have generated  password-less ssh keys. If not yet, use the command below as an example
```
ssh-keygen -C "tutorial"  -f ~/.ssh/tutorial_id_rsa -t rsa -b 4096
```
## Step 4.1 Prepare a dedicated module directory for spawning NocoDB instances    
### Step 4.1.1 Inside the *project* directory create a *module* directory named `nocodb` and navigate to the same
```
mkdir "nocodb" && cd "$_"
```
### Step 4.1.2 Create the `providers.tf` for the `nocodb` module
On top of the `yandex` provier we will be using the `template` provider in this module. So the `./nocodb/providers.tf` file content should be as follows:
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

## Step 4.2 Create the NocoDB instance group
We will use Yandex Container Optimized Image for our virtual machine as long as we want to run NocoDB in the container. The bootstrapping process for the container based machines is made of two essential parts:
1. Creation of the infrastructure  itself. The parameters of the virtual machines will be described in the  `nocodb_instance.tf` configuration file
2. Pulling the image and running the container. When using Yandex Container Optimized Image we will need to pass a *docker-compose* configuration to tell the provider such things as which images need to be pulled, what values to set to the container environment variables, which ports to map and volume and many others. We use the `docker-compose` parameter of the `metadata` block of the `instance_template` section in the  `nocodb_instance.tf` as a means to send the *docker-compose* configuration to the instances of the group.
   
### Step 4.2.1 In the `'04 Deploy NocoDB'/nocodb` module directory create the `nocodb_instance_gr.tf` file with the following content:
```
data "template_file" "docker_compose_yaml" {
  template = file("${path.module}/docker-compose.tpl.yaml")
  vars = {
    DEFAULT_USER             = var.default_user
    POSTGRES_USER            = var.default_user
    POSTGRES_PASSWORD        = var.postgres_password
    PG_INSTANCE_PRIVATE_IP   = var.pg_instance_private_ip
    NOCODB_DATABASE          = var.nocodb_database
  }
}

data "yandex_compute_image" "container_optimized_image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance_group" "nocodb_instances" {
  
  service_account_id = yandex_iam_service_account.nocodb_manager_sa.id
  depends_on = [
    yandex_resourcemanager_folder_iam_binding.editor_account_iam  
  ]

  instance_template {

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

    network_interface {
      subnet_ids = var.subnet_ids 
    }  

    labels = {
      postgres = var.pg_instance_private_ip
    }

    metadata = {
        docker-compose = data.template_file.docker_compose_yaml.rendered
        ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
    }
  }

  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = var.zones
  }

  deploy_policy {
    max_unavailable = 2
    max_expansion   = 2
  }
}

```
Unlike in earlier examples with the NAT instance or the PostgreSQL Server,  we create a group of similar instances rather than a standalone virtual machine. The `instance_template` section tells what kind of instance we are using as pattern. Like in our previous tutorial, we use the smallest possible preemptible Yandex Container Optimized Image based virtual machine as a pattern in order minimize cost. The `size = 3` in the `fixed_scale` block of `scale_policy` section indicates that we want to make 3 machines. 

These 3 instances would vary by subnets and zones. We must pass the list of 3 subnets to the parameter `subnet_ids` of the `network_interface` block as well as the list of 3 zones to the `zones` parameter of the `allocation_policy` block.

The two parameters in the `deploy_policy` block are the required ones. They basically tell that during the update process maximum 2 instances can be taken offline simultaneously. Likewise, maximum 2 instances can be temporarily allocated above the group's target size during the update process.


### Step 4.2.2 Create a *docker-compose* template 
Make sure you working directory is `'04 Deploy NocoDB'/nocodb` or navigate to the same and create the file `docker-compose.tpl.yaml` with the following content:
```
version: '3'
services:
  nocodb_app: 
    container_name: nocodb_app
    environment: 
      NC_DB: "pg://${PG_INSTANCE_PRIVATE_IP}:5432?u=${POSTGRES_USER}&p=${POSTGRES_PASSWORD}&d=${NOCODB_DATABASE}" 
    image: "nocodb/nocodb:0.99.0"
    ports:
      - 80:8080
    restart: always
```
Returning to `nocodb_instance_gr.tf` we see that it begins with the  `data "template_file" "docker_compose_yaml" {...}` definition, which refers to the template file `docker-compose.tpl.yaml` and passes a list of variables to this template in the `vars` section. The `template` provider will render the *docker-compose* manifest taking `docker-compose.tpl.yaml` as a template and filling the variable placeholders with the corresponding variables' values. Further it will give the rendered material to the `docker-compose` parameter in the `metadata` section of the instances group's `intance_template` block.

During the initialization every instance will use the received *docker-compose* manifest to: pull the NocoDB image from the DockerHub, run the container, connect to Postgres, serve NocoDB on port 80, and set the restart policies 
 
### Step 4.2.3 Create a service account for instances group deployment
Yandex provider requires to specify a *service account* authorized to manage the instances group. In other words `service_account_id` is a required parameter for `yandex_compute_instance_group` resource. In the [step 4.2.1]() we have sent the value to this argument in the line `service_account_id = yandex_iam_service_account.nocodb_manager_sa.id`. Now we need to define the `yandex_iam_service_account.nocodb_manager_sa` and give it the `editor` role that is sufficient to create and destroy the virtual machines.

In the `'04 Deploy NocoDB'/nocodb` module directory create the `service_account.tf` file with the following content
```
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
```
### Step 4.2.4 Create the module input variables file 
In the `'04 Deploy NocoDB'/nocodb` module directory create the `variables.tf` file with the following content
```
variable "folder_id" {
  description = "Yandex folder id from yc config list"
  type        = string
}

variable "default_user" {
  type        = string
  default     = "tutorial"
}

variable "private_key_file" {
  type        = string
  default     = "tutorial_id_rsa"
}

variable "pg_instance_private_ip" {
  description = "Private IP address on the PostgreSQL Server" 
  type        = string
}

variable "postgres_password" {
  description = "Postgres password for default_user"
  type        = string  
}

variable "nocodb_database" {
  description = "Schema name for nocodb database on the PostgreSQL Server" 
  type        = string
  default     = "nocodb"
}

variable "subnet_ids" {
  description = "Subnets for nocobd instances"  
  type        =  list(string)
}

variable "zones" {
  description = "List of zones for nocodb instances"  
  type        =  list(string)
}
```
### Step 4.2.5 Call the `nocodb` module from the root module
Edit the `'04 Deploy NocoDB'/main.tf` file and append the following lines in the bottom:
```
module "nocodb" {
  source                 = "./nocodb"
  folder_id              = var.folder_id
  pg_instance_private_ip = module.postgres.pg_instance_private_ip
  postgres_password      = var.postgres_password
  subnet_ids             = [for s in module.vpc_subnets.webapp_subnets: s.id]
  zones                  = [for s in module.vpc_subnets.webapp_subnets: s.zone]
}
```
### Step 4.2.6 Run interim Terraform check
Navigate back to the root module directory `'04 Deploy NocoDB'` and run the following commands:
- `./dterraform validate` - to check for syntax errors
- `yc compute disk get --name pg-data-disk` to check if you already have the persistent data disk that you might have created during the previous tutorials
- `./dterraform plan` (or `./dterrafrom plan --var recreate_data_disk="empty"` if the last command returned ERROR) - to review the plan without making any updates to the cloud
- `./dterraform apply --auto-approve` (or `./dterrafrom plan --var recreate_data_disk="empty"` if there is yet no persistent data disk in the cloud) - to apply the plan and see if the instance group has been successfully created
- `./dterraform destroy --auto-approve`  - to clear infrastructure and proceed to setting up the load balancer

## Step 4.3 Setup the network load balancer
Now that we have multiple instances of similar configuration we should be able to seamlessly switch from one to another if some of the instances become unavailable. Load balancers handle availability by routing requests to the instance that is most suited to serve them. 

There are two major types of load balancers: Network Load Balancer (NLB) and Application Load Balancer (ALB). In this tutorial we are creating an NLB which is simpler thing to do. Network Load Balancers operate at the network connection level, and they can only consider the properties of the network connection with the client when determining which instance to serve the request. Unlike the ALB, they do not examine the request's contents and instead merely forward it. The NLB method of assuring the availability of the application is also fairly straightforward. They just send a request to a specified URL endpoint and anticipate a return code of 200. If you need anything more advanced, you should look into ALB. However, for the purposes of this tutorial, NLB is more than adequate.      
### Step 4.3.1 Create a Terraform configuration for the load balancer and the target group
Navigate again to the `nocodb` module directory and create the file `lb.tf` with the following content:
```
resource "yandex_lb_target_group" "tg" {
  name      = "web-service-tg"
  region_id = "ru-central1"

  dynamic "target" {
    for_each = yandex_compute_instance_group.nocodb_instances.instances
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }

  }
}

resource "yandex_lb_network_load_balancer" "nlb" {
  name = "load-balancer"
  type = "internal"

  listener {
    name = "nocodb-upstream-listener"
    port = 80
    target_port = 80
    internal_address_spec {
      subnet_id  = var.nlb_subnet.id
      address    = cidrhost(var.nlb_subnet.v4_cidr_blocks[0], 101) 
    }
  }

  attached_target_group {
    target_group_id = "${yandex_lb_target_group.tg.id}"

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/dashboard/"
      }
    }
  }
}
```
Here we start from creating the target group `yandex_lb_target_group.tg` that includes every virtual machine on the `yandex_compute_instance_group.nocodb_instances` instance group that we have created in the earlier step. Then we create an internal network load balancer that listens on the port 80 and routes the requests to the port 80 of the chosen NocoDB instance that is supposed to serve the request.

In order to assure the availability of the application on each of the target group members, our load balancer will periodically (every two seconds by default) send its own http check requests to `http://<nocodb_instance_ip>:80/dashboard/` anticipating the response code 200. If the response code is different than 200 for a number of requests in a row then the load balancer would mark the instance as *Unhealthy*. It will not consider the instance for processing client requests during its unhealthy time, but will continue to send check requests in anticipation of the instance's recovery. 

We will assign a static private IP address to a load balancer. It will be hosted at `10.129.0.101` unless we specify a different CIDR for our web front subnet sending a value to the  `web_front_subnets` input of the `vpc-subnets` module. The three left numbers of the IP address are taken from the input variable `var.nlb_subnet` that we have not yet declared. We will do this in the following step.

### Step 4.3.2 Declare the `var.nlb_subnet` input variable in the `nocodb` module
In the `nocodb` *module* directory edit the file `variables.tf` and append the following text in its bottom:
```
variable nlb_subnet {
  description = "home subnet for network load balancer"  
  type = object({id = string, zone = string, v4_cidr_blocks = list(string)})
}
```

### Step 4.3.3 Pass the web front subnet as the value for `nlb_subnet` argument from the root module
In the *root module* directory edit the file `main.tf` and add the line `nlb_subnet = module.vpc_subnets.webfront_subnet` in the `module "nocodb {...}"` block so that the whole block appears as follows:
```
module "nocodb" {
  source                 = "./nocodb"
  folder_id              = var.folder_id
  pg_instance_private_ip = module.postgres.pg_instance_private_ip
  postgres_password      = var.postgres_password
  subnet_ids             = [for s in module.vpc_subnets.webapp_subnets: s.id]
  zones                  = [for s in module.vpc_subnets.webapp_subnets: s.zone]
  nlb_subnet             = module.vpc_subnets.webfront_subnet
}
``` 

### Step 4.3.4 Let the `nocodb` module output the IP address of the network load balancer and some information required to access the Nocodb instances directly   
In the `nocodb` module directory create the file `outputs.tf` with the following content:
```
output "nlb_instance_private_ip" {
   description = "Private IP of network load balancer"
   value       = [for s in yandex_lb_network_load_balancer.nlb.listener: s.internal_address_spec.*.address].0[0]
}

output "nocodb_instances" {
  value = [for s in yandex_compute_instance_group.nocodb_instances.instances: {"ip_address": s.network_interface.0.ip_address,
                                                                               "id": s.instance_id, 
                                                                               "zone": s.zone_id}] 
}
```
### Step 4.3.5 Update the ssh command printed out from the *root module* 
In the *root module* directory edit the `output "ssh_command" {...}` block of the file `outputs.tf` as follows:
```
output "ssh_command" {
   value = "ssh -L 31080:${module.postgres.pg_instance_private_ip}:80 -L 41080:${module.nocodb.nlb_instance_private_ip}:80 -i ~/.ssh/${var.private_key_file}  ${var.default_user}@${module.vpc_subnets.nat_instance_public_ip}"
}
```
Note the argument `-L 41080:${module.nocodb.nlb_instance_private_ip}:80` that has been added to the ssh command. Now this command will let anyone with the private half of the ssh key send http requests to NLB from outside the private network.   

## Step 4.4 Apply the coniguration and review the outcomes
### Step 4.4.1  Apply Terraform configuration 
Navigate back to the root module directory `'04 Deploy NocoDB'` and run the following commands:
- `./dterraform validate` - to check for syntax errors
- `yc compute disk get --name pg-data-disk` to check if you already have the persistent data disk that you might have created during the previous tutorials
- `./dterraform plan` (or `./dterrafrom plan --var recreate_data_disk="empty"` if the last command returned ERROR) - to review the plan without making any updates to the cloud
- `./dterraform apply --auto-approve` (or `./dterrafrom plan --var recreate_data_disk="empty"` if there is yet no persistent data disk in the cloud) - to apply the plan and see if the instance group and the load balancer have been successfully created

The last command should return the following output following the Terraform log stream:
```
Apply complete! Resources: 14 added, 0 changed, 0 destroyed.

Outputs:

nat_instance_private_ip = "10.129.0.100"
nat_instance_public_ip = "{sanitized}"
network_id = "{sanitized}"
pg_data_disk_id = "{sanitized}"
ssh_command = "ssh -L 31080:10.130.0.101:80 -L 41080:10.129.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@{sanitized}"
webfront_subnet = "{sanitized}"
```
### Step 4.4.2 SSH into NAT instance
Run the ssh command from the Terraform output
```
ssh -L 31080:10.130.0.101:80 -L 41080:10.129.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@{nat_instance_public_ip}
``` 
We have added one more -L argument that tells the tunnel to forward all the requests on port localhost:41080 to the port 80 on the load balancer's private IP address.
### Step 4.4.3 Now in your browser go to `localhost:41080`  
You will be directed to the Nocodb signup page. Signup with a new user and explore the NocoDB functionality. So far, it is beyond the scope of this class, but the tool is simple to use and straightforward to learn. 
> A reminder again: if you are working from the Yandex Cloud Toolbox machine, you have no browser there. You can instead install the `tutorial_id_rsa` provate key into ~/.ssh folder on your local machine that does have a browser and run the same ssh command locally
### Step 4.4.4 Review the changes in the Yandex Cloud Console
In the [Yandex Cloud Console](https://console.cloud.yandex.com/) navigate to the project *folder* and on the "Folder services" panel click on the "Network Load Balancer" card. You will be directed to a list of load balancers, which will most likely consist of only one entry. Click on the `load-balancer` record  to open the load balancer overview. In the bottom of the overview locate the "Target groups" section and expand the `web-service-tg` target group. You will see the list of three NocoDB virtual machines' IP addresses alongside their status (most likely "Healthy"). Remember the IP addresses to use them in the next step.  
### Step 4.4.4 Examine the NocoDB instances from the inside
- Choose one of the three newly generated NocoDB instances at random. In the SSH session with the NAT instance run `ssh -i ~/.ssh/tutorial_id_rsa tutorial@{NocoDB instance IP address}`. This will start an SSH session with the selected NocoDB virtua mchine
- In the started SSH session run `docker ps`. THis command will print a list of one `nocodb_app` container running on this instance
- Run `docker logs nocodb_app`. This command will print out multiple lines of this kind `GET /dashboard/ 200 17656 - 1.296 ms`.  These are the health checks from the load balancer 
- Now open the browser, refresh the page at `localhost:41080`, quickly go back to the SSH session and run `docker logs nocodb_app` once again. If you see anything different than the health check request from the load balancer, that means you are on SSH with the machine selected by the load balancer to serve the request from your browser. If not, ssh into the other NocoDB instances until you find the one the load balancer chose. 
### Step 4.4.5 Examine how load balancer handles availability
- Press `Enter` followed by `~` and `.` to close all SSH sessions
- In the [Yandex Cloud Console](https://console.cloud.yandex.com/) stop two of the three virtual machines from the load balancer's target group, then return to the load balancer overview page. The load balancer will alert you to two unhealthy resources in the target group. 
- Now run `ssh -L 31080:10.130.0.101:80 -L 41080:10.129.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@{nat_instance_public_ip}`
 and go to `localhost:41080` in your browser. The application will stay up and running until at least one resource is healthy.             


Enter the credentials that you have put in the step 3.4.7 into `pgadmin_credentials` variable. This will bring you to main pgAdmin interface
> If you are working from the Yandex Cloud Toolbox machine, you have no browser there. You can instead install the `tutorial_id_rsa` provate key into ~/.ssh folder on your local machine that does have a browser and run the same command locally

### Step 4.4.6 Destroy the infrastructure to avoid unnecessary cost
- `./dterraform destroy --auto-approve` to destroy everything but the data disk
- `yc compute disk delete --name pg-data-disk` to remove the data disk`` 

## _Congratulations! You have completed this module!_
