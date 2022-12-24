# 05 Enable public access to the application
Both NocoDB and pgAdmin are web applications. The normal scenario for the user to access the web application is typing some meaningful URL into a browser or clicking a link on a web page. This is different to what we have now after our previous exercises completed. So far one can only access the applications by means of SSH tunneling into the private network and forwarding the arbitrary localhost ports to the applications' addresses. Tunneling is only possible if one has the private part of the SSH key which certainly isn't something that every application user is supposed to have   

In this tutorial we will make both NocoDB and pgAdmin webapps available to public at such addresses as https://nocodb.{your_domain} and https://pgadmin.{your_domain}. Both links will refer to the same external IP address, and the *Nginx web server* will process the incoming web traffic and route the request to the right application depending on the URL specified in the request. Thus Nginx will become a single point of contact or a kind of a gateway for the client browsers or CLI commands to access the applications' interfaces.

Also we will provide our user with some basic comfort about the security of the data that they exchange with our web application. We will use SSL/TLS protocol to make sure that the traffic between the client device and the gateway is encrypted hence protected from interception. The *Nginx web server* will terminate the SSL/TLS connection, and the traffic in the private network between Nginx and the applications will be already decrypted.     

We will also legitimate our website by a kind of "stamp of authority", witnessing at least that the URL itself points to the server that belongs to us. We will use [Let's Encrypt](https://letsencrypt.org/certificates/) as such an authority.

The web server applications that serve a single point of contact and terminate SSL/TLS are often referred to as the *reverse proxy*. So in this tutorial the *Nginx web server* and the *reverse proxy* refer to the same virtual machine 

Technically we will do the following:
- Register the domain {your domain} and delegate the same to Yandex Cloud nameservers
- In the Yandex Cloud DNS create a public zone and link it to the delegated domain in order to start managing it's DNS records from the cloud
- Use `certbot` tool to perform [DNS challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) and create certificates enabling secure HTTPS connections with our website
- Spawn a *reverse proxy* and make it NAT to allow traffic from the outside of the private network without tunneling
- Add necessary A-records in the Yandex Cloud DNS in order to associate the addresses `nocodb.{your_domain}` and `pgadmin.{your_domain}` with the external IP address of the *reverse proxy* 
- Deploy the infrastructure and access the NocoDB and pgAdmin web applications from various devices connected to the Internet
- Do the independent security check for our SSL/TLS enabled web server

## Prerequisites
- You need to have the ['04 Deploy NocoDB'](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/04%20Deploy%20NocoDB) tutorial completed before starting this one
- Please copy the folder "04 Deploy NocoDB" into a new project directory named "05 Enable Public Access". We will further refer to "04 Deploy NocoDB" as to our *root module* directory or *project*  directory. You may use `cp -R  '04 Deploy NocoDB' '05 Enable Public Access'` command
- Navigate to `'05 Enable Public Access'` directory and run `./dterraform init`.  
- During completion of [02 Create Network](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/02%20Create%20Network) tutorial you should have generated  password-less ssh keys. If not yet, use the command below as an example
```
ssh-keygen -C "tutorial"  -f ~/.ssh/tutorial_id_rsa -t rsa -b 4096
```
- You will also need to have a registered domain name that you can access and manage. You should have the privileges to change the nameservers and the contents of the DNS records for your domain. 
> Normally one has to pay to a registrar for the very privelege of using the domain name. Some registrars such as freenom.com allow to register domains for free for the period up to one year. One can register a domain name in .ml or .tk or .gq segment for free at freenom.com, and this would be pretty much sufficient for the goals of this exercise
  
## Step 5.1 Delegate the domain name to Yandex Cloud
Once you rent a domain name from a registrar, typically the name is attached to the nameservers maintained by this registrar. The registrar would normally provide web interface to change the contents of the DNS records for your domain. Some registrars even offer API for managing DNS records programmatically.

Yandex Cloud, on the other hand, offers the Cloud DNS service that also provides the interfaces for both manual and programatic DNS records management. Cloud DNS, as a typical Yandex Cloud service,  supports a broader range of means to manage DNS programmatically, such as YC CLI, Terraform etc. As long as the rest of our infrastructure is built in Yandex Cloud using Terraform, it makes sense to use Yandex Cloud with Terraform  for DNS management as well.

To delegate the domain name to Yandex Cloud you should login into your account with the registrar and set the custom nameservers for the domain `ns1.yandexcloud.net` and `ns2.yandexcloud.net`. You will likely notice the warning that changes can take up to 24 hours to propogate, so please don't expect that the delegation will happen immediately. However, normally it takes considerably less than 24 hours. 

## Step 5.2 Create TLS/SSL certificates for your domain
### Step 5.2.1 Navigate to the *root module* directory, create a `proxy` *module* directory and navigate to the same
```
cd '05 Enable Public Access'
mkdir "proxy" && cd "$_"
``` 
All the remaining commands for the step 5.2 to be run from this `proxy` directory
### Step 5.2.2 Create a DNS zone for your domain
Let the DNS zone name follow the pattern `{your domain name}-public-zone`. Yandex Cloud will not accept the `.` symbol in the zone name, so let's replace the dot `.` with the dash `-`, such that for the domain name `johnsmith.gq` the zone name would look like `johnsmith-gq-public-zone`.

Note that the value for the `--zone` argument should look like a domain name ending with the dot `.` 

Run the following command replacing the `--name ` and `--zone` arguments values with the ones relevant to your domain
```
yc dns zone create --name johnsmith-gq-public-zone --zone johnsmith.gq. --public-visibility
``` 
Expected outcome:
```
id: <sanitized>
folder_id: <sanitized>
created_at: "2022-12-21T17:46:40.116Z"
name: johnsmith-gq-public-zone
zone: johnsmith.gq.
public_visibility: {}
```
### Step 5.2.3 Run `certbot` in a container to create the diretory `certs` with the certificates files
From the `proxy` *module* directory run the command (first replace `john.smith@abc.com` with your email, also replace `*.johnsmith.gq` with your domain)
```
docker run -it --rm --name certbot \
-v "$(pwd)/certs:/etc/letsencrypt" \
certbot/certbot certonly \
--manual \
--preferred-challenges=dns \
--email john.smith@abc.com \
--agree-tos \
-d *.johnsmith.gq
```
This command will pull the latest [certbot image](https://hub.docker.com/r/certbot/certbot/) from DockerHub and run `certbot` in a container. The output would look like the following:
```
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Would you be willing, once your first certificate is successfully issued, to
share your email address with the Electronic Frontier Foundation, a founding
partner of the Let's Encrypt project and the non-profit organization that
develops Certbot? We'd like to send you email about our work encrypting the web,
EFF news, campaigns, and ways to support digital freedom.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: N
Account registered.
Requesting a certificate for *.johnsmith.gq

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name:

_acme-challenge.johnsmith.gq.

with the following value:

<value - some combination of symbols that you will need to copy into the buffer>

Before continuing, verify the TXT record has been deployed. Depending on the DNS
provider, this may take some time, from a few seconds to multiple minutes. You can
check if it has finished deploying with aid of online tools, such as the Google
Admin Toolbox: https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.johnsmith.gq.
Look for one or more bolded line(s) below the line ';ANSWER'. It should show the
value(s) you've just added.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
```
**DON'T Press Enter to Continue for now.** Copy the value for the acme challenge into the buffer and proceed to the next step
### Step 5.2.3 Create a DNS TXT record for Letsencypt to validate that you are authorized to manage the DNS zone for the domain 
Open another terminal window and run the following command (again replace `johnsmith.gq` with your domain name in both `--name` and `--record` arguments)
```
yc dns zone add-records --name johnsmith-gq-public-zone \
   --record "_acme-challenge.johnsmith.gq. 600 TXT <value that you have copied into the buffer during previous step>"
```
Expected outcome:
```
+--------+-------------------------------+------+---------------------------------------------+-----+
| ACTION |              NAME             | TYPE |                    DATA                     | TTL |
+--------+-------------------------------+------+---------------------------------------------+-----+
| +      | _acme-challenge.johnsmith.gq. | TXT  | <--------value generated by certbot-------> | 600 |
+--------+-------------------------------+------+---------------------------------------------+-----+
```
### Step 5.2.4 Finalize certificates generation process
Go back to the terminal window that you've left awaiting for you to Press Enter to Continue. Do Press Enter to Continue now. The successful outcome should look like the following:
```
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/johnsmith.gq/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/johnsmith.gq/privkey.pem
This certificate expires on 2023-03-21.
These files will be updated when the certificate renews.

NEXT STEPS:
- This certificate will not be renewed automatically. Autorenewal of --manual certificates requires the use of an authentication hook script (--manual-auth-hook) but one was not provided. To renew this certificate, repeat this same certbot command before the certificate's expiry date.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
```
You will also notice that a new directory `certs` has been created inside the `proxy` module directory. This is the where all the certificates have been written into. 
### Step 5.2.5 Change ownership on `certs` directory
If you run `ls -l` you will see that the `certs` directory is owned by *root*. This makes the files in this directory invisible to you unless you explore the directory as a root user using `sudo su` command.

In this tutorial we run Terraform as a non-root user, and we will further want to copy the certificates to a reverse proxy server as part of its bootstrapping. We will run into an error if we try to copy the files that are invisible to us. The easiest way to fix this is changing the ownership of the `certs` directory 
```
sudo chown -R $USER certs 
```
Congratulations! You have delegated your domain to Yandex Cloud nameservers and created the SSL/TLS certificates! Now we can go back to Terraform manifest for the reverse proxy

## Step 5.3 Create reverse proxy configuration file
In this step we will instruct Terraform to create an Nginx configuration file and save it locally under `./proxy/nginx/` path
### Step 5.3.1 Create the `providers.tf` for the `proxy` module
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
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }        
  }
  required_version = ">= 0.13"
}
```
There is one provider that we have not used so far, which is `local`. This provider is required when we want to save locally the file generated from the template. 
### Step 5.3.2 Create a template for Nginx configuration
In the `proxy` directory create a file `nginx.tpl.conf` with the following content:
```
map $http_upgrade $connection_upgrade {
        default upgrade;
        ''      close;
}

