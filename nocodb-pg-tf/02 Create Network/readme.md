# 02 Create Network
## First, a "for dummies" look at how private networks connect to Internet
Think of the way you connect to Internet from home. Whatever is the complexity of the setup, you will almost certainly have at least one device, such as a router or a modem, that connects your private network to an Internet Service Provider. 

Computers on your private network are given IP addresses that can only belong to one of the following special purpose address ranges:
- 10.0.0.0 to 10.255.255.255
- 172.16.0.0 to 172.31.255.255
- 192.168.0.0 to 192.168.255.255

On the contrary the public IP address can never belong to either of these ranges, neither to a few more ranges specfied in the "special purpose address registry"

For two computers to connect, they each need to know the other's IP address so they can send packets to it. The computer on the private network will know the remote servers' public IP addresses. But since our computer only has a private IP address, the remote servers won't be able to send the packets back because they won't know where to send them. It's like if someone sent a letter and said that the return address should be "apartment 123", but didn't specify the apartment building address. The receiver obviously won't be able to send the response, and the connection won't be made.

The router would have both private and public IP addresses. When a computer in the private network wants to talk to Internet, it sends the packets to the router's private IP address.  The router then changes the outgoing IP address from private to public and sends the packet to the web. Now the other side knows where to send the response. The information will get back to the computer by using the public address of the router, not the private address of the computer. This is the way how network address translation (NAT) works      
 
## We are creating a basic private network connected to Internet
In this tutorial we will create a Virtual Private Cloud (VPC) and 4 subnets. 
- One **public** subnet will host instances directly exposed to web traffic, such as load balancers, NATs, gateways,  bastions etc. 
- Three more **private** subnets are made, one for each Yandex Cloud availability zone (there are currently three of them). These subnets will hold virtual machines with web applications and databases.

In the public subnet we will create an NAT istance that will have both public and pivate IP addresses.

We will also create a static route that would tell all the packets to travel via NAT instance. This instance would change the outgoing IP address for the packets sent to the web. **As a result, the NAT instance will operate much like a router in a conventional home network.** 

Operating systems on private subnet virtual machines would be able to connect to the Internet and receive installation packages, Docker images, and so on. However, because the instances would not have public IP addresses, they would be inaccessible without *tunneling* into the private network. To access the command shell on such a private virtual machine, one must first *ssh* into the NAT instance and then into the target computer's private IP address.  
## Prerequisites
- You need to have the [01 Prepare Terraform to work with Yandex Cloud](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/01%20Prepare%20Terraform%20for%20YC) tutorial completed before starting this one
- Please copy the folder "01 Prepare Terraform to work with Yandex Cloud" into a new project directory. You may use `cp -R '01 Prepare Terraform for YC' '02 Create Network'` command
- Navigate to `02 Create Network` directory and run `./dterraform init`
- Generate password-less ssh keys, use the command below as an example
```
ssh-keygen -C "tutorial"  -f ~/.ssh/tutorial_id_rsa -t rsa -b 4096
```
## Step 2.1 Use Terraform to create your first resources 
### Step 2.1.1 Inside the *project* directory create a *module* directory and navigate to the same
```
mkdir "vpc-subnets" && cd "$_"
```  
### Step 2.1.2 Copy the `providers.tf` file from the *project* directory to the *module* directory
```
cp ../providers.tf .
``` 
### Step 2.1.3 In the module directory create the `variables.tf` file with the following content
```
variable "vpc_name" {
  type = string
  default = "web-service-vpc-tf"
}

variable "web_front_subnets" {
 description = "Public subnets for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions etc."
 type =  list(object({zone = string, v4_cidr_blocks = list(string)}))
 default = [{"zone":"ru-central1-b", "v4_cidr_blocks" : ["10.129.0.0/24"]}]
}
```
These variables store information that Terraform will use to create the VPC and the public subnet. We can pass the values for the variables from the main module (see step XXX). If we don't, default values will be assigned.
The current default values tell Terrafom that the VPC will be spawned with the name *web-service-vpc-tf* and the public subnet will be created in the availability zone *ru-central1-b*. The private IP addresses for the instances in this subnet will range from 10.129.0.0 to 10.129.0.255.
> The subnet mask, which is set by the 'v4 cidr blocks' parameter, tells a subnet what range of private IP addresses it can use. Technically, IP address is a 32-bit number, which is made up of four 8-bit numbers separated by dots. The number after the slash symbol in the `v4 cidr blocks`  shows how many bits on the left are reserved to identify the subnet. The remaining bits identify the device on the network. So "v4 cidr blocks": ["10.129.0.0/24"] meant that three first 8-bit numbers 10.129.0 (that make 24 bits in total) are reserved to identify the subnet, and there could be up to 255 addresses in this subnet.
### Step 2.1.4 In the *vpc-subnets* module directory create the `vpc.tf` file with the following content
```
# Create VPC
resource "yandex_vpc_network" "vpc" {
  name = var.vpc_name
  description = "Terraform managed VPC for basic web-service"
}

# Create web-front subnet
resource "yandex_vpc_subnet" "web_front_subnets" {
  count = length(var.web_front_subnets)
  network_id = yandex_vpc_network.vpc.id
  name = "${var.vpc_name}-web-front-${var.web_front_subnets[count.index].zone}-${count.index}"
  description = "Public subnet for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions"
  zone = var.web_front_subnets[count.index].zone
  v4_cidr_blocks = var.web_front_subnets[count.index].v4_cidr_blocks
}
```  
These two blocks define the configuration of: 
- The Virtual Private Cloud, which will hold the network for our project. It can also be known as a network. The name of the network is read from the variable `vpc_name` that we have defined on the previous step
- The public subnets.  The variable `web front subnets` is used to find out how many public subnets need to be made and what their parameters, such as zones and private IP ranges, are. By default, we create one subnet in the availability zone *ru-central1-b*, and the private IP range is defined by the mask *10.129.0.0/24*, which we set in the variable on the previous step.
### Step 2.1.5 Create a reference from main project module to `vpc-subnets`
Navigate from the *module* directory back to the *project* directory using `cd ..` 

