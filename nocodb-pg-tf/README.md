# How to provision a basic NocoDB stack on Yandex Cloud using Terraform
This directory offers step-by-step instructions for configuring Terraform to deploy a database web application, such as [NocoDB](https://www.nocodb.com/), on a group of virtual machines in Yandex Cloud and make this app publicly accessible

## Purpose
This directory's code and readme files are intended to serve as a tutorial for using Terraform with Yandex Cloud. By following the tutorial's instructions, the learner will gain hands-on experience automating the deployment of web applications in the cloud

The tutorial addresses the following use cases:
- Creation of a virtual private cloud (VPC)
- Traffic routing in the cloud network: granting virtual machines Internet access while preventing access to the local network from the outside
- Virtual machines provisioning and bootstrapping
- Hosting and load balancing a web application on a cluster of several virtual machines
- Using a reverse proxy to route web requests, encrypt traffic, and protect against attacks
- Providing public access to a web application by URL
- Infrastructure removal to reduce costs while avoiding the loss of web application data

The learner should advance in the following technical topics after completing the tutorial:
- Using the Linux command prompt
- Docker and Compose for managing containers
- Yandex CLI and Terraform to programmatically manage infratructure in Yandex Cloud
- Cloud Init for virtual machines bootstrapping
- SSH tunneling to access resources on a local network
- Configuring the Nginx Web Server
- DNS record management 

## You will benefit from this repo materials if:
- You've heard of cloud technologies or use them yourself. You know what they're good for and want to improve your cloud skills
- You're neither a system administrator nor an infrastructure architect. But in your professional life, you interact with experts in this field, and you'd like to be able to communicate with them in their language, clearly articulate requirements, and have a basic understanding of how scalability, security, and fault tolerance of web applications in the cloud are ensured in practice
- You are a business consultant, manager, or power user of digital products looking to quickly and cheaply test a hypothesis, automate a process, or build a business application
- You are a developer who has created an application that runs on a local PC and wants to publish it on the internet

## Requirements
- Linux / MacOS / Windows with WSL2 machine connected to Internet
- Docker and optionally Compose
- A pair of ssh keys whereas a public key would be uploaded to the provisioned virtual machines 
- Yandex Cloud account that has a payment method activated, [see how-to](https://cloud.yandex.com/en-ru/docs/billing/operations/create-new-account)
- A registered domain name that you can access and manage. You should have the privileges to change the nameservers and the contents of the DNS records for your domain
> Domains can be registered for free for up to a year at registrars like freenom.com. At freenom.com, you can register a domain name in the .ml, .tk, or .gq segments for free, which should be enough for the purposes of this exercise

## How to use this tutorial
The materials are organized into five directories, each containing a Terraform manifest and a readme file. The final Terraform manifest is put together in a way that builds on itself. Each directory repeats the Terraform files from the previous directory and adds a new module on top.

The readme files are individual for each of the five directories. They contain step-by-step instructions on how to make the manifest, what commands to run to apply the settings, and how to examine the results. They also try to explain why certain parts of the code are done the way they are, so that the learner can understand what is going on and why certain things are done.

So, the best way to learn is to follow the instructions in the readme to make your own Terraform manifest from scratch. The code and templates are here to help you check your work or, if you get stuck, to show you what working code looks like.  

## What you get at the end of the day
- NocoDB app running on your own domain at https://nocodb.{your_domain.tld}, for example at https://nocodb.johnsmith.gq if you register a `johnsmith.gq` domain with freenom.com
- pgAdmin app running on https://pgadmin.{your_domain.tld}
- underlying infrastructure put together in an architecture that is made specifically for demo purposes with a view to minimize cost [\*](https://github.com/gdlyan/yc-playground/edit/master/nocodb-pg-tf/README.md#-not-for-production)
- a straightforward one line command to destroy  all the infrastructure but the data in order to reduce cost charged by the cloud provider
- a similarly simple command to get the infrastructre and apps up and running as you need them again with all the data and settings persisted 
- command line recipes to backup and restore your data from snapshots, hence to prevent data loss 
- other useful Terraform, Docker and Yandex Cloud code recipes, tips and tricks that you learn on the way    
> ###### \* Not for production 
> Under no circumstances should it be used for production as it is though. It is not  adequately secure as we expose pgAdmin to the public as well as we haven't provided any firewall rules to filter malicious traffic. It is not fault tolerant either, as we use preemptible instances that can be deliberately taken back by the cloud provider at their discretion

## Architecture diagram
This is how the architeture would look like after completion of the module [05 Enable Public Access](https://github.com/gdlyan/nocodb-pg-tf/tree/master/05%20Enable%20Public%20Access)
```
                          |                                                   
            https://nocodb.{your_domain.tld}
            https://pgadmin.{your_domain.tld}                                                
                          |                                                   
                          v                                                    
                +-----------------------+  +----------+                                      
                | Reverse proxy (Nginx) |  |    NAT   |<--------SSH------                                       
   +---webfront-----------------------------------------+                          
   |    subnet  |                       |  |          | |                     
   |            +--------+--------------+  +-----+----+ |                     
   |                     |       ^               |      |                     
   |                    http     |              SSH     |                     
   |                     |       |               |      |
   |  +------------------+       +----SSH--------+      |
   |  |                  |                       |      |
   |  |           +------+--------+              |      |
   |  |           |    Network    |              |      |                                                               
   |  |           | Load Balancer |              |      |
   |  |           +------+--------+              |      |                     
   |  |                  |                       |      |                     
   |  |                  |                       |      |                     
   |  |  subnet-a     subnet-b    subnet-c       |      |                     
   |  |                  |                       |      | 
   |  |                  |    +-------SSH--------+      | 
   |  |                  |    |                  |      | 
   | http     +----------+----+----+            SSH     |                     
   |  |       |          |         |             |      |                     
   |  |       v          v         v             |      |                     
   |  |  +--------+ +--------+ +--------+        |      |                     
   |  |  | NocoDB | | NocoDB | | NocoDB |        |      |                     
   |  |  +----+---+ +----+---+ +----+---+        |      |                     
   |  |       |          |          |            |      |                     
   |  |       |          v          |            |      |                     
   |  |       |     +----------+    |            |      |                     
   |  |       +---->| Postgres |<---+            |      |                     
   |  |             | port 5432|                 |      |   
   |  |             |          |<----------------+      |
   |  +------------>| pgAdmin  |                        |
   |                | port 80  |                        |                     
   |                +----------+                        |                     
   +----------------------------------------------------+ 
```
