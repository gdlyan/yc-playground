name: ${YC_PREFIX}-instance-group
service_account_id: ${YC_SERVICE_ACCOUNT}
instance_template:
    platform_id: standard-v3
    resources_spec:
        memory: 1g
        cores: 2
        core_fraction: 20
    boot_disk_spec:
        mode: READ_WRITE
        disk_spec:
            image_id: ${YC_IMAGE}
            type_id: network-hdd
            size: 32g             
    network_interface_specs:
        - network_id: ${YC_VPC_NETWORK}
          primary_v4_address_spec: {}
    scheduling_policy:
        preemptible: true
    metadata:
      ssh-keys: "ubuntu:${TUTORIAL_SSH_KEY}"
      user-data: |-
        #cloud-config
          package_update: true
          runcmd:
            - [apt-get, install, -y, nginx ]
            - [/bin/bash, -c, 'source /etc/lsb-release; sed -i "s/Welcome to nginx/It is $(hostname) on $DISTRIB_DESCRIPTION/" /var/www/html/index.nginx-debian.html']         
deploy_policy:
    max_unavailable: 1
    max_expansion: 0
scale_policy:
    fixed_scale:
        size: 3
allocation_policy:
    zones:
        - zone_id: ru-central1-a
        - zone_id: ru-central1-b
        - zone_id: ru-central1-c                                
load_balancer_spec:
    target_group_spec:
        name: ${YC_PREFIX}-target-group        