#nocodb webapp
upstream webapp {
      server ${NLB_INSTANCE_PRIVATE_IP}:80 fail_timeout=0;
}

server {
        server_name ${SUBDOMAIN}.${DOMAIN};
        listen 80;
        listen [::]:80;
        # Redirect to ssl
        return 301 https://$host$request_uri;
}
server {
        server_name ${SUBDOMAIN}.${DOMAIN};
        listen 443 ssl http2 ;
        listen [::]:443 ssl http2;
        client_max_body_size 500M;
        ssl_session_timeout 5m;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;

        #certificates
        ssl_certificate /etc/nginx/certs/fullchain1.pem;
        ssl_certificate_key /etc/nginx/certs/privkey1.pem;

        # the browser should remember over 1 year that a site and its subdomains
        # are only to be accessed using HTTPS 
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # prevents the browser from doing MIME-type sniffing.
        # Most browsers are now respecting this header, 
        # including Chrome/Chromium, Edge, IE >= 8.0, Firefox >= 50 and Opera >= 13.
        # See : https://blogs.msdn.com/b/ie/archive/2008/09/02/ie8-security-part-vi-beta-2-update.aspx?Redirected=true
        add_header X-Content-Type-Options nosniff;

        # Expose logs to "docker logs"
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;


        location / {
        proxy_pass http://webapp;

                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection 'upgrade';
                proxy_set_header Host $host;            
       }

}