Append the following lines in the bottom of the `main.tf` file:
```
module "vpc_subnets" {
  source = "./vpc-subnets" 
}
``` 
### Step 2.1.6 Run `/.dterraform init` to reinitialize the project wth the newly created module
The outcome would look like the following
```
Initializing provider plugins...
- Reusing previous version of yandex-cloud/yandex from the dependency lock file
- Using previously-installed yandex-cloud/yandex v0.82.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
### Step 2.1.7 Run `/.dterraform validate` to check for syntax and internal consistencies
Expected outcome:
```
Success! The configuration is valid.
```
### Step 2.1.8 Run `./dterraform plan` to reconcile your Terraform configuration with your real world cloud setup and review the changes that Terraform would introduce therein
Expected outcome:
```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.vpc_subnets.yandex_vpc_network.vpc will be created
  + resource "yandex_vpc_network" "vpc" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + description               = "Terraform managed VPC for basic web-service"
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "web-service-vpc-tf"
      + subnet_ids                = (known after apply)
    }

  # module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0] will be created
  + resource "yandex_vpc_subnet" "web_front_subnets" {
      + created_at     = (known after apply)
      + description    = "Public subnet for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "web-service-vpc-tf-web-front-ru-central1-b-0"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.129.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```
### Step 2.1.9 Run `./dterraform apply --auto-approve` 
I hope you observe the following outcome:
```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.vpc_subnets.yandex_vpc_network.vpc will be created
  + resource "yandex_vpc_network" "vpc" {
      + created_at                = (known after apply)
      + default_security_group_id = (known after apply)
      + description               = "Terraform managed VPC for basic web-service"
      + folder_id                 = (known after apply)
      + id                        = (known after apply)
      + labels                    = (known after apply)
      + name                      = "web-service-vpc-tf"
      + subnet_ids                = (known after apply)
    }

  # module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0] will be created
  + resource "yandex_vpc_subnet" "web_front_subnets" {
      + created_at     = (known after apply)
      + description    = "Public subnet for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions"
      + folder_id      = (known after apply)
      + id             = (known after apply)
      + labels         = (known after apply)
      + name           = "web-service-vpc-tf-web-front-ru-central1-b-0"
      + network_id     = (known after apply)
      + v4_cidr_blocks = [
          + "10.129.0.0/24",
        ]
      + v6_cidr_blocks = (known after apply)
      + zone           = "ru-central1-b"
    }

Plan: 2 to add, 0 to change, 0 to destroy.
module.vpc_subnets.yandex_vpc_network.vpc: Creating...
module.vpc_subnets.yandex_vpc_network.vpc: Creation complete after 2s [id=enp19jmeku8i3l5dij50]
module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0]: Creating...
module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0]: Creation complete after 0s [id=e2ljs7da5ul0i1p0uh2j]
```
Congratulations! You have now created your first resource with Terraform. If you login to Yandex Cloud account and open the relevant folder, you would notice one new network and one new subnet on the "Virtual Private Cloud" card in the "Folder Services" grid.

### Step 2.1.10 Run `./dterraform destroy --auto-approve`
We do so since this lab's mission has not yet been finished. We will recreate the network once we have completed the exercise entirely, i.e. set up the NAT instance, the static route, and build the private subnets. The result of this command would be as follows:
```
module.vpc_subnets.yandex_vpc_network.vpc: Refreshing state... [id=enp19jmeku8i3l5dij50]
module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0]: Refreshing state... [id=e2ljs7da5ul0i1p0uh2j]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  # module.vpc_subnets.yandex_vpc_network.vpc will be destroyed
  - resource "yandex_vpc_network" "vpc" {
      - created_at  = "2022-12-01T14:48:39Z" -> null
      - description = "Terraform managed VPC for basic web-service" -> null
      - folder_id   = "b1gq1bhui2gch9pkgas8" -> null
      - id          = "enp19jmeku8i3l5dij50" -> null
      - labels      = {} -> null
      - name        = "web-service-vpc-tf" -> null
      - subnet_ids  = [
          - "e2ljs7da5ul0i1p0uh2j",
        ] -> null
    }

  # module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0] will be destroyed
  - resource "yandex_vpc_subnet" "web_front_subnets" {
      - created_at     = "2022-12-01T14:48:40Z" -> null
      - description    = "Public subnet for instances that are directly exposed to web-traffic such as Load balancers, NAT, gateways, bastions" -> null
      - folder_id      = "b1gq1bhui2gch9pkgas8" -> null
      - id             = "e2ljs7da5ul0i1p0uh2j" -> null
      - labels         = {} -> null
      - name           = "web-service-vpc-tf-web-front-ru-central1-b-0" -> null
      - network_id     = "enp19jmeku8i3l5dij50" -> null
      - v4_cidr_blocks = [
          - "10.129.0.0/24",
        ] -> null
      - v6_cidr_blocks = [] -> null
      - zone           = "ru-central1-b" -> null
    }

Plan: 0 to add, 0 to change, 2 to destroy.
module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0]: Destroying... [id=e2ljs7da5ul0i1p0uh2j]
module.vpc_subnets.yandex_vpc_subnet.web_front_subnets[0]: Destruction complete after 7s
module.vpc_subnets.yandex_vpc_network.vpc: Destroying... [id=enp19jmeku8i3l5dij50]
module.vpc_subnets.yandex_vpc_network.vpc: Destruction complete after 0s

Destroy complete! Resources: 2 destroyed.
```      

## Step 2.2 Create an NAT instance 
### Step 2.2.1 Navigate back to the *module* directory
`cd vpc-subnets`
So if you strictly follow this tutorial and don't change naming then for this paticular lab your *project* directory will be `./02 Create Network` and your *module* directory will be `/02 Create Network/vpc-subnets` 
### Step 2.2.2 Add the following lines to the `variables.tf` file in the *module* directory
```
variable "nat_ip_address" {
 description = "Static private IP address for the NAT instance"
 type =  string
 default = "10.129.0.100"
}
```
We will use this variable on the next step.
### Step 2.2.3 In the *module* directory create the `nat_instance.tf` file with the following content:
```
# Create NAT instance
data "yandex_compute_image" "nat_instance_ubuntu_image" {
  family = "nat-instance-ubuntu"
}

resource "yandex_compute_instance" "nat_instance_tf" {
  name = "nat-instance-tf"
  zone = yandex_vpc_subnet.web_front_subnets.0.zone

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
          image_id = data.yandex_compute_image.nat_instance_ubuntu_image.id          
          size = 10
      }
  }

  network_interface {
      subnet_id  = yandex_vpc_subnet.web_front_subnets.0.id
      ip_address = var.nat_ip_address
      nat        = true
  }

  metadata = {
      user-data = data.template_file.cloud_config_yaml.rendered
  }
}
```
This script declares a virtual machine created from a *nat-instance-ubuntu* image available on Yandex Cloud Marketplace. An NAT instance will not need much of computing capacity and we would rather prefer saving money here. That's why the configuration is minimal - 2 cores, 20% of guaranteed CPU capacity, 1Gb RAM, 10Gb HDD. We also make this instance preemptible. Preemptible instances are available at a good discount, however Yandex Cloud can stop the instance and reclaim capacity at their discretion. We are not building a fault tolerant system at this moment, hence we can afford making instances preemptible for the sake of cost saving.

We also provide this instance a public IP address by specifying `nat = true` on the *network_interface* section. We could assign the static IP, but this would incur some extra costs for us. In this experiment, we may do without a static IP address and prefer to allocate it dynamically. The public IP address would vary every time the instance was restarted. 

It costs nothing extra for a private IP address to be static. That's why we make it static in the *network interface* section by specifying `ip address = var.nat ip address`. Remember that in the previous step, we declared the variable *nat ip address* and its default value.

Also note that the line `user-data = data.template_file.cloud_config_yaml.rendered` in the *metadata* section refers to something that we have not yet specified in our configuration. We normally use *user-data* to define the bootstrapping operations to be performed on the machine once is provisioned even before the first login. This may involve creation of users and granting them access, copying the public ssh-keys, packages installation, execution of shell commands etc. In the following few steps, we will define the *user-data*.

### Step 2.2.4 In the *module* directory create the `cloud_config.tf` file with the following content:
```
data "template_file" "cloud_config_yaml" {
  template = file("${path.module}/cloud-config.tpl.yaml")
  vars = {
    DEFAULT_USER            = var.default_user
    PRIVATE_KEY_FILE        = var.private_key_file
  }
}
```
This creates a declaration for the `data.template_file.cloud_config_yaml` object referred in the *user-data* in the previous step. However, this declaration refers to a few things that are still missing on our configuration:
- `default_user` and `private_key_file` variables
- `cloud-config.tpl.yaml` file referred in the template session
Let's fix these missed configurations in the next two steps

### Step 2.2.5 Add the following lines to the `variables.tf` file in the *module* directory
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
Note that the default value for the *private_key_file* is the same as for the password-less key that we have created in the prerequisites. The default value for the *default_user* can be arbitrary. 

### Step 2.2.6 In the *module* directory create the `cloud-config.tpl.yaml` file with the following content: 
```
#cloud-config
ssh_pwauth: no
users:
  - name: ${DEFAULT_USER}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${file("~/.ssh/${PRIVATE_KEY_FILE}.pub")}
```
The `data.template_file.cloud_config_yaml` object will send the 'default_user' and 'private_key_file' variables' values to the `cloud-config.tpl.yaml` template. The specified values will be inserted into the `${DEFAULT_USER}` and `${PRIVATE_KEY_FILE}` placeholders in the *name* and *ssh_authorized_keys* sections, respectively. The text derived from the template will be passed to *user-data* of the NAT instance declaration.

The text itself contains [cloud-config](https://cloudinit.readthedocs.io/en/latest/topics/examples.html) directives that basically tell Terraform to perform the following initial setup once the virtual machine is deployed:
- create a user `tutorial` (as specified in *defaul_user* variable)
- copy a public key `~/.ssh/tutorial_id_rsa.pub` (as specified in *private_key_file* variable) from your local machine to the newly provisioned VM
- grant a `tutorial` user password-less sudo shell access subject to providing a private ssh-key that matches an uploaded public key     

### Step 2.2.7 In the module directory update the file `providers.tf`
Add a template section and make the script look as follows:
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
We need to install *template* provider to enable the generation of cloud-config directive from the template file as described in the previous step

## Step 2.3 Transform an NAT instance into a router for the private subnets
By doing step 2.2, a NAT instance would be created, but we still need to tell the virtual machines on the private subnets that all the packets they send out must go through this NAT instance. To do so, we will create a route table with one basic static route that forwards any outbound packets to our newly created NAT instance. Finally we will create the private subnets (one per each availability zone) and tell them to use this routing table.

### Step 2.3.1 Create a route table and a static route
Stay in the `vpc-subnets` module directory. Append the following lines in the bottom of the `vpc.tf` file:
```
# Create route table
resource "yandex_vpc_route_table" "nat_route_table_tf" {
  name = "nat-route-table-tf"
  description = "Terraform managed route table for basic web service"
  network_id = yandex_vpc_network.vpc.id

  static_route {
     destination_prefix = "0.0.0.0/0"
     next_hop_address = var.nat_ip_address
  }
}
```

### Step 2.3.2 Create the private subnets
Still stay in the `vpc-subnets` module directory. First append the following lines in the bottom of the `variables.tf` file:
```
variable "webapp_subnets" {
 description = "Isolated subnets for web applications frontend and backend"
 type =  list(object({zone = string, v4_cidr_blocks = list(string)}))
 default = [{"zone":"ru-central1-a", "v4_cidr_blocks" : ["10.130.0.0/24"]},
            {"zone":"ru-central1-b", "v4_cidr_blocks" : ["10.131.0.0/24"]},
            {"zone":"ru-central1-c", "v4_cidr_blocks" : ["10.132.0.0/24"]}]
}
```
Then go back to `vpc.tf` file and append the following lines in the bottom:
```
#Create private subnets
resource "yandex_vpc_subnet" "webapp_subnets" {
  count = length(var.webapp_subnets)
  network_id = yandex_vpc_network.vpc.id
  name = "${var.vpc_name}-webapp-${var.webapp_subnets[count.index].zone}-${count.index}"
  description = "Isolated subnet for web applications frontend and backend"
  zone = var.webapp_subnets[count.index].zone
  v4_cidr_blocks = var.webapp_subnets[count.index].v4_cidr_blocks
  route_table_id = yandex_vpc_route_table.nat_route_table_tf.id
}
```
This will do something similar to what was done in step 2.1.4 with the public subnet. These two things are different:
- We make three subnets, one for each availability zone 
- For each subnet, we attach the route table we configured in the previous step.

## Step 2.4 Create outputs
We wrapped our network configuration as a Terraform module (remember our `module "vpc_subnets"` section in the `"./02 Create Network/main.tf"`). Some of the outputs from the modules need to be exported so they can be used outside of the module.

When we make more virtual machines for our experiments, we will point them to the ids of the networks and subnets where the instances will be placed. So, these ids need to be exported.

We will also use the NAT instance, so both its public and private IP addresses need to be exported.

### Step 2.4.1 Create the `outputs.tf` file in the *module* folder
The content should be as follows:
```
output "network_id" {
  value = yandex_vpc_network.vpc.id  
}

output "webfront_subnet" {
   value = {"id":yandex_vpc_subnet.web_front_subnets.0.id,
            "zone":yandex_vpc_subnet.web_front_subnets.0.zone,
            "v4_cidr_blocks":yandex_vpc_subnet.web_front_subnets.0.v4_cidr_blocks} 
}

output "webapp_subnets" {
  value = [for s in yandex_vpc_subnet.webapp_subnets: {"id":s.id,
                                                       "zone":s.zone, 
                                                       "v4_cidr_blocks":s.v4_cidr_blocks}]
}

output "nat_instance_private_ip" {
   description = "Private IP of NAT instance and ssh bastion"
   value       = yandex_compute_instance.nat_instance_tf.network_interface.0.ip_address
}

output "nat_instance_public_ip" {
   description = "Public IP of NAT instance and ssh bastion"
   value       = yandex_compute_instance.nat_instance_tf.network_interface.0.nat_ip_address
}
``` 
### Step 2.4.2 Create the `outputs.tf` file in the *project* folder
This is to test that the export is working and the module outputs are visible in the main project. We only test on a sample outputs, not the entire set. Note that the values are read from `module.vpc_subnets` outputs, not from Yandex Provider.

The content of the `outputs.tf` should be as follows:
```
output "network_id" {
  value = module.vpc_subnets.network_id 
}

output "webfront_subnet" {
   value = module.vpc_subnets.webfront_subnet.id
}

output "nat_instance_private_ip" {
   value = module.vpc_subnets.nat_instance_private_ip
}

output "nat_instance_public_ip" {
   value = module.vpc_subnets.nat_instance_public_ip
}
``` 
## Now repeat the steps 2.1.6 - 2.1.10
Navigate to the *project* directory and subsequently run the commands:
- `/.dterraform init`
- `/.dterraform validate`
- `/.dterraform plan`
- `/.dterraform apply --auto-approve`
- `/.dterraform destroy --auto-approve`

Once configuration applied (after `/.dterraform apply --auto-approve`) login to [Yandex Cloud account in the console](https://console.cloud.yandex.com/) and open the relevant folder. Check that the following new resources are there on the cards of the "Folder Services" grid: 
- one new network, four new subnets and one new address on the "Virtual Private Cloud" card
- one new VM and one new disk on the "Compute Cloud" card

Click on the "Virtual Private Cloud" card and select "Routing tables" menu on the left hand side. You will find the new *nat-route-table-tf* route table in the list

Select "Subnets" menu on the left hand side. You will find four new subnets. Three of them, which are private subnets will *nat-route-table-tf* attached in the "Routing table" colmn on the right hand side

Make sure that everything is destroyed once you run `/.dterraform destroy --auto-approve` to avoid unexpected charges
