# Prepare Terraform to work with Yandex Cloud
In this tutorial we will get Terraform on our local machine and connect it to your Yandex Cloud
## Prerequisites 
To complete this exercise, you will need:
- Linux / Windows with WSL2 / MacOS machine connected to Internet with sudo privileges and Docker installed
- Yandex Cloud account that has a payment method activated, [see how-to](https://cloud.yandex.com/en-ru/docs/billing/operations/create-new-account)
- Yandex Cloud CLI installed with `curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash` and initialized with `yc init` as explained in the [Getting started with the YC CLI manual](https://cloud.yandex.com/en-ru/docs/cli/quickstart)
> You may also launch virtual machine from [Yandex Cloud Toolbox](https://cloud.yandex.com/en/marketplace/products/yc/toolbox) image and work from there    
## Step 1.1 Make sure you may run Terraform on your machine 
There are already a lot of tutorials about how to install Terraform, and this one will not be one of them. It works fine if you already have Terraform on your machine. But if you choose not to, you don't have to. You can run Terraform instead inside a Docker container. This will separate Terraform from other software on your computer and make sure that no conflicts or wrong settings are made by accident. We would expect Terraform to act the same way against our manifests no matter how the client machine was set up or what was different about it.

### 1.1.1 Create a project directory for this lab and navigate to it
```
mkdir "01 Prepare Terraform for YC" && cd "$_"
```  
### 1.1.2 Create `dterraform` shell script with the following content:
```
#!/bin/bash
docker run  -it \
            -w /opt \
            -e TF_VAR_token="$(yc config get token)" \
            -e TF_VAR_cloud_id="$(yc config get cloud-id)" \
            -e TF_VAR_folder_id="$(yc config get folder-id)" \
            -v "$(pwd)"/:/opt/ \
            -v ~/.ssh:/root/.ssh \
            -v "$(pwd)"/.terraformrc:/root/.terraformrc \
            hashicorp/terraform:1.3.5 $@
```
Then run the command to add execution privilege to the current owner user of the file
```
sudo chmod +x dterraform
```
### 1.1.3 You may notice that `dterraform` expects the `.terraformrc` to present in the working directory. Create this `.terraformrc` file with the following content:
```
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```
This will let Terraform know that it should install providers from a mirror registry rather than directly from `registry.terraform.io`. This helps keeping Terraform operational in the regions where direct access to the main Terraform registry is blocked.
### 1.1.4 Run `./dterraform version` to test Terraform is there. The outcome would look similar to the one below 
```
Unable to find image 'hashicorp/terraform:1.3.5' locally
1.3.5: Pulling from hashicorp/terraform
ca7dd9ec2225: Pull complete 
ff434b3103df: Pull complete 
a3bd7bdced12: Pull complete 
Digest: sha256:98821caea83ac03b917feb04b842d7e83d45b425cc560bc3f32e838bf904aa3e
Status: Downloaded newer image for hashicorp/terraform:1.3.5
Terraform v1.3.5
on linux_amd64
```  
## Step 1.2 Initialize Yandex Cloud provider
We need to tell Terraform that we are going to use it for Yandex Cloud. To do so we need to point Terraform to a *provider* that authenticates and connects Terraform to the cloud.   
### 1.2.1 Navigate to the project directory and create there a `providers.tf` file with the following content:
```
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }    
  }
  required_version = ">= 0.13"
}
``` 
### 1.2.2 Run `./dterraform init` to initialize Terraform and observe the following outcome:
```
Initializing the backend...

Initializing provider plugins...
- Finding latest version of yandex-cloud/yandex...
- Installing yandex-cloud/yandex v0.82.0...
- Installed yandex-cloud/yandex v0.82.0 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

╷
│ Warning: Incomplete lock file information for providers
│ 
│ Due to your customized provider installation methods, Terraform was forced to calculate lock file checksums locally for the following providers:
│   - yandex-cloud/yandex
│ 
│ The current .terraform.lock.hcl file only includes checksums for linux_amd64, so Terraform running on another platform will fail to install these providers.
│ 
│ To calculate additional checksums for another platform, run:
│   terraform providers lock -platform=linux_amd64
│ (where linux_amd64 is the platform to generate)
╵

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
Ignore the *Incomplete lock file information for providers* warning. We notice it since Terraform is running inside a Docker container, but this won't have any impact on our other activities here
## Step 1.3 Connect to Yandex Cloud
Now that we have installed Yandex Cloud provider we need to use it to connect to the cloud. To authenticate yourself you need to provide Terraform an authentication token as well as references to the segments of the cloud where you want to sign Terraform in (in Yandex Cloud these are the identifiers of your cloud and folder). This is sensitive information, we don't want it to end up on any public sites. That's why we want to keep our credentials separate from the human readable Terraform manifests.
### 1.3.1 Run `yc config list` command.
If you have Yandex Cloud CLI  installed as required in the prerequisites and if you followed the [Getting started with the YC CLI manual](https://cloud.yandex.com/en-ru/docs/cli/quickstart) then the oucome of this command would look like:
```
token: <Yandex Cloud OAuth token>
cloud_id: <ID of the cloud>
folder_id: <ID of the folder>
```
The following three lines in `dterraform` automatically pass your Yandex Cloud config details to Terraform variables that we will create on the next step:
```
            -e TF_VAR_token="$(yc config get token)" \
            -e TF_VAR_cloud_id="$(yc config get cloud-id)" \
            -e TF_VAR_folder_id="$(yc config get folder-id)" \
```
If you use your host Terraform installation then you need to export the same environment variables running the following command:
```
export TF_VAR_token="$(yc config get token)" && \
export TF_VAR_cloud_id="$(yc config get cloud-id)" && \
export TF_VAR_folder_id="$(yc config get folder-id)"
``` 
> Note that Yandex Cloud users can also authenticate as [service accounts](https://cloud.yandex.com/en-ru/docs/cli/operations/authentication/service-account) and as [federates users](https://cloud.yandex.com/en-ru/docs/cli/operations/authentication/federated-user). When numerous users cooperate within the same cloud with restricted access and roles separation, this is a common practice. However, because this article assumes you have full control over the cloud, we won't get into the nuances of these methods of authentication. 

### 1.3.2 Create a `variables.tf` file with the following content
```
variable "token" {
  description = "echo $TF_VAR_token (env varriable should be exported in advance) or set in terraform.tfvars"
  type        = string
}

variable "cloud_id" {
  description = "Yandex cloud id from yc config list"
  type        = string
}

variable "folder_id" {
  description = "Yandex folder id from yc config list"
  type        = string
}
```
Here we declare input variables. Terraform will look into the following registers for the values to be assigned to the declared variables:
- Values of the environment variables whose name starts with `TF_VAR_`. This is how we pass the values to input variables in our particular case
- File terraform.tfvars, each line of that has the format "variable = value"
- Manual user input whe running `terraform plan`,  `terraform apply` and `terrafor destroy` commands
- Default value if they are assigned during declaration (not for the thre variables above)    
### 1.3.3 Create a `main.tf` file with the following content
```
provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}
```
This is where cloud connnection happens. We call the provider plugin and pass as the arguments the values of the three Terraform variables declared above 
### 1.1.4 Run `./dterraform plan` and verify that the outcome is similar to the following:
```
No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration and found no differences, so no changes are needed.
```

## Now Terraform is connected to the cloud and you are ready to create infrastructure in an organized and automated manner