#pgadmin
upstream pgadmin {
      server ${PG_INSTANCE_PRIVATE_IP}:80 fail_timeout=0;
}

server {
        server_name pgadmin.${DOMAIN};
        listen 80;
        listen [::]:80;
        # Redirect to ssl
        return 301 https://$host$request_uri;
}
server {
        server_name pgadmin.${DOMAIN};
        listen 443 ssl http2 ;
        listen [::]:443 ssl http2;
        client_max_body_size 500M;
        ssl_session_timeout 5m;
        ssl_session_cache shared:SSL:50m;
        ssl_session_tickets off;

        #certificates
        ssl_certificate /etc/nginx/certs/fullchain1.pem;
        ssl_certificate_key /etc/nginx/certs/privkey1.pem;

        # the browser should remember over 1 year that a site and its subdomains
        # are only to be accessed using HTTPS 
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

        # prevents the browser from doing MIME-type sniffing.
        # Most browsers are now respecting this header, 
        # including Chrome/Chromium, Edge, IE >= 8.0, Firefox >= 50 and Opera >= 13.
        # See : https://blogs.msdn.com/b/ie/archive/2008/09/02/ie8-security-part-vi-beta-2-update.aspx?Redirected=true
        add_header X-Content-Type-Options nosniff;

        # Expose logs to "docker logs"
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;


        location / {
        proxy_pass http://pgadmin;

                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection 'upgrade';
                proxy_set_header Host $host;            
       }

}
```
It is beyond this tutorial's scope to deep dive into this configuration, but there are a few major thing you need to know about what this configuration is supposed to do:
- This Nginx server will expose a public IP address to the Web, and process the http requests to `pgadmin.${DOMAIN}` (for example https://pgadmin.johnsmith.gq) and to `${SUBDOMAIN}.${DOMAIN}` (for example https://nocodb.johnsmith.gq)
- Requests to `pgadmin.${DOMAIN}` will be forwarded to the Postgres SQL Server machine where our pgAdmin app should be listening at port 80 
- Requests to `${SUBDOMAIN}.${DOMAIN}` will be forwarded to the Network Load Balancer, that will further choose the best fit NocoDB virtual machine to serve the client session
- All the requests to the websites running on this Nginx server will be redirected to use the SSL connection (https). So if one tries to connect via regular http (e.g. http://nocodb.johnsmth.gq), the request will be redirected to https (which is https://nocodb.johnsmth.gq in our example) 

The `nginx.tpl.conf` file is a template, yet not a configuration file itself. Terraform will further do the following:
- Use `template` provider to substitute the placeholders `${DOMAIN}`,  `${SUBDOMAIN}`, `${NLB_INSTANCE_PRIVATE_IP}` and `${PG_INSTANCE_PRIVATE_IP}` with the values of the corresponding variables
- Use the `local` provider to save the rendered template locally in the `./proxy/nginx/nginx.conf` file on the machine where Terraform is running
- Use `null_resource`  with the `remote-exec` and `file` provisioners to create an `nginx` directory on the *reverse proxy* virtual machine under default user's home directory during its bootstrapping, and copy the configuration file `nginx.conf` into this new directory
- Likewise, use `null_resource`  with the `remote-exec` and `file` provisioners to create a `certs` directory on the *reverse proxy* machine, and copy the  `archives/${DOMAIN}` subdirectory of the local `certs` directory created by `certbot` (you remember, the one we have changed ownership for) into this new directory. This `archives/${DOMAIN}` subdirectory contains only the certificates, whereas certbot logged into the `cert` directory a lot more information that Nginx would not require in our case.
- The `nginx` Docker container running on the *reverse proxy* machine will map its `/etc/nginx/conf.d/default.conf` file into the `nginx.conf` file copied in the previous step. Also it will map `/etc/nginx/certs` directory into the `certs` directory made up in the previous step. It is `docker-compose` configuration where such mapping is specified. We will create the `docker-compose` configuration in the following step 
- Thus the Nginx server will know its new configuration and this configuration will point to the TLS/SSL certificates files. The configuration update will trigger the automated Nginx restart to apply the changes
### Step 5.3.3 Create the part of Terraform manifest that generates the Nginx configuration from the template
In the `proxy` directory create a file `proxy_instance.tf` with the following content:
```
## Generate nginx.conf
data "template_file" "nginx_conf" {
  template = file("${path.module}/nginx.tpl.conf")
  vars = {
    DOMAIN                   = var.domain
    SUBDOMAIN                = var.subdomain
    NLB_INSTANCE_PRIVATE_IP  = var.nlb_instance_private_ip
    PG_INSTANCE_PRIVATE_IP   = var.pg_instance_private_ip
  }
}

