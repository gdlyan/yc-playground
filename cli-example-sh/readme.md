# YC CLI Quickstart
Shell files to practice CLI Yandex Cloud lesson from [Yandex Cloud Engineer Course](https://practicum.yandex.ru/ycloud). 
Tested on Ubuntu.

## Usage scenario 
First be sure to have `chmod 755 *.sh` to be able to execute the shell files in this directory. Also `jq` and `tr` utilities should be installed.

For `jq` run:
```
sudo apt update && sudo apt install -y jq && jq --version
```
For `tr` most likely no additional installation would be required, generally it comes with `coreutils` package. 
### `create.sh`
As long as you have [YC CLI installed and configured](https://cloud.yandex.com/en-ru/docs/cli/quickstart) `./create.sh` will build the following infrastructure from scratch:
- a network with three subnets, one for each availability zone, a gateway, and a routing table that allows any VM on the network to connect to the Internet via the gateway without the need for a public IP address
- a service account bound to the `editor` role
- an instance group of three Ubuntu 18.04 LTS instances managed by the previously created service account, running Nginx similarly to the original lesson, but without a public IP address, and also accessible via ssh from within the network
- a bastion host running on Centos 7 to enable ssh access into the Ubuntu instances
- a network load balancer providing the single public IP address for http requests
### `update.sh`
Running `./update.sh` will roll out Ubuntu 20.04 LTS in a similar manner as described in the original lesson
### `delete.sh`
Running `./delete.sh` will remove everything that has been created by `create.sh`