resource "local_file" "nginx_conf" {
  content = data.template_file.nginx_conf.rendered
  filename = "${path.module}/nginx/nginx.conf"
}
```
Note that the variables in the `vars` section have not yet been declared. We will do this later in one of the last steps, when we understand the full list of variables used in the module

## Step 5.4 Bootstrap the reverse proxy virtual machine and point DNS to its public IP address
### Step 5.4.1 Create a template for the docker-compose configuration
In the `proxy` directory create a file `docker-compose.tpl.yaml` with the following content:           
```
version: "3"

services:
    proxy:
        image: nginx
        container_name: web-proxy
        restart: always
        ports:
        - 80:80
        - 443:443
        volumes:
        - /home/${DEFAULT_USER}/certs:/etc/nginx/certs:ro
        - /home/${DEFAULT_USER}/nginx/nginx.conf:/etc/nginx/conf.d/default.conf
```
### Step 5.4.2 Create the part of Terraform manifest that spawns a *reverse proxy* virtual machine
Append the following code in the bottom of the `proxy_instance.tf` file:
```
# Create virtual machine
data "template_file" "docker_compose_yaml" {
  template = file("${path.module}/docker-compose.tpl.yaml")
  vars = {
    DEFAULT_USER             = var.default_user
  }
}

data "yandex_compute_image" "container_optimized_image" {
  family = "container-optimized-image"
}

resource "yandex_compute_instance" "proxy_docker_instance" {
  name = "proxy-docker-instance"
  zone = "${var.proxy_subnet.zone}"


  labels = { 
    ansible_group = "proxy_docker_instance"
  }

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
      subnet_id       = var.proxy_subnet.id
      ip_address      = cidrhost(var.proxy_subnet.v4_cidr_blocks[0], 102)
      nat = true
  }  

  metadata = {
    docker-compose = data.template_file.docker_compose_yaml.rendered
    ssh-keys = "${var.default_user}:${file("~/.ssh/${var.private_key_file}.pub")}"
  }
}
 
```
This part of the manifest defines the smallest possible preemptible virtual machine based on the Container Optimized Image, and using the previously created *docker-compose* configuration. It will also expose the dynamic public IP address  

Note that the archiecture proposed here is far from ideal in terms of the website availability and fit for production use. Our reverse proxy being a single point of contact becomes a single point of failure as well. When this virtual machine is down, the entire site becomes unavailable. Moreover, creating this instance as preemptible makes the site unavailability nearly inevitable.

We are conscious of this unavailability risk as well as we are aware of multiple methods to manage the same, such as:
- setting `preemptible  = false` 
- creating multiple Nginx instances and placing them behind the network load balancer
- using the [Application Load Balancer](https://cloud.yandex.com/en-ru/docs/application-load-balancer/) instead of Nginx. This is a production scale managed solution that is a good fit to serve the same purpose as we use Nginx for

However, as long as we are making up a toy example, we prioritize the cost over production readiness and keep the setup as cheap as possible. Also if we expect a relatively small number of concurrent users and do not promise always-on availability, then even such a tiny configuration would cope the workload quite well.     
### Step 5.4.3 Create the part of Terraform manifest that copies the Nginx configuration and certificates to the *reverse proxy* virtual machine
Append the following code in the bottom of the `proxy_instance.tf` file:
```
## Copy ssl certificates and nginx configuration to proxy
resource "null_resource" "copy_nginx_files" {
  depends_on = [yandex_compute_instance.proxy_docker_instance]
# Connection Block for Provisioners to connect to VM Instance
  connection {
    type = "ssh"
    host = yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address
    user = var.default_user
    private_key = file("~/.ssh/${var.private_key_file}")
  }

## Remote Exec Provisioner: creates a directory with nginx certificates and configuration - to further use by nginx instance
  provisioner "remote-exec" {
    inline = [
      "mkdir /home/${var.default_user}/nginx",
      "mkdir /home/${var.default_user}/certs"
    ]
  } 

## File Provisioner: Copies nginx configuration to proxy server
  provisioner "file" {
    source      = "${path.module}/nginx/"
    destination = "/home/${var.default_user}/nginx"
  }

## File Provisioner: Copies ssl certificates to proxy server
  provisioner "file" {
    source      = "${path.module}/certs/archive/${var.domain}/"
    destination = "/home/${var.default_user}/certs"
  }  
}
```
### Step 5.4.4 Create the DNS A-records for the NocoDB an pgAdmin apps pointing at the public IP address of the *reverse proxy*
In the `proxy` directory create a file `dns.tf` with the following content:
```
data "yandex_dns_zone" "public_zone" {
  name        = "${replace(var.domain, ".", "-")}-public-zone"
}

resource "yandex_dns_recordset" "a_record_nocodb" {
  zone_id = data.yandex_dns_zone.public_zone.id
  name    = "${var.subdomain}.${var.domain}."
  ttl     = 600
  type    = "A"
  data    = [yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address]
}

resource "yandex_dns_recordset" "a_record_pgadmin" {
  zone_id = data.yandex_dns_zone.public_zone.id
  name    = "pgadmin.${var.domain}."
  ttl     = 600
  type    = "A"
  data    = [yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address]
}
```
This code assumes that the public zone has been created in step 5.2.2
### Step 5.4.5 Collate all the `proxy` module input variables definitions in the `variables.tf` file
In the `proxy` directory create a file `variables.tf` with the following content:
```
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

variable "nlb_instance_private_ip" {
  description = "Private IP address on the webapp network load balancer" 
  type        = string
}

variable "domain" {
  description = "Second level domain, for example johnsmith.jq"
  type        = string
}

variable "subdomain" {
  description = "Third level domain"
  type        = string
  default     = "nocodb"
}

variable proxy_subnet {
  description = "home subnet for nginx proxy"  
  type = object({id = string, zone = string, v4_cidr_blocks = list(string)})
}
``` 
### Step 5.4.6 Declare the `proxy` module outputs
This module will produce only one output which is the public IP of the *reverse proxy*

In the `proxy` directory create a file `outputs.tf` with the following content:
```
output "reverse_proxy_public_ip" {
   description = "Public IP of Nginx reverse proxy"
   value       = yandex_compute_instance.proxy_docker_instance.network_interface.0.nat_ip_address
}
``` 
### Step 5.4.7 Call the `proxy` module from the root module
Edit the `'05 Enable Public Access'/main.tf` file and append the following lines in the bottom:
```
module "proxy" {
  source                  = "./proxy"
  nlb_instance_private_ip = module.nocodb.nlb_instance_private_ip
  pg_instance_private_ip  = module.postgres.pg_instance_private_ip
  proxy_subnet            = module.vpc_subnets.webfront_subnet
  domain                  = var.domain 
}
```
### Step 5.4.8 Update declarations for  the *root module* variables
Edit the `'05 Enable Public Access'/variables.tf` file and append the following lines in the bottom:
```
variable "domain" {
  type = string
}
```
The other new input variables introduced im the module `proxy` have the default values. If we don't send them values from the root module they will just use their defaults.  
### Step 5.4.9 Add you domain name to `terraform.tfvars` 
Edit the `'05 Enable Public Access'/terraform.tfvars` file and append the following line in the bottom (replace `johnsmith.gq` with your domain name):
```
domain  = "johnsmith.gq"  
```
### Step 5.4.10 Add the reverse proxy public IP address to the root module outputs
Edit the `'05 Enable Public Access'/outputs.tf` file and append the following line in the bottom:
```
output "reverse_proxy_public_ip" {
   value = module.proxy.reverse_proxy_public_ip
}
```

## Step 5.5 Apply the coniguration and review the outcomes
### Step 5.5.1  Apply Terraform configuration 
Navigate back to the root module directory `'05 Enable Public Access'` and run the following commands:
- `./dterraform init` - to reinitialize the providers (remember we introduced a `local` provider that we have never used before)
- `./dterraform validate` - to check for syntax errors
- `yc compute disk get --name pg-data-disk` to check if you already have the persistent data disk that you might have created during the previous tutorials
- `./dterraform plan` (or `./dterrafrom plan --var recreate_data_disk="empty"` if the last command returned ERROR) - to review the plan without making any updates to the cloud
- `./dterraform apply --auto-approve` (or `./dterrafrom plan --var recreate_data_disk="empty"` if there is yet no persistent data disk in the cloud) - to apply the plan and see if the instance group and the load balancer have been successfully created

The last command should return the following output following the Terraform log stream:
```
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.

Outputs:

nat_instance_private_ip = "10.129.0.100"
nat_instance_public_ip = "{sanitized}"
network_id = "{sanitized}"
nocodb_instances = [
  {
    "id" = "{sanitized}"
    "ip_address" = "10.131.0.30"
    "zone" = "ru-central1-b"
  },
  {
    "id" = "{sanitized}"
    "ip_address" = "10.132.0.21"
    "zone" = "ru-central1-c"
  },
  {
    "id" = "{sanitized}"
    "ip_address" = "10.130.0.14"
    "zone" = "ru-central1-a"
  },
]
pg_data_disk_id = "{sanitized}"
reverse_proxy_public_ip = "{sanitized}"
ssh_command = "ssh -L 31080:10.130.0.101:80 -L 41080:10.129.0.101:80 -i ~/.ssh/tutorial_id_rsa  tutorial@{sanitized}"
webfront_subnet = "{sanitized}"
```
### Step 5.5.2 In your browser go to `nocodb.johnsmith.gq` (replace `johnsmith.gq` with your domain name)  
If you applied Terraform  specifying `--var recreate_data_disk=empty`  you will be directed to the Nocodb signup page. Signup with a new user and explore the NocoDB functionality. 

Otherwise you will come back to NocoDB in its state you left it last time or by the moment of the last snapshot if you recretate the data disk from the snapshot. 

### Step 5.5.3 In your browser go to `pgadmin.johnsmith.gq` (replace `johnsmith.gq` with your domain name)  
If you applied Terraform  specifying `--var recreate_data_disk=empty`  you will have to totally repeat the [Step 3.4.13 Connect to PostgreSQL Server with pgAdmin](https://github.com/gdlyan/yc-playground/tree/master/nocodb-pg-tf/03%20Create%20PostgreSQL%20Server#step-3413-connect-to-postgresql-server-with-pgadmin)

Otherwise you will be required to sign in to pgAdmin, but your connection to the PostgreSQL Server will persist 

### Step 5.5.4 Scan both NocoDB and pgAdmin hosts with [SSL Server Test](https://www.ssllabs.com/ssltest/analyze.html)
Both should obtain A+ rating
### Step 5.5.5  Try to access both NocoDB and pgAdmin from different networks and devices
### Step 5.5.6 Review the changes in the Yandex Cloud Console
In the [Yandex Cloud Console](https://console.cloud.yandex.com/) navigate to the project *folder* . On the "Folder services" panel subsequently click on the following cards: 
- "Network Load Balancer" to check if the NocoDB instances are healthy
- "Compute Cloud" to explore the created instance groups, virtual machines, disks, and snapshots
- "Virtual Private Cloud" to explore subnets, IP addresses and routing tables
- "Cloud DNS" to explore DNS zones and records      

### Step 5.5.7 Destroy the infrastructure to avoid unnecessary cost
- `./dterraform destroy --auto-approve` to destroy everything but the data disk
- `yc compute disk delete --name pg-data-disk` to remove the data disk`` 

## Congratulations! You have learned how to create a Terraform manifest that deploys the generic database app MVP to the Web
Further learning steps may include:
- Making the app more secure, e.g. implement the firewall rules that only allow the traffic that is required by the apps to function properly and prohibits everything else, protect from DDoS attacks, keeping secrets in the vaults, using a private container registry instead of DockerHub etc.
- Making the app more scalable and production ready, e.g. migration of the prototype/MVP to the specialized managed services (Postgres, Kubernetes, Application Load Balancer), add logging and monitoring functionality, stress tesing etc.   
- Investigating possible use cases for NocoDB in the areas of rapid solutions prototyping and MVP